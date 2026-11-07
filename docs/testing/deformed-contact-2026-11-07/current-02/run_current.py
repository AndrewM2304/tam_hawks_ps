#!/usr/bin/env python3
from pathlib import Path
import datetime,hashlib,json,os,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent/(sys.argv[1] if len(sys.argv)>1 else 'current-focus-01')
OUT.mkdir(exist_ok=False)
def sources():
    files=[p for name in ['game','tests','tools'] for p in (ROOT/name).rglob('*') if p.is_file()]+[ROOT/'project.godot']
    return {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
before=sources();env=os.environ.copy()
for kind in ['DATA','CONFIG','CACHE']:env['XDG_'+kind+'_HOME']=str(OUT/'xdg'/kind.lower())
env['TAM_DEFORMED_EVIDENCE_DIR']=str(OUT)
observer=ROOT/'.local/deformed-contact/current_focus.gd'
command=['godot','--headless','--path',str(ROOT),'--fixed-fps','60','--script',str(observer)]
started=datetime.datetime.now(datetime.timezone.utc).isoformat();start=time.monotonic();code=None;timed_out=False
with (OUT/'native.log').open('w') as log:
    try:code=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120).returncode
    except subprocess.TimeoutExpired:timed_out=True
after=sources();raw=(OUT/'native.log').read_text()
receipt={'command':command,'utc':started,'wall_s':time.monotonic()-start,'returncode':code,'timed_out':timed_out,
    'source_before':before,'source_after':after,'source_stable':before==after,'observer_sha256':hashlib.sha256(observer.read_bytes()).hexdigest(),
    'raw_engine_error':any(t in raw for t in ['SCRIPT ERROR:','\nERROR:','WARNING: ObjectDB instances leaked']),
    'scope':'actual current production source and entire two modules; no renderer/M5 performance claim'}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({k:v for k,v in receipt.items() if k not in ['source_before','source_after']}))
sys.exit(0 if code==0 and not timed_out and before==after and not receipt['raw_engine_error'] else 1)
