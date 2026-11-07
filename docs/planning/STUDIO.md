# Specialist studio workflow

The owner asks for high realism, deliberate compact skating lines, reusable specialist agents/skills, independent BA verification and changes merged into `main`. This guide makes that work resumable from the repository. The machine target is the **MacBook Air M5**. Engine replacement is authorised if evidence makes it necessary; the [engine decision ticket](FIDELITY_TICKETS.md#fid-010--evaluate-enginerenderer-against-macbook-air-m5) requires an honest comparison rather than assuming a rewrite is progress.

## Start a future session

1. Read `AGENTS.md`, [STATUS](../STATUS.md), [FIDELITY_TICKETS](FIDELITY_TICKETS.md), [AAA_BENCHMARK](../product/AAA_BENCHMARK.md), [interfaces](../architecture/interfaces.md), and the relevant original backlog tickets. Current user instructions take precedence over older directions.
2. Inspect the checkout and refs with `git status --short`, `git branch --show-current`, `git log -5 --oneline` and `git remote -v`. Preserve changes. The November starting source is main `0b62035`; the stale October 17 alpha was an ancestor and is not the current baseline. Work directly on `main`, without feature branches/worktrees, and preserve remote history with non-force integration. Root alone handles Git so specialists cannot move the shared checkout underneath each other.
3. Read [the roster](../../.agents/agents/README.md) and explicitly load [studio-production](../../.agents/skills/studio-production/SKILL.md). Load each specialist's exact skill and role brief before delegation. Repository Markdown persists instructions; it does not claim that future runtimes automatically spawn or register them.
4. Reconcile [the current C01–C11 queue](PT24-REMAINING-2026-10-27.md), current interfaces and existing source-bound evidence before selecting an unblocked ticket. Human/Mac evidence remains a separate gate, not a reason to stop independent implementation. Native contacts, 78-trick repertoire, compact routes, station/train, pond/ducks/cable and civic/green are implemented. Keep normal trial features enabled, preserve personal Music isolation and do not restart finished systems from an old blockout plan. Completed facade attribution/startup diagnostics and rejected timing cells retain their recorded outcomes.
5. Assign disjoint files, public interfaces and evidence requirements. Reserve capacity for independent QE, then BA. The thirteen logical roles share root plus six concurrent slots; activate the specialists needed for the current dependencies and reuse completed workers for later tickets. BA must remain independent of the production change it verifies.

The active owner follow-ups are FID-303's natural forward-facing push and FID-304's manual combo links/balance feedback. ME owns the assigned push-pose section after RA's capture handoff; the delegated combo engineer owns the assigned controller/combo/HUD manual work under root integration. The default ownership table below does not override these active section-level assignments. Independent BA/QE must inspect both results.

## Role and ownership contracts

| Specialist | Typical ownership; root must confirm actual assignment | Must coordinate |
| --- | --- | --- |
| Rider artist | `game/player/skater_visual.gd`, anatomy/garments/footwear, new rider assets | Motion state/contacts, renderer/material response |
| Board artist | Assigned native board generator/derivatives, side UVs, layered construction and material/provenance diagnostics | Protected grip/truck/wheel geometry, rider stance, native contact and export gates |
| Rigging engineer | Assigned fitted-seam mapping, native Skin/bone attachment proof and deformation tests | Rider artist's source mesh/generator, motion's actual per-leg shoe contacts |
| Contact rigging engineer | Cached bounds from actual native Skin/inverse binds, arm contact proposals and mesh/bind mutation controls | Rider artist's authenticated geometry/weights, motion's finite-contact authority, independent QE |
| Environment artist | `game/levels/art/*`, `city_art.gd`, assigned materials/shaders, lighting sections | Level topology, shared materials, camera/landing clearances |
| Environment architect | Assigned facade/gallery construction, recessed openings, joinery and original shop displays | Existing native colliders, BoxMesh consumers, batching/occlusion and environment materials |
| Motion engineer | `skater.gd`, `skate_response.gd`, `chase_camera.gd`, native contact/transition/wall helpers and focused checks as assigned | Rider state fields, authenticated native support/clearance and level rails |
| Level designer | `glasgow_square.gd`, `core_terrain.gd`, outdoor topology, new line metadata | Lighting sections/material assignment, motion/rail/gap contracts |
| Rendering engineer | Assigned renderer settings, engine decision, representative cost probes and resource budgets | Environment/rider asset work, native Metal/Mac export, current C02/C07/C10 admission |
| Combo engineer | Assigned manual request/buffer/selection/balance, HUD feedback and affected input drivers | Motion/contact shared-file sections, remapping, score contracts |
| Technical QE | Independent tests/captures/reproduction and defect report | Root freeze, production owners for repairs |
| BA verifier | Acceptance matrix, requirement/evidence audit, cold-read handoff | Owner review boundaries; no production self-certification |
| Studio director | Integration/test runner, shared contracts, Git, STATUS/backlog/resume | All owners |

Paths above describe defaults, not permission to overwrite another live worker. Agree exact shared sections before concurrent edits. Prefer a new narrow module to a contested large file when that improves the design. Do not create worktrees unless explicitly requested; the cloud checkout is already isolated.

## Dispatch template

> Load `<role brief>` and `<skill>`. Own `<explicit paths/sections>` for `<ticket IDs>`. The observable result is `<benchmark clauses>`. Preserve `<interfaces and existing behaviour>`. Reproduce `<known defect>` or audit `<specific view/route>`. Coordinate `<shared boundary>` before editing. Return a short early diagnosis, then source changes, exact commands/counts, source-bound actual captures, licence additions, failed cases and next action. You may not mark your own production change independently accepted. Do not run Git mutations or a competing full suite. Continue substantive authorised refinement; no paid services or unattended jobs.

## Integration and evidence cycle

1. Specialists inspect current main first and write their exact-use-case skill if missing. They map existing implementations/evidence before proposing new creation tasks, then report real defects, approaches and public-interface needs before substantial changes.
2. Root resolves shared contracts, then independent implementation proceeds. Use focused local checks during development. Avoid repeated simultaneous imports/full suites on the shared workspace.
3. At a review checkpoint, root freezes relevant source. Capture baseline/candidate receipts using existing tools, with actual hashes and fixture labels. Prefer selective extension of the existing full-fidelity/native motion pipeline, including its render/pixel synchronization proofs, over a new overlapping harness. Keep source changes out of a claimed stable run.
4. QE independently replays the failed behaviour and neighbouring cases, runs appropriate checks and inspects actual frames/motion. It reports failures even when the full suite passes.
5. Authors repair the defects. QE retests exact reproductions and affected neighbours. The BA verifier audits benchmark clauses against the resulting evidence, including visible deficiencies that automated tests cannot judge.
6. Root updates tickets, current STATUS, the original backlog mapping, active work and resume. Integrate tested changes directly on `main`; inspect/preserve existing remote history and push without force. Report actual local/remote commit outcomes. No hosted CI, release publication or unattended compute is implied by a checkpoint.
7. Continue the next useful authorised ticket. If the session ends, leave the exact in-progress edit, known defect, reproduction and next owner. Several hours of work do not themselves pass the benchmark; an early clean test run does not mean the game is finished.

## Repeatable evidence menu

Use installed tools and inspect their arguments before running; existing scripts may write fixed historical output paths, so preserve prior evidence or assign a new output destination first. Root coordinates render windows and changes to capture infrastructure.

| Purpose | Existing starting point | Acceptance limit |
| --- | --- | --- |
| Import and full regression | `./tools/check.sh` | Counts, nonzero failure status and clean engine/script logs; no visual/hardware claim |
| Ordinary title-to-play, mapped movement and tight cameras | `./tools/playability_capture.sh --private-display` | Actual normal scene; inspect and disclose fixtures/camera conditions; output must identify current source |
| Rider action stills | `./tools/rider_capture.sh` | Read script for output/fixtures; actual frames and worst deformations must be inspected |
| Normal-speed action sequence | `./tools/rider_motion.sh` | Read script for display/options; decode all action cuts and label full-meter/setup fixtures |
| Full existing 78-trick/native contact and route proof | `./tools/full_fidelity_capture.sh --private-display` | Read its substantial workload first; preserve source/fixture/native-pixel/render-synchronization proofs and extend selectively rather than duplicate. Do not relabel this as a target-performance run. |
| Six-area/world views | `./tools/level_design_capture.sh` or visual-pass capture | Read capture definitions; static placements cannot certify line traversal |
| Natural circuit and career events | Existing `tests/career_route_tests.gd`, world/grind/gap suites, new focused line replay | Preserve actual inputs/collision; no per-tick position/speed/heading/event injection |
| Current compact/native density routes | Existing `tests/full_level_density_tests.gd`, `tests/authentic_fidelity_integration_tests.gd` and C04 receipts | Audit two distinct lines per arena and safe bypass; old coordinate/segment counts are not immutable contracts |
| Cold source launch | `python3 tools/source_launch_smoke.py` | Actual copied source/import/title branch, isolated profile and explicit negative case |
| Representative renderer workload | `./tools/profile.sh` | State OS/GPU/renderer/resolution; Linux llvmpipe is a diagnostic, never M5 Air performance |
| Local native package | `./tools/export.sh` with installed official templates | Packaging success does not certify actual Mac launch or controller behaviour |

Do not launch the full long reel by default just to generate activity. Inspect retained current-source evidence, identify missing/changed clauses and capture the necessary subset. Only root schedules the integrated full regression/render run. Personal Music must remain isolated from all CLI/test execution.

Before claiming a visible change, record at least a current actual frame or an exact rendering blocker. Before claiming smooth movement or playable lines, record the relevant moving/actual-input evidence. A PNG save, screenshot count or fixture success is not a quality verdict.

## BA acceptance matrix

For every active ticket and benchmark gate, use this row format:

| Ticket/clause | Expected observable result | Source/evidence | Actual finding | Result | Independent reviewer | Next action |
| --- | --- | --- | --- | --- | --- | --- |
| Example only | A complete grounded rider in ordinary play | Actual current frame/trace path and source identity | State what was inspected | Pass / Fail / Unmeasured | Named role/agent | Exact retest, correction or missing device |

Keep implementation, automated technical checks, visible inspection, human feel/discoverability and actual Mac performance separate. An unavailable reviewer/device leaves that dimension Unmeasured. A passing narrower implementation can coexist with an open overall gate only if the distinction is explicit and separately ticketed.

## Defect triage

Use [quality-verification](../../.agents/skills/quality-verification/SKILL.md) severity definitions and `FID-D###` identifiers. Each defect needs its source, concrete reproduction, expected/actual, frame/trace, affected clause, owner, state and exact retest. Preserve failed diagnostics and link corrected evidence. Do not rewrite a failed criterion, hide a script error, or replace visible support problems with invisible catch geometry to make the count pass.

P0/P1 integration failures block a technically ready candidate. Pending final art, human fun and target-Mac measurements block their own acceptance gates while useful independent work proceeds. This distinction prevents both premature completion and unnecessary permission stops.

## Durable session handoff

Record these facts in current STATUS and the ticket ledger:

- Actual branch, local/remote commit and dirty state; whether merge/push really completed.
- Implemented ticket clauses, changed public contracts, asset sources/licences and included notices.
- Exact focused/full commands, counts, exit codes, logs, inspected images/motion and source receipt.
- Independent QE/BA findings, unresolved defect IDs and the worst remaining visible case.
- Actual hardware/human results or the explicit missing device/scenario; no fabricated M5 RAM/OS/FPS.
- The next unblocked ticket, assigned role/skill, exact source location and first reproduction/edit.

This studio is available to future sessions through repository files. It does not launch autonomous work after the session, purchase services, schedule paid workers or guarantee hardware acceptance that has not occurred.
