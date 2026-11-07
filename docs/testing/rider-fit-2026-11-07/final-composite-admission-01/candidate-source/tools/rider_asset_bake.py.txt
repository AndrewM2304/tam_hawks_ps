#!/usr/bin/env python3
"""Build pinned CC0 rider derivatives without running an engine or downloading data.

Defaults to ignored staging output. Source body, full skin atlas, fitting cages,
diagnostic arrays and unselected source assets are never copied to runtime.
Requires numpy, Pillow and scipy. Acquire sources with rider_asset_acquire.py.
"""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import tempfile
from PIL import Image

import rider_asset_fit as fit
import rider_asset_accessories as accessories
import rider_asset_head as head
import rider_asset_laces as laces
import rider_asset_shoes as shoes
import rider_asset_skin as skin
import rider_asset_surfaces as surfaces


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verified(path, size, sha256):
    if not path.is_file() or path.stat().st_size != size or digest(path) != sha256:
        raise RuntimeError(f"Pinned source differs or is missing: {path}")


def verify_sources(root, manifest_path):
    manifest = json.loads(manifest_path.read_text())
    if manifest['licence'] != 'CC0-1.0' or len(manifest['members']) != 21:
        raise RuntimeError('Unexpected selected-source manifest; review provenance before changing it.')
    source = root / '.local/downloads/mh_skin'
    names = [Path(record['member']).name for record in manifest['members']]
    if len(names) != len(set(names)):
        raise RuntimeError('Flattened source cache would contain a basename collision.')
    headers = {}
    for record in manifest['members']:
        path = source / Path(record['member']).name
        verified(path, record['bytes'], record['sha256'])
        if path.suffix in ('.obj', '.mhclo', '.mhmat'):
            lines = path.read_text().splitlines()[:30]
            if not any('CC0' in line for line in lines):
                raise RuntimeError(f'No inspected explicit CC0 header: {path.name}')
            headers[record['member']] = lines
    body_manifest = json.loads((root / 'game/art/assets/makehuman_hm08/manifest.json').read_text())
    body_source = root / '.local/downloads/makehuman_hm08'
    if set(body_manifest['sources']) != {'base.obj', 'african-male-young.target', 'asian-male-young.target', 'caucasian-male-young.target'}:
        raise RuntimeError('Unexpected original body/morph selection.')
    for name, record in body_manifest['sources'].items():
        verified(body_source / name, record['bytes'], record['sha256'])
    for name in ('head.obj', 'left_hand.obj', 'right_hand.obj'):
        record = body_manifest['outputs'][name]
        verified(root / 'game/art/assets/makehuman_hm08' / name, record['bytes'], record['sha256'])
    skin_source = source / 'young_lightskinned_male_diffuse.png'
    if not skin_source.is_file() or digest(skin_source) != skin.SKIN_SHA256:
        raise RuntimeError('The explicitly licensed skin source is missing or differs.')
    skin_header = source / 'young_caucasian_male.mhmat'
    if not skin_header.is_file() or digest(skin_header) != '6eda60b07ff2afbde078a2535ef3913593d84e9de92b2eb76c30f396a181fe2e':
        raise RuntimeError('The pinned skin licence declaration is missing or differs.')
    return manifest, headers, source, body_source


