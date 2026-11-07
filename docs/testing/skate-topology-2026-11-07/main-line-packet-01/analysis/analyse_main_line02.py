"""Offline BA review. Reads retained native output; never runs/changes gameplay."""
from pathlib import Path
import hashlib
import importlib.util
import json
import math

ROOT = Path(__file__).resolve().parents[2]
OWN = Path(__file__).resolve().parent
EPOCH = OWN / "main-line-native-02"
METHOD = ROOT / ".local/gap-combo-validation/compare_matched.py"
spec = importlib.util.spec_from_file_location("independent_score_replay", METHOD)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def norm(v):
    return math.sqrt(sum(x*x for x in v))


def sub(a, b):
    return [x-y for x, y in zip(a, b)]


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


data = json.loads((EPOCH / "native-result.json").read_text())
receipt = json.loads((EPOCH / "receipt.json").read_text())
registry = json.loads((OWN / "bypass-native-03/native-result.json").read_text())["registry"]
checks = []


def check(name, ok):
    checks.append({"name": name, "passed": bool(ok)})


check("native original result exactly 15/0", data["passed"] == 15 and data["failed"] == 0)
check("source/cache and actual/observer inputs stable", all(receipt[x] for x in ["source_stable", "actual_source_stable", "owned_entrypoints_stable", "source_matches_combined02", "eligible"]))
check("both parser/native exit0 with no raw error", len(receipt["stages"]) == 2 and all(x["exit_code"] == 0 and not x["raw_error"] for x in receipt["stages"]))
check("declared three initial fixture offsets only", len(data["runs"]) == 3 and all(x["initial_only_fixture"] for x in data["runs"]))
results = []
for run in data["runs"]:
    label = run["label"]
    rows, events = run["trace"], run["score_events"]
    replay = module.score_ledger({"score_events": events})
    rr = replay["runs"][label]
    check(label + ": independent point/identity integer replay", not replay["mismatches"])
    check(label + ": exactly one independent bank and no drops", len(rr["positive_banks"]) == 1 and rr["drops"] == 0)
    check(label + ": derived500base x4=2000", rr["positive_banks"] == [{"physics": next(e["physics"] for e in events if e["kind"] == "bank_combo"), "base": 500, "multiplier": 4, "value": 2000}])
    check(label + ": all sampled physics frames consecutive", all(b["physics"] == a["physics"] + 1 for a, b in zip(rows, rows[1:])))
    check(label + ": native named50_50 before bufferedManual", run["named_capture"] and run["manual_seen"] and not any(x["bail"] for x in rows))
    capture = next(e for e in run["events"] if e["kind"] == "capture")
    ci = next(i for i, row in enumerate(rows) if row["physics"] == capture["physics"])
    before, after, next_row = rows[ci-1:ci+2]
    manual_i = next(i for i, e in enumerate(events) if e["kind"] == "add_trick" and e["identity"] == "manual")
    manual = events[manual_i]
    landing_order = [e["kind"] for e in events[:manual_i+1] if e["physics"] == manual["physics"]]
    check(label + ": actual landing thencontinue thenManual samephysics", landing_order == ["begin_landing", "continue_combo", "add_trick"])
    check(label + ": no early bank/drop or gap award", not any(e["kind"] in ("bank_combo", "drop_combo") for e in events[:manual_i]) and not any(e["awards"] for e in run["gap_updates"]))
    body_delta = sub(after["position"], before["position"])
    head_delta = sub(after["head"], before["head"])
    before_rel = sub(before["head"], before["position"])
    after_rel = sub(after["head"], after["position"])
    frame_dt = (after["physics"] - before["physics"]) / 60.0
    expected_velocity = [x * frame_dt for x in before["velocity"]]
    witness_keys = ["physics", "stage", "position", "head", "board", "velocity", "speed", "airborne", "floor", "grinding", "guide", "style", "capture_rejection", "capture_obstruction", "contacts"]
    compact = [{k: row[k] for k in witness_keys} for row in (before, after, next_row)]
    result = {
        "label": label,
        "initial_spawn": run["initial_spawn"],
        "end_position": run["end_position"],
        "spatial_return_distance_m": norm(sub(run["end_position"], run["initial_spawn"])),
        "physics_frames": [rows[0]["physics"], rows[-1]["physics"]],
        "trace_rows": len(rows),
        "score_event_order": [{k: e[k] for k in ["physics", "kind", "identity", "points", "awarded", "banked"] if k in e} for e in events],
        "independent_score_replay": replay,
        "manual_landing_event_order": landing_order,
        "capture": capture,
        "capture_motion": {
            "source": "Consecutive after-physics observer values of actual native actor and live rig markers; not pixels or interpolated render frames.",
            "physics_dt_seconds": frame_dt,
            "body_displacement_m": norm(body_delta),
            "body_delta": body_delta,
            "previous_velocity_times_dt_m": norm(expected_velocity),
            "body_delta_minus_previous_velocity_dt_m": norm(sub(body_delta, expected_velocity)),
            "head_world_displacement_m": norm(head_delta),
            "head_relative_to_actor_displacement_m": norm(sub(after_rel, before_rel)),
            "before_capture_after_native_samples": compact,
            "interpretation": "Actual capture maps all three approaches onto the same finite endpoint; substantial body correction and relative rig pose change coincide. This is a motion defect witness, not proof of its root cause or its rendered/interpolated size.",
        },
    }
    results.append(result)

result = {
    "scope": "Real Main local OPEN linkage diagnostic only. Three separate one-bank runs, never one shared total. No local return, cross-area circuit, whole body/truck contact, rendered fidelity or M5 performance acceptance.",
    "offline_checks": {"passed": sum(c["passed"] for c in checks), "failed": sum(not c["passed"] for c in checks), "checks": checks},
    "source_receipt": {"path": str(EPOCH / "receipt.json"), "sha256": sha(EPOCH / "receipt.json"), "project_input_count": receipt["source_count"], "actual_input_count": receipt["actual_source_inputs"]},
    "integer_replay_method": {"path": str(METHOD), "sha256": sha(METHOD), "note": "Replays API input points/stable identities; observed returned awards/base are comparison outputs, never replay inputs. Nested nonmutating landing/continue events are excluded from arithmetic, retained for timing/order. No spin/upgrade/drop outcome newly exercised."},
    "results": results,
    "registry_lookup": [line for line in registry["lines"] if line.get("id") == "Grind_MD_Market_Seats_-19.0"],
    "open_acceptance": {"returned_local_lines_accepted": 0, "closed_crossarea_circuits_accepted": 0, "capture_motion_accepted": False, "displayed_model_contact_accepted": False, "performance_accepted": False},
}
(OWN / "main-line-analysis-02.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"offline_checks": result["offline_checks"], "runs": [{"label": r["label"], "bank": r["independent_score_replay"]["runs"][r["label"]]["positive_banks"], "return_distance": r["spatial_return_distance_m"], "body_m": r["capture_motion"]["body_displacement_m"], "head_m": r["capture_motion"]["head_world_displacement_m"], "relative_head_m": r["capture_motion"]["head_relative_to_actor_displacement_m"]} for r in results]}, indent=2))
assert all(c["passed"] for c in checks)
