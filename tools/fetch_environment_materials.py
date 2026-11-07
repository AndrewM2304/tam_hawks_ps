#!/usr/bin/env python3
"""Fetch or verify the inspected free CC0 materials; no runtime dependency.

Fetch repeats the documented subset and refuses changed upstream bytes against
the saved manifest. --verify-only performs no network or writes: it validates
source bytes/dimensions and tracked mipmap/compression/size-limit contracts.
"""
from __future__ import annotations
import argparse
import concurrent.futures
import datetime
import hashlib
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'game/art/assets/environment_pbr'
ZC_REV = 'a866769b0ccb5e041f8855a52223d7d1a1166125'
POLY_ASSETS = [('pavement_01', 1.5), ('sandstone_blocks_04', 3.0), ('asphalt_02', 3.0)]
ZC_ASSETS = [('T_grass01', 1.5), ('T_wood01', 2.0)]
IMPORT_POLICY = {
    'mipmaps': True, 'filter': 'linear anisotropic', 'maximum_dimension': 2048,
    'maximum_dimension_by_map': {'albedo': 2048, 'normal_opengl': 1024, 'arm': 1024, 'zc_materials_all_maps': 1024},
    'added_texture_budget_mib': 32,
    'desktop_vram_compression': {
        'high_quality': False,
        'cache_targets': 'S3TC/ETC2 remaps trigger ordinary editor reimport without deleting cached files',
        'opaque': 'S3TC DXT1 (BC1)',
        'normal': 'RGTC_RG (BC5); reconstruct positive Z from RG',
        'allowed_native_formats': ['DXT1', 'DXT5', 'RGTC_R', 'RGTC_RG'],
        'reason': 'Compatibility desktop OpenGL including macOS4.1; BC7/BPTC requires an extension unavailable in the observed AppleM5 driver',
    },
    'budget_note': 'Declared additional resident GPU texture ceiling; actual renderer memory must be measured. Primary albedo remains 2K, normals and packed roughness/AO import at 1K; close/chase comparison must verify the normal-map resource reduction.',
}
PACKED_CHANNELS = {'red': 'ambient occlusion', 'green': 'roughness', 'blue': 'metallic (unused on dielectric stone/asphalt)'}

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def jpeg_dimensions(data: bytes) -> list[int]:
    if not data.startswith(b'\xff\xd8'):
        raise ValueError('Expected a JPEG source')
    offset = 2
    while offset + 4 < len(data):
        if data[offset] != 255:
            raise ValueError('Malformed JPEG marker')
        while data[offset] == 255:
            offset += 1
        marker = data[offset]
        offset += 1
        if marker in [0x01, *range(0xD0, 0xDA)]:
            continue
        length = int.from_bytes(data[offset:offset + 2], 'big')
        if marker in [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF]:
            return [int.from_bytes(data[offset + 5:offset + 7], 'big'), int.from_bytes(data[offset + 3:offset + 5], 'big')]
        if length < 2:
            raise ValueError('Malformed JPEG segment')
        offset += length
    raise ValueError('JPEG source dimensions are unavailable')

def size_limit(asset: str, channel: str) -> int:
    return 1024 if asset.startswith('T_') or channel in ['normal_opengl', 'arm'] else 2048

def apply_import_policy(path: Path, asset: str, channel: str) -> None:
    import_path = Path(str(path) + '.import')
    resource_path = 'res://' + path.relative_to(ROOT).as_posix()
    text = import_path.read_text() if import_path.exists() else f'[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\n\nsource_file="{resource_path}"\n\n[params]\n'
    if '[params]' not in text:
        raise ValueError(f'{import_path}: missing importer parameters')
    parameters = {'compress/mode': '2', 'compress/high_quality': 'false',
                  'compress/normal_map': '1' if channel == 'normal_opengl' else '2',
                  'mipmaps/generate': 'true', 'mipmaps/limit': '-1',
                  'process/normal_map_invert_y': 'false',
                  'process/size_limit': str(size_limit(asset, channel)),
                  'roughness/mode': '0', 'roughness/src_normal': '""',
                  'detect_3d/compress_to': '0'}
    for key, value in parameters.items():
        pattern = rf'^{re.escape(key)}=.*$'
        if re.search(pattern, text, flags=re.MULTILINE):
            text = re.sub(pattern, key + '=' + value, text, flags=re.MULTILINE)
        else:
            text += '\n' + key + '=' + value
    # Keep the authored cache targets consistent with the compatible policy.
    # A normal editor import sees missing S3TC/ETC2 targets and regenerates them
    # even if its previous filesystem cache is absent; no cache wipe is needed.
    text = text.replace('path.bptc=', 'path.s3tc=').replace('.bptc.ctex', '.s3tc.ctex')
    text = text.replace('path.astc=', 'path.etc2=').replace('.astc.ctex', '.etc2.ctex')
    import_path.write_text(text.rstrip() + '\n')

