#!/usr/bin/env python3
"""Exercise the exact fitted-asset export validator on isolated source copies.

No engine, downloads, asset regeneration or changes to the supplied assets.
The production validator is extracted from tools/export.sh, not reimplemented.
"""
import argparse
import datetime
import hashlib
import json
import pathlib
import shutil
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project-root', type=pathlib.Path, required=True)
    parser.add_argument('--assets', type=pathlib.Path, required=True)
    parser.add_argument('--generators', type=pathlib.Path, required=True)
    parser.add_argument('--output', type=pathlib.Path, required=True)
    args = parser.parse_args()
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    project = args.project_root.resolve()
    assets = args.assets.resolve()
    generators = args.generators.resolve()
    export_script = project / 'tools/export.sh'
    text = export_script.read_text()
    start = text.index("fitted_manifest_path = root / 'game/art/rider/fitted-manifest.json'")
    end = text.index("\nmanifest = {'git_commit':", start)
    validator = text[start:end]
    manifest = json.loads((assets / 'fitted-manifest.json').read_text())
    names = list(manifest['outputs']) + ['fitted-manifest.json']
    module_names = list(manifest['generator_sha256'])
    body_manifest = project / 'game/art/assets/makehuman_hm08/manifest.json'
    watched = [assets / name for name in names]
    watched += [generators / name for name in module_names]
    watched += [body_manifest, export_script]
    before = {str(path): digest(path) for path in watched}
    cases = []
    with tempfile.TemporaryDirectory(prefix='fitted-export-') as directory:
        root = pathlib.Path(directory)
        target = root / 'game/art/rider'
        target.mkdir(parents=True)
        tools = root / 'tools'
        tools.mkdir()
        for name in names:
            shutil.copy2(assets / name, target / name)
        for name in module_names:
            shutil.copy2(generators / name, tools / name)
        body_target = root / 'game/art/assets/makehuman_hm08/manifest.json'
        body_target.parent.mkdir(parents=True)
        shutil.copy2(body_manifest, body_target)

        def run(label, expected):
            entries = {str(path.relative_to(root)): digest(path) for path in root.rglob('*') if path.is_file()}
            error = None
            try:
                exec(compile(validator, str(export_script), 'exec'), {'root': root, 'entries': entries, 'json': json, 'pathlib': pathlib})
            except SystemExit as exc:
                error = str(exc)
            accepted = error is None
            cases.append({'case': label, 'expected_accept': expected, 'accepted': accepted, 'pass': accepted == expected, 'refusal': error})

        run('intact selected outputs and generator chain', True)
        mutations = [
            ('changed source-selection pin', target / 'fitted-source-pins.json'),
            ('changed original-body provenance', body_target),
            ('changed fitted geometry', target / 'fitted_outfit.glb'),
            ('changed generator module', tools / 'rider_asset_fit.py'),
        ]
        for label, path in mutations:
            original = path.read_bytes()
            path.write_bytes(original + b'\n')
            run(label, False)
            path.write_bytes(original)
        missing = target / 'fitted_hair.obj'
        original = missing.read_bytes()
        missing.unlink()
        run('missing fitted hair', False)
        missing.write_bytes(original)
        manifest_path = target / 'fitted-manifest.json'
        original = manifest_path.read_bytes()
        changed = json.loads(original)
        changed['outputs']['../outside.obj'] = {'sha256': '0' * 64, 'bytes': 0}
        manifest_path.write_text(json.dumps(changed))
        run('output path escaping asset directory', False)
        manifest_path.write_bytes(original)
        run('restored intact source', True)
    after = {str(path): digest(path) for path in watched}
    report = {'started_utc': started, 'ended_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'scope': 'Exact pre-export fitted provenance validator only. No native fitted branch, packaged resources, visuals, frame times or target Mac acceptance.',
              'validator_sha256': hashlib.sha256(validator.encode()).hexdigest(),
              'source_before': before, 'source_after': after, 'source_unchanged': before == after,
              'selected_outputs': len(manifest['outputs']), 'generator_modules': len(module_names), 'cases': cases}
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'provenance-cases.json').write_text(json.dumps(report, indent=2) + '\n')
    (args.output / 'executed-validator.py.txt').write_text(validator + '\n')
    print(json.dumps({'cases': len(cases), 'failed': sum(not case['pass'] for case in cases), 'source_unchanged': before == after}))
    if before != after or any(not case['pass'] for case in cases):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
