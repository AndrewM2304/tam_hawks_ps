---
name: quality-verification
description: Independently verify this skating game's fidelity and line-design tickets through evidence mapping, actual rendered/moving review, meaningful physics checks, defect triage and separate Mac/human acceptance gates.
---

# Quality verification

Use when independently reviewing a fidelity, animation, level-flow, portability or production-process ticket. Choose **QE mode** for technical reproduction and **BA mode** for requirements/outcome acceptance. The verifier must not be the production-change author. The same independent reviewer may perform both modes if the reports separate their results.

## Inputs

Read `AGENTS.md`, current STATUS, the exact ticket in `docs/planning/FIDELITY_TICKETS.md`, `docs/product/AAA_BENCHMARK.md`, changed public interfaces and the candidate source identity. Inspect actual code/evidence; do not infer success from the implementation owner's prose.

Start from current main/PT24 evidence, not the October 17 alpha. Existing native wall/transition/contact and full 78-trick motion/route tools are the baseline. Preserve default-enabled station/train, pond/cable, civic/green and personal Music isolation. Do not reopen rejected rendering-cost cells or completed diagnostics as if no investigation occurred.

## QE mode

1. Identify a concrete defect or criterion and its reproducible setup. Keep initial fixture placement distinct from actual movement; use production input/collisions for physical route claims.
2. Run appropriate focused checks and the coordinated full suite. Record exact command, result count, exit code, source hashes and warnings/errors. Report a failing production behaviour rather than weakening tests or silently changing physics to satisfy a fixture.
3. Capture ordinary title-to-play, moving routes and worst-case diagnostics using available tools. Prefer selective extension of `tools/full_fidelity_capture.sh` and its native timing/pixel/source proofs over a new overlapping harness. Record renderer, OS, resolution, driver, settings, timestamps and every fixture/override. Verify source did not change during capture. Preserve failed frames. Keep personal Music isolated from CLI/tests.
4. Inspect real frames and a normal-speed action sequence: forms/deformation, foot/board contacts, texture scale, aliasing, support seams, camera collisions, approach/runout and route recovery. A clean log is necessary but insufficient.
5. Reproduce defects, assign severity/owner, and request the smallest suitable correction through root. Retest the exact failed case plus affected neighbours after a fix.

## BA mode

Create one row per acceptance clause with: ticket/clause ID, observable expected outcome, source/evidence path, actual finding, result (`Pass`, `Fail`, `Unmeasured`), reviewer and next action. Check the owner request is covered, including no blocky riders, good surfaces, continuous movement, dense connected original lines, reusable skills and main integration.

Distinguish five dimensions: implementation, automated verification, visible review, human feel/discoverability, and MacBook Air M5 delivery/performance. No dimension inherits a pass from another. A ticket with a required unmeasured clause remains open. A narrower completed milestone can be Done only when the broader gap has its own active ticket and no misleading completion claim.

Check asset provenance, scope changes, source freshness, fixture disclosure and actual branch/ref outcomes. Do not claim precise hardware, visual quality or playability that was not inspected. Keep subjective finish and physical-controller findings for the actual reviewer/device.

## Severity and report

- **P0:** source will not launch; crash/data loss; missing rider/support; broken mandatory goal/run; lost input; systematic unusable camera; unlicensed shipped asset.
- **P1:** visible blockout or major deformation at ordinary view; frequent clipping/pops; unreliable line/gap; large dead corridor; target-performance failure; an unfulfilled required benchmark gate.
- **P2:** local visible seam, minor material inconsistency, isolated camera/transition defect with a usable route, noncritical readability issue.
- **P3:** optional polish or a hypothesis needing reproduction.

Severity describes impact, not how quickly a fix can be written. Include reproduction, source, expected/actual, evidence, affected criteria, owner and retest result. End with a clear bounded verdict, open gaps and next ticket. Never award “AAA achieved” from aggregate tests, elapsed time or a handful of curated screenshots.
