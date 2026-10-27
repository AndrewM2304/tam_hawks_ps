"""Restore the exact ignored native recorder witness; never launch an engine."""
from pathlib import Path
import hashlib
import json

root = Path.cwd()
evidence = Path(__file__).resolve().parents[1]
execution = evidence / "executions/native"
snapshots = json.loads((execution / "SNAPSHOTS.json").read_text())
for row in snapshots["files"]:
    if row["input"] not in (
        ".local/recorder_display_witness.gd",
        ".local/recorder_display_witness.sh",
    ):
        continue
    source = execution / row["file"]
    data = source.read_bytes()
    assert hashlib.sha256(data).hexdigest() == row["sha256"], source
    destination = root / row["input"]
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)
    print(destination.relative_to(root))
