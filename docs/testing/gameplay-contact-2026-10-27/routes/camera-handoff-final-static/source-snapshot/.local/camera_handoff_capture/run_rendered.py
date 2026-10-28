#!/usr/bin/env python3
"""One foreground current-production static camera-support handoff capture, total bound 60s."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("--script", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
root = Path.cwd()
output = args.output.resolve()
assert output.is_relative_to(root / ".local") and not output.exists()
output.mkdir(parents=True)
deadline = time.monotonic() + 58
children = []
handles = []

def stop(child):
    if child.poll() is None:
        os.killpg(child.pid, signal.SIGTERM)
        try:
            child.wait(timeout=1)
        except subprocess.TimeoutExpired:
            os.killpg(child.pid, signal.SIGKILL)
            child.wait(timeout=1)

try:
    display = (output / "display").open("w")
    log = (output / "xorg-console.log").open("w")
    handles.extend((display, log))
    xorg = subprocess.Popen(
        ["/usr/lib/xorg/Xorg", "-displayfd", str(display.fileno()), "-config",
         str(root / "tools/xorg-dummy.conf"), "-logfile", str(output / "xorg.log"),
         "-noreset", "-nolisten", "tcp"],
        stdout=log, stderr=subprocess.STDOUT, start_new_session=True,
        pass_fds=(display.fileno(),))
    children.append(xorg)
    display_deadline = min(deadline, time.monotonic() + 8)
    while not (output / "display").read_text().strip():
        if xorg.poll() is not None or time.monotonic() >= display_deadline:
            raise RuntimeError("Private display did not start")
        time.sleep(.05)
    env = dict(os.environ, DISPLAY=":" + (output / "display").read_text().strip(),
               LIBGL_ALWAYS_SOFTWARE="1")
    command = [str(root / "tools/run.sh"), "--rendering-method", "gl_compatibility",
               "--audio-driver", "Dummy", "--windowed", "--resolution", "960x640",
               "--fixed-fps", "60", "--script", str(args.script.resolve()), "--", str(output)]
    (output / "command.json").write_text(json.dumps(command, indent=2) + "\n")
    child = subprocess.Popen(command, cwd=root, env=env, start_new_session=True)
    children.append(child)
    raise SystemExit(child.wait(timeout=max(.1, deadline - time.monotonic())))
finally:
    for child in reversed(children): stop(child)
    for handle in handles: handle.close()
