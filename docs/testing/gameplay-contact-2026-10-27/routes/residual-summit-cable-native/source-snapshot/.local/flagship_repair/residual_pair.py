from pathlib import Path
import subprocess
import sys
import time

script = Path(sys.argv[1]).resolve()
started = time.monotonic()
failed = False
for mode in ('park', 'cable-legacy'):
    remaining = min(20.0, 29.0 - (time.monotonic() - started))
    if remaining < 3.0:
        print('FOCUS_PAIR incomplete: foreground budget exhausted', flush=True)
        raise SystemExit(1)
    print('FOCUS_CASE ' + mode, flush=True)
    try:
        result = subprocess.run(['./tools/run.sh', '--headless', '--fixed-fps', '60',
                                 '--script', str(script), '--', mode], timeout=remaining)
    except subprocess.TimeoutExpired:
        print('FOCUS_PAIR incomplete: bounded child timed out', flush=True)
        raise SystemExit(1)
    failed |= result.returncode != 0
raise SystemExit(1 if failed else 0)
