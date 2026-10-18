#!/usr/bin/env python3
"""Reuse the strict archive auditor with current capture/ordinary/probe contracts.

Run only after an unchanged source checkpoint passes tools/check.sh and exports.
No download, rendering, player-save mutation, signing or Mac execution.
"""
import argparse
import hashlib
import importlib.util
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PARENT = HERE.parent / 'native-exchange-gallery' / 'audit.py'
spec = importlib.util.spec_from_file_location('archive_audit', PARENT)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build')
    parser.add_argument('--receipt-dir', required=True)
    parser.add_argument('--ordinary', default='docs/testing/logs/performance-ordinary-source.json')
    parser.add_argument('--capture', default='docs/testing/screenshots/playability-repair/manifest.json')
    args = parser.parse_args()
    build = pathlib.Path(args.build).resolve()
    output = pathlib.Path(args.receipt_dir).resolve()
    ordinary_path = (ROOT / args.ordinary).resolve()
    ordinary_bytes = ordinary_path.read_bytes()
    ordinary = json.loads(ordinary_bytes)
    base.require(ordinary.get('accepted') is True and ordinary.get('source_stable') is True
                 and ordinary.get('exit_code') == 0 and ordinary.get('failed') == 0
                 and ordinary.get('passed', 0) > 0 and ordinary.get('changed_inputs') == [],
                 'Required current ordinary suite did not pass on stable source')
    source_inputs = ordinary.get('source_inputs', {})
    base.require(len(source_inputs) == ordinary.get('input_count') and source_inputs,
                 'Ordinary source inventory is incomplete')
    for name, expected in ordinary['logs_sha256'].items():
        retained = HERE.parent / 'logs' / ('performance-ordinary-final.log' if name.endswith('/tests.log')
                    else 'performance-ordinary-import.log' if name.endswith('/import.log')
                    else 'performance-ordinary-console.log')
        base.require(base.file_sha(retained) == expected, 'Retained ordinary log differs: ' + name)
    metadata = json.loads((build / 'BUILD-METADATA.json').read_text())
    entries = metadata['source_files_sha256']
    overlap = set(source_inputs) & set(entries)
    base.require('project.godot' in overlap and len(overlap) >= 100
                 and all(source_inputs[name] == entries[name] for name in overlap)
                 and all(not name.startswith('game/') or name in source_inputs for name in entries),
                 'Ordinary-tested game inputs differ from exported package')
    # Parent accepts source_sha256; retain the complete original receipt and
    # attach only an alias, under ignored build output, for that schema adapter.
    work = build / 'independent-performance-audit'
    work.mkdir(exist_ok=True)
    normalized = dict(ordinary, source_sha256=source_inputs)
    normalized_path = work / 'ordinary-evidence.json'
    normalized_path.write_text(json.dumps(normalized, indent=2) + '\n')

    base.CAPTURE_COUNT = 19
    base.CAPTURE_SLICE = 'ordinary_launch_camera_response_and_exploration_repair'
    original_capture_audit = base.audit_captures

    def current_capture_audit(path, evidence, package_entries):
        base.require(evidence.get('schema_version') == 5 and evidence.get('normal_scene_launch') is True,
                     'Expected schema-5 actual normal-scene capture')
        # Same image/hash/source fields as schema 4, plus ordinary-play evidence.
        adapted = dict(evidence, schema_version=4)
        return original_capture_audit(path, adapted, package_entries)

    base.audit_captures = current_capture_audit
    base.PROBE = (HERE / 'pack_probe.gd').read_text()
    base.REQUIRED_MODULES += (
        'game/levels/static_batches.gd', 'game/levels/city_visibility.gd',
        'game/core/graphics_quality.gd', 'game/levels/transition_park.gd',
        'game/tricks/trick_catalog.gd', 'game/tricks/directional_tricks.gd',
        'game/player/trick_animation.gd',
    )
    sys.argv = [str(PARENT), str(build), '--root', str(ROOT), '--receipt-dir', str(output),
                '--evidence', args.capture, '--evidence', str(normalized_path)]
    base.main()
    for platform in ('linux', 'macos'):
        base.require('PACK ART EXCLUSION CHECK: art_source absent' in
                     (output / (platform + '-district-resources.log')).read_text(),
                     'Pack-only prototype exclusion was not checked: ' + platform)
    report_path = output / 'ARCHIVE-AUDIT.json'
    report = json.loads(report_path.read_text())
    report.update(audit='Current performance/classic-mechanics native/source construction audit',
                  reused_archive_auditor_sha256=base.file_sha(PARENT),
                  audit_helper_sha256=base.file_sha(HERE / 'audit.py'),
                  pack_probe_sha256=base.file_sha(HERE / 'pack_probe.gd'),
                  ordinary_receipt={'path':str(ordinary_path.relative_to(ROOT)),
                                    'sha256':hashlib.sha256(ordinary_bytes).hexdigest(),
                                    'passed':ordinary['passed'], 'failed':ordinary['failed'],
                                    'source_input_count':len(source_inputs), 'package_overlap':len(overlap),
                                    'all_overlap_matches':True},
                  prototype_excluded_from_both_packs=True)
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print('CURRENT PERFORMANCE PACKAGE AUDIT PASS:', ordinary['passed'], 'ordinary checks;',
          len(overlap), 'source overlaps; current probe, all 19 capture PNGs and both archives')


if __name__ == '__main__':
    main()
