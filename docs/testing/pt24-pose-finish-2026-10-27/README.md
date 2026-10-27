# Rider continuity, menu Back and fountain finish — 27 October 2026

The owner asked to push all work to main and continue. Main and origin were
confirmed identical at `b257b5682bdd40310660cc4be8b40ba20717ee7f`; the push reported
everything up to date. This batch continues the accepted tickets directly on
main, with disjoint implementation agents and independent QE. Normal trial
content remains enabled and scripted fixtures isolate personal Music and saves.

| Slice | Owner / priority / milestone | Defect and bounded acceptance |
| --- | --- | --- |
| C03 / PT24-28 Pogo attachment | Rider agent + QE · P0 · M02/M05 | The existing Pogo hand-reach loop moves torso without pelvis during entry. Check actual deformed clothes, joints, palms/soles, both rest stances, mapped manual entry/release and bail/restart. Preserve the earlier grab repair. |
| C03 wall-to-Ollie continuity | Wall agent + QE · P1 · M02/M05 | A real native wall stop followed by mapped Ollie drops the ordinary connected offset, putting deck/shoes through the wall. Verify actual vertices and unchanged native-twin physics through fresh crouch, air and landing, with finite obstruction and exclusion controls. |
| C09 menu Back | UI agent + QE · P1 · M06 | The native menu map lacks gamepad accept/cancel bindings, and Circle/B never reaches the existing modal Back path. Verify parsed pad navigation/activation, nested pause origins, title/results protection, binding capture and no actual Grab leaking into resumed play. Physical hardware remains separate. |
| C07 / PT24-26 fountain finish | Finish agent + QE · P1 · M05/M06 | The fitted water still uses generic metallic glass. Reuse the existing opaque, filtered water material; preserve all geometry/coping/recovery and compare matched native views and resource costs. |

Dependencies are the existing rig/contact, UI navigation/input, authored fountain
and shared water contracts. There is no new route, obstacle, asset download,
paid service or feature gate. Existing independently declared wall-span probes
already cover required closure, actual displayed faces and protected openings;
this batch does not add arbitrary walls or repeat unchanged boundary surveys.

## Focused and native evidence

- [Pogo](pogo/README.md): **189/0**, including19 new cloth/contact/controller
  assertions and170 unchanged AuthenticPose checks. The old13/6 and rejected
  marker-continuity185/4 candidates are retained; thresholds remain unchanged.
  Four native frames compare both deck stances at identical entry moments.
- [Wall-to-Ollie](wall/README.md): **33/0**, including20 ordinary and13 new
  transition assertions. Actual held and quick-tap input retains8mm clearance
  with unchanged native-twin physics/local pose. Finite release/refusal and
  shared query restoration pass. Four matched native frames are retained.
- [Controller menus](ui/README.md): **31/0**, covering parsed pad focus,
  activation, Back origins, sliders, capture and actual gameplay. Exact old
  HUD23/8 and no-action-release29/2 controls preserve the causal failures.
- [Fountain](fountain/README.md): **19/0** native observer, including7 new
  basin/contact/material assertions; six A/B/A frames and360 raw timing samples.
  Every paired draw/primitive/memory counter agrees and both views pass existing
  independent timing caps. These software-rendered samples all exceed50ms;
  they are not a60fps or Mac performance result.

The14 PNGs are completed native render readbacks. Pogo uses labelled static rig
sequences; wall uses actual native input and matched controllers; fountain uses
labelled world cameras and paused simulation. Their exact sources, raw receipts
and retained failures remain separate; an intermediate snapshot is never
relabelled final combined evidence. [Independent QE](qe.md) reviews the bounds.

The Pogo fix adds no state/resource/query. The wall extension retains one shared
convex shape/RID previously discarded after support-face extraction; resident
bytes are unmeasured. It adds at most six finite shape checks only while carrying
an existing fit through a plain flat Ollie. Ordinary clear skating adds none.
Fountain reuses one existing material with no resource/geometry additions;
controller setup adds only idempotent native action bindings and modal routing.
Physics, scoring, save/goal IDs, personal Music isolation and default features
remain intact.

The older same-update Grab request buffer may briefly remain after Back, although
actual modern Grab/pending state and scoring stay clear. Its launch-family
compatibility use remains a documented limit, rather than a false claim that
all input edges are erased. Other active tricks at walls, Mac execution,
physical controls, personal Music, moving shadows, target stutter and final
art/human acceptance remain open. Earlier connection/body/wall receipts certify
their own sources; no blanket PT24 or historical backlog closure is claimed.

## Final integrated admission

**5,220 passed /0 failed**, plus the actual short-script Music guard **2/0**.
Exit0, clean log, **627 unchanged inputs**,535.756s. The exact
[receipt/maps/logs](validation/combined/receipt.json) and lossless line traces in
[MANIFEST.json](validation/combined/MANIFEST.json) bind this final combined source.

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-pose-finish-admitted ./tools/check.sh
```

Manifest SHA256:
`39fb10e90d3cfe2f131fc732c6b2fbde35c86d634df1bc54391cabadd0ad859f`.
The receipt's Git head is development parent`b257b56`; it is not a claim that the
parent already included these repairs. The checked bytes are committed at`8d16c39a3850` for packaging.
The new assertions execute inside the full run; ordinary-Main
connected routes, previous body/wall contacts, Music isolation and the original
boundary protections remain passing.

Four [cold-source phases](cold/SOURCE-LAUNCH.json) pass with533 unchanged inputs:
cold/warm startup, normal no-script title→play50/0, and deliberate invalid-copy
source refusal. The copied source is restored; no live source/profile is changed.
Current unsigned Linux/universal-Mac packages export from clean source
`8d16c39a3850`; [archive audit and normal Linux standalone startup](packages/README.md)
pass. Actual Mac execution, target frame times and human acceptance remain
separate. All source and retained evidence are pushed to main; no unattended
continuation is scheduled.
