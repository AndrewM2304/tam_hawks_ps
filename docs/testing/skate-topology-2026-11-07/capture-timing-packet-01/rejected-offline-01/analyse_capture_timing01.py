"""Independent offline split of physical capture correction and rig-relative motion."""
from pathlib import Path
import hashlib
import json
import math

O = Path(__file__).resolve().parent
D = O / "main-capture-timing-01"
data = json.loads((D / "native-result.json").read_text())
receipt = json.loads((D / "receipt.json").read_text())
old = json.loads((O / "main-line-native-02/native-result.json").read_text())
old_source = json.loads((O / "main-line-native-02/source-before.json").read_text())
new_source = json.loads((D / "source-before.json").read_text())


def sub(a, b):
    return [x-y for x, y in zip(a, b)]


def norm(a):
    return math.sqrt(sum(x*x for x in a))


checks = []


def check(name, value):
    checks.append({"name": name, "passed": bool(value)})


check("original native result12/0", data["passed"] == 12 and data["failed"] == 0)
check("all source/cache/actual/observer manifests stable", all(receipt[x] for x in ["eligible", "source_stable", "actual_source_stable", "owned_entrypoints_stable", "source_matches_combined02"]))
check("parser/native clean exit0", len(receipt["stages"]) == 2 and all(x["exit_code"] == 0 and not x["raw_error"] and x["stop"] is None for x in receipt["stages"]))
check("all original1187 project inputs unchanged", len(old_source) == 1187 and all(new_source.get(k) == v for k, v in old_source.items()))
added = {k: v for k, v in new_source.items() if k not in old_source}
check("only addition is Root's uninvoked input probe", set(added) == {"tests/neighbourhood_level_input_probe.gd"})
baseline = data["runs"][0]["trace"]
comparison_keys = ["physics", "position", "velocity", "speed", "airborne", "floor", "manual", "manual_balance", "grinding", "guide", "style", "bail", "head", "board", "push", "brake", "ollie", "grind", "manual_input", "total", "base", "multiplier", "pending", "landing_remaining"]
differences = []
for i, (a, b) in enumerate(zip(old["runs"][0]["trace"], baseline)):
    for k in comparison_keys:
        if a[k] != b[k]:
            differences.append({"index": i, "key": k, "old": a[k], "new": b[k]})
