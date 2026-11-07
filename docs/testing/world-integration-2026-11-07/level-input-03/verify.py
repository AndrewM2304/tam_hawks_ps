from pathlib import Path
import gzip
import hashlib
import json
import subprocess
import sys

HERE = Path(__file__).resolve().parent
passed = 0


def check(value, label):
    global passed
    if not value:
        raise AssertionError(label)
    passed += 1


def sha(data):
    return hashlib.sha256(data).hexdigest()


subprocess.run([sys.executable, str(HERE / "../main-lifecycle-02/verify.py")], check=True)
for item in json.loads((HERE / "raw-preservation.json").read_text())["files"]:
    data = (HERE / item["destination"]).read_bytes()
    check(sha(data) == item["stored_sha256"], "stored " + item["destination"])
    if item["encoding"] == "gzip":
        data = gzip.decompress(data)
    check(sha(data) == item["raw_sha256"] and len(data) == item["raw_bytes"],
          "raw " + item["destination"])
closure = json.loads((HERE / "source-closure.json").read_text())
parent = json.loads(gzip.decompress((HERE / "../main-lifecycle-02/combined-02/before.json.gz").read_bytes()))
current = json.loads(gzip.decompress((HERE / "level-input-03/before.json.gz").read_bytes()))
after = json.loads(gzip.decompress((HERE / "level-input-03/after.json.gz").read_bytes()))
check(current == after and len(current) == closure["source_count"] == 897, "complete unchanged source scope")
check(len(closure["common_inputs"]) == 895 and len(closure["additional_inputs"]) == 2, "complete source split")
check(set(closure["common_inputs"]) | set(closure["additional_inputs"]) == set(current), "no omitted native inputs")
for path, item in closure["common_inputs"].items():
    check(item == parent[path] == current[path], "exact inherited source " + path)
for path, item in closure["additional_inputs"].items():
    data = (HERE / "source-objects" / item["sha256"]).read_bytes()
    check(sha(data) == item["sha256"] and len(data) == item["bytes"] and item == current[path],
          "additional source " + path)
for number in range(1, 4):
    epoch = HERE / ("level-input-%02d" % number)
    before = json.loads(gzip.decompress((epoch / "before.json.gz").read_bytes()))
    probe_path = ".local/neighbourhood-integration/project/tests/neighbourhood_level_input_probe.gd"
    runner_path = ".local/neighbourhood-integration/run-level-input-%02d.py" % number
    check(sha((epoch / "probe.gd.txt").read_bytes()) == before[probe_path]["sha256"], "before-bound probe")
    check(sha((epoch / "runner.py.txt").read_bytes()) == before[runner_path]["sha256"], "before-bound launcher")
    receipt = json.loads((epoch / "receipt.json").read_text())
    check(receipt["eligible"] is (number == 3), "raw eligibility retained")
receipt = json.loads((HERE / "level-input-03/receipt.json").read_text())
check(all(stage["exit_code"] == 0 and not stage["raw_errors"] for stage in receipt["stages"]), "native/parser clean")
check(receipt["elapsed_seconds"] < receipt["deadline_seconds"] == 180, "original bound")
check("LEVEL INPUT RESULT: 31 passed, 0 failed" in (HERE / "level-input-03/native.log").read_text(), "positive native result")
check("LEVEL INPUT RESULT: 27 passed, 4 failed" in (HERE / "level-input-02/native.log").read_text(), "failed fixture retained")
print(json.dumps({"passed": passed, "failed": 0, "native_result": [31, 0], "source_inputs": 897,
                  "scope": "Offline source/raw verification, plus separately reported parent verification; no new engine/device/art/performance acceptance."}))
