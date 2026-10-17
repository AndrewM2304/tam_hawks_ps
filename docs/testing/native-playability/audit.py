#!/usr/bin/env python3
"""Independent playability audit adapted from native-exchange-gallery/audit.py; run only after final clean build release."""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import plistlib
import posixpath
import re
import shutil
import stat
import struct
import subprocess
import wave
import zipfile
import zlib


def sha(data):
    return hashlib.sha256(data).hexdigest()


def file_sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        while block := stream.read(2 * 1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def safe_path(value):
    path = pathlib.PurePosixPath(value)
    return bool(value) and bool(path.parts) and not path.is_absolute() and '..' not in path.parts and '\\' not in value and '\x00' not in value and ':' not in path.parts[0]


# Final content/capture contract released by geometry/planning/integration.
CAPTURE_COUNT = 19
CAPTURE_SLICE = 'ordinary_launch_camera_response_and_exploration_repair'
CONTRACT_READY = True

REQUIRED_MODULES = (
    'game/characters/market_encounter.gd',
    'game/characters/market_actor.gd',
    'game/levels/art/barras_market.gd',
    'game/levels/art/clyde_landmarks.gd',
    'game/levels/art/exchange_gallery.gd',
    'game/player/skate_response.gd',
    'game/player/chase_camera.gd',
    'game/levels/exploration_boundary.gd',
)
PROBE = pathlib.Path(__file__).with_name('pack_probe.gd').read_text()
ERRORS = re.compile(r'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:|TIMEOUT')


def audit_source_launch(path, evidence, root):
    require(evidence['schema'] == 1 and evidence['passed'] is True, 'Cold-source launch receipt did not pass')
    for key in ('initial_cache_absent', 'cold_import_created_cache', 'copied_main_restored', 'copied_source_unchanged', 'source_stable'):
        require(evidence[key] is True, 'Source-launch invariant failed: ' + key)
    require(not evidence['changed_inputs'] and evidence['input_count'] == len(evidence['source_inputs']), 'Source-launch source count/stability differs')
    fingerprint = sha(json.dumps(evidence['source_inputs'], sort_keys=True, separators=(',', ':')).encode())
    require(fingerprint == evidence['source_fingerprint'] == evidence['source_fingerprint_after'], 'Source-launch nested fingerprint mismatch')
    require(file_sha(root / 'tools/source_launch_smoke.py') == evidence['helper_sha256'], 'Source-launch helper differs from recorded invocation')
    for name, item in evidence['source_inputs'].items():
        require(safe_path(name), 'Unsafe source-launch input path')
        source = root / name
        require(source.is_file() and not source.is_symlink() and file_sha(source) == item['sha256']
                and source.stat().st_size == item['bytes'] and oct(source.stat().st_mode & 0o777) == item['mode'],
                'Source-launch input hash/size/mode differs: ' + name)
    phases = evidence['phases']
    require([phase['name'] for phase in phases] == ['cold', 'normal-branch', 'warm', 'invalid-source'], 'Missing/reordered source-launch phases')
    inspected = {}
    for phase in phases:
        name = phase['name']
        require(phase['accepted'] and not phase.get('timed_out', False), 'Source-launch phase did not complete: ' + name)
        require('--script' not in phase['command'] and '-s' not in phase['command'], 'Source-launch evidence bypassed ordinary scene entry')
        require('--headless' in phase['command'] and '--audio-driver' in phase['command'] and 'Dummy' in phase['command'], 'Unexpected source-launch execution mode')
        texts = {}
        for kind, digest_key, lines_key in [('log', 'log_sha256', 'error_lines'), ('import_log', 'import_sha256', 'import_error_lines')]:
            filename = phase[kind]
            require(safe_path(filename) and '/' not in filename, 'Unsafe source-launch log path')
            log = path.parent / filename
            require(file_sha(log) == phase[digest_key], 'Source-launch log hash mismatch: ' + filename)
            texts[kind] = log.read_text(errors='replace')
            require([line for line in texts[kind].splitlines() if ERRORS.search(line)] == phase[lines_key], 'Source-launch error scan differs: ' + filename)
        if name == 'invalid-source':
            require(phase['exit_code'] != 0 and phase['launcher_refused'] and phase['parse_error_detected'], 'Injected source error was not refused')
            require('Game assets could not be prepared; the game was not started.' in texts['log']
                    and 'Parse Error:' in texts['import_log'], 'Missing actual launcher refusal/parse diagnostic')
        else:
            require(phase['exit_code'] == 0 and not phase['error_lines'] and not phase['import_error_lines'], 'Source-launch clean phase failed')
            if name == 'normal-branch':
                found = re.findall(r'^PLAYABILITY RESULT: ([1-9][0-9]*) passed, 0 failed$', texts['log'], re.MULTILINE)
                marker = 'PASS: playability boot: unmodified Main enters its actual paused title branch'
                count = texts['log'].splitlines().count(marker)
                require(len(found) == 1 and int(found[0]) == phase['passed'] and phase['failed'] == 0
                        and count == phase['normal_title_branch_count'] and count > 0,
                        'Normal source title branch/result differs from actual log')
                require('res://tests/playability_boot.tscn' in phase['command'] and '--fixed-fps' in phase['command'], 'Wrong normal-scene harness command')
            else:
                require('--quit-after' in phase['command'] and phase['command'][phase['command'].index('--quit-after') + 1] == '5', 'Wrong bounded normal-main workload')
        inspected[name] = {'exit_code':phase['exit_code'], 'stdout_sha256':phase['log_sha256'],
                           'import_sha256':phase['import_sha256'], 'expected_negative_test':name == 'invalid-source'}
    return {'initial_cache_absent':True, 'all_nested_inputs_match_source':True, 'source_fingerprint':fingerprint,
            'normal_title_branch_count':phases[1]['normal_title_branch_count'], 'normal_scene_passed':phases[1]['passed'],
            'logs_hashes_and_error_scans_match':True, 'phases':inspected, 'native_or_hardware_acceptance_claim':False}


def audit_suite(path, evidence):
    require(evidence['command'] == './tools/check.sh' and evidence['exit_code'] == 0 and evidence['passed'] > 0
            and evidence['failed'] == 0 and evidence['source_stable'] and not evidence['changed_inputs']
            and not evidence['engine_script_errors'], 'Ordinary suite was not clean/stable/passing')
    candidates = [log for log in path.parent.glob('*.log') if file_sha(log) == evidence['log_sha256']]
    require(candidates, 'Ordinary suite actual log missing or changed')
    text = candidates[0].read_text(errors='replace')
    results = re.findall(r'^RESULT: ([1-9][0-9]*) passed, 0 failed$', text, re.MULTILINE)
    require(len(results) == 1 and int(results[0]) == evidence['passed'] and not ERRORS.search(text), 'Ordinary suite log differs from receipt')
    return {'passed':evidence['passed'], 'failed':0, 'exit_code':0, 'actual_log':candidates[0].name,
            'log_sha256':evidence['log_sha256'], 'source_stable':True}



def audit_captures(path, evidence, entries):
    """Validate bytes/PNG structure and final source overlap, not visual acceptance."""
    require(evidence['schema_version'] == 5, 'Unexpected playability capture schema')
    require(evidence['expected_captures'] == len(evidence['captures']) == CAPTURE_COUNT, 'Unexpected current district capture count')
    require(evidence['valid_capture_set'] and evidence['source_stable_capture_set'] and not evidence['source_changed_during_run'] and not evidence['changed_inputs'] and evidence['failures'] == 0, 'Capture set was not clean and stable')
    require(evidence['resolution'] == [1280, 800] and not evidence['performance_measurement'] and not evidence['target_hardware_acceptance'] and not evidence['profile_writes_enabled'], 'Unexpected capture claim/resolution')
    require(evidence['normal_scene_launch'] and evidence['actual_title_branch']
            and 'res://tools/playability_capture.tscn' in evidence['command']
            and '--script' not in evidence['command'] and '-s' not in evidence['command'],
            'Capture did not use the actual ordinary title/scene branch')
    require(evidence['route_count'] == len(evidence['routes']) == 48
            and evidence['exploration_boundary_count'] == len(evidence['exploration_boundaries']) == 58,
            'Capture does not contain current routes and boundaries')
    for filename, digest_key in [('engine.log', 'engine_log_sha256'), ('import.log', 'import_log_sha256')]:
        log = path.parent / filename
        require(file_sha(log) == evidence[digest_key] and not ERRORS.search(log.read_text(errors='replace')),
                'Capture engine/import log is changed or contains an error')
    require('PLAYABILITY CAPTURE RESULT: 19 frames, 0 failures;' in (path.parent / 'engine.log').read_text(),
            'Capture actual completion marker is missing')
    hashes = evidence['source_sha256']
    require(all(name in hashes and hashes[name] == entries[name] for name in REQUIRED_MODULES), 'Capture omits/differs for new district modules')
    images = {}
    for capture in evidence['captures']:
        name = capture['file']
        require(safe_path(name) and '/' not in name and name.endswith('.png') and name not in images, 'Unsafe/duplicate PNG path')
        image = path.parent / name
        data = image.read_bytes()
        require(sha(data) == capture['sha256'], 'Capture image hash mismatch: ' + name)
        require(len(data) == capture['bytes'] and capture['resolution'] == [1280, 800] and capture['png_crc_and_rows_valid'], 'Capture image byte/resolution metadata differs')
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'Invalid PNG signature: ' + name)
        at, packed, header, ended = 8, bytearray(), None, False
        while at < len(data):
            require(at + 12 <= len(data), 'Truncated PNG chunk')
            size = struct.unpack_from('>I', data, at)[0]
            kind = data[at+4:at+8]
            chunk = data[at+8:at+8+size]
            require(at + size + 12 <= len(data), 'Truncated PNG payload')
            crc = struct.unpack_from('>I', data, at+8+size)[0]
            require(zlib.crc32(kind+chunk) & 0xffffffff == crc, 'PNG CRC mismatch: ' + name)
            if kind == b'IHDR':
                require(header is None and at == 8 and size == 13, 'Invalid PNG header')
                header = struct.unpack('>IIBBBBB', chunk)
            elif kind == b'IDAT': packed.extend(chunk)
            elif kind == b'IEND':
                require(size == 0 and at + 12 == len(data), 'Unexpected data after PNG end')
                ended = True
            at += size + 12
        require(ended and header is not None, 'Missing PNG structure')
        width, height, depth, color, compression, filtering, interlace = header
        require((width,height) == (1280,800) and depth == 8 and color in (2,6) and compression == filtering == interlace == 0, 'Unexpected PNG encoding')
        raw = zlib.decompress(packed)
        stride = width * (3 if color == 2 else 4) + 1
        require(len(raw) == height * stride and all(raw[row*stride] in range(5) for row in range(height)), 'Invalid decompressed PNG scanlines')
        images[name] = {'bytes':len(data),'sha256':sha(data),'width':width,'height':height,'png_crc_and_scanlines_pass':True}
    require({p.name for p in path.parent.glob('*.png')} == set(images), 'Unexpected/missing capture PNGs')
    return {'capture_count':CAPTURE_COUNT,'all_image_hashes_match':True,'all_png_chunks_crc_and_scanlines_valid':True,
            'images':images,'normal_scene_launch':True,'actual_title_branch':True,'route_count':48,'boundary_count':58,
            'engine_import_log_hashes_and_error_scans_match':True,'source_capture_git_dirty':evidence['git_dirty'],
            'source_capture_commit':evidence['git_commit'],'performance_measurement':False,'subjective_acceptance_claim':False}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('build')
    parser.add_argument('--root', default='/workspace/tam_hawks_ps')
    parser.add_argument('--receipt-dir', required=True)
    parser.add_argument('--evidence', action='append', default=[])
    args = parser.parse_args()
    require(CONTRACT_READY, 'Final playability capture contract has not been released')
    root = pathlib.Path(args.root).resolve()
    build = pathlib.Path(args.build).resolve()
    output = pathlib.Path(args.receipt_dir).resolve()
    metadata_path = build / 'BUILD-METADATA.json'
    metadata_bytes = metadata_path.read_bytes()
    metadata = json.loads(metadata_bytes)
    commit = metadata['git_commit']
    entries = metadata['source_files_sha256']
    require(not metadata['working_tree_dirty'], 'Build metadata records a dirty tree')
    require(metadata['engine'].startswith('4.6.3.'), 'Wrong engine version')
    require(metadata['template_verification']['version'] == '4.6.3-stable' and metadata['template_verification']['sha512'] == 'da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68', 'Template pin differs from reviewed official release')
    template_hashes = metadata['template_verification']['extracted_sha256']
    require(template_hashes['linux_release.x86_64'] == '2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0' and template_hashes['macos.zip'] == '700a5759952b2260b7d894dc9bc4908d99ce9abe2964a76c6d2bddd4af4738b2', 'Extracted template pins differ from reviewed official release')
    # Derived from the release binary in the SHA512-pinned official templates.
    # Keep this reproducible without the ignored 1.17GB template cache.
    mac_binary_sha256 = '5a65c5e1fc81bb7816b03e1be1f902de58c1ff4b71b9a83973665f35d4f4e737'
    require(not any(metadata[key] for key in ('macos_signed', 'macos_notarized', 'macos_launch_tested')), 'Unsupported Mac acceptance claim')
    require(metadata['runtime_source_sha256'] == sha(json.dumps(entries, sort_keys=True).encode()), 'Source fingerprint mismatch')
    require(all(name in entries for name in REQUIRED_MODULES), 'New district modules absent from source manifest')
    current_inputs = [root / name for name in ('project.godot', 'export_presets.cfg', 'tools/export.sh', 'docs/PLAYER-GUIDE.md')]
    current_inputs += [path for folder in ('game', 'docs/licences') for path in (root / folder).rglob('*') if path.is_file()]
    require({str(path.relative_to(root)) for path in current_inputs} == set(entries), 'Package source set differs from checkout')
    for relative, expected in entries.items():
        require(safe_path(relative), 'Unsafe source path: ' + relative)
        require(file_sha(root / relative) == expected, 'Checkout input mismatch: ' + relative)
        blob = subprocess.check_output(['git', 'show', commit + ':' + relative], cwd=root)
        require(sha(blob) == expected, 'Git object mismatch: ' + relative)

    expected_notices = {path.name: path.read_bytes() for path in (root / 'docs/licences/third-party').glob('*.txt')}
    for name in ('GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt'):
        cached = root / '.local/export-notices' / name
        if cached.is_file():
            expected_notices[name] = cached.read_bytes()
        else:
            # Hashes below independently pin these two official notice bytes.
            with zipfile.ZipFile(build / 'TamHawksProSkater-linux.zip') as archive:
                expected_notices[name] = archive.read('NOTICES/' + name)
    for name, source in {
        'VOICE-PROVENANCE.json': 'game/audio/generated/manifest.json',
        'TEXTURE-PROVENANCE.json': 'game/art/assets/zc_textures/manifest.json',
        'HUMAN-MESH-PROVENANCE.json': 'game/art/assets/makehuman_hm08/manifest.json',
        'PROVENANCE.md': 'docs/licences/REGISTER.md',
    }.items():
        expected_notices[name] = (root / source).read_bytes()

    require(len(expected_notices) == 13, 'Expected all 13 reviewed notice/provenance records')
    require(sha(expected_notices['GODOT-LICENSE.txt']) == 'b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80', 'Godot licence differs from reviewed pin')
    require(sha(expected_notices['GODOT-COPYRIGHT.txt']) == 'b3330849267d56ddd3d62a513817506606c2195034411fe05859f0140bff9d8a', 'Godot copyright differs from reviewed pin')
    texture = json.loads(expected_notices['TEXTURE-PROVENANCE.json'])
    require(entries[texture['license_file']] == texture['license_sha256'], 'Texture licence pin mismatch')
    for material in texture['materials'].values():
        for channel, resource in material['files'].items():
            relative = resource.removeprefix('res://')
            require(entries[relative] == material['file_sha256'][channel], 'Texture provenance mismatch')
            require(entries[relative + '.import'] == material['import_config_sha256'][channel], 'Texture import provenance mismatch')
    human = json.loads(expected_notices['HUMAN-MESH-PROVENANCE.json'])
    require(entries['game/art/assets/makehuman_hm08/generate.py'] == human['generator_sha256'], 'Human generator pin mismatch')
    for notice in human['licences']:
        require(entries[notice['path']] == notice['sha256'], 'Human licence pin mismatch')
    for model in human['outputs'].values():
        require(entries[model['path'].removeprefix('res://')] == model['sha256'], 'Human mesh pin mismatch')
    voice = json.loads(expected_notices['VOICE-PROVENANCE.json'])
    for bark in voice['barks'].values():
        relative = 'game/audio/generated/' + bark['file']
        require(entries[relative] == bark['sha256'], 'Voice output provenance mismatch')
        with wave.open(str(root / relative), 'rb') as pcm:
            require(pcm.getnchannels() == 1 and pcm.getsampwidth() == 2 and pcm.getframerate() == bark['sample_rate'] == 16000 and pcm.getnframes() == bark['frames'], 'Voice PCM parameters differ from provenance')
    for log in build.glob('*.log'):
        require(not any(marker in log.read_text() for marker in ('SCRIPT ERROR:', 'Parse Error:', 'ERROR:', 'FAIL:')), 'Export/resource log contains an error: ' + log.name)

    report = {'audit': 'Independent native/source/playability construction audit', 'runtime_commit': commit,
              'clean_build': True, 'source_input_count': len(entries), 'all_source_inputs_match_git_objects_and_checkout': True,
              'runtime_source_sha256': metadata['runtime_source_sha256'], 'metadata_sha256': sha(metadata_bytes),
              'notices_and_provenance_records_each': len(expected_notices), 'archives': {}, 'source_evidence': {},
              'qe_native_launch_performed': False, 'macos_launch_tested': False, 'macos_signed': False,
              'macos_notarized': False, 'target_hardware_or_subjective_acceptance_claim': False}
    package_packs = {}
    for platform in ('linux', 'macos'):
        archive = build / ('TamHawksProSkater-' + platform + '.zip')
        package = build / platform
        packaged = json.loads((package / 'PACKAGED-RESOURCES.json').read_text())
        source_resource_report = json.loads((build / (platform + '-resources.json')).read_text())
        require({key: value for key, value in packaged.items() if key not in ('pack_path', 'pack_sha256')} == source_resource_report, 'Resource reports differ')
        require(source_resource_report['main_scene_loaded'] and len(source_resource_report['voice_streams']) == 3 and len(source_resource_report['textures']) == 4 and len(source_resource_report['human_meshes']) == 4, 'Incomplete exported resource report')
        require(all(texture['width'] == texture['height'] == 1024 and texture['mipmaps'] == 10 for texture in source_resource_report['textures'].values()), 'Texture report differs from bounded mipmap contract')
        require(all(mesh['surfaces'] >= 1 and mesh['vertices'] >= 50 for mesh in source_resource_report['human_meshes'].values()), 'Anatomical resource report is invalid')
        require(safe_path(packaged['pack_path']), 'Unsafe pack path')
        package_packs[platform] = package / packaged['pack_path']
        require(list(package.rglob('*.pck')) == [package_packs[platform]], 'Expected exactly the inspected data pack')
        require(file_sha(package_packs[platform]) == packaged['pack_sha256'], 'Pack bytes differ from inspected report')
        with zipfile.ZipFile(archive) as z:
            names = z.namelist()
            require(len(names) == len(set(names)) and all(safe_path(name) for name in names), 'Unsafe/duplicate archive paths')
            require(z.testzip() is None, 'Archive CRC failure')
            package_paths = {str(path.relative_to(package)) for path in package.rglob('*') if path.is_file() or path.is_symlink()}
            require(set(names) == package_paths, 'Archive differs from unpacked file list')
            for member in z.infolist():
                local = package / member.filename
                mode = member.external_attr >> 16
                require(stat.S_ISREG(mode) or stat.S_ISLNK(mode), 'Unexpected archive member type: ' + member.filename)
                require(not (mode & (stat.S_ISUID | stat.S_ISGID)), 'Privileged archive mode: ' + member.filename)
                require(stat.S_IMODE(mode) == stat.S_IMODE(local.lstat().st_mode), 'Archive/local mode mismatch: ' + member.filename)
                if stat.S_ISLNK(mode):
                    target = z.read(member).decode()
                    resolved = posixpath.normpath(posixpath.join(posixpath.dirname(member.filename), target))
                    require(not target.startswith('/') and safe_path(resolved), 'Unsafe symlink target')
                    require(local.is_symlink() and os.readlink(local) == target, 'Symlink content mismatch')
                else:
                    require(not local.is_symlink() and sha(z.read(member)) == file_sha(local), 'Archive member byte mismatch: ' + member.filename)
            require(z.read('BUILD-METADATA.json') == metadata_bytes, 'Embedded metadata differs')
            require(z.read('PLAYER-GUIDE.md') == (root / 'docs/PLAYER-GUIDE.md').read_bytes(), 'Guide differs')
            for name, expected in expected_notices.items():
                require(z.read('NOTICES/' + name) == expected, 'Notice/provenance mismatch: ' + name)
            require(sha(z.read(packaged['pack_path'])) == packaged['pack_sha256'], 'Archive pack identity mismatch')
            if platform == 'linux':
                executable = 'TamHawksProSkater.x86_64'
                data = z.read(executable)
                require(data[:6] == b'\x7fELF\x02\x01' and struct.unpack_from('<H', data, 18)[0] == 62, 'Expected ELF64 x86_64')
                require(sha(data) == template_hashes['linux_release.x86_64'], 'Linux binary differs from verified official template')
                architecture = 'ELF64 x86_64'
            else:
                info = plistlib.loads(z.read('Tam Hawks Pro Skater.app/Contents/Info.plist'))
                executable = 'Tam Hawks Pro Skater.app/Contents/MacOS/' + info['CFBundleExecutable']
                data = z.read(executable)
                magic, count = struct.unpack_from('>II', data)
                require(magic == 0xcafebabe and count == 2, 'Expected two-slice universal Mach-O')
                architectures = set()
                for index in range(count):
                    cpu, subtype, offset, size, align = struct.unpack_from('>IIIII', data, 8 + index * 20)
                    require(offset + size <= len(data) and data[offset:offset+4] == b'\xcf\xfa\xed\xfe', 'Invalid Mach-O slice')
                    require(struct.unpack_from('<I', data, offset + 4)[0] == cpu, 'Mach-O slice CPU mismatch')
                    architectures.add(cpu)
                require(architectures == {0x01000007, 0x0100000c}, 'Expected x86_64/arm64 slices')
                require(sha(data) == mac_binary_sha256, 'Mac binary differs from verified official template')
                architecture = 'Universal Mach-O x86_64 and arm64'
            require(stat.S_IMODE(z.getinfo(executable).external_attr >> 16) == 0o755 and stat.S_IMODE((package / executable).stat().st_mode) == 0o755, 'Executable mode differs from 0755')
        report['archives'][platform] = {'bytes': archive.stat().st_size, 'sha256': file_sha(archive), 'format': architecture,
                                        'crc_pass': True, 'unique_safe_paths': True, 'file_count': len(names),
                                        'all_members_match_package': True, 'all_member_modes_match_package': True, 'executable_mode': '0755', 'pack_sha256': packaged['pack_sha256']}

    for relative in args.evidence:
        path = pathlib.Path(relative)
        if not path.is_absolute(): path = root / path
        evidence = json.loads(path.read_text())
        hashes = evidence.get('source_sha256', evidence.get('source_files_sha256', evidence.get('input_sha256', {})))
        if 'source_inputs' in evidence:
            hashes = {name:item['sha256'] for name,item in evidence['source_inputs'].items()}
        require(isinstance(hashes, dict) and hashes, 'Evidence lacks input hashes: ' + str(path))
        require(all(safe_path(name) and file_sha(root / name) == value for name,value in hashes.items()), 'Evidence inputs differ from current source: ' + str(path))
        overlap = set(hashes) & set(entries)
        require(overlap and all(name in overlap for name in REQUIRED_MODULES), 'Evidence omits packaged playability helpers')
        require(all(hashes[key] == entries[key] for key in overlap), 'Evidence source differs from package: ' + str(path))
        evidence_report = {'sha256': file_sha(path), 'inputs': len(hashes), 'overlap': len(overlap), 'overlap_matches_build': True,
                           'all_inputs_match_current_source':True, 'overlap_paths':sorted(overlap), 'applies_to_archives':['linux','macos']}
        report['source_evidence'][str(path.relative_to(root))] = evidence_report
        if evidence.get('evidence_slice') == CAPTURE_SLICE:
            evidence_report['capture_audit'] = audit_captures(path, evidence, entries)
        elif 'source_inputs' in evidence:
            evidence_report['source_launch_audit'] = audit_source_launch(path, evidence, root)
        elif evidence.get('command') == './tools/check.sh':
            evidence_report['ordinary_suite_audit'] = audit_suite(path, evidence)

    require(any('capture_audit' in value for value in report['source_evidence'].values()), 'Current playability capture manifest is required')
    require(any('source_launch_audit' in value for value in report['source_evidence'].values()), 'Current cold-source launch receipt is required')
    require(any('ordinary_suite_audit' in value for value in report['source_evidence'].values()), 'Current ordinary-suite receipt is required')

    # Supplemental probes use an empty project and --main-pack, never fallback
    # to this checkout. Each constructs Main and checks new district nodes; the
    # retained original percussion stream is also compared against source.
    audit_work = build / 'independent-playability-audit'
    empty = audit_work / 'empty-project'
    empty.mkdir(parents=True, exist_ok=True)
    script = audit_work / 'pack-probe.gd'
    script.write_text(PROBE)
    godot = os.environ.get('GODOT_BIN', shutil.which('godot'))
    require(godot, 'Godot unavailable for independent pack probe')
    version_env = os.environ.copy()
    for key, folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
        directory = audit_work / 'version' / folder
        directory.mkdir(parents=True, exist_ok=True)
        version_env[key] = str(directory)
    version_process = subprocess.run([godot, '--version'], env=version_env, text=True, capture_output=True, timeout=15)
    require(version_process.returncode == 0 and not version_process.stderr.strip(), 'Godot version query failed: ' + version_process.stderr)
    version = version_process.stdout.strip()
    require(version == metadata['engine'], 'Independent probe engine differs from exported metadata')
    probes = {}
    for platform in ('source', 'linux', 'macos'):
        destination = audit_work / (platform + '-district-resources.json')
        command = [godot, '--headless', '--audio-driver', 'Dummy', '--path', str(root if platform == 'source' else empty)]
        if platform != 'source': command += ['--main-pack', str(package_packs[platform])]
        command += ['--script', str(script), '--', str(destination)]
        env = os.environ.copy()
        for key, folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
            directory = audit_work / platform / folder
            directory.mkdir(parents=True, exist_ok=True)
            env[key] = str(directory)
        process = subprocess.run(command, cwd=empty, env=env, text=True, capture_output=True, timeout=60)
        log = process.stdout + process.stderr
        (audit_work / (platform + '-district-resources.log')).write_text(log)
        require(process.returncode == 0 and not any(marker in log for marker in ('SCRIPT ERROR:', 'Parse Error:', 'ERROR:', 'FAIL:')), 'Independent pack probe failed: ' + platform)
        probes[platform] = json.loads(destination.read_text())
    require(probes['source'] == probes['linux'] == probes['macos'], 'Pack construction/percussion reports differ from pinned source')
    report['bin_percussion'] = probes['source']['bin_percussion']
    report['isolated_bin_percussion_probes_pass'] = True
    report['isolated_main_construction_probes_pass'] = True
    report['district_resources'] = probes['source']['district_resources']
    report['required_modules'] = list(REQUIRED_MODULES)
    report['cross_platform_packs_byte_identical'] = file_sha(package_packs['linux']) == file_sha(package_packs['macos'])
    report['source_output_import_and_licence_provenance_hashes_pass'] = True
    report['native_executables_match_pinned_official_templates'] = True
    report['recorded_at_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    for relative, expected in entries.items():
        require(file_sha(root / relative) == expected, 'Source changed during audit: ' + relative)
    report['source_stable_during_audit'] = True
    report['audit_helper_sha256'] = file_sha(pathlib.Path(__file__).resolve())
    report['pack_probe_sha256'] = file_sha(pathlib.Path(__file__).with_name('pack_probe.gd'))
    output.mkdir(parents=True, exist_ok=True)
    (output / 'ARCHIVE-AUDIT.json').write_text(json.dumps(report, indent=2) + '\n')
    for platform in ('source', 'linux', 'macos'):
        shutil.copy2(audit_work / (platform + '-district-resources.json'), output)
        shutil.copy2(audit_work / (platform + '-district-resources.log'), output)
    print('INDEPENDENT AUDIT PASS:', commit, len(entries), 'source inputs;', len(expected_notices), 'notices each; both archives, captures and isolated district construction')
    print(json.dumps(report['archives'], indent=2))


if __name__ == '__main__':
    main()