def fetch_material(entry: tuple, provider: str, previous: dict) -> tuple:
    asset, metres = entry
    if provider == 'Poly Haven':
        channels = {'albedo': 'diff', 'normal_opengl': 'nor_gl', 'arm': 'arm'}
        urls = {key: f'https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/{asset}/{asset}_{suffix}_2k.jpg' for key, suffix in channels.items()}
        author, source_url = 'Rob Tuytel / Poly Haven', f'https://polyhaven.com/a/{asset}'
    else:
        channels = {'albedo': 'albedo', 'normal_opengl': 'normal_opengl', 'ambient_occlusion': 'ao'}
        urls = {key: f'https://raw.githubusercontent.com/DaZCDude/ZCs-Spectacular-Textures/{ZC_REV}/textures/{asset}/{asset}_{suffix}.jpg' for key, suffix in channels.items()}
        author = 'ZC / DaZCDude'
        source_url = f'https://github.com/DaZCDude/ZCs-Spectacular-Textures/tree/{ZC_REV}/textures/{asset}'
    folder = DEST / asset
    folder.mkdir(parents=True, exist_ok=True)
    files, hashes, sizes, dimensions = {}, {}, {}, {}
    for key, url in urls.items():
        with urllib.request.urlopen(url, timeout=90) as response:
            data = response.read()
        old_hash = previous.get(asset, {}).get('file_sha256', {}).get(key)
        if old_hash and old_hash != sha(data):
            raise RuntimeError(f'{asset}/{key}: upstream bytes changed; inspect before accepting')
        name = url.rsplit('/', 1)[-1]
        path = folder / name
        path.write_bytes(data)
        apply_import_policy(path, asset, key)
        files[key] = 'res://' + path.relative_to(ROOT).as_posix()
        hashes[key], sizes[key], dimensions[key] = sha(data), len(data), jpeg_dimensions(data)
    return asset, {'source_url': source_url, 'download_urls': urls, 'creator': author,
                   'provider': provider, 'licence': 'CC0-1.0', 'tile_size_m': metres,
                   'scale_evidence': 'Published width on inspected official asset page' if provider == 'Poly Haven' else 'Authored starting scale; source supplies no physical dimensions',
                   'files': files, 'file_sha256': hashes, 'file_bytes': sizes, 'source_dimensions_px': dimensions}

def manifest_for(materials: dict, retrieved_utc: str) -> dict:
    return {'schema': 1, 'licence': 'CC0-1.0',
            'licence_urls': ['https://polyhaven.com/license', f'https://github.com/DaZCDude/ZCs-Spectacular-Textures/blob/{ZC_REV}/LICENSE'],
            'inspected_utc_date': '2026-11-06', 'retrieved_utc': retrieved_utc,
            'images_modified': False, 'normal_convention': 'OpenGL +Y',
            'packed_arm_channels': PACKED_CHANNELS, 'import_policy': IMPORT_POLICY,
            'materials': materials}

def verify(manifest: dict) -> None:
    if manifest.get('import_policy') != IMPORT_POLICY or manifest.get('packed_arm_channels') != PACKED_CHANNELS:
        raise ValueError('Manifest import policy/packed channel schema differs from the declared contract')
    count = 0
    for asset, entry in manifest['materials'].items():
        for key, resource in entry['files'].items():
            path = ROOT / resource.removeprefix('res://')
            data = path.read_bytes()
            if sha(data) != entry['file_sha256'][key] or len(data) != entry['file_bytes'][key] or jpeg_dimensions(data) != entry['source_dimensions_px'][key]:
                raise ValueError(f'{asset}/{key}: source image integrity/dimensions differ')
            settings = Path(str(path) + '.import').read_text()
            expected = {'compress/mode': '2', 'compress/high_quality': 'false', 'compress/normal_map': '1' if key == 'normal_opengl' else '2',
                        'mipmaps/generate': 'true', 'process/normal_map_invert_y': 'false',
                        'process/size_limit': str(size_limit(asset, key))}
            for property_name, value in expected.items():
                if not re.search(rf'^{re.escape(property_name)}={re.escape(value)}$', settings, flags=re.MULTILINE):
                    raise ValueError(f'{asset}/{key}: {property_name} must equal {value}')
            if '.bptc.ctex' in settings or '.astc.ctex' in settings:
                raise ValueError(f'{asset}/{key}: cache targets retain unsupported high-quality compression')
            count += 1
    if count != 15:
        raise ValueError(f'Expected exactly 15 inspected maps, found {count}')
    rebuilt = manifest_for(manifest['materials'], manifest['retrieved_utc'])
    if rebuilt != manifest:
        raise ValueError('Repeat manifest generation would alter the saved schema or authored policy')
    print(f'VERIFY: {len(manifest["materials"])} materials / {count} exact maps / stable repeat schema / import contracts passed; no network or writes')

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-only', action='store_true')
    arguments = parser.parse_args()
    manifest_path = DEST / 'manifest.json'
    if arguments.verify_only:
        verify(json.loads(manifest_path.read_text()))
        return
    DEST.mkdir(parents=True, exist_ok=True)
    previous = json.loads(manifest_path.read_text()).get('materials', {}) if manifest_path.exists() else {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        futures = [pool.submit(fetch_material, entry, 'Poly Haven', previous) for entry in POLY_ASSETS]
        futures += [pool.submit(fetch_material, entry, 'ZC', previous) for entry in ZC_ASSETS]
        materials = dict(f.result() for f in futures)
    manifest = manifest_for(materials, datetime.datetime.now(datetime.timezone.utc).isoformat())
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    verify(manifest)
    print(f'Fetched {len(materials)} inspected CC0 materials, {sum(sum(x["file_bytes"].values()) for x in materials.values()):,} retained bytes')

if __name__ == '__main__':
    main()
