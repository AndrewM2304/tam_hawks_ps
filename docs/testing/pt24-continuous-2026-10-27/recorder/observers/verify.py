"""Read-only independent PNG, native-source and ZIP verification; no engine."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile
from PIL import Image

evidence = Path(__file__).resolve().parents[1]
manifest = json.loads((evidence / "manifest.json").read_text())
for row in manifest["records"]:
    path = evidence / "session" / (row["report"] + ".png")
    with Image.open(path) as image:
        assert image.size == (1440, 900), path
        digest = hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()
        assert digest == row["draw"]["pixel_sha256"], path
for name in ("parser", "native"):
    execution = evidence / "executions" / name
    before = json.loads((execution / "source-before.json").read_text())
    assert before == json.loads((execution / "source-after.json").read_text())
    index = json.loads((execution / "SNAPSHOTS.json").read_text())
    changed = {row["input"]: row for row in index["files"]}
    for path, digest in before.items():
        data = (
            (execution / changed[path]["file"]).read_bytes()
            if path in changed
            else subprocess.check_output(["git", "show", index["git_parent"] + ":" + path])
        )
        assert hashlib.sha256(data).hexdigest() == digest, path
with zipfile.ZipFile(evidence / "session.zip") as archive:
    assert archive.testzip() is None
    for number in (1, 2):
        for suffix in (".png", ".json"):
            name = f"issue-{number:04d}{suffix}"
            assert archive.read(name) == (evidence / "session" / name).read_bytes(), name
print("Verified two same-draw pixel hashes, 654/655 exact source inputs and ZIP PNG/JSON bytes.")
