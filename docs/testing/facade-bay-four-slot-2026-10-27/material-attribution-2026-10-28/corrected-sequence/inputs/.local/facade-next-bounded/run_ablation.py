#!/usr/bin/env python3
"""Plan by default; five bounded fresh native near-camera processes on request."""
import argparse
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

PHASES = [('a1', 'full'), ('n', 'no-normal'), ('r', 'constant-orm'), ('nr', 'both'), ('a2', 'full')]
HERE = Path(__file__).resolve().parent
DEPENDENCIES = [Path(__file__).resolve(), HERE/'near_material_ablation.gd',
                HERE/'run_bound.sh', HERE.parent/'facade_stage4/facade_bay_reduced_probe.gd']


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True)+'\n')


def fingerprint(repo):
    paths = [repo/'project.godot', *DEPENDENCIES]
    paths += [p for folder in ['game', 'assets', 'tests', 'tools']
              for p in (repo/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    return {str(p.relative_to(repo)):digest(p) for p in sorted(set(paths))}


def retain_inputs(repo, out, sources):
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
    raw = subprocess.check_output(['git', 'ls-tree', '-rz', '--full-tree', head], cwd=repo)
    tree = {row.split(b'\t', 1)[1].decode():row.split(b'\t', 1)[0].split()[2].decode()
            for row in raw.split(b'\0') if row}
    bindings = {}
    for name, sha256 in sources.items():
        data = (repo/name).read_bytes()
        assert hashlib.sha256(data).hexdigest() == sha256, 'Source changed while binding: '+name
        blob = hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
        if tree.get(name) == blob:
            bindings[name] = {'sha256':sha256, 'git_blob':blob, 'git_commit':head}
        else:
            target = out/'inputs'/name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            bindings[name] = {'sha256':sha256, 'snapshot':str(target.relative_to(out))}
    write(out/'source-binding.json', {'git_head':head, 'files':bindings})
    return head


def stop(child):
    if child.poll() is None:
        os.killpg(child.pid, signal.SIGTERM)
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(child.pid, signal.SIGKILL)
            child.wait(timeout=5)


def phase(repo, output, variant, sources):
    from PIL import Image
    output.mkdir()
    record = {'variant':variant, 'source_before':fingerprint(repo), 'valid':False}
    assert record['source_before'] == sources, 'Source changed between processes.'
    children, handles = [], []
    try:
        env = os.environ.copy()
        display = (output/'display').open('w')
        xlog = (output/'xorg-console.log').open('w')
        handles.extend([display, xlog])
        xorg = subprocess.Popen(['/usr/lib/xorg/Xorg', '-displayfd', str(display.fileno()),
            '-config', str(repo/'tools/xorg-dummy.conf'), '-logfile', str(output/'xorg.log'),
            '-noreset', '-nolisten', 'tcp'], stdout=xlog, stderr=subprocess.STDOUT,
            start_new_session=True, pass_fds=(display.fileno(),))
        children.append(xorg)
        deadline = time.monotonic()+10
        while not (output/'display').read_text().strip():
            if xorg.poll() is not None or time.monotonic() > deadline:
                raise RuntimeError('Private display failed to start.')
            time.sleep(.1)
        env.update(DISPLAY=':'+(output/'display').read_text().strip(), LIBGL_ALWAYS_SOFTWARE='1')
        command = [str(repo/'tools/run.sh'), '--rendering-method', 'gl_compatibility',
                   '--audio-driver', 'Dummy', '--windowed', '--resolution', '1280x800',
                   '--script', str(HERE/'near_material_ablation.gd'), '--', variant,
                   str(output), '20']
        record['command'] = command
        log = (output/'engine.log').open('w')
        handles.append(log)
        started = time.monotonic()
        child = subprocess.Popen(command, cwd=repo, env=env, stdout=log,
                                 stderr=subprocess.STDOUT, start_new_session=True)
        children.append(child)
        record['exit_code'] = child.wait(timeout=90)
        record['wall_seconds'] = time.monotonic()-started
        log.flush()
        text = (output/'engine.log').read_text()
        assert record['exit_code'] == 0 and not any(s in text for s in ['SCRIPT ERROR', 'ERROR:', 'FAIL:']), 'Engine rejected; inspect log.'
        report = json.loads((output/'report.json').read_text())
        assert report['valid'] and not report['errors'] and report['variant'] == variant
        assert all(report['ordinary_defaults'].values()) and not report['profile_writes']
        assert report['normal_render_loop'] and not report['fixed_fps'] and report['original_maps_resident']
        assert report['size'] == [1280,800] and report['requested_seconds'] == 20
        assert report['camera_position'] == [-23,7.5,7] and report['camera_target'] == [-35,7.5,5.75]
        assert len(report['stationary_views']) == 1 and not report['moving_trials']
        pngs = sorted(output.glob('*.png'))
        assert len(pngs) == 1
        with Image.open(pngs[0]) as image:
            image.load()
            assert image.size == (1280,800)
        rows = list(csv.DictReader((output/'frames.csv').open()))
        assert len(rows) == report['stationary_views'][0]['samples'] and len(rows) >= 30
        assert all(r['district'] == '03-frontage-near' and float(r['frame_ms']) > 0 for r in rows)
        record['valid'] = True
    except Exception as error:
        record['error'] = str(error)
    finally:
        for child in reversed(children): stop(child)
        for handle in handles: handle.close()
        record['source_after'] = fingerprint(repo)
        record['source_stable'] = record['source_before'] == record['source_after'] == sources
        record['valid'] = record['valid'] and record['source_stable']
        record['artifacts'] = {str(p.relative_to(output)):digest(p) for p in sorted(output.iterdir()) if p.is_file() and p.name != 'receipt.json'}
        write(output/'receipt.json', record)
    if not record['valid']: raise RuntimeError('Phase rejected: '+str(output)+' '+record.get('error',''))
    return record


def percentile(values, fraction):
    values = sorted(values)
    assert values and all(math.isfinite(v) for v in values)
    return values[min(len(values)-1, max(0, math.ceil(len(values)*fraction)-1))]


def compare(output):
    reports, distributions = {}, {}
    for label, variant in PHASES:
        folder = output/label
        receipt = json.loads((folder/'receipt.json').read_text())
        assert receipt['valid'] and receipt['source_stable'] and receipt['variant'] == variant
        for name, sha256 in receipt['artifacts'].items(): assert digest(folder/name) == sha256
        reports[label] = json.loads((folder/'report.json').read_text())
        rows = list(csv.DictReader((folder/'frames.csv').open()))
        distributions[label] = {key:{'p'+str(q):percentile([float(r[key]) for r in rows], q/100) for q in [50,95,99]}
            for key in ['frame_ms','process_ms','physics_ms','draw_calls','primitives','visible_draws','shadow_draws',
                        'render_objects','nodes','static_memory_bytes','video_memory_bytes','texture_memory_bytes','buffer_memory_bytes']}
        assert len(rows) == reports[label]['stationary_views'][0]['samples'] >= 30
        for q in [50,95,99]:
            assert abs(distributions[label]['frame_ms']['p'+str(q)]-reports[label]['stationary_views'][0]['p'+str(q)+'_ms']) < 1e-6
    fixed = ['geometry','size','settings','ordinary_defaults','camera_position','camera_target','camera_fov',
             'camera_near','camera_far','stone_before','device','renderer','mesh_root','texture_root']
    for label in reports:
        for key in fixed: assert reports[label][key] == reports['a1'][key], (label,key,'not matched')
    assert reports['a1']['stone_after'] == reports['a2']['stone_after'] == reports['a1']['stone_before']
    result = {'schema':1, 'source_artifact_binding_pass':True, 'diagnostic_only':True,
              'production_admission':False, 'target_mac_acceptance':False,
              'distributions':distributions, 'comparisons':{}}
    for label in ['n','r','nr']:
        metrics = {}
        for q in [95,99]:
            key = 'p'+str(q)
            first, last = [distributions[p]['frame_ms'][key] for p in ['a1','a2']]
            candidate = distributions[label]['frame_ms'][key]
            midpoint, noise = (first+last)/2, abs(first-last)
            metrics[key] = {'baseline_midpoint_ms':midpoint, 'repeat_noise_ms':noise,
                'candidate_ms':candidate, 'reduction_ms':midpoint-candidate,
                'reduction_beyond_noise_and_five_percent':midpoint-candidate > noise and midpoint-candidate > midpoint*.05}
        draw_keys = ['draw_calls','visible_draws','shadow_draws','primitives','render_objects']
        matched = all(distributions[label][key]['p50'] == distributions['a1'][key]['p50'] == distributions['a2'][key]['p50'] for key in draw_keys)
        result['comparisons'][label] = {'timing':metrics, 'same_draw_and_geometry_medians':matched,
            'attribution_signal':matched and all(m['reduction_beyond_noise_and_five_percent'] for m in metrics.values()),
            'needs_reverse_order_confirmation_before_source_change':True}
    write(output/'comparison.json', result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--execute', action='store_true')
    args = parser.parse_args()
    repo, output = args.repo.resolve(), args.output.resolve()
    if not output.is_relative_to(repo/'.local') or output.exists():
        parser.error('Output must be a NEW directory below repository .local/.')
    plan = [{'label':label,'variant':variant,'size':[1280,800],'sample_seconds':20} for label,variant in PHASES]
    if not args.execute:
        print(json.dumps({'not_executed':True,'plan':plan,'engine_timeout_seconds_each':90,
            'whole_command_timeout_seconds':500,'only_after_root_engine_lease':True},indent=2))
        return 0
    def interrupted(signum, _frame): raise RuntimeError('Interrupted by signal '+str(signum))
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    output.mkdir(parents=True)
    before = fingerprint(repo)
    write(output/'source-before.json', before)
    head = retain_inputs(repo, output, before)
    record = {'plan':plan,'git_head':head,'started_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),
              'completed':[],'valid':False,'diagnostic_only':True}
    started = time.monotonic()
    try:
        for label,variant in PHASES:
            print('START '+label+' '+variant, flush=True)
            phase(repo, output/label, variant, before)
            record['completed'].append({'label':label,'receipt_sha256':digest(output/label/'receipt.json')})
            write(output/'sequence.json', record)
            print('DONE '+label, flush=True)
        compare(output)
        record['valid'] = True
    except Exception as error:
        record['error'] = str(error)
        print(str(error), file=sys.stderr, flush=True)
    finally:
        after = fingerprint(repo)
        write(output/'source-after.json', after)
        record['source_stable'] = before == after
        record['valid'] = record['valid'] and record['source_stable']
        record['wall_seconds'] = time.monotonic()-started
        record['completed_utc'] = time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())
        write(output/'sequence.json', record)
    print(json.dumps({'valid':record['valid'],'diagnostic_only':True,'completed':len(record['completed']),
                      'error':record.get('error')}), flush=True)
    return 0 if record['valid'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
