#!/usr/bin/env python3
"""Bound and validate the local rendered moving profile. No network services."""
from __future__ import annotations

import csv
import hashlib
import json
import math
import os
import pathlib
import platform
import re
import signal
import struct
import subprocess
import sys
import time
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPECTED = ['quay_weave', 'market_inner_loop', 'park_rolling_loop']


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fingerprint():
    names = ['project.godot', 'tools/run.sh', 'tools/profile.gd', 'tools/profile.gd.uid',
             'tools/moving_profile.gd', 'tools/moving_profile.gd.uid', 'tools/moving_profile.sh',
             'tools/moving_profile.py', 'tools/xorg-dummy.conf']
    paths = [ROOT / name for name in names if (ROOT / name).is_file()]
    for folder in ('game', 'assets'):
        paths += [path for path in (ROOT / folder).rglob('*') if path.is_file()]
    return {str(path.relative_to(ROOT)): digest(path) for path in sorted(paths)}


def git(*args):
    child = subprocess.run(['git', *args], cwd=ROOT, capture_output=True, text=True, check=False)
    return child.stdout.strip() if child.returncode == 0 else 'unavailable'


def percentile(values, fraction):
    return sorted(values)[max(0, math.ceil(len(values) * fraction) - 1)]


def hardware():
    result = {'system': platform.system(), 'machine': platform.machine(), 'platform': platform.platform()}
    if platform.system() == 'Darwin':
        for name in ('hw.model', 'hw.memsize'):
            child = subprocess.run(['/usr/sbin/sysctl', '-n', name], capture_output=True, text=True, check=False)
            result[name] = child.stdout.strip() if child.returncode == 0 else 'unavailable'
        result['macos_version'] = platform.mac_ver()[0]
    elif pathlib.Path('/proc/meminfo').is_file():
        result['physical_memory_bytes'] = int(pathlib.Path('/proc/meminfo').read_text().split('MemTotal:')[1].split()[0]) * 1024
    return result


def png(path, width, height):
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('PNG signature')
    offset, stream, dimensions, ended = 8, bytearray(), None, False
    while offset < len(data):
        length = struct.unpack('>I', data[offset:offset + 4])[0]
        kind, chunk = data[offset + 4:offset + 8], data[offset + 8:offset + 8 + length]
        crc = struct.unpack('>I', data[offset + 8 + length:offset + 12 + length])[0]
        if zlib.crc32(kind + chunk) & 0xffffffff != crc:
            raise ValueError('PNG CRC')
        if kind == b'IHDR':
            dimensions = struct.unpack('>IIBBBBB', chunk)
        elif kind == b'IDAT':
            stream.extend(chunk)
        elif kind == b'IEND':
            ended = True
        offset += length + 12
    if not ended or dimensions is None or dimensions[:2] != (width, height):
        raise ValueError('PNG dimensions/end')
    w, h, depth, colour, _, _, interlace = dimensions
    channels = {2: 3, 6: 4}.get(colour)
    if depth != 8 or channels is None or interlace != 0 or len(zlib.decompress(stream)) != h * (1 + w * channels):
        raise ValueError('PNG encoding/rows')
    return {'sha256': digest(path), 'bytes': len(data), 'resolution': [width, height], 'png_crc_and_rows_valid': True}


