#!/usr/bin/env bash
# Local, unsigned exports only. No publishing, credentials, signing or paid services.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
mkdir -p builds
# Exported apps/screenshots are outputs, never resources for the next import.
: > builds/.gdignore
TASK_TARGET=all
TASK_PREPARE=false
TASK_CHECK=true
while (($#)); do
  case "$1" in
    --prepare) TASK_PREPARE=true ;;
    --skip-check) TASK_CHECK=false ;;
    --target) shift; TASK_TARGET="${1:?Supply all, linux, or macos}" ;;
    *) echo 'Usage: tools/export.sh [--prepare] [--target all|linux|macos] [--skip-check]' >&2; exit 2 ;;
  esac
  shift
done
case "$TASK_TARGET" in all|linux|macos) ;; *) echo 'Unknown export target.' >&2; exit 2 ;; esac
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac

python3 - <<'PY'
import hashlib, json, os, pathlib, urllib.request, zipfile
root = pathlib.Path.cwd()
cache = root / '.local/downloads'
templates = root / '.local/data/godot/export_templates/4.6.3.stable'
notices = root / '.local/export-notices'
for path in (cache, templates, notices): path.mkdir(parents=True, exist_ok=True)
base = 'https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/'
name = 'Godot_v4.6.3-stable_export_templates.tpz'
# Inspected official SHA512-SUMS.txt for this exact release; never disable verification.
expected = 'da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68'
archive = cache / name
def digest(path, algorithm='sha512'):
    h = hashlib.new(algorithm)
    with path.open('rb') as stream:
        while block := stream.read(2 * 1024 * 1024): h.update(block)
    return h.hexdigest()
if not archive.exists():
    print('Downloading official 1.17 GB Godot templates; no installation outside this checkout.', flush=True)
    sums = urllib.request.urlopen(base + 'SHA512-SUMS.txt', timeout=30).read()
    advertised = next(line.split()[0] for line in sums.decode().splitlines() if line.split()[-1] == name)
    if advertised != expected: raise SystemExit('Official checksum differs from the reviewed pin; stop and investigate.')
    (cache / 'SHA512-SUMS-4.6.3.txt').write_bytes(sums)
    partial = archive.with_suffix('.tpz.part')
    total = 0
    with urllib.request.urlopen(base + name, timeout=60) as response, partial.open('wb') as out:
        while block := response.read(2 * 1024 * 1024):
            out.write(block)
            total += len(block)
            if total % (128 * 1024 * 1024) == 0: print('Downloaded', total, 'bytes', flush=True)
    if digest(partial) != expected: raise SystemExit('Template SHA512 mismatch. Partial archive must not be used.')
    partial.rename(archive)
if digest(archive) != expected: raise SystemExit('Template SHA512 mismatch. Archive must not be used.')
members = ['version.txt', 'linux_debug.x86_64', 'linux_release.x86_64', 'macos.zip']
extracted = {}
with zipfile.ZipFile(archive) as z:
    if z.read('templates/version.txt').decode().strip() != '4.6.3.stable':
        raise SystemExit('Unexpected template version in verified archive.')
    for name in members:
        data = z.read('templates/' + name)
        target = templates / name
        wanted = hashlib.sha256(data).hexdigest()
        if not target.exists() or digest(target, 'sha256') != wanted: target.write_bytes(data)
        if name.startswith('linux_'): target.chmod(0o755)
        extracted[name] = wanted
notice_sources = {
    'GODOT-LICENSE.txt': ('LICENSE.txt', 'b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80'),
    'GODOT-COPYRIGHT.txt': ('COPYRIGHT.txt', 'b3330849267d56ddd3d62a513817506606c2195034411fe05859f0140bff9d8a'),
}
for destination, (source, sha256) in notice_sources.items():
    target = notices / destination
    if not target.exists():
        url = 'https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/' + source
        data = urllib.request.urlopen(url, timeout=30).read()
        if hashlib.sha256(data).hexdigest() != sha256: raise SystemExit('Godot notice checksum mismatch: ' + source)
        target.write_bytes(data)
    if digest(target, 'sha256') != sha256: raise SystemExit('Cached Godot notice checksum mismatch: ' + source)
manifest = {'version': '4.6.3-stable', 'url': base + archive.name,
            'checksum_url': base + 'SHA512-SUMS.txt', 'sha512': expected,
            'size': archive.stat().st_size, 'extracted_sha256': extracted,
            'notice_sources': notice_sources}
(cache / 'export-template-verification.json').write_text(json.dumps(manifest, indent=2) + '\n')
print('Verified official templates and runtime notices:', templates, flush=True)
PY

