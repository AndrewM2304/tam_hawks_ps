"""Capture the actual exported main window while the existing smoke runner boots.
No Godot script override, fixed clock, input injection or player-profile reuse.
"""
from pathlib import Path
from PIL import ImageGrab, ImageStat
import hashlib,json,os,re,signal,subprocess,sys,time
build=Path(sys.argv[1]).resolve();folder=build/'standalone-smoke';folder.mkdir(exist_ok=True)
empty=folder/'empty-working-directory';empty.mkdir(exist_ok=True)
runner=(Path.cwd()/'tools/native_smoke.sh').resolve()
started=time.monotonic();capture=None;display_ready=None
with (folder/'smoke-summary.log').open('w') as log:
 child=subprocess.Popen([str(runner),str(build)],cwd=empty,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 try:
  while child.poll() is None and time.monotonic()-started<150:
   display_path=folder/'display';rendered=folder/'rendered.log'
   if capture is None and display_path.exists() and display_path.read_text().strip() and rendered.exists() and rendered.stat().st_size:
    display=':'+display_path.read_text().strip()
    if display_ready is None:display_ready=time.monotonic()
    if time.monotonic()-display_ready>=6:
     tree=subprocess.run(['xwininfo','-display',display,'-root','-tree'],text=True,capture_output=True,timeout=3)
     if tree.returncode==0 and 'Tam Hawks' in tree.stdout:
      frame=ImageGrab.grab(xdisplay=display)
      if frame.size==(1920,1080) and len(frame.resize((320,180)).getcolors(100000) or [])>700:
       candidate=folder/'title-candidate.png';frame.save(candidate)
       ocr=subprocess.run(['tesseract',str(candidate),'stdout','--psm','11'],env=dict(os.environ,OMP_THREAD_LIMIT='1'),capture_output=True,text=True,timeout=10)
       text=re.sub('[^a-z]','',ocr.stdout.lower())
       if ocr.returncode!=0 or not all(word in text for word in ('career','freeskate','settings','controls')):
        time.sleep(1);continue
       path=folder/'title-live.png';candidate.replace(path)
       capture={'path':path.name,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'dimensions':list(frame.size),'capture_method':'X11 root while exported native main window is visible','window_tree':tree.stdout,'wall_seconds_since_smoke_start':time.monotonic()-started,'fixed_clock':False,'script_override':False,'performance_measurement':False,'title_menu_words_verified':['career','free skate','settings','controls'],'ocr_text':ocr.stdout}
   time.sleep(.5)
  if child.poll() is None:raise TimeoutError('Native smoke exceeded 150 seconds')
  code=child.returncode
 finally:
  if child.poll() is None:
   os.killpg(child.pid,signal.SIGTERM)
   try:child.wait(timeout=5)
   except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait()
result={'command':[str(runner),str(build)],'empty_working_directory':str(empty),'exit_code':code,'wall_seconds':time.monotonic()-started,'title_capture':capture,'macos_launch_tested':False,'target_performance_acceptance':False}
(folder/'SMOKE-RESULTS.json').write_text(json.dumps(result,indent=2)+'\n')
print((folder/'smoke-summary.log').read_text(),end='')
print(json.dumps(result,indent=2))
raise SystemExit(0 if code==0 and capture is not None else 1)