def main():
    duration, output, width, height, mode = float(sys.argv[1]), pathlib.Path(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
    quality = sys.argv[6] if len(sys.argv) > 6 else "balanced"
    if quality not in ("performance", "balanced", "high"): raise SystemExit("Unknown graphics quality.")
    before = fingerprint()
    commit = git('rev-parse', 'HEAD')
    (output / 'source-manifest.json').write_text(json.dumps(before, indent=2) + '\n')
    command = [str(ROOT / 'tools/run.sh'), '--rendering-method', 'gl_compatibility', '--windowed',
               '--resolution', f'{width}x{height}', '--disable-vsync', '--audio-driver', 'Dummy',
               '--script', 'tools/moving_profile.gd', '--', str(duration), str(output), str(width), str(height), mode, quality]
    child = None

    def stop():
        if child is not None and child.poll() is None:
            os.killpg(child.pid, signal.SIGTERM)
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait(timeout=5)

    def interrupted(signum, _frame):
        stop()
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGINT, interrupted)
    signal.signal(signal.SIGTERM, interrupted)
    started = time.monotonic()
    print(f'Moving rendered profile: {duration:g}s sampled wall time across three routes; {output}', flush=True)
    try:
        with (output / 'engine.log').open('w') as log:
            child = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            try:
                code = child.wait(timeout=duration + 90)
            except subprocess.TimeoutExpired:
                stop()
                code = 124
    finally:
        stop()
    log = (output / 'engine.log').read_text()
    print(log, end='', flush=True)
    reasons = []
    if code:
        reasons.append(f'Engine exited {code}.')
    if re.search(r'SCRIPT ERROR:|ERROR:|FAIL:', log):
        reasons.append('Engine log contains errors.')
    after = fingerprint()
    changed = sorted(name for name in before.keys() | after.keys() if before.get(name) != after.get(name))
    if changed:
        reasons.append('Source changed: ' + ', '.join(changed))
    try:
        report = json.loads((output / 'report.json').read_text())
    except (OSError, ValueError):
        report = {}
        reasons.append('Engine report is absent or invalid.')
    trials = report.get('trials', [])
    if report.get('requested_quality') != quality or report.get('settings', {}).get('graphics_quality') != quality:
        reasons.append('Requested graphics quality differs from applied profile.')
    if [trial.get('route') for trial in trials] != EXPECTED or not report.get('valid_rendered_run'):
        reasons.append('Three valid moving route trials were not completed.')
    if report.get('render_resolution') != [width, height] or report.get('profile_writes_enabled') is not False:
        reasons.append('Actual resolution/persistence isolation failed.')
    if (report.get('render_loop_enabled') is not True or report.get('scripted_frame_advance') is not False
            or report.get('time_scale') != 1 or report.get('physics_ticks_per_second') != 60):
        reasons.append('Native rendering/physics scheduling contract failed.')
    try:
        with (output / 'frames.csv').open(newline='') as source:
            rows = list(csv.DictReader(source))
        if len(rows) != report.get('summary', {}).get('samples'):
            raise ValueError('Raw sample count differs.')
        timestamps = [int(row['elapsed_us']) for row in rows]
        if any(a >= b for a, b in zip(timestamps, timestamps[1:])):
            raise ValueError('Raw frame timestamps are not strictly monotonic.')
        if any(row['district'] not in EXPECTED or not math.isfinite(float(row['frame_ms'])) or float(row['frame_ms']) <= 0 for row in rows):
            raise ValueError('Invalid raw frame interval/route.')
    except (OSError, ValueError, KeyError) as error:
        rows = []
        reasons.append('Raw frames invalid: ' + str(error))
    screenshots = {}
    aggregate = [float(row['frame_ms']) for row in rows]
    recomputed = {'samples': len(aggregate)}
    if aggregate:
        for fraction in (.5, .95, .99):
            field = f'p{int(fraction * 100)}_ms'
            recomputed[field] = percentile(aggregate, fraction)
            if not math.isclose(float(report.get('summary', {}).get(field, -1)), recomputed[field], abs_tol=.000001):
                reasons.append(f'Aggregate {field} differs from raw rows.')
        recomputed['frames_over_ms'] = {str(threshold): sum(value > threshold for value in aggregate)
                                       for threshold in (16.666667, 33.333333, 50.0, 100.0)}
        declared_long = report.get('summary', {}).get('frames_over_ms', {})
        for threshold, count in declared_long.items():
            if sum(value > float(threshold) for value in aggregate) != count:
                reasons.append('Aggregate long-frame count differs from raw rows.')
    for trial in trials:
        name = trial.get('route')
        selected = [row for row in rows if row.get('district') == name]
        intervals = [float(row['frame_ms']) for row in selected]
        admission = report.get('admission', {})
        if (not trial.get('valid_trial') or len(selected) != trial.get('samples') or len(selected) < admission.get('minimum_samples', 3)
                or trial.get('distance_m', 0) < admission.get('minimum_distance_m', 4)
                or trial.get('simulated_seconds', 0) < admission.get('minimum_simulated_seconds', 1)
                or trial.get('absolute_turn_radians', 0) < admission.get('minimum_turn_radians', .08)
                or trial.get('moving_tick_fraction', 0) < .6 or trial.get('bails') != 0
                or trial.get('discontinuous_recoveries') != 0):
            reasons.append(f'{name}: incomplete moving/turning workload or recovery.')
        if intervals:
            if sum(intervals) / 1000 + .001 < duration / 3:
                reasons.append(f'{name}: sampled duration too short.')
            for fraction in (.5, .95, .99):
                field = f'p{int(fraction * 100)}_ms'
                if not math.isclose(float(trial.get(field, -1)), percentile(intervals, fraction), abs_tol=.000001):
                    reasons.append(f'{name}: {field} differs from raw rows.')
            if any(float(a['sim_seconds']) > float(b['sim_seconds']) or float(a['distance_m']) > float(b['distance_m'])
                   for a, b in zip(selected, selected[1:])):
                reasons.append(f'{name}: actual simulation/progress counters regressed.')
        try:
            screenshots[name] = png(output / f'{name}.png', width, height)
        except (OSError, ValueError, struct.error, zlib.error) as error:
            reasons.append(f'{name}: image validation failed: {error}')
    report.update(git_commit=commit, git_commit_after=git('rev-parse', 'HEAD'), git_dirty=bool(git('status', '--porcelain')),
                  source_manifest='source-manifest.json', source_manifest_sha256=digest(output / 'source-manifest.json'),
                  source_stable=not changed, changed_inputs=changed, command=command, host=hardware(),
                  process_elapsed_seconds=round(time.monotonic() - started, 3), screenshots=screenshots, raw_recomputed_summary=recomputed,
                  source_stable_rendered_run=not reasons, wrapper_validation_errors=reasons,
                  run_status='accepted_diagnostic' if not reasons else 'incomplete_or_rejected', artifact_manifest='artifacts.json')
    (output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    artifacts = {}
    for path in sorted(output.iterdir()):
        if path.name in ('report.json', 'frames.csv', 'source-manifest.json', 'engine.log', 'import.log') or path.suffix == '.png':
            artifacts[path.name] = {'bytes': path.stat().st_size, 'sha256': digest(path)}
    (output / 'artifacts.json').write_text(json.dumps(artifacts, indent=2) + '\n')
    if reasons:
        raise SystemExit('Moving diagnostic rejected: ' + ' '.join(reasons))
    print(f'MOVING_PROFILE_OK: {report["adapter"]}; {width}x{height}; {len(rows)} rendered frames; Mac acceptance remains open.', flush=True)


if __name__ == '__main__':
    main()