if "$TASK_PREPARE"; then exit 0; fi
if "$TASK_CHECK"; then ./tools/check.sh; fi
TASK_BUILD="$(python3 - <<'PY'
import datetime, pathlib, subprocess
sha = subprocess.check_output(['git', 'rev-parse', '--short=12', 'HEAD'], text=True).strip()
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
path = pathlib.Path('builds') / ('tam-hawks-' + stamp + '-' + sha)
path.mkdir(parents=True, exist_ok=False)
print(path.resolve())
PY
)"
export TASK_BUILD TASK_VERSION TASK_CHECK TASK_TARGET
python3 - <<'PY'
import hashlib, json, os, pathlib, subprocess
root = pathlib.Path.cwd()
paths = [root / 'project.godot', root / 'export_presets.cfg', root / 'tools/export.sh', root / 'docs/PLAYER-GUIDE.md']
paths += [p for folder in ('game', 'docs/licences') for p in (root / folder).rglob('*') if p.is_file()]
entries = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}
fingerprint = hashlib.sha256(json.dumps(entries, sort_keys=True).encode()).hexdigest()
texture_manifest = json.loads((root / 'game/art/assets/zc_textures/manifest.json').read_text())
if entries.get(texture_manifest['license_file']) != texture_manifest['license_sha256']:
    raise SystemExit('Texture licence differs from its reviewed provenance manifest.')
for material in texture_manifest['materials'].values():
    for channel, resource in material['files'].items():
        if not resource.startswith('res://game/art/assets/'):
            raise SystemExit('Unexpected texture source path in provenance manifest: ' + resource)
        relative = resource.removeprefix('res://')
        if entries.get(relative) != material['file_sha256'][channel]:
            raise SystemExit('Texture source differs from reviewed provenance: ' + relative)
        if entries.get(relative + '.import') != material['import_config_sha256'][channel]:
            raise SystemExit('Texture import settings differ from reviewed provenance: ' + relative)
human_manifest = json.loads((root / 'game/art/assets/makehuman_hm08/manifest.json').read_text())
if entries.get('game/art/assets/makehuman_hm08/generate.py') != human_manifest['generator_sha256']:
    raise SystemExit('Human asset generator differs from reviewed provenance.')
for notice in human_manifest['licences']:
    if entries.get(notice['path']) != notice['sha256']:
        raise SystemExit('Human asset licence differs from reviewed provenance: ' + notice['path'])
for model in human_manifest['outputs'].values():
    relative = model['path'].removeprefix('res://')
    if not relative.startswith('game/art/assets/makehuman_hm08/') or entries.get(relative) != model['sha256']:
        raise SystemExit('Cropped human mesh differs from reviewed provenance: ' + relative)
manifest = {'git_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
            'working_tree_dirty': bool(subprocess.check_output(['git', 'status', '--porcelain'], text=True)),
            'runtime_source_sha256': fingerprint, 'source_files_sha256': entries,
            'engine': os.environ['TASK_VERSION'], 'checks_run_by_export_script': os.environ['TASK_CHECK'] == 'true',
            'macos_signed': False, 'macos_notarized': False, 'macos_launch_tested': False,
            'template_verification': json.loads((root / '.local/downloads/export-template-verification.json').read_text())}
(pathlib.Path(os.environ['TASK_BUILD']) / 'BUILD-METADATA.json').write_text(json.dumps(manifest, indent=2) + '\n')
PY

if [[ "$TASK_TARGET" == all || "$TASK_TARGET" == linux ]]; then
  mkdir -p "$TASK_BUILD/linux"
  ./tools/run.sh --headless --export-release 'Linux x86_64' "$TASK_BUILD/linux/TamHawksProSkater.x86_64" 2>&1 | tee "$TASK_BUILD/linux-export.log"
fi
if [[ "$TASK_TARGET" == all || "$TASK_TARGET" == macos ]]; then
  mkdir -p "$TASK_BUILD/macos"
  ./tools/run.sh --headless --export-release 'macOS unsigned universal' "$TASK_BUILD/macos/Tam Hawks Pro Skater.app" 2>&1 | tee "$TASK_BUILD/macos-export.log"
