"""Verify archived source and raw logs; this does not rerun the game."""
from pathlib import Path
import argparse
import gzip
import hashlib
import json
import subprocess
import tarfile

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument("--repo", type=Path)
args = parser.parse_args()
passed = 0


def check(value, label):
    global passed
    if not value:
        raise AssertionError(label)
    passed += 1


def sha(data):
    return hashlib.sha256(data).hexdigest()


for item in json.loads((HERE / "raw-preservation.json").read_text())["files"]:
    data = (HERE / item["destination"]).read_bytes()
    check(sha(data) == item["stored_sha256"], "stored " + item["destination"])
    if item["encoding"] == "gzip":
        data = gzip.decompress(data)
    check(sha(data) == item["raw_sha256"] and len(data) == item["raw_bytes"],
          "original " + item["destination"])

epoch = HERE / "combined-02"
receipt = json.loads((epoch / "receipt.json").read_text())
before = json.loads(gzip.decompress((epoch / "before.json.gz").read_bytes()))
after = json.loads(gzip.decompress((epoch / "after.json.gz").read_bytes()))
check(before == after and len(before) == 896, "all 896 source inputs unchanged")
check(receipt["eligible"] is True and not receipt["changed_inputs"], "raw positive receipt")
check(len(receipt["stages"]) == 2 and all(s["exit_code"] == 0 and not s["raw_errors"]
      for s in receipt["stages"]), "parser and native logs clean")
check(receipt["elapsed_seconds"] < receipt["deadline_seconds"] == 195, "bounded native cohort")
check("NEIGHBOURHOOD RESULT: 20 passed, 0 failed" in (epoch / "native.log").read_text(),
      "native lifecycle result")
old = json.loads((HERE / "combined-01/receipt.json").read_text())
check(old["eligible"] is False and any(s["raw_errors"] for s in old["stages"]),
      "original freed-instance failure remains rejected")
bindings = json.loads((HERE / "source-bindings.json").read_text())
refs = json.loads((HERE / "unchanged-git-source-references.json").read_text())
check(bindings["base_commit"] == refs["base_commit"], "one exact Git base")
check(set(bindings["inputs"]) == set(before), "complete source closure")
with tarfile.open(HERE / "source-delta-objects.tar.gz", "r:gz") as archive:
    objects = {item.name: archive.extractfile(item).read() for item in archive.getmembers()
               if item.isfile()}
check(len(objects) == 21 and len(refs["files"]) == 875, "complete deduplicated source split")
for path, item in bindings["inputs"].items():
    check(item["sha256"] == before[path]["sha256"] and item["bytes"] == before[path]["bytes"],
          "bound source " + path)
    if "object" in item:
        data = objects[item["object"]]
        check(sha(data) == item["sha256"] and len(data) == item["bytes"], "delta " + path)
    else:
        check(refs["files"][path]["sha256"] == item["sha256"] and
              refs["files"][path]["bytes"] == item["bytes"], "base reference " + path)
runner = ".local/neighbourhood-integration/run-combined-02.py"
check(sha((epoch / "runner.py.txt").read_bytes()) == before[runner]["sha256"],
      "outer launcher was before-bound")
repo = args.repo or next((p for p in HERE.parents if (p / ".git").exists()), None)
if repo is not None:
    proc = subprocess.Popen(["git", "cat-file", "--batch"], cwd=repo,
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    for path, item in refs["files"].items():
        proc.stdin.write((item["git_blob"] + "\n").encode())
        proc.stdin.flush()
        header = proc.stdout.readline().decode().split()
        check(len(header) == 3 and header[1] == "blob", "Git blob " + path)
        data = proc.stdout.read(int(header[2]))
        check(proc.stdout.read(1) == b"\n", "Git framing")
        check(sha(data) == item["sha256"] and len(data) == item["bytes"], "Git bytes " + path)
    proc.stdin.close()
    check(proc.wait() == 0, "Git source reader exited cleanly")
print(json.dumps({"passed": passed, "failed": 0, "native_result": [20, 0],
                  "source_inputs": 896, "git_objects_verified": repo is not None,
                  "scope": "Offline raw/source closure; cache, parsed input, natural lines, art and hardware are not certified."}))
