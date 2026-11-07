"""Portable stdlib integrity check; does not rerun Godot or accept art/hardware."""
from pathlib import Path
import gzip
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent
inventory = json.loads((ROOT / "preservation-index.json").read_text())
checks = 0


def require(condition, label):
    global checks
    if not condition:
        raise AssertionError(label)
    checks += 1


def raw(relative):
    entry = inventory["files"][relative]
    payload = (ROOT / relative).read_bytes()
    require(hashlib.sha256(payload).hexdigest() == entry["sha256"], relative)
    decoded = gzip.decompress(payload) if entry["compression"] else payload
    require(hashlib.sha256(decoded).hexdigest() == entry["raw_sha256"], relative + " decoded")
    require(len(decoded) == entry["raw_bytes"], relative + " length")
    return decoded


for relative in inventory["files"]:
    raw(relative)

for stage, expected in {
    "math-01": 12,
    "wall-remedy-01": 91,
    "motion-02": 67,
    "core-remedy-02": 199,
    "constructors-01": 249,
}.items():
    receipt = json.loads(raw(stage + "/receipt.json"))
    before = json.loads(raw(stage + "/source-before.json.gz"))
    after = json.loads(raw(stage + "/source-after.json.gz"))
    log = raw(stage + "/native.log.gz")
    require(receipt["returncode"] == 0 and not receipt["raw_engine_error"], stage + " clean")
    require(before == after and receipt["source_stable"], stage + " source identity")
    require(before["WRAPPER"] == hashlib.sha256(raw(stage + "/run_final_stage.py.txt")).hexdigest(), stage + " prebound wrapper")
    require(len(re.findall(rb"^PASS ", log, re.MULTILINE)) == expected, stage + " actual pass count")
    require(not re.search(rb"SCRIPT ERROR|ERROR:|^FAIL[ :]|Parse Error", log, re.MULTILINE), stage + " raw errors")

for stage in ["core-01", "wall-trace-01", "motion-01"]:
    receipt = json.loads(raw(stage + "/receipt.json"))
    require(receipt["returncode"] != 0, stage + " rejected baseline retained")

manifest = json.loads(raw("integration-manifest.json"))
require(manifest["status"] == "ADMITTED (private scoped)", "scoped admission status")
require(len(manifest["files"]) == 115 and manifest["selected_outputs"] == 43, "exact integration scope")
for stage, observer in [("core-remedy-02", "cohort_core.gd"), ("motion-02", "cohort_motion.gd"), ("constructors-01", "cohort_constructors.gd")]:
    before = json.loads(raw(stage + "/source-before.json.gz"))
    require(before[observer] == hashlib.sha256(raw("observers/" + observer + ".txt")).hexdigest(), stage + " exact observer")
    for relative, item in manifest["files"].items():
        if relative.startswith("game/") and not relative.endswith(".uid"):
            require(before.get(relative) == item["candidate_sha256"], stage + " runtime/asset " + relative)

public_source = raw("candidate-source/tests/fitted_garment_tests.gd.txt")
public_pins = json.loads(raw("constructors-01/source-before.json.gz"))
require(public_pins["tests/fitted_garment_tests.gd"] == hashlib.sha256(public_source).hexdigest(), "executed public module")
require(b".run(tree,_check)" not in public_source, "undefined extraction callback removed")
for stage in ["core-remedy-02", "constructors-01"]:
    certificate = json.loads(raw(stage + "/exact-shoe-certificate.json"))
    require(certificate["passed"] and all(certificate["oracle_self_test"].values()), stage + " exact independent enclosure")
    native = raw(stage + "/shoe-support-certificate.json.gz")
    require(certificate["input_sha256"] == hashlib.sha256(native).hexdigest(), stage + " exact native certificate input")

result = {"checks": checks, "failures": 0, "scope": "Stored source/native packet integrity only; no engine rerun, visual, current Main or target hardware acceptance."}
print(json.dumps(result, indent=2))
