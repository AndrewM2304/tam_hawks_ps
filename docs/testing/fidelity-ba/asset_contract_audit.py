#!/usr/bin/env python3
"""Independent local asset-contract inspection; never imports Godot or downloads.

Run from the checkout with --output <new receipt.json>. This compares raw bytes,
decoded dimensions and tracked import settings to the declared source manifest.
It is a provenance/metadata audit, not a visual or performance benchmark.
Pillow is used only by this development-side audit, not by the game runtime.
"""
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re
import subprocess

from PIL import Image


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    manifest = root / 'game/art/assets/environment_pbr/manifest.json'
    manifest_data = json.loads(manifest.read_text())
    paths = {manifest, Path(__file__).resolve(), root / 'tools/fetch_environment_materials.py'}
    for entry in manifest_data['materials'].values():
        for reference in entry['files'].values():
            path = root / reference.removeprefix('res://')
            paths.add(path)
            paths.add(Path(str(path) + '.import'))
    before = {str(p.relative_to(root)): digest(p) for p in sorted(paths) if p.exists()}
    identity_errors, policy_errors, findings = [], [], []
    caps = manifest_data.get('import_policy', {}).get('maximum_dimension_by_map', {})
    for name, entry in manifest_data['materials'].items():
        for channel, reference in entry['files'].items():
            path = root / reference.removeprefix('res://')
            data = path.read_bytes()
            with Image.open(path) as picture:
                dimensions = list(picture.size)
            if digest(path) != entry['file_sha256'][channel]:
                identity_errors.append(f'{name}/{channel}: SHA-256 mismatch')
            if len(data) != entry['file_bytes'][channel]:
                identity_errors.append(f'{name}/{channel}: byte-count mismatch')
            if dimensions != entry.get('source_dimensions_px', {}).get(channel):
                identity_errors.append(f'{name}/{channel}: decoded dimensions mismatch/missing')
            settings_path = Path(str(path) + '.import')
            settings = settings_path.read_text() if settings_path.exists() else ''
            match = re.search(r'^process/size_limit=(\d+)$', settings, re.MULTILINE)
            actual_cap = int(match.group(1)) if match else None
            declared_cap = caps.get('zc_materials_all_maps') if entry['provider'] == 'ZC' else caps.get(channel)
            if actual_cap != declared_cap:
                policy_errors.append(f'{name}/{channel}: import cap {actual_cap} differs from declared {declared_cap}')
            if 'mipmaps/generate=true' not in settings:
                policy_errors.append(f'{name}/{channel}: mipmaps not enabled')
            if 'compress/mode=2' not in settings:
                policy_errors.append(f'{name}/{channel}: VRAM compression not enabled')
            findings.append({'material': name, 'channel': channel, 'file': str(path.relative_to(root)),
                             'sha256': digest(path), 'bytes': len(data), 'decoded_dimensions_px': dimensions,
                             'declared_import_cap': declared_cap, 'actual_import_cap': actual_cap})
    after = {str(p.relative_to(root)): digest(p) for p in sorted(paths) if p.exists()}
    stable = before == after
    report = {'schema': 1, 'observed_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'git_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
              'scope': 'Raw environment-map identity, decoded dimensions and import-policy consistency only; no visual/runtime/hardware claim',
              'working_tree_candidate': True, 'relevant_inputs_stable_during_audit': stable,
              'inputs_before': before, 'inputs_after': after, 'files_checked': len(findings),
              'identity_errors': identity_errors, 'policy_errors': policy_errors, 'findings': findings,
              'result': 'pass' if stable and not identity_errors and not policy_errors else 'fail'}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(f"ASSET CONTRACT AUDIT: {report['result']}; {len(findings)} files; "
          f"{len(identity_errors)} identity errors; {len(policy_errors)} policy errors; "
          f"{len(before)} relevant inputs stable={stable}; receipt={args.output}")
    return 0 if report['result'] == 'pass' else 1


if __name__ == '__main__':
    raise SystemExit(main())