fi
# Inspect exported packs from an empty project directory, so missing packaged
# resources cannot accidentally fall back to source files in this checkout.
mkdir -p "$TASK_BUILD/resource-inspection" "$TASK_BUILD/resource-inspection/data" "$TASK_BUILD/resource-inspection/config" "$TASK_BUILD/resource-inspection/cache"
cat > "$TASK_BUILD/check-pack.gd" <<'GDSCRIPT'
extends SceneTree
func _initialize() -> void:
	var report: Dictionary = {"voice_streams": {}, "textures": {}, "human_meshes": {}, "main_scene_loaded": false}
	var main_scene := load("res://game/main.tscn") as PackedScene
	if main_scene == null:
		push_error("Pack is missing its main scene or script dependencies.")
		quit(1)
		return
	var instance := main_scene.instantiate()
	if instance.get_script() == null:
		push_error("Pack main scene has no loadable game script.")
		instance.free()
		quit(1)
		return
	instance.free()
	report.main_scene_loaded = true
	var durations: Dictionary = {"landing": 0.9495, "cone": 1.2485, "again": 1.137875}
	for id: String in durations:
		var path := "res://game/audio/generated/%s.wav" % id
		var stream := load(path) as AudioStreamWAV
		if stream == null or absf(stream.get_length() - float(durations[id])) > 0.03:
			push_error("Pack is missing the expected imported voice stream: " + path)
			quit(1)
			return
		report.voice_streams[id] = {"resource": path, "seconds": stream.get_length()}
	for material: String in ["T_bricks01", "T_concrete01"]:
		for channel: String in ["albedo", "normal_opengl"]:
			var path := "res://game/art/assets/zc_textures/%s/%s_%s.jpg" % [material, material, channel]
			var texture := load(path) as Texture2D
			if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0 or texture.get_width() > 1024 or texture.get_height() > 1024:
				push_error("Pack is missing a bounded imported material texture: " + path)
				quit(1)
				return
			var image := texture.get_image()
			if image == null or not image.has_mipmaps():
				push_error("Pack texture is missing its image or required mipmaps: " + path)
				quit(1)
				return
			report.textures[path] = {"width": texture.get_width(), "height": texture.get_height(), "mipmaps": image.get_mipmap_count()}
	for id: String in ["head", "hair", "left_hand", "right_hand"]:
		var path := "res://game/art/assets/makehuman_hm08/%s.obj" % id
		var mesh := load(path) as ArrayMesh
		if mesh == null or mesh.get_surface_count() == 0 or mesh.surface_get_array_len(0) < 50:
			push_error("Pack is missing cropped anatomical mesh: " + path)
			quit(1)
			return
		report.human_meshes[id] = {"resource": path, "surfaces": mesh.get_surface_count(), "vertices": mesh.surface_get_array_len(0)}
	var output := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	if output == null:
		push_error("Could not write packaged resource report.")
		quit(1)
		return
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	print("RESOURCES VERIFIED: main scene/scripts, 3 voice streams, 4 material textures and 4 anatomical meshes")
	quit(0)
GDSCRIPT
for TASK_PLATFORM in linux macos; do
  if [[ ! -d "$TASK_BUILD/$TASK_PLATFORM" ]]; then continue; fi
  TASK_PCK="$(python3 - "$TASK_BUILD/$TASK_PLATFORM" <<'PY'
import pathlib, sys
packs = list(pathlib.Path(sys.argv[1]).rglob('*.pck'))
if len(packs) != 1: raise SystemExit('Expected exactly one exported data pack.')
print(packs[0])
PY
)"
  XDG_DATA_HOME="$TASK_BUILD/resource-inspection/data" XDG_CONFIG_HOME="$TASK_BUILD/resource-inspection/config" XDG_CACHE_HOME="$TASK_BUILD/resource-inspection/cache" "${GODOT_BIN:-godot}" --headless --path "$TASK_BUILD/resource-inspection" --main-pack "$TASK_PCK" --script "$TASK_BUILD/check-pack.gd" -- "$TASK_BUILD/$TASK_PLATFORM-resources.json" 2>&1 | tee "$TASK_BUILD/$TASK_PLATFORM-resources.log"
done
python3 - <<'PY'
import hashlib, json, os, pathlib, plistlib, shutil, stat, struct, zipfile
root = pathlib.Path.cwd()
build = pathlib.Path(os.environ['TASK_BUILD'])
metadata = json.loads((build / 'BUILD-METADATA.json').read_text())
current_inputs = [root / 'project.godot', root / 'export_presets.cfg', root / 'tools/export.sh', root / 'docs/PLAYER-GUIDE.md']
current_inputs += [p for folder in ('game', 'docs/licences') for p in (root / folder).rglob('*') if p.is_file()]
if {str(p.relative_to(root)) for p in current_inputs} != set(metadata['source_files_sha256']):
    raise SystemExit('Source files were added or removed during export. Rebuild a stable checkpoint.')
for relative, expected in metadata['source_files_sha256'].items():
    if hashlib.sha256((root / relative).read_bytes()).hexdigest() != expected:
        raise SystemExit('Source changed during export: ' + relative + '. Rebuild a stable checkpoint.')
for log in build.glob('*.log'):
    if any(marker in log.read_text() for marker in ('SCRIPT ERROR:', 'Parse Error:', 'ERROR:')):
        raise SystemExit('Exporter logged an error: ' + str(log))
