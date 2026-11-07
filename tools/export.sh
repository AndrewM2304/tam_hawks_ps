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
paths += list((root / 'tools').glob('rider_asset_*.py'))
paths += [p for p in (root / 'tools/art').rglob('*') if p.is_file() and '__pycache__' not in p.parts]
paths += [root / 'tools' / name for name in ('fetch_environment_materials.py', 'build_environment_derivatives.py')]
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
# Verify the November fidelity inputs before packaging. Imported GPU resources
# are checked again from the empty-project pack inspection below.
environment_manifest = json.loads((root / 'game/art/assets/environment_pbr/manifest.json').read_text())
for material in environment_manifest['materials'].values():
    for channel, resource in material['files'].items():
        relative = resource.removeprefix('res://')
        if not relative.startswith('game/art/assets/environment_pbr/') or entries.get(relative) != material['file_sha256'][channel]:
            raise SystemExit('Fidelity material differs from reviewed provenance: ' + relative)
derived_manifest = json.loads((root / 'game/art/assets/environment_pbr/derived/manifest.json').read_text())
for name, image in derived_manifest['files'].items():
    if pathlib.Path(name).name != name or entries.get('game/art/assets/environment_pbr/derived/' + name) != image['sha256']:
        raise SystemExit('Derived fidelity surface differs from reviewed provenance: ' + name)
rider_manifest = json.loads((root / 'game/art/rider/manifest.json').read_text())
for name, image in rider_manifest['maps'].items():
    if pathlib.Path(name).name != name or entries.get('game/art/rider/' + name) != image['sha256']:
        raise SystemExit('Rider surface differs from reviewed provenance: ' + name)
if entries.get(rider_manifest['generator']) != rider_manifest['generator_sha256']:
    raise SystemExit('Rider surface generator differs from reviewed provenance.')
fitted_manifest_path = root / 'game/art/rider/fitted-manifest.json'
if fitted_manifest_path.exists():
    fitted = json.loads(fitted_manifest_path.read_text())
    if fitted['schema'] != 1 or not fitted['outputs'] or not fitted['generator_sha256']:
        raise SystemExit('Unsupported or empty fitted-rider provenance.')
    if fitted['source_manifest_sha256'] != entries.get('game/art/rider/fitted-source-pins.json'):
        raise SystemExit('Fitted rider source selection differs from its reviewed provenance.')
    if fitted['original_body_manifest_sha256'] != entries.get('game/art/assets/makehuman_hm08/manifest.json'):
        raise SystemExit('Fitted rider original anatomy provenance differs.')
    for name, record in fitted['outputs'].items():
        relative = 'game/art/rider/' + name
        if pathlib.Path(name).name != name or not name or name in ('.', '..'):
            raise SystemExit('Invalid fitted-rider output name.')
        if entries.get(relative) != record['sha256'] or (root / relative).stat().st_size != record['bytes']:
            raise SystemExit('Fitted rider output differs from reviewed provenance: ' + name)
    for name, expected in fitted['generator_sha256'].items():
        if pathlib.Path(name).name != name or not name.startswith('rider_asset_') or not name.endswith('.py'):
            raise SystemExit('Invalid fitted-rider generator name.')
        if entries.get('tools/' + name) != expected:
            raise SystemExit('Fitted rider generator differs from reviewed provenance: ' + name)
# Board UV04 preflight; stdlib only, no editor tool execution or runtime dependency.
import gzip, re, struct
board_relative = 'game/art/assets/tam_skateboard/'
board_path = root / board_relative
board_manifest = json.loads((board_path / 'manifest.json').read_text())
if (board_manifest.get('schema') != 2 or board_manifest.get('meshes') != 1
        or board_manifest.get('surfaces') != 4 or board_manifest.get('triangles') != 5696
        or board_manifest.get('materials') != ['MapleAndRiverInk', 'Griptape', 'CastAluminium', 'Urethane']
        or board_manifest.get('texture', {}).get('dimensions') != [1024, 1024]
        or set(board_manifest.get('outputs', {})) != {'tam_skateboard.glb', 'board_albedo.png'}):
    raise SystemExit('Unsupported native board provenance/schema/resource contract.')
expected_board_contract = {'axle_z_m': [-0.255, 0.255], 'wheel_center_y_m': -0.088, 'wheel_radius_m': 0.032, 'deck_grip_center_y_m': 0.017, 'shoe_contact_at_z_m': [-0.255, 0.255]}
if any(board_manifest.get('contract', {}).get(key) != value for key, value in expected_board_contract.items()):
    raise SystemExit('Native board functional datums differ from the reviewed UV04 contract.')