def build(root, manifest_path, output, include_skin=True, garment_fit=None):
    manifest, headers, source, body_source = verify_sources(root, manifest_path)
    staging_parent = root / '.local/rider-fitted-build'
    staging_parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='build-', dir=staging_parent) as directory:
        work = Path(directory)
        exported = work / 'selected'
        exported.mkdir()
        fit.configure(root, source, body_source, work, garment_fit)
        head.restore(fit, work)
        fit.main()
        shoes.bake(fit, work)
        laces.bake(fit, work, exported)
        if include_skin:
            skin.bake_all(root, exported)
        surfaces.bake(fit, work, exported)
        accessories.bake(fit, work, exported)
        copies = {
            'fitted-head-natural.obj': 'fitted_head.obj',
            'fitted-short02.obj': 'fitted_hair.obj',
            'fitted-casual01.glb': 'fitted_outfit.glb',
            'cloth-landmarks.json': 'fitted_landmarks.json',
            'cloth-fit.json': 'fitted_fit.json',
            'source-neck-helper-map.json': 'source-neck-helper-map.json',
            'head-neck-restoration.json': 'head-neck-restoration.json',
            'shoe-fit.json': 'footwear-fit.json',
        }
        for side in ('left', 'right'):
            for part in ('sole', 'upper'):
                copies[f'fitted-shoe-{side}-{part}.obj'] = f'fitted_shoe_{side}_{part}.obj'
        for old, new in copies.items():
            shutil.copy2(work / old, exported / new)
        if garment_fit is not None:
            shutil.copy2(garment_fit, exported / 'fitted-garment-fit.json')
        (exported / 'fitted-source-pins.json').write_text(json.dumps(manifest, indent=2) + '\n')
        (exported / 'fitted-licence-headers.json').write_text(json.dumps(headers, indent=2) + '\n')
        generators = {p.name: digest(p) for p in sorted(Path(__file__).parent.glob('rider_asset_*.py'))}
        maps = {}
        for path in sorted(exported.glob('*.png')):
            with Image.open(path) as image:
                maps[path.name] = {'sha256': digest(path), 'bytes': path.stat().st_size,
                    'width': image.width, 'height': image.height, 'mode': image.mode}
        surface_manifest = {
            'schema': 1,
            'authorship': 'Selected CC0 MakeHuman skin, hair, wardrobe, footwear, eyes and brow derivatives; original deterministic roughness/normal maps, source fitting, flat laces and NPC apron. No AI-generated images or copied program/rig/animation code.',
            'skin_source': {
                'url': manifest['archive'],
                'member': 'skins/young_caucasian_male/young_lightskinned_male_diffuse.png',
                'sha256': skin.SKIN_SHA256, 'licence': 'CC0-1.0',
                'notice': 'game/art/rider/SKIN-NOTICE.md',
                'adaptation': 'Mask used head and authenticated exposed-chest UV islands; opaque eyes use a verified unused head RGB region. Each original hand uses positive uniform material UV scale/offset and repeat to pack its two real palm/nail islands into512 with12pixel padding; original mesh attributes unchanged. Full body atlas stays ignored.',
            },
            'geometry_uv_source': 'Existing CC0 anatomical manifest plus exact21 selected system-pack members in fitted-source-pins.json; fitted source correspondences in fitted_landmarks.json.',
            'generator': 'tools/rider_asset_bake.py',
            'generator_sha256': generators['rider_asset_bake.py'],
            'generator_chain': {'tools/' + name: sha256 for name, sha256 in generators.items()},
            'fitted_provenance': 'game/art/rider/fitted-manifest.json',
            'selected_source_manifest': 'game/art/rider/fitted-source-pins.json',
            'selected_source_manifest_sha256': digest(manifest_path),
            'hand_atlas_layout': 'game/art/rider/hand-atlas-layout.json',
            'resolution_policy': 'Head RGB albedo2048/normal1024/roughness512; hands albedo/normal/roughness512; hair1024RGBA; brows256RGBA; cloth1024RGB/normal512; shoes1024RGB; shared vest/reflector512RGBA. Native skateboard atlas unchanged.',
            'maps': maps,
            'retired_resources': ['cloth_albedo.png', 'cloth_normal.png', 'cloth_roughness.png',
                'hair_albedo.png', 'suede_albedo.png', 'suede_normal.png', 'short_crop.obj', 'short_crop.json'],
        }
        (exported / 'manifest.json').write_text(json.dumps(surface_manifest, indent=2) + '\n')
        outputs = {p.name: {'bytes': p.stat().st_size, 'sha256': digest(p)} for p in sorted(exported.iterdir())}
        report = {
            'schema': 1,
            'scope': 'Reproducible source build, not native motion, Main, visual or target performance acceptance.',
            'source_manifest_sha256': digest(manifest_path),
            'original_body_manifest_sha256': digest(root / 'game/art/assets/makehuman_hm08/manifest.json'),
            'generator_sha256': generators,
            'outputs': outputs,
        }
        (exported / 'fitted-manifest.json').write_text(json.dumps(report, indent=2) + '\n')
        output.mkdir(parents=True, exist_ok=True)
        for path in sorted(exported.iterdir()):
            temporary = output / ('.' + path.name + '.tmp')
            shutil.copy2(path, temporary)
            temporary.replace(output / path.name)
        return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project-root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--source-manifest', type=Path)
    parser.add_argument('--output', type=Path, help='Selected derivatives only; default is ignored staging.')
    parser.add_argument('--garment-fit', type=Path, help='Source-authenticated offline wardrobe fit; defaults to the published fit when present.')
    parser.add_argument('--skip-skin', action='store_true', help='Development fitting reproduction; does not produce a complete runtime asset set.')
    args = parser.parse_args()
    root = args.project_root.resolve()
    manifest_path = args.source_manifest or root / 'game/art/rider/fitted-source-pins.json'
    output = args.output or root / '.local/rider-fitted-build/output'
    garment_fit = args.garment_fit or root / 'game/art/rider/fitted-garment-fit.json'
    report = build(root, manifest_path, output, not args.skip_skin, garment_fit if garment_fit.is_file() else None)
    print(f"Built {len(report['outputs'])} selected rider derivatives in {output}")