checksums = []
for platform in ('linux', 'macos'):
    package = build / platform
    if not package.exists(): continue
    if platform == 'linux':
        executable = package / 'TamHawksProSkater.x86_64'
        if not executable.is_file() or not executable.with_suffix('.pck').is_file():
            raise SystemExit('Linux executable or data pack missing.')
    else:
        app = package / 'Tam Hawks Pro Skater.app'
        info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
        executable = app / 'Contents/MacOS' / info['CFBundleExecutable']
        with executable.open('rb') as stream: header = stream.read(64)
        magic, count = struct.unpack('>II', header[:8])
        if magic != 0xcafebabe or count != 2:
            raise SystemExit('Expected a universal macOS executable with two architectures.')
        architectures = {struct.unpack('>I', header[8 + 20 * i:12 + 20 * i])[0] for i in range(count)}
        if architectures != {0x01000007, 0x0100000c}:
            raise SystemExit('Expected x86_64 and arm64 slices in the macOS executable.')
    notices = package / 'NOTICES'
    notices.mkdir()
    for source in (root / '.local/export-notices').glob('GODOT-*.txt'): shutil.copy2(source, notices / source.name)
    reviewed_notices = sorted((root / 'docs/licences/third-party').glob('*.txt'))
    for source in reviewed_notices: shutil.copy2(source, notices / source.name)
    shutil.copy2(root / 'game/audio/generated/manifest.json', notices / 'VOICE-PROVENANCE.json')
    shutil.copy2(root / 'docs/licences/REGISTER.md', notices / 'PROVENANCE.md')
    shutil.copy2(root / 'game/art/assets/zc_textures/manifest.json', notices / 'TEXTURE-PROVENANCE.json')
    shutil.copy2(root / 'game/art/assets/makehuman_hm08/manifest.json', notices / 'HUMAN-MESH-PROVENANCE.json')
    shutil.copy2(root / 'docs/PLAYER-GUIDE.md', package / 'PLAYER-GUIDE.md')
    shutil.copy2(build / 'BUILD-METADATA.json', package / 'BUILD-METADATA.json')
    resource_report = json.loads((build / (platform + '-resources.json')).read_text())
    packs = list(package.rglob('*.pck'))
    resource_report['pack_path'] = str(packs[0].relative_to(package))
    resource_report['pack_sha256'] = hashlib.sha256(packs[0].read_bytes()).hexdigest()
    (package / 'PACKAGED-RESOURCES.json').write_text(json.dumps(resource_report, indent=2) + '\n')
    archive = build / ('TamHawksProSkater-' + platform + '.zip')
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for path in sorted(package.rglob('*')):
            relative = str(path.relative_to(package))
            if path.is_symlink():
                info = zipfile.ZipInfo(relative)
                info.create_system = 3
                info.external_attr = (stat.S_IFLNK | 0o777) << 16
                z.writestr(info, os.readlink(path))
            elif path.is_file(): z.write(path, relative)
    with zipfile.ZipFile(archive) as z:
        bad_entry = z.testzip()
        if bad_entry is not None:
            raise SystemExit('ZIP CRC check failed: ' + bad_entry)
        required_notices = ['flite-COPYING.txt', 'flite-kal16-LICENSE.txt', 'flite-debian-copyright.txt', 'not-pro-skater-MIT.txt', 'zc-spectacular-textures-CC0.txt', 'makehuman-CC0.txt', 'makehuman-LICENCE-SCOPE.txt', 'GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']
        if not all('NOTICES/' + name in z.namelist() for name in required_notices):
            raise SystemExit('A required third-party notice is absent from the completed ZIP.')
        for source in reviewed_notices:
            if z.read('NOTICES/' + source.name) != source.read_bytes():
                raise SystemExit('Packaged notice differs from reviewed source: ' + source.name)
        provenance_sources = {
            'TEXTURE-PROVENANCE.json': root / 'game/art/assets/zc_textures/manifest.json',
            'HUMAN-MESH-PROVENANCE.json': root / 'game/art/assets/makehuman_hm08/manifest.json',
            'VOICE-PROVENANCE.json': root / 'game/audio/generated/manifest.json',
            'PROVENANCE.md': root / 'docs/licences/REGISTER.md',
        }
        for name, source in provenance_sources.items():
            if z.read('NOTICES/' + name) != source.read_bytes():
                raise SystemExit('Packaged provenance differs from reviewed source: ' + name)
        if hashlib.sha256(z.read(resource_report['pack_path'])).hexdigest() != resource_report['pack_sha256']:
            raise SystemExit('ZIP data pack differs from the inspected resource pack.')
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    checksums.append(digest + '  ' + archive.name)
    print(str(archive), archive.stat().st_size, 'bytes; SHA256', digest)
(build / 'SHA256SUMS.txt').write_text('\n'.join(checksums) + '\n')
PY
echo "Local artifacts and build metadata: $TASK_BUILD"
