#!/usr/bin/env python3
"""World-only geometry/culling receipt, preserving command status and source."""
import hashlib, json, pathlib, re, subprocess, sys
output, cell = pathlib.Path(sys.argv[1]), sys.argv[2]
root = pathlib.Path(__file__).resolve().parent.parent
paths = [root / 'project.godot', *root.joinpath('game/levels').rglob('*'), *root.joinpath('game/art').rglob('*'), *root.joinpath('game/tricks').glob('*')]
paths += [root/'tools'/f'static_batches_probe.{extension}' for extension in ('gd','sh','py')] + [root/'tools/moving_profile.py']
def fingerprint():
    return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths) if p.is_file()}
before = fingerprint()
command = [str(root/'tools/run.sh'),'--windowed','--resolution','1280x800','--audio-driver','Dummy','--disable-vsync','--script','tools/static_batches_probe.gd','--',str(output),cell]
print('Static-batch world comparison:',output,flush=True)
with (output/'engine.log').open('w') as log:
    result = subprocess.run(command,cwd=root,stdout=log,stderr=subprocess.STDOUT,timeout=600)
after = fingerprint()
changed = [name for name in sorted(set(before)|set(after)) if before.get(name)!=after.get(name)]
text = (output/'engine.log').read_text()
report = json.loads((output/'report.json').read_text()) if (output/'report.json').exists() else {}
valid = result.returncode==0 and not changed and not re.search(r'SCRIPT ERROR:|ERROR:',text) and report.get('errors')==0 and report.get('records_preserved') and len(report.get('views',[]))==24
if valid:
    from moving_profile import png
    for view in report['views']:
        png(output/view['image'],1280,800)
report.update({'source_stable':not changed,'changed_inputs':changed,'source_inputs':before,'command':command,'valid_comparison':bool(valid)})
(output/'report.json').write_text(json.dumps(report,indent=2)+'\n')
artifacts={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in output.iterdir() if p.suffix in ('.json','.png') or p.name=='engine.log'}
(output/'artifacts.json').write_text(json.dumps(artifacts,indent=2)+'\n')
print('STATIC_BATCH_PROBE_VALID',bool(valid),'exit',result.returncode,'inputs',len(before),'output',output)
if not valid:
    print(text[-6000:])
sys.exit(0 if valid else 1)
