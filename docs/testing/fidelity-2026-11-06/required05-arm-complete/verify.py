from pathlib import Path
import gzip
import hashlib
import json
import subprocess
import tarfile

root = Path(__file__).resolve().parent
passed = 0


def check(ok, label):
    global passed
    if not ok:
        raise AssertionError(label)
    passed += 1


def sha(data):
    return hashlib.sha256(data).hexdigest()


for item in json.loads((root / "raw-preservation.json").read_text())["files"]:
    data = (root / item["destination"]).read_bytes()
    check(sha(data) == item["stored_sha256"], "stored raw bytes")
    if item["encoding"] == "gzip":
        data = gzip.decompress(data)
    check(sha(data) == item["sha256"] and len(data) == item["bytes"], "original raw bytes")
receipt = json.loads((root / "receipt.json").read_text())
check(receipt["eligible"] is True and receipt["engine_exit"] == 0, "strict positive receipt")
check(receipt["main_result"] == [6697, 0] and receipt["script_launch_result"] == [2, 0], "exact native results")
check(not receipt["changed_inputs"] and not receipt["error_lines"], "no source or native errors")
check(receipt["wall_seconds"] < receipt["deadline_seconds"] == 3600, "original deadline")
before = json.loads(gzip.decompress((root / "source-before.json.gz").read_bytes()))
after = json.loads(gzip.decompress((root / "source-after.json.gz").read_bytes()))
check(before == after and len(before) == 900, "all900 inputs unchanged")
bindings = json.loads((root / "source-bindings.json").read_text())
refs = json.loads((root / "git-references.json").read_text())
check(bindings["base_commit"] == refs["base_commit"] == receipt["git_head"], "one exact base")
check(set(bindings["inputs"]) == set(before) and len(refs["files"]) == 898, "complete source closure")
with tarfile.open(root / "source-objects.tar.gz") as archive:
    objects = {entry.name: archive.extractfile(entry).read() for entry in archive.getmembers() if entry.isfile()}
check(len(objects) == 2, "two delta objects")
repo = next((p for p in root.parents if (p / ".git").exists()), None)
proc = subprocess.Popen(["git", "cat-file", "--batch"], cwd=repo, stdin=subprocess.PIPE, stdout=subprocess.PIPE) if repo else None
for path, item in bindings["inputs"].items():
    check(item["sha256"] == before[path]["sha256"] and item["bytes"] == before[path]["bytes"], "bound source " + path)
    if "object" in item:
        data = objects[item["object"]]
    elif proc:
        check(refs["files"][path]["git_blob"] == item["git_blob"], "base reference")
        proc.stdin.write((item["git_blob"] + "\n").encode())
        proc.stdin.flush()
        header = proc.stdout.readline().decode().split()
        check(len(header) == 3 and header[1] == "blob", "Git blob")
        data = proc.stdout.read(int(header[2]))
        check(proc.stdout.read(1) == b"\n", "Git framing")
    else:
        continue
    check(sha(data) == item["sha256"] and len(data) == item["bytes"], "reconstructed bytes " + path)
if proc:
    proc.stdin.close()
    check(proc.wait() == 0, "Git reader exit")
check(sha((root / "runner.py.txt").read_bytes()) == before[".local/run-fidelity-checkpoint05.py"]["sha256"], "before-bound outer launcher")
print(json.dumps({"passed": passed, "failed": 0, "native": [6697, 0], "cli": [2, 0], "source_inputs": 900,
                  "git_objects_verified": repo is not None, "scope": "Offline raw/source closure only."}))