check("original baseline first91 physics/state/presentation/input/score samples exact", len(baseline) == 91 and not differences)
runs = []
for run in data["runs"]:
    rows = run["trace"]
    captures = [e for e in run["events"] if e["kind"] == "capture"]
    check(run["mode"] + ": consecutive recorded physics", all(b["physics"] == a["physics"] + 1 for a, b in zip(rows, rows[1:])))
    check(run["mode"] + ": fixed original initial fixture", run["initial_only_fixture"] and run["initial_spawn"] == [-18.7, 4.08, 36.0] and run["initial_heading"] == 0)
    summary = {k: run[k] for k in ["label", "mode", "initial_spawn", "initial_heading", "initial_only_fixture", "request", "named_capture"]}
    summary["frame_range"] = [rows[0]["physics"], rows[-1]["physics"]]
    summary["recorded_frames"] = len(rows)
    summary["capture_count"] = len(captures)
    summary["captures"] = captures
    if run["mode"] == "grounded_no_ollie":
        check("grounded ordinary request refuses withoutOllie", not captures and not run["named_capture"] and not any(e["kind"] == "trick" and e.get("id") == "ollie" for e in run["events"]))
        check("grounded refusal remains supported/no bail", not any(r["airborne"] or r["bail"] for r in rows))
        summary["scope"] = "Negative acceptance/refusal only; not a combo bank or topology result."
    else:
        check(run["mode"] + ": exactly one authenticated intended named50_50 capture", len(captures) == 1 and run["named_capture"] and captures[0]["native_contact_valid"] and captures[0]["contact_verified"])
        capture = captures[0]
        i = next(i for i, row in enumerate(rows) if row["physics"] == capture["physics"])
        before, after = rows[i-1:i+1]
        check(run["mode"] + ": actual airborne pre-entry with realOllie", before["airborne"] and not before["floor"] and len([e for e in run["events"] if e["kind"] == "trick" and e.get("id") == "ollie"]) == 1)
        if run["mode"] == "interior_rising":
            check("rising point lies strictly inside finiteguide", 19.3 < after["position"][2] < 28.7 and before["velocity"][1] > 0)
        if run["mode"] == "interior_descending":
            check("descending point lies strictly inside finiteguide", 19.3 < after["position"][2] < 28.7 and before["velocity"][1] < 0)
        a_rel = sub(before["head"], before["position"])
        b_rel = sub(after["head"], after["position"])
        summary["capture_measurement"] = {
            "physics": [before["physics"], after["physics"]],
            "body_displacement_m": norm(sub(after["position"], before["position"])),
            "body_delta": sub(after["position"], before["position"]),
            "head_world_displacement_m": norm(sub(after["head"], before["head"])),
            "head_relative_to_body_displacement_m": norm(sub(b_rel, a_rel)),
            "board_world_displacement_m": norm(sub(after["board"]["origin"], before["board"]["origin"])),
            "airborne_before": before["airborne"],
            "floor_before": before["floor"],
            "vertical_velocity_before": before["velocity"][1],
            "finite_guide_distance_after": after["grind_distance"],
            "body_y_correction_m": after["position"][1] - before["position"][1],
            "body_x_correction_m": after["position"][0] - before["position"][0],
            "body_z_correction_m": after["position"][2] - before["position"][2],
            "basis": "Actual consecutive native after-physics values, dt1/60. Marker changes are not interpolated render/pixel measurements. Body and relative-head are separate vectors, not additive scalar distances.",
        }
        keys = ["physics", "stage", "position", "velocity", "airborne", "floor", "grinding", "guide", "style", "head", "board", "visual", "grind_visual_offset", "native_contact_valid", "grind_distance", "contacts", "capture_rejection", "capture_obstruction"]
        summary["before_capture_after_native_witness"] = [{k: row[k] for k in keys} for row in rows[i-1:i+3]]
    runs.append(summary)
result = {
    "scope": "Natural mapped-input capture diagnosis, no controller/geometry/score changes or fidelity/route acceptance.",
    "source_inputs": {"original_count": len(old_source), "current_count": len(new_source), "added_uninvoked_root_fixture": added, "old_inputs_changed": [k for k, v in old_source.items() if new_source.get(k) != v]},
    "offline_review": {"passed": sum(x["passed"] for x in checks), "failed": sum(not x["passed"] for x in checks), "checks": checks},
    "baseline_parity": {"rows": len(baseline), "keys": comparison_keys, "differences": differences},
    "runs": runs,
    "finding": "Endpoint entry adds a longitudinal correction, but substantial body correction and rig-relative handoff also occur during both rising and descending interior catches. A grounded no-Ollie approach correctly refuses. This is not solely an endpoint or grounded shortcut issue.",
    "source_hypothesis": "Skater2126 seeds _grind_visual_offset with physical correction, while exact native-contact display2750..2757 immediately replaces the visual frame and clears that offset. Bearing must stay authenticated in any eventual repair; this observation does not authorize broad clearance changes or cosmetic interpolation through steel.",
    "open": ["Root/ME repair design and adversarial native bearing guards", "Actual interpolated/pixel presentation and full displayed model contacts", "Mapped returned local lines and closed cross-area single-bank circuits", "MacBook Air M5 hardware/fidelity/performance"],
}
(O / "capture-timing-analysis-01.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"checks": result["offline_review"], "runs": [{"mode": r["mode"], "capture": r.get("capture_measurement"), "capture_count": r["capture_count"]} for r in runs]}, indent=2))
assert all(x["passed"] for x in checks)
