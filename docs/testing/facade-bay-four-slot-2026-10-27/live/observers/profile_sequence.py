#!/usr/bin/env python3
"""Explicit foreground-only six-process same-source comparison; not a scheduler."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time

PHASES = [(label, mode, size, duration) for size, duration in [('1280x800', 20), ('1920x1080', 30)] for label, mode in [('a1', 'off'), ('b', 'on'), ('a2', 'off')]]

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', type=Path, required=True)
    p.add_argument('--runner', type=Path, required=True)
    p.add_argument('--script', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--execute', action='store_true', help='Launch only with root engine lease and admitted native visual/resource result.')
    a = p.parse_args()
    repo, output = a.repo.resolve(), a.output.resolve()
    if not output.is_relative_to(repo / '.local') or output.exists():
        p.error('Output must be a NEW directory under repository .local/.')
    plan = [{'name':size+'-'+label, 'mode':mode, 'size':size, 'seconds':seconds,
             'command':[sys.executable, str(a.runner.resolve()), '--repo', str(repo), '--script', str(a.script.resolve()), 'profile', mode, str(output/(size+'-'+label)), '--size', size, '--seconds', str(seconds), '--quality', 'balanced']}
            for label, mode, size, seconds in PHASES]
    if not a.execute:
        print(json.dumps({'not_executed':True, 'sample_seconds_per_process':'3*T stationary + 2*T moving', 'historical_wall_seconds_total':1063, 'plan':plan}, indent=2))
        return 0
    for path in [a.runner.resolve(), a.script.resolve()]:
        if not path.is_file(): p.error('Missing runner/probe: '+str(path))
    dependency_hashes = {str(path.resolve()):sha(path.resolve()) for path in [Path(__file__), a.runner, a.script]}
    output.mkdir(parents=True)
    record = {'schema':1, 'started_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()), 'plan':plan, 'dependencies':dependency_hashes, 'completed':[], 'valid':False, 'quality':'balanced', 'current_ordinary_defaults_required':True, 'not_target_mac_acceptance':True}
    record_path = output/'sequence.json'
    record_path.write_text(json.dumps(record,indent=2)+'\n')
    try:
        source = None
        for phase in plan:
            for name, digest in dependency_hashes.items():
                if sha(Path(name)) != digest: raise RuntimeError('Prepared measurement dependency changed: '+name)
            print('START '+phase['name'],flush=True)
            result = subprocess.run(phase['command'],cwd=repo,check=False)
            if result.returncode: raise RuntimeError('Phase rejected: '+phase['name']+' code '+str(result.returncode))
            receipt_path = output/phase['name']/'receipt.json'
            receipt = json.loads(receipt_path.read_text())
            if not receipt['acceptance'] or not receipt['unchanged']: raise RuntimeError('Unstable or rejected phase: '+phase['name'])
            if source is None: source = receipt['source_before']
            if receipt['source_before'] != source or receipt['source_after'] != source: raise RuntimeError('Combined source differed between phases.')
            record['completed'].append({'name':phase['name'],'receipt_sha256':sha(receipt_path)})
            record_path.write_text(json.dumps(record,indent=2)+'\n')
            print('DONE '+phase['name'],flush=True)
        for name,digest in dependency_hashes.items():
            if sha(Path(name)) != digest: raise RuntimeError('Measurement dependency changed: '+name)
        record['valid'] = len(record['completed']) == 6
        return 0 if record['valid'] else 1
    except Exception as error:
        record['error'] = str(error)
        print(str(error),file=sys.stderr,flush=True)
        return 1
    finally:
        record['completed_utc'] = time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())
        record_path.write_text(json.dumps(record,indent=2)+'\n')

if __name__=='__main__': raise SystemExit(main())
