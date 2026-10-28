#!/usr/bin/env python3
import argparse,os,signal,subprocess,time,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--script',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--seconds',type=int,default=150);a=p.parse_args();root=Path.cwd();output=a.output.resolve();assert output.is_relative_to(root/'.local') and not output.exists();output.mkdir(parents=True)
children=[];handles=[]
def stop(child):
 if child.poll() is None:
  os.killpg(child.pid,signal.SIGTERM)
  try:child.wait(timeout=5)
  except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait(timeout=5)
try:
 display=(output/'display').open('w');handles.append(display);log=(output/'xorg-console.log').open('w');handles.append(log)
 xorg=subprocess.Popen(['/usr/lib/xorg/Xorg','-displayfd',str(display.fileno()),'-config',str(root/'tools/xorg-dummy.conf'),'-logfile',str(output/'xorg.log'),'-noreset','-nolisten','tcp'],stdout=log,stderr=subprocess.STDOUT,start_new_session=True,pass_fds=(display.fileno(),));children.append(xorg)
 end=time.monotonic()+10
 while not(output/'display').read_text().strip():
  if xorg.poll() is not None or time.monotonic()>end:raise RuntimeError('Private display failed.')
  time.sleep(.1)
 env=dict(os.environ,DISPLAY=':'+(output/'display').read_text().strip(),LIBGL_ALWAYS_SOFTWARE='1')
 command=[str(root/'tools/run.sh'),'--rendering-method','gl_compatibility','--audio-driver','Dummy','--windowed','--resolution','1280x800','--fixed-fps','60','--script',str(a.script.resolve()),'--',str(output)]
 (output/'command.json').write_text(json.dumps(command,indent=2)+'\n')
 child=subprocess.Popen(command,cwd=root,env=env,start_new_session=True);children.append(child)
 try:code=child.wait(timeout=a.seconds)
 except subprocess.TimeoutExpired:stop(child);raise
 raise SystemExit(code)
finally:
 for child in reversed(children):stop(child)
 for handle in handles:handle.close()
