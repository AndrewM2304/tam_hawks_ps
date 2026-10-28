#!/usr/bin/env python3
"""Bounded source-bound facade evidence; local installed Godot/Xorg only."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def fingerprint():
    paths = [ROOT / 'project.godot']
    for directory in ('game', 'assets', 'tests', 'tools'):
        paths.extend(p for p in (ROOT / directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}


def stop(child):
    if child and child.poll() is None:
        os.killpg(child.pid, signal.SIGTERM)
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(child.pid, signal.SIGKILL)
            child.wait(timeout=5)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True, type=Path)
    parser.add_argument('--script', required=True, type=Path)
    parser.add_argument('mode', choices=['capture', 'profile'])
    parser.add_argument('pilot', choices=['on', 'off'])
    parser.add_argument('output', type=Path)
    parser.add_argument('--size', default='1280x800', choices=['1280x800', '1920x1080'])
    parser.add_argument('--seconds', type=float, default=15)
    parser.add_argument('--quality', default='balanced', choices=['performance', 'balanced', 'high'])
    args = parser.parse_args()
    global ROOT
    ROOT = args.repo.resolve()
    script = args.script.resolve()
    if not script.is_relative_to(ROOT / '.local') or not script.is_file():
        parser.error('Fresh probe script must be a file under repository .local/.')
    probe_before = hashlib.sha256(script.read_bytes()).hexdigest()
    output = args.output.resolve()
    if not output.is_relative_to(ROOT / '.local') or output.exists():
        parser.error('Output must be a new directory under repository .local/.')
    output.mkdir(parents=True)
    width, height = args.size.split('x')
    command = [str(ROOT / 'tools/run.sh'), '--rendering-method', 'gl_compatibility',
               '--audio-driver', 'Dummy', '--windowed', '--resolution', args.size,
               '--script', str(script), '--', args.mode, args.pilot,
               str(output), width, height, str(args.seconds), args.quality]
    receipt = {'command': command, 'started_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
               'source_before': fingerprint(), 'acceptance': False}
    children = []
    handles = []
    def interrupted(signum, _):
        raise RuntimeError(f'Interrupted by signal {signum}')
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        env = os.environ.copy()
        if os.name == 'posix' and Path('/usr/lib/xorg/Xorg').exists():
            display = (output / 'display').open('w')
            handles.append(display)
            log = (output / 'xorg-console.log').open('w')
            handles.append(log)
            xorg = subprocess.Popen(['/usr/lib/xorg/Xorg', '-displayfd', str(display.fileno()),
                '-config', str(ROOT / 'tools/xorg-dummy.conf'), '-logfile', str(output / 'xorg.log'),
                '-noreset', '-nolisten', 'tcp'], stdout=log, stderr=subprocess.STDOUT,
                start_new_session=True, pass_fds=(display.fileno(),))
            children.append(xorg)
            deadline = time.monotonic() + 10
            while not (output / 'display').read_text().strip():
                if xorg.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError('Private display failed to start.')
                time.sleep(.1)
            env.update(DISPLAY=':' + (output / 'display').read_text().strip(), LIBGL_ALWAYS_SOFTWARE='1')
        log = (output / 'engine.log').open('w')
        handles.append(log)
        child = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log,
                                 stderr=subprocess.STDOUT, start_new_session=True)
        children.append(child)
        receipt['exit_code'] = child.wait(timeout=600)
        log.flush()
        if receipt['exit_code'] or re.search(r'SCRIPT ERROR:|ERROR:|FAIL:', (output / 'engine.log').read_text()):
            raise RuntimeError('Engine failed or logged an error; inspect engine.log.')
        report = json.loads((output / 'report.json').read_text())
        if not report['valid']:
            raise RuntimeError('Probe admission rejected; inspect report.json.')
        from PIL import Image
        pngs = []
        for path in sorted(output.glob('*.png')):
            with Image.open(path) as image:
                image.load()
                if image.size != (int(width), int(height)):
                    raise RuntimeError(f'Wrong PNG size: {path}')
                pngs.append({'file': path.name, 'size': image.size, 'decoded': True})
        expected = 7 if args.mode == 'capture' else 4
        if len(pngs) != expected:
            raise RuntimeError(f'Expected {expected} PNGs, found {len(pngs)}.')
        receipt['pngs'] = pngs
        receipt['acceptance'] = True
    except Exception as error:
        receipt['error'] = str(error)
    finally:
        for child in reversed(children):
            stop(child)
        for handle in handles:
            handle.close()
        receipt['probe_script'] = str(script.relative_to(ROOT))
        receipt['probe_before'] = probe_before
        receipt['probe_after'] = hashlib.sha256(script.read_bytes()).hexdigest()
        receipt['runner_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
        receipt['source_after'] = fingerprint()
        receipt['unchanged'] = receipt['source_before'] == receipt['source_after'] and receipt['probe_before'] == receipt['probe_after']
        receipt['acceptance'] = receipt['acceptance'] and receipt['unchanged']
        receipt['artifacts'] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                                for p in sorted(output.iterdir()) if p.is_file() and p.name != 'receipt.json'}
        receipt['completed_utc'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        (output / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps({'output': str(output), 'valid': receipt['acceptance'],
                      'unchanged_inputs': len(receipt['source_before']) if receipt['unchanged'] else False,
                      'error': receipt.get('error')}), flush=True)
    return 0 if receipt['acceptance'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
