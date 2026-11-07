#!/usr/bin/env python3
import json,os,signal,subprocess,sys,time
from pathlib import Path
signal.signal(signal.SIGTERM,signal.SIG_IGN)
if len(sys.argv)>1 and sys.argv[1]=='worker':
 Path(os.environ['FAKE_WORKER_READY']).write_text(str(os.getpid()))
 while True:time.sleep(.05)
worker=subprocess.Popen([sys.executable,__file__,'worker'])
while not Path(os.environ['FAKE_WORKER_READY']).is_file():time.sleep(.01)
Path(os.environ['FAKE_READY']).write_text(json.dumps({'parent':os.getpid(),'worker':worker.pid,'group':os.getpgrp(),'helper':os.getppid()}))
while True:time.sleep(.05)
