# Overnight skating completion — 24 October 2026, Europe/London

Owner request: keep implementing every identified navigation/trick gap and audit/
revise the current level, without routine feedback stops. Completion means actual
working mechanics, supported/usable surfaces, purposeful lines, captured review
and honest regression evidence. [ADR-015](../architecture/decisions/ADR-015-complete-skate-process.md)
defines the integration contracts. Keep all current career/save identities.

| Work | Owner | Priority / milestone | Dependencies | Acceptance |
|---|---|---|---|---|
| Charge/release, setup tricks, stance/landing, powerslide | Root | P0 / M01-003/004, M02 | Existing collision/takeoff | Actual tap/hold launches, charge bounds, directional setups, clean/bad rotation landings, signed stance and quick-turn tests |
| True transition/vert/re-entry/lip | transition_vert | P0 / M02-011 | Native feature geometry + root hooks | Actual full 90° approach, rollback, departure, re-entry, lip/exit, collision/reset/camera traces |
| Wallride/wallie | wallride | P0 / M02-012 | Solidwall classification + root hooks | Actual eligible/invalid approaches, finite ride, wallie/release, obstruction, cooldown/bail |
| Input language and trick extensions | trick_language + Root | P0 / M02-001/002/003/006 | Catalog/input | Double taps, queued tricks, manual gestures/extensions, special sequences and direction-based setup with bounded timing |
| Combo/special economy | combo_economy + Root | P0 / M02-005/006 | Effective trick signals | Entry multiplier, persistent repetition, rotation bonus, live maintained meter, pause/bail/reset |
| Surface coverage and purposeful density | level_polish | P0 / M03-013/014, M05 | Eligiblewalls/ledgepaths + transition feature | Inventory and explicit exclusions; collision-backed ledges; useful linked park/quay features and preserved route clearance |
| Independent integration/capture | overnight_qe | P0 / M02-008, M06 | Integrated source freeze | Meaningful new/legacy checks, real physics/camera/surface audits, actual rendered actions/places; exact receipts |

Current baseline: local commit `bf7af80`, 1,489/0 at the previous trick-vocabulary
checkpoint. Those results are historical after overnight edits. Do not claim
they validate unfinished new work. All ordinary no-spend/provenance rules remain.

## Continuation protocol

Read AGENTS, STATUS, this plan, ADR-015 and `git status` first. Stay on feature
branch `work`, in this checkout. Check `.local/overnight-lease.json`: a recent
unexpired active lease means another run is working; leave it alone. A stale
lease can be reclaimed. Save a fresh bounded lease during active implementation.

Resume existing edits; never reset them. Use multi-agents with disjoint ownership,
continue independently until the assigned acceptance criteria are genuinely met,
and fix failures before broadening tests again. Update STATUS and this file with
actual outcomes, defects, exact next steps and automation state at checkpoints.
Commit clean tested source when appropriate. Do not purchase, provision, publish,
merge, send third-party messages or invent human acceptance. Stop overnight
continuation by the morning window or when `OVERNIGHT_COMPLETE` is recorded.

## Verified core checkpoint — full fidelity still in progress

The bounded core work in the table is implemented. This does not complete the
owner's broader full-fidelity/polish request; the prior completion wording was too
broad. `OVERNIGHT_COMPLETE` refers only to that engineering checkpoint. Final source passes
`./tools/check.sh`:1817/0, exit 0,213 unchanged inputs. Cold-source Main/title 44/0
and cold/warm/refusal/restoration pass with 210 unchanged inputs. Final28 PNG/44-check
capture passes source stability, PNG CRC/row checks and independent source/image
rehashes; all images are reviewed. Exact receipts and commands are in
[STATUS](../STATUS.md) and [verification](../testing/OVERNIGHT-SKATE-PROCESS.md).

The wall visual penetration/contact and vert speed issues found during actual
review are fixed and verified. Level inventory is357/55/45/111 (bodies/eligible
walls/tracked ledge bodies/grind paths), with explicit exclusions and useful
practice pockets. Existing ten-goal career and all side challenge routes pass.

The bounded overnight continuation was successfully paused after completion.
It will not consume further included allowance while paused. No spending budget,
token purchase, upgrade or billing change exists. The lease is complete/closed.
No new native export is claimed. Human Mac/controller/feel, target performance,
listening and final-art acceptance remain separate; bowls/spine structures and
skitching remain their separate backlog scope. Unfinished fidelity and polish work remains authorized under the owner's
standing request. The continuation is currently paused; no automation was changed
during the24 October status audit. Preserve the tested source and no-spend rule.

## Remaining build priorities

| Work | Owner / priority | Existing tickets | Acceptance / validation |
|---|---|---|---|
| Authentic Boneless/No Comply, stance/catch/landing and bail/recovery motion | A04/A05/A09, P0 | M01-004, M02-008, M05-002/006 | Real hand/foot contact and complete animation states; actual motion captures and physics regressions |
| Broader lip and trick repertoire | A04/A05/A09, P1 | M02-001/002/003/006/008 | Distinct handplants/inverts/lip and other variants with valid support, input and score behavior |
| Bowls/connected curved terrain/spine structures | A04/A05/A09, P1 | M02-011, M03-014 | Native approach/transfer/re-entry and camera tests across connected surfaces |
| Full-map density, art and reachable-line finishing | A05/A08/A09, P0 | M03-014, M05-001/002, M06-007 | Ground-level natural-input review of usable surfaces and purposeful spaces, plus actual captures |
| Planned route event, river stunt, park lap and skitch feasibility | A04/A05/A06/A09, existing priorities | M02-013, M03-015, M04-008/011 | Implement or document the existing scoped feasibility decisions and verify each real playable loop |
| Current Mac package and hardware/feel/performance | A01/A04/A09 + Owner, P0 | M06-004/005/006, M07-003 | Fresh source-bound package; physical Mac/DualSense and moving-route evidence |
