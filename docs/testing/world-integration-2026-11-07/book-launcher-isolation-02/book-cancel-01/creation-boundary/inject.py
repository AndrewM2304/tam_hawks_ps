import os,runpy,signal,subprocess,time
from pathlib import Path
original=subprocess.Popen
def inject(*args,**kwargs):
 child=original(*args,**kwargs)
 limit=time.monotonic()+5
 while not Path(os.environ['FAKE_READY']).is_file()and time.monotonic()<limit:time.sleep(.01)
 os.kill(os.getpid(),signal.SIGTERM)
 return child
subprocess.Popen=inject
runpy.run_path(os.environ['QA_HELPER'],run_name='__main__')