board_pipeline_inputs = ['finish_board_uv.py', 'regenerate_skateboard_uv.py', 'requirements-board.txt', 'import_board_wood.gd', 'board_wood_source.gd', 'build_skateboard.py', 'source/tam_skateboard-base.glb.gz', 'source/tam_skateboard-base-manifest.json']
if any(not entries.get('tools/art/' + name) for name in board_pipeline_inputs) or board_manifest.get('regenerate') != 'python tools/art/regenerate_skateboard_uv.py':
    raise SystemExit('Native board is missing a reproducible pinned source pipeline input.')
for name, record in board_manifest['outputs'].items():
    if pathlib.Path(name).name != name or entries.get(board_relative + name) != record['sha256'] or (board_path / name).stat().st_size != record['bytes']:
        raise SystemExit('Native board output differs from reviewed provenance: ' + name)
if (board_manifest.get('generator') != 'tools/art/finish_board_uv.py'
        or entries.get(board_manifest['generator']) != board_manifest['generator_sha256']):
    raise SystemExit('Native board UV generator differs from reviewed provenance.')
base_board = board_manifest.get('base_source', {})
if (base_board.get('archive') != 'tools/art/source/tam_skateboard-base.glb.gz'
        or base_board.get('manifest') != 'tools/art/source/tam_skateboard-base-manifest.json'
        or base_board.get('original_generator') != 'tools/art/build_skateboard.py'
        or entries.get(base_board['original_generator']) != base_board['original_generator_sha256']):
    raise SystemExit('Native board original source/generator paths differ from the reviewed contract.')
base_raw = gzip.decompress((root / base_board['archive']).read_bytes())
base_manifest = json.loads((root / base_board['manifest']).read_text())
if (hashlib.sha256(base_raw).hexdigest() != base_board['sha256']
        or base_manifest.get('outputs', {}).get('tam_skateboard.glb', {}).get('sha256') != base_board['sha256']
        or base_manifest.get('generator_sha256') != base_board['original_generator_sha256']):
    raise SystemExit('Native board pinned original archive/manifest is inconsistent.')
board_editor = board_manifest.get('editor_import', {})
for field, expected in [('policy', 'tools/art/import_board_wood.gd'), ('decoder', 'tools/art/board_wood_source.gd')]:
    if board_editor.get(field) != expected or entries.get(expected) != board_editor.get(field + '_sha256'):
        raise SystemExit('Native board editor import source differs from reviewed provenance: ' + field)
if board_editor.get('global_force_disable_compression') is not False or board_editor.get('runtime_generation') is not False:
    raise SystemExit('Native board requires its reviewed editor-only narrow compression policy.')
board_import = (board_path / 'tam_skateboard.glb.import').read_text()
for line in ['meshes/force_disable_compression=false', 'import_script/path="res://tools/art/import_board_wood.gd"']:
    if len(re.findall(r'^' + re.escape(line) + r'$', board_import, flags=re.M)) != 1:
        raise SystemExit('Native board importer configuration differs from its reviewed policy.')
source_pin = re.search(r'^const SOURCE_SHA\s*:?=\s*"([0-9a-f]{64})"\s*$', (root / board_editor['decoder']).read_text(), flags=re.M)
if source_pin is None or source_pin.group(1) != board_manifest['outputs']['tam_skateboard.glb']['sha256']:
    raise SystemExit('Native board decoder is not pinned to this exact board source.')
