#!/usr/bin/env python3
"""Independent read-only package/source checks; run only after build release."""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import plistlib
import posixpath
import shutil
import stat
import struct
import subprocess
import wave
import zipfile


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
    return bool(value) and not path.is_absolute() and '..' not in path.parts and '\\' not in value and ':' not in path.parts[0]


PROBE = r'''extends SceneTree
func _initialize() -> void:
	var report: Dictionary = {}
	var main_scene := load("res://game/main.tscn") as PackedScene
	if main_scene == null: push_error("Missing main scene");quit(1);return
	var instance := main_scene.instantiate()
	if instance.get_script() == null: push_error("Missing main script");quit(1);return
	instance.free()
	report.main_scene_loaded = true
	var script := load("res://game/characters/bin_percussion.gd") as GDScript
	var actor_script := load("res://game/characters/cat_actor.gd") as GDScript
	if script == null or actor_script == null: push_error("Missing bin busker resource");quit(1);return
	var stream: AudioStreamWAV = script.stream()
	var cached: AudioStreamWAV = script.stream()
	var pcm: PackedByteArray = stream.data
	var minimum := 32767
	var maximum := -32768
	for index in range(0,pcm.size(),2):
		var value := pcm.decode_s16(index)
		minimum = mini(minimum,value)
		maximum = maxi(maximum,value)
	if stream.format != AudioStreamWAV.FORMAT_16_BITS or stream.mix_rate != 22050 or stream.stereo or pcm.size() != 352800 or absf(stream.get_length()-8.0)>0.001 or stream.loop_mode != AudioStreamWAV.LOOP_FORWARD or stream.loop_begin != 0 or stream.loop_end != 176400 or stream != cached or minimum >= 0 or maximum <= 0:
		push_error("Unexpected percussion stream/cache/loop parameters");quit(1);return
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(pcm)
	var pcm_sha256 := context.finish().hex_encode()
	report.bin_percussion = {"resource":"res://game/characters/bin_percussion.gd","pcm_sha256":pcm_sha256,"pcm_bytes":pcm.size(),"mix_rate":stream.mix_rate,"seconds":stream.get_length(),"format":"PCM16","stereo":stream.stereo,"loop_begin":stream.loop_begin,"loop_end":stream.loop_end,"cached_identity":stream==cached,"minimum_sample":minimum,"maximum_sample":maximum}
	var output := FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	if output == null: push_error("Cannot write audit report");quit(1);return
	output.store_string(JSON.stringify(report,"\t")+"\n")
	output.close()
	print("INDEPENDENT PACK PROBE PASS: main, bin busker script, original 8s percussion")
	quit(0)
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('build')
    parser.add_argument('--root', default='/workspace/tam_hawks_ps')
    parser.add_argument('--receipt-dir', required=True)
    parser.add_argument('--evidence', action='append', default=[])
    parser.add_argument('--preview')
    parser.add_argument('--preview-sha256')
    args = parser.parse_args()
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
    require('game/characters/bin_percussion.gd' in entries, 'New percussion absent from source manifest')
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

    report = {'audit': 'Independent native/source/bin-percussion audit', 'runtime_commit': commit,
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
            require(stat.S_IMODE(z.getinfo(executable).external_attr >> 16) == 0o755 and stat.S_IMODE((package / executable).stat().st_mode) == 0o755, 'Executable mode differs from0755')
        report['archives'][platform] = {'bytes': archive.stat().st_size, 'sha256': file_sha(archive), 'format': architecture,
                                        'crc_pass': True, 'unique_safe_paths': True, 'file_count': len(names),
                                        'all_members_match_package': True, 'executable_mode': '0755', 'pack_sha256': packaged['pack_sha256']}

    for relative in args.evidence:
        path = pathlib.Path(relative)
        if not path.is_absolute(): path = root / path
        evidence = json.loads(path.read_text())
        hashes = evidence.get('source_sha256', evidence.get('source_files_sha256', evidence.get('input_sha256', {})))
        require(isinstance(hashes, dict) and hashes, 'Evidence lacks input hashes: ' + str(path))
        overlap = set(hashes) & set(entries)
        require(all(hashes[key] == entries[key] for key in overlap), 'Evidence source differs from package: ' + str(path))
        report['source_evidence'][str(path.relative_to(root))] = {'sha256': file_sha(path), 'inputs': len(hashes), 'overlap': len(overlap), 'overlap_matches_build': True}

    # Supplemental probes use an empty project and --main-pack, never fallback
    # to this checkout. A source probe provides a deterministic PCM comparison.
    audit_work = build / 'independent-bin-cats-audit'
    empty = audit_work / 'empty-project'
    empty.mkdir(parents=True, exist_ok=True)
    script = audit_work / 'pack-probe.gd'
    script.write_text(PROBE)
    godot = os.environ.get('GODOT_BIN', shutil.which('godot'))
    require(godot, 'Godot unavailable for independent pack probe')
    version = subprocess.check_output([godot, '--version'], text=True).strip()
    require(version == metadata['engine'], 'Independent probe engine differs from exported metadata')
    probes = {}
    for platform in ('source', 'linux', 'macos'):
        destination = audit_work / (platform + '-bin-percussion.json')
        command = [godot, '--headless', '--audio-driver', 'Dummy', '--path', str(root if platform == 'source' else empty)]
        if platform != 'source': command += ['--main-pack', str(package_packs[platform])]
        command += ['--script', str(script), '--', str(destination)]
        env = os.environ.copy()
        for key, folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
            env[key] = str(audit_work / platform / folder)
        process = subprocess.run(command, cwd=empty, env=env, text=True, capture_output=True, timeout=60)
        log = process.stdout + process.stderr
        (audit_work / (platform + '-bin-percussion.log')).write_text(log)
        require(process.returncode == 0 and not any(marker in log for marker in ('SCRIPT ERROR:', 'Parse Error:', 'ERROR:', 'FAIL:')), 'Independent pack probe failed: ' + platform)
        probes[platform] = json.loads(destination.read_text())
    require(probes['source'] == probes['linux'] == probes['macos'], 'Pack percussion behavior differs from pinned source')
    report['bin_percussion'] = probes['source']['bin_percussion']
    report['isolated_bin_percussion_probes_pass'] = True
    report['cross_platform_packs_byte_identical'] = file_sha(package_packs['linux']) == file_sha(package_packs['macos'])
    report['source_output_import_and_licence_provenance_hashes_pass'] = True
    report['native_executables_match_pinned_official_templates'] = True
    if args.preview:
        preview = pathlib.Path(args.preview).resolve()
        require(args.preview_sha256 and file_sha(preview) == args.preview_sha256, 'Preview differs from accepted digest')
        probe_command = ['ffprobe', '-v', 'error', '-count_frames', '-show_entries', 'stream=codec_type,codec_name,width,height,r_frame_rate,nb_read_frames,nb_frames,duration:format=duration,size', '-of', 'json', str(preview)]
        preview_data = json.loads(subprocess.check_output(probe_command, text=True))
        streams = preview_data['streams']
        require(len(streams) == 1 and streams[0]['codec_type'] == 'video' and streams[0]['codec_name'] == 'h264' and streams[0]['r_frame_rate'] == '30/1' and int(streams[0]['nb_read_frames']) == 100 and abs(float(preview_data['format']['duration']) - 100/30) < 0.02, 'Preview parameters differ from accepted100-frame silent clip')
        subprocess.run(['ffmpeg', '-v', 'error', '-i', str(preview), '-f', 'null', '-'], check=True, capture_output=True, timeout=60)
        report['preview'] = {'file': preview.name, 'bytes': preview.stat().st_size, 'sha256': args.preview_sha256, 'silent': True, 'decoded_frames': 100, 'fps': 30, 'seconds': float(preview_data['format']['duration']), 'full_decode_pass': True, 'performance_claim': False}
        (audit_work / 'preview-ffprobe.json').write_text(json.dumps(preview_data, indent=2) + '\n')
    report['recorded_at_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    output.mkdir(parents=True, exist_ok=True)
    (output / 'ARCHIVE-AUDIT.json').write_text(json.dumps(report, indent=2) + '\n')
    for platform in ('source', 'linux', 'macos'):
        shutil.copy2(audit_work / (platform + '-bin-percussion.json'), output)
        shutil.copy2(audit_work / (platform + '-bin-percussion.log'), output)
    if args.preview:
        shutil.copy2(audit_work / 'preview-ffprobe.json', output)
    print('INDEPENDENT AUDIT PASS:', commit, len(entries), 'source inputs;', len(expected_notices), 'notices each; both archives and isolated percussion')
    print(json.dumps(report['archives'], indent=2))


if __name__ == '__main__':
    main()
