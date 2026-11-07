from pathlib import Path
import gzip
import hashlib
import json
import subprocess
import tarfile

HERE = Path(__file__).resolve().parent
passed = 0


def check(ok, label):
    global passed
    if not ok:
        raise AssertionError(label)
    passed += 1


def sha(data):
    return hashlib.sha256(data).hexdigest()


for item in json.loads((HERE / "raw-preservation.json").read_text())["files"]:
    data = (HERE / item["destination"]).read_bytes()
    check(sha(data) == item["stored_sha256"], "stored " + item["destination"])
    if item["encoding"] == "gzip":
        data = gzip.decompress(data)
    check(sha(data) == item["raw_sha256"] and len(data) == item["raw_bytes"], "original raw bytes")
before = json.loads(gzip.decompress((HERE / "before.json.gz").read_bytes()))
after = json.loads(gzip.decompress((HERE / "after.json.gz").read_bytes()))
check(before == after and len(before) == 897, "unchanged complete source scope")
receipt = json.loads((HERE / "receipt.json").read_text())
check(receipt["eligible"] is True and not receipt["changed_inputs"], "original eligible receipt")
check(receipt["elapsed_seconds"] < receipt["deadline_seconds"] == 195, "original bounded cohort")
check(len(receipt["stages"]) == 2 and all(stage["exit_code"] == 0 and not stage["raw_errors"]
      for stage in receipt["stages"]), "clean native/parser")
check("NEIGHBOURHOOD RESULT: 22 passed, 0 failed" in (HERE / "native.log").read_text(), "native result")
bindings = json.loads((HERE / "source-bindings.json").read_text())
refs = json.loads((HERE / "unchanged-git-source-references.json").read_text())
check(bindings["base_commit"] == refs["base_commit"], "one Git base")
check(set(bindings["inputs"]) == set(before), "complete input reconstruction")
with tarfile.open(HERE / "source-delta-objects.tar.gz") as archive:
    objects = {item.name: archive.extractfile(item).read() for item in archive.getmembers() if item.isfile()}
check(len(refs["files"]) == 849 and len(objects) == 48, "complete source split")
for path, item in bindings["inputs"].items():
    check(item["sha256"] == before[path]["sha256"] and item["bytes"] == before[path]["bytes"], "bound source " + path)
    if "object" in item:
        data = objects[item["object"]]
        check(sha(data) == item["sha256"] and len(data) == item["bytes"], "delta " + path)
    else:
        check(refs["files"][path]["sha256"] == item["sha256"] and refs["files"][path]["bytes"] == item["bytes"], "Git reference " + path)
check(sha((HERE / "runner.py.txt").read_bytes()) == before[".local/neighbourhood-integration/run-combined-03.py"]["sha256"], "before-bound outer launcher")
repo = next((p for p in HERE.parents if (p / ".git").exists()), None)
if repo is not None:
    proc = subprocess.Popen(["git", "cat-file", "--batch"], cwd=repo, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    for path, item in refs["files"].items():
        proc.stdin.write((item["git_blob"] + "\n").encode())
        proc.stdin.flush()
        header = proc.stdout.readline().decode().split()
        check(len(header) == 3 and header[1] == "blob", "Git blob " + path)
        data = proc.stdout.read(int(header[2]))
        check(proc.stdout.read(1) == b"\n", "Git framing")
        check(sha(data) == item["sha256"] and len(data) == item["bytes"], "exact Git bytes " + path)
    proc.stdin.close()
    check(proc.wait() == 0, "Git reader exit")
print(json.dumps({"passed": passed, "failed": 0, "native_result": [22, 0], "source_inputs": 897,
                  "git_objects_verified": repo is not None, "scope": "Offline source/raw verification only."}))
