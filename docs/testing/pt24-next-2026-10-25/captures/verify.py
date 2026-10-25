"""Verify retained PNGs, paired cameras and current capture-source bindings."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image

root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
folder = Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sources(mapping):
    for name, digest in mapping.items():
        assert name.startswith("res://"), name
        assert sha(root / name.removeprefix("res://")) == digest, name


def frames(directory, records):
    assert len({entry["file"] for entry in records}) == len(records)
    for entry in records:
        path = directory / entry["file"]
        assert sha(path) == entry.get("sha256", entry.get("image_sha256")), path
        with Image.open(path) as frame:
            assert frame.size == (1280, 800), path
            assert len(frame.resize((160, 100)).getcolors(16001) or []) > 12, path


design = json.loads((folder / "design/manifest.json").read_text())
assert design["source_stable"] and design["source_before"] == design["source_after"]
assert design["failures"] == 0 and not design["timed_out"]
assert design["run_layout"] and len(design["records"]) == design["expected_frames"] == 20
assert not design["profile_writes_enabled"]
sources(design["source_after"])
frames(folder / "design", design["records"])
controls = []
for mode in ("before", "after"):
    data = json.loads((folder / "temporal" / mode / "manifest.json").read_text())
    assert data["source_stable"] and data["failures"] == 0
    assert data["baseline_display"] == (mode == "before")
    assert len(data["records"]) == 12
    assert {(r["witness"], r["sample"]) for r in data["records"]} == {
        (witness, sample) for witness in (5, 16, 17, 18) for sample in range(3)}
    sources(data["source_sha256"])
    frames(folder / "temporal" / mode, data["records"])
    controls.append(data)
assert controls[0]["source_sha256"] == controls[1]["source_sha256"]
assert controls[0]["quality"] == controls[1]["quality"]
for before, after in zip(controls[0]["records"], controls[1]["records"]):
    for key in ("file", "witness", "sample", "camera_position"):
        assert before[key] == after[key], key
logs = [folder / name for name in ("pt24-next-design.log", "pt24-next-temporal-before.log", "pt24-next-temporal-after.log")]
for log in logs:
    assert not any(token in log.read_text() for token in ("SCRIPT ERROR", "ERROR:", "FAIL:", "Parse Error")), log
result = {"valid": True, "design_frames": 20, "matched_world_frames": 24,
          "dimensions": [1280, 800], "current_source_bindings_verified": True,
          "paired_camera_positions_and_settings_verified": True,
          "clean_logs": True, "log_sha256": {p.name: sha(p) for p in logs},
          "limits": ["Static authored/contact diagnostics and world-only analytic readbacks; no actual-input motion acceptance.",
                     "Baseline skips the entire display repair helper, including older repairs.",
                     "No target-Mac temporal, frame-time, art or fun acceptance."]}
(folder / "CAPTURE-AUDIT.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))