atlas_bytes = (board_path / 'board_albedo.png').read_bytes()
if (atlas_bytes[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', atlas_bytes[16:24]) != (1024, 1024)
        or atlas_bytes[24:26] != bytes([8, 2])):
    raise SystemExit('Native board atlas must retain reviewed 8-bit RGB1024 allocation.')
board_bytes = (board_path / 'tam_skateboard.glb').read_bytes()
if struct.unpack_from('<III', board_bytes) != (0x46546c67, 2, len(board_bytes)):
    raise SystemExit('Native board GLB container differs from reviewed format.')
json_size, json_kind = struct.unpack_from('<II', board_bytes, 12)
if json_kind != 0x4e4f534a: raise SystemExit('Native board is missing its JSON chunk.')
board_gltf = json.loads(board_bytes[20:20 + json_size])
binary_at = 20 + json_size
binary_size, binary_kind = struct.unpack_from('<II', board_bytes, binary_at)
if binary_kind != 0x004e4942 or len(board_gltf.get('images', [])) != 1:
    raise SystemExit('Native board must retain one embedded atlas.')
image_view = board_gltf['bufferViews'][board_gltf['images'][0]['bufferView']]
image_start = binary_at + 8 + image_view.get('byteOffset', 0)
if image_start + image_view['byteLength'] > binary_at + 8 + binary_size or board_bytes[image_start:image_start + image_view['byteLength']] != atlas_bytes:
    raise SystemExit('Native board embedded atlas differs from its pinned RGB source output.')
board_notice = board_path / 'UV-NOTICE.md'
if not board_notice.is_file() or 'Permission is hereby granted' not in board_notice.read_text() or 'Godot' not in board_notice.read_text():
    raise SystemExit('Native board adapted shadow algorithm is missing its retained MIT/ownership notice.')

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
	var environment_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/assets/environment_pbr/manifest.json"))
	var rider_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/rider/manifest.json"))
	if not environment_manifest is Dictionary or not rider_manifest is Dictionary:
		push_error("Pack is missing its readable fidelity provenance manifests.")
		quit(1)
		return
	for material: Dictionary in environment_manifest.materials.values():
		for channel: String in material.files:
			var policy: Dictionary = environment_manifest.import_policy.maximum_dimension_by_map
			var cap := int(policy.get(channel, 1024)) if material.provider == "Poly Haven" else int(policy.zc_materials_all_maps)
			if not _fidelity_texture(str(material.files[channel]), cap, report):
				quit(1)
				return
	for name: String in rider_manifest.maps:
		if not _fidelity_texture("res://game/art/rider/" + name, 2048, report):
			quit(1)
			return
	var derived_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/assets/environment_pbr/derived/manifest.json"))
	if not derived_manifest is Dictionary:
		push_error("Pack is missing its derived-surface provenance.")
		quit(1)
		return
	for name: String in derived_manifest.files:
		var cap := 2048 if name.begins_with("pavement_") else 1024
		if not _fidelity_texture("res://game/art/assets/environment_pbr/derived/" + name, cap, report):
			quit(1)
			return
	var fitted_path := "res://game/art/rider/fitted-manifest.json"
	var has_fitted := FileAccess.file_exists(fitted_path)
	var hair_path := "res://game/art/rider/fitted_hair.obj" if has_fitted else "res://game/art/rider/short_crop.obj"
	var hair := load(hair_path) as ArrayMesh
	if hair == null or hair.get_surface_count() != 1 or hair.surface_get_array_len(0) < 1000:
		push_error("Pack is missing its single-surface cropped hair mesh.")
		quit(1)
		return
	if has_fitted and not _fitted_resources(fitted_path, report):
		quit(1)
		return
	if not _board_resource(report):
		quit(1)
		return
	var output := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	if output == null:
		push_error("Could not write packaged resource report.")
		quit(1)
		return
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	print("RESOURCES VERIFIED: main scene/scripts, 3 voice streams, ", report.textures.size(), " material/rider textures and 4 anatomical meshes")
	quit(0)

func _fidelity_texture(path: String, cap: int, report: Dictionary) -> bool:
	var texture := load(path) as Texture2D
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0 or texture.get_width() > cap or texture.get_height() > cap:
		push_error("Pack is missing its bounded fidelity texture: " + path)
		return false
	var image := texture.get_image()
	if image == null or not image.has_mipmaps():
		push_error("Packed fidelity texture has no image/mipmaps: " + path)
		return false
	report.textures[path] = {"width": texture.get_width(), "height": texture.get_height(), "mipmaps": image.get_mipmap_count()}
	return true

func _fitted_resources(manifest_path: String, report: Dictionary) -> bool:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary or int(manifest.get("schema", -1)) != 1:
		push_error("Pack is missing readable fitted-rider provenance.")
		return false
	report.fitted_resources = {}
	for name: String in manifest.outputs:
		var path := "res://game/art/rider/" + name
		if name.ends_with(".json"):
			var parser := JSON.new()
			if not FileAccess.file_exists(path) or parser.parse(FileAccess.get_file_as_string(path)) != OK:
				push_error("Pack is missing readable fitted-rider metadata: " + path)
				return false
			report.fitted_resources[name] = {"kind": "json"}
		elif name.ends_with(".obj"):
			var mesh := load(path) as ArrayMesh
			if mesh == null or mesh.get_surface_count() == 0 or mesh.surface_get_array_len(0) < 3:
				push_error("Pack is missing an imported fitted-rider mesh: " + path)
				return false
			report.fitted_resources[name] = {"kind": "mesh", "surfaces": mesh.get_surface_count(), "vertices": mesh.surface_get_array_len(0)}
		elif name.ends_with(".glb"):
			var scene := load(path) as PackedScene
			if scene == null:
				push_error("Pack is missing an imported fitted-rider scene: " + path)
				return false
			var actor := scene.instantiate()
			var meshes := actor.find_children("*", "MeshInstance3D", true, false)
			var skeletons := actor.find_children("*", "Skeleton3D", true, false)
			var valid := not meshes.is_empty()
			var skinned := 0
			for node: MeshInstance3D in meshes:
				valid = valid and node.mesh != null and node.mesh.get_surface_count() > 0
				if node.skin != null and node.skin.get_bind_count() >= 11:
					skinned += 1
			if name == "fitted_outfit.glb":
				valid = valid and skinned >= 2 and not skeletons.is_empty()
			if not valid:
				actor.free()
				push_error("Pack contains an incomplete fitted-rider scene: " + path)
				return false
			report.fitted_resources[name] = {"kind": "scene", "mesh_nodes": meshes.size(), "skeletons": skeletons.size(), "skinned_meshes": skinned}
			actor.free()
	return true
func _board_resource(report: Dictionary) -> bool:
	# Read the cooked scene and its data-only import receipt. Editor importers,
	# source decoders and Python generators are intentionally not runtime loads.
	var manifest_path := "res://game/art/assets/tam_skateboard/manifest.json"
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary or int(manifest.get("schema", -1)) != 2:
		return _board_failure(null, "Pack is missing readable board UV provenance.")
	if int(manifest.get("meshes", 0)) != 1 or int(manifest.get("surfaces", 0)) != 4 or int(manifest.get("triangles", 0)) != 5696:
		return _board_failure(null, "Pack board provenance has an unsupported resource contract.")
	var path := "res://game/art/assets/tam_skateboard/tam_skateboard.glb"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return _board_failure(null, "Pack is missing its cooked skateboard scene.")
	var model: Node3D = packed.instantiate() as Node3D
	if model == null:
		return _board_failure(null, "Pack skateboard has no native 3D root.")
	var meta: Dictionary = model.get_meta("tam_board_wood_import", {})
	var outputs: Dictionary = manifest.get("outputs", {})
	var source_record: Dictionary = outputs.get("tam_skateboard.glb", {})
	var editor: Dictionary = manifest.get("editor_import", {})
	if (str(meta.get("source_sha256", "")) != str(source_record.get("sha256", "")) or str(meta.get("source_sha256", "")).length() != 64
			or str(meta.get("policy_sha256", "")) != str(editor.get("policy_sha256", "")) or str(meta.get("policy_sha256", "")).length() != 64
			or str(meta.get("decoder_sha256", "")) != str(editor.get("decoder_sha256", "")) or str(meta.get("decoder_sha256", "")).length() != 64
			or int(meta.get("source_vertices", 0)) != 1600 or int(meta.get("source_indices", 0)) != 7800
			or meta.get("wood_compressed", true) != false or meta.get("protected_packed_surfaces_exact", false) != true or meta.get("protected_shadow_surfaces_exact", false) != true):
		return _board_failure(model, "Cooked board source/editor/decoder receipt differs from packaged provenance.")
	var meshes: Array[MeshInstance3D] = []
	_board_collect(model, meshes)
	if meshes.size() != 1 or model.transform != Transform3D.IDENTITY or meshes[0].transform != Transform3D.IDENTITY:
		return _board_failure(model, "Pack skateboard changed its single-mesh identity frame.")
	var mesh: ArrayMesh = meshes[0].mesh as ArrayMesh
	if mesh == null or mesh.get_surface_count() != 4:
		return _board_failure(model, "Pack skateboard is missing its four native ArrayMesh surfaces.")
	var names: Array[String] = ["MapleAndRiverInk", "Griptape", "CastAluminium", "Urethane"]
	var texture_ids: Dictionary = {}
	var triangles := 0
	var grip_minimum: float = INF
	var wheel_points := PackedVector3Array()
	for surface: int in mesh.get_surface_count():
		var material: StandardMaterial3D = mesh.surface_get_material(surface) as StandardMaterial3D
		if material == null or material.resource_name != names[surface] or material.albedo_texture == null:
			return _board_failure(model, "Pack skateboard material/atlas identity changed.")
		texture_ids[material.albedo_texture.get_instance_id()] = material.albedo_texture
		var arrays: Array = mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if points.is_empty() or indices.is_empty() or indices.size() % 3 != 0:
			return _board_failure(model, "Pack skateboard has incomplete indexed native geometry.")
		triangles += indices.size() / 3
		for index: int in indices:
			if index < 0 or index >= points.size() or not points[index].is_finite():
				return _board_failure(model, "Pack skateboard contains invalid indexed positions.")
		if surface == 0:
			var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			if indices.size() != 7800 or uv.size() != points.size() or (mesh.surface_get_format(0) & Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES) != 0:
				return _board_failure(model, "Pack wood lost source geometry/compression protection.")
			for i: int in range(0, indices.size(), 3):
				var a: Vector2 = uv[indices[i]]
				var b: Vector2 = uv[indices[i + 1]]
				var c: Vector2 = uv[indices[i + 2]]
				if not a.is_finite() or not b.is_finite() or not c.is_finite() or absf((b - a).cross(c - a)) * 0.5 <= 1e-12:
					return _board_failure(model, "Pack wood contains collapsed/nonfinite native UV triangles.")
		elif surface == 1:
			for point: Vector3 in points:
				grip_minimum = minf(grip_minimum, point.y)
		elif surface == 3:
			for point: Vector3 in points:
				if absf(point.x) > 0.09:
					wheel_points.append(point)
	if triangles != 5696 or texture_ids.size() != 1 or not model.find_children("*", "CollisionObject3D", true, false).is_empty():
		return _board_failure(model, "Pack skateboard changed its triangle/atlas/visual-only contract.")
	var contract: Dictionary = manifest.get("contract", {})
	if absf(grip_minimum - float(contract.get("deck_grip_center_y_m", INF))) > 0.000001:
		return _board_failure(model, "Pack board grip datum differs from its physical contract.")
	var wheels: Array = []
	var axles: Array = contract.get("axle_z_m", [])
	if axles.size() != 2:
		return _board_failure(model, "Pack board is missing its two axle datums.")
	for axle: float in axles:
		for side: float in [-1.0, 1.0]:
			var minimum_y: float = INF
			var maximum_y: float = -INF
			var minimum_z: float = INF
			var maximum_z: float = -INF
			var count := 0
			for point: Vector3 in wheel_points:
				if point.x * side <= 0.09 or point.z * signf(axle) <= 0.0:
					continue
				minimum_y = minf(minimum_y, point.y)
				maximum_y = maxf(maximum_y, point.y)
				minimum_z = minf(minimum_z, point.z)
				maximum_z = maxf(maximum_z, point.z)
				count += 1
			if (count < 20 or absf((minimum_y + maximum_y) * 0.5 - float(contract.get("wheel_center_y_m", INF))) > 0.000001
					or absf((maximum_y - minimum_y) * 0.5 - float(contract.get("wheel_radius_m", INF))) > 0.000001
					or absf((minimum_z + maximum_z) * 0.5 - axle) > 0.000001):
				return _board_failure(model, "Pack board native wheel centre/radius/axle contract changed.")
			wheels.append({"side": side, "axle_z": axle, "native_points": count, "minimum_y": minimum_y, "maximum_y": maximum_y})
	var texture: Texture2D = texture_ids.values()[0]
	var image: Image = texture.get_image()
	if (image == null or texture.get_width() != 1024 or texture.get_height() != 1024
			or image.get_format() != Image.FORMAT_RGB8 or image.get_mipmap_count() != 10 or image.get_data().size() != 4194303):
		return _board_failure(model, "Pack board atlas lost its RGB8/mip allocation contract.")
	report.board = {"resource": path, "mesh_nodes": meshes.size(), "surfaces": mesh.get_surface_count(), "triangles": triangles,
		"atlas_resource": texture.resource_path, "atlas_width": texture.get_width(), "atlas_height": texture.get_height(),
		"atlas_format": image.get_format(), "atlas_mipmaps": image.get_mipmap_count(), "atlas_bytes": image.get_data().size(),
		"native_import_receipt": meta, "grip_minimum_y": grip_minimum, "native_wheels": wheels, "editor_tools_required": false}
	model.free()
	return true

func _board_collect(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child: Node in node.get_children():
		_board_collect(child, meshes)

func _board_failure(model: Node, reason: String) -> bool:
	if is_instance_valid(model):
		model.free()
	push_error(reason)
	return false

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
current_inputs += list((root / 'tools').glob('rider_asset_*.py'))
current_inputs += [p for p in (root / 'tools/art').rglob('*') if p.is_file() and '__pycache__' not in p.parts]
current_inputs += [root / 'tools' / name for name in ('fetch_environment_materials.py', 'build_environment_derivatives.py')]
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
    shutil.copy2(root / 'game/art/assets/environment_pbr/manifest.json', notices / 'ENVIRONMENT-PROVENANCE.json')
    shutil.copy2(root / 'game/art/assets/environment_pbr/derived/manifest.json', notices / 'ENVIRONMENT-DERIVATIVES.json')
    shutil.copy2(root / 'game/art/rider/manifest.json', notices / 'RIDER-SURFACE-PROVENANCE.json')
    shutil.copy2(root / 'game/art/rider/SKIN-NOTICE.md', notices / 'SKIN-NOTICE.md')
    shutil.copy2(root / 'game/art/assets/tam_skateboard/UV-NOTICE.md', notices / 'UV-NOTICE.md')
    shutil.copy2(root / 'game/art/assets/tam_skateboard/manifest.json', notices / 'BOARD-PROVENANCE.json')
    for name in ('fitted-manifest.json', 'fitted-source-pins.json', 'fitted-licence-headers.json', 'FITTED-NOTICE.md'):
        source = root / 'game/art/rider' / name
        if source.exists(): shutil.copy2(source, notices / name)
    shutil.copy2(root / 'docs/licences/ENVIRONMENT-FIDELITY.md', notices / 'ENVIRONMENT-FIDELITY.md')
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
        required_notices = ['flite-COPYING.txt', 'flite-kal16-LICENSE.txt', 'flite-debian-copyright.txt', 'not-pro-skater-MIT.txt', 'zc-spectacular-textures-CC0.txt', 'makehuman-CC0.txt', 'makehuman-LICENCE-SCOPE.txt', 'GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt', 'UV-NOTICE.md', 'BOARD-PROVENANCE.json']
        if not all('NOTICES/' + name in z.namelist() for name in required_notices):
            raise SystemExit('A required third-party notice is absent from the completed ZIP.')
        for source in reviewed_notices:
            if z.read('NOTICES/' + source.name) != source.read_bytes():
                raise SystemExit('Packaged notice differs from reviewed source: ' + source.name)
        provenance_sources = {
            'TEXTURE-PROVENANCE.json': root / 'game/art/assets/zc_textures/manifest.json',
            'HUMAN-MESH-PROVENANCE.json': root / 'game/art/assets/makehuman_hm08/manifest.json',
            'ENVIRONMENT-PROVENANCE.json': root / 'game/art/assets/environment_pbr/manifest.json',
            'ENVIRONMENT-DERIVATIVES.json': root / 'game/art/assets/environment_pbr/derived/manifest.json',
            'RIDER-SURFACE-PROVENANCE.json': root / 'game/art/rider/manifest.json',
            'SKIN-NOTICE.md': root / 'game/art/rider/SKIN-NOTICE.md',
            'UV-NOTICE.md': root / 'game/art/assets/tam_skateboard/UV-NOTICE.md',
            'BOARD-PROVENANCE.json': root / 'game/art/assets/tam_skateboard/manifest.json',
            'ENVIRONMENT-FIDELITY.md': root / 'docs/licences/ENVIRONMENT-FIDELITY.md',
            'VOICE-PROVENANCE.json': root / 'game/audio/generated/manifest.json',
            'PROVENANCE.md': root / 'docs/licences/REGISTER.md',
        }
        for name, source in provenance_sources.items():
            if z.read('NOTICES/' + name) != source.read_bytes():
                raise SystemExit('Packaged provenance differs from reviewed source: ' + name)
        for name in ('fitted-manifest.json', 'fitted-source-pins.json', 'fitted-licence-headers.json', 'FITTED-NOTICE.md'):
            source = root / 'game/art/rider' / name
            if source.exists() and z.read('NOTICES/' + name) != source.read_bytes():
                raise SystemExit('Packaged fitted-rider provenance differs from reviewed source: ' + name)
        if hashlib.sha256(z.read(resource_report['pack_path'])).hexdigest() != resource_report['pack_sha256']:
            raise SystemExit('ZIP data pack differs from the inspected resource pack.')
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    checksums.append(digest + '  ' + archive.name)
    print(str(archive), archive.stat().st_size, 'bytes; SHA256', digest)
(build / 'SHA256SUMS.txt').write_text('\n'.join(checksums) + '\n')
PY
echo "Local artifacts and build metadata: $TASK_BUILD"
