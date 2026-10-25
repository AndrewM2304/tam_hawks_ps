# Owner debug session — portable cloud evidence

Reviewed 25 October 2026, planning only. Session ID
`2026-10-24T22-29-11-9325535`; recorded UTC 22:29–22:43 on 24 October
(local British Summer Time 23:29–23:43). Original source is the owner's Godot
user-data debug_sessions folder on their Mac. No cloud worker was started.

[38-capture index and exact comments](INDEX.md),
[30 local implementation tickets](../../planning/DEBUG-SESSION-2026-10-24.md),
[station/pond direction ADR](../../architecture/decisions/ADR-032-playtest-station-and-park-direction.md).

## Contents and verification

- reports/: all 38 JSON captures and 38 engine logs copied byte-for-byte.
- images/: 38 JPEG review derivatives, width 1280; originals are 2851×1782 PNGs.
  These show the owner's actual captured frames. They are not repair screenshots
  or lossless evidence for diagnosing pixel-level temporal flicker.
- manifest.json: source fingerprints, original PNG hashes/sizes, copied JSON and
  derivative JPEG hashes, original session.json hash, count and session header.
  The original session duplicates all reports; its 38 entries were checked equal
  to the individual JSONs and omitted here to avoid redundant repository data.
- captured-candidate.patch: recoverable local production/test candidate over
  commit 7e4d26351eae0740d3a985f5bb986b1105236b3c. Includes tracked game/project
  changes and new recorder/test/UID files; it does not apply itself.

All 38 images were inspected; all 38 JSONs/logs reviewed. The ten captured source
fingerprints are identical across reports and match the local candidate files.
All screenshot_error fields are OK. History is bounded at 0–40 samples; the
first capture has none. Engine logs are identical 150-byte renderer startup
headers, not a full explanatory bug trace. No exceptions were recorded in them.

The source candidate is unfinished. Required 4560/0 in the older STATUS certifies
main 7e4d263, not these dirty game changes. The prior local work includes candidate
world fixes and recorder UI plus a clean native after capture; full regression,
new world tests and final recorder integration remain outstanding. This session
demonstrates that owner-visible defects remain despite the narrow candidate checks.

## Cloud source recovery

Use pushed branch `fix/kelvingrove-owner-defects-20261024` (planning/evidence
commit `da8250f` and handoff follow-up). Main remains the canonical default and
has not received this unfinished gameplay candidate.

Start from a feature branch containing the pinned base, using the existing cloud
checkout. Preserve any newer work; do not reset it or recreate a worktree. Compare
HEAD and local changes before applying the patch. On the exact base, after a
clean application check:

```sh
git apply --check docs/testing/debug-session-2026-10-24/captured-candidate.patch
git apply docs/testing/debug-session-2026-10-24/captured-candidate.patch
```

If current source already has these changes, do not reapply. If main has moved,
reconcile the patch deliberately and record the new base. Verify each SHA-256 in
manifest.json against its res:// project-relative file before reproducing. The
patch also preserves modified Glasgow, horizon and HUD source not fingerprinted
by recorder format 1. No Git commit identity can be inferred from ten hashes alone.

The recorded positions/heading/camera initialize diagnosis; history/input is a
bounded observation, **not** a deterministic replay or complete session movie.
Reproduce movement with actual inputs after initial placement. For flicker fixes,
capture new matched moving control/after footage and measure render cost. A
Linux rendering result cannot certify Apple M5 shadows, controllers or frame time.

## Planning validation

Local review checks: 38/38 JSON/PNG/log triplets, completed manifest matches all
38 reports, one source-fingerprint set with 10/10 local matches; all 38 derivatives
decode. Every capture maps to a primary ticket. Documentation links, 30 unique
ticket IDs, patch recovery and copied-file hashes are validated in the planning
handoff. Production files are unchanged by this planning review; no game suite
was rerun for documentation alone. Original full backlog bodies are preserved.
