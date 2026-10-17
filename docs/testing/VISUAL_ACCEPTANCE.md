# Visual cleanup and acceptance — Tam Hawks Pro Skater

**Recorded:** 17 October 2026. **Status:** planned acceptance procedure. Historical screenshots establish the M01 blockout baseline; current captures show an initial architectural/rider/UI pass, without certifying the owner's requested final graphical quality. Follow [ART_DIRECTION.md](../product/ART_DIRECTION.md) and the tracked M05/M06 tasks. **M06-007** owns the required final graphics/UI cleanup gate.

## Entry gates and evidence discipline

The owner authorizes implementation and cleanup to proceed without recurring approvals while M02-008 feel and M03 traversal acceptance remain open. Preserve tested movement and collision, record subsequent gameplay changes, and retain human acceptance as a release gate. The initial art pass is implemented; it does not substitute for those acceptance results.

Each evidence set must identify commit, Godot version, platform/GPU, renderer, window/render resolution, quality settings, camera transform, route/pose and lighting state. Save capture instructions alongside the results so the next session can repeat them. Evidence must be real rendered gameplay or UI. Concept images and editor-only views cannot establish playable quality.

`./tools/capture.sh` now exercises ordinary play, air tricks, rail capture, manual balance, goals, pause, title, results, settings at both scales, controls and authored district viewpoints. Capture results and exact image paths are recorded in STATUS/QE-REPORT. The 1280×800 software-rendered frames establish visibility, while 1080p target hardware and normal-speed animation review remain open. Preserve historical captures with their original build identity; the title-corrected baseline is retained at `ad31a56`, and the first rail baseline is the commit introducing `docs/testing/GRINDING.md`.

## Required placeholder inventory

The cleanup owner creates a checklist of actual scene/resource paths and marks each item **planned**, **replaced**, **verified**, or **blocked**, with task ID and evidence. Do not close an item merely because a replacement file exists.

| Category | Current baseline / area to inspect | Production completion evidence |
|---|---|---|
| Skater and board | Primitive rider/body/board construction | Rigged, proportioned model; credible board detail; every action and transition inspected |
| Buildings and shopfronts | Cuboid shells, repeated windows, flat-colour shop strips | Detailed modular facades, researched street-edge character, material scale and close-view finish |
| Ground and obstacles | Simple paving, ramps, ledges, rails and boundaries | Credible surfaces and edges; grindable features remain legible; accepted collision preserved |
| Landmarks and props | Statue, rooflines, street details and distant silhouettes | Deliberate district identity; intentional mesh/material finish at normal camera distances |
| Lighting and materials | Prototype exposure and shared flat rough materials | Coherent daylight, readable shadows, grounded objects and controlled highlights |
| HUD and all menus | Prototype theme, labels, panels, prompts and transitions | Complete common theme, typography, spacing, accessible focus, device prompts and motion |
| Feedback and effects | Trick poses, banking, bail, records and captions | Consistent visual cues, clear action timing and comfortable repeated play |

Hidden collision primitives and intentional simple geometry do not require cosmetic replacement. Every visible exception must be recorded with its reason and owner disposition; remaining prototype-looking foreground buildings, rider or UI block visual acceptance.

## Matched world and action captures

For each before/after pair, keep resolution, camera framing, route/pose and scene state comparable. Include an unaltered screenshot plus notes; avoid grading or editing the evidence image. Record a short normal-speed route video when motion is the behavior under review. If video capture is unavailable, record the blocker and retain a human playtest log plus pose captures.

| Capture ID | View or route | Inspect |
|---|---|---|
| V01 | Spawn `(0, 0.8, 12)` facing `-Z`, normal chase view | Title/HUD hierarchy, rider scale, central composition, facade quality and safe first approach |
| V02 | Central launch: spawn toward `-Z`, ramp Z=-4 to -12, landing through Z=-28 | Approach readability, airborne silhouette, board contact, exposure and landing visibility |
| V03 | Tenement return: X=-17, Z=-23 toward `+Z`, ramp Z=-14.5 to -7.5 | Shopfront close pass, textured facade detail, rail/ledge contrast, camera clearance and skating snags |
| V04 | Full four-district loop, once each direction where supported | District identity, border continuity, material transitions, skyline seams, popping and occlusion |
| V05 | One fixed close shopfront view and one street-width view in each district | Researched frontage arrangement, bay proportions, entrance depth, texture density and repeated modules |
| V06 | M02 reference combo: air → grind → release → revert/manual → bank, plus a deliberate bail | State transitions, grind/manual balance, feet/board alignment, trick history, banking and recovery cues |
| V07 | A bright and a shaded landing zone with captions and a long combo visible | Text contrast, obstacle readability, highlight/shadow range and HUD overlap |

V01–V03 use the current square's documented coordinates; update their manifest when the accepted level moves. The four districts and combo mechanics now exist; V04–V07 still need the prescribed continuous-route and matched lighting review. At implementation, assign saved transforms and deterministic actions/timings where practical, rather than silently skipping missing routes. The fixed shopfront views must link to the corresponding dated location reference and explain intentional adaptations.

## Screen and interaction coverage

Capture title/main menu, mode selection, ordinary HUD, a long active combo, goals, pause, settings, remapping, results with a record, and relevant empty/error/disconnected states when implemented. Use the corrected title **Tam Hawks Pro Skater** throughout. Exercise the following with keyboard and a real DualSense:

- Traverse every screen without a mouse, change a setting, close/reopen it and confirm sensible focus return. Confirm prompts agree with the actual mapping.
- Inspect 1920×1080 at default and increased UI scale, then the existing 1280×800 window as a secondary layout check. Log clipping, overlap, awkward wrapping, alignment and loss of safe margins.
- Fill the HUD with long trick names, a large score, active balance feedback, a goal update and captions. Inspect both bright and shaded world backgrounds. Record measured contrast values for the final text/panel colours, then inspect the rendered result.
- Play repeated banks, bails, pauses and fast restarts. Verify transitions never hold up the next eligible input or hide the landing line. Repeat with reduced motion, reduced shake and muted audio; key gameplay state must remain understandable.
- Review text and icon consistency: casing, number formatting, labels, spacing, title, disabled/focused states and saved versus transient progress. No debug/placeholder strings or missing resources remain on reachable player screens.

Synthetic inputs can supplement coverage; they do not certify physical-controller comfort or navigation. Log accessibility defects alongside ordinary visual defects.

## Gameplay, provenance and performance regression

1. Run `./tools/check.sh` after integrating production scene/script changes. Record actual assertion counts and failures from that build; do not copy an earlier passing total. Preserve accepted movement, collision, combo and restart behavior.
2. Replay the central launch, return loop and M02 reference combo on the art-integrated build. Inspect camera clearance, new snagging surfaces, readable landing areas, animation latency and visual/physical board alignment.
3. Audit every introduced model, texture, font, icon, animation and shader against `docs/licences/REGISTER.md`. Verify actual included files, notices and permitted modification/redistribution. Record original procedural sources too. Reference photographs, map tiles and Street View imagery are not production assets by default.
4. Measure the representative polished scene early, then M06-004's ten-minute full-district route on the declared Apple Silicon Mac at 1920×1080. Record model, OS, power mode, build, renderer/settings, frame-time distribution and visible stutters. The target remains 60 fps / 16.67 ms; investigate sustained misses and worst-case views. Linux software rendering is visual evidence only.
5. Compare visual quality and frame cost before/after each substantive optimization. Retest routes affected by collision, culling, batching or LOD. Keep the agreed visual target while resolving the measured bottleneck.

## Required review record and exit gate

Create a review entry linked from `docs/STATUS.md` containing:

- Task and build identifiers; inventory completion and any explicit exceptions.
- Before/after capture paths and repeatable routes/screens, with remaining evidence blockers.
- Actual regression results, provenance review and measured hardware performance status.
- Defects with severity, reproduction, assigned owner and retest evidence.
- Owner response to the playable presentation: does Glasgow feel recognisable, are the visuals convincing and fun, is the UI polished and easy to use, and does the finish preserve skating readability?

The representative scene may be reviewed before the full-world pass, with its narrower scope stated. Final cleanup closes only after the complete visible placeholder inventory is resolved, A09 verifies the evidence, required hardware/performance gates pass and the owner accepts the final playable visuals. A pending owner review or unavailable target hardware remains explicitly open in the handoff. Gameplay acceptance alone does not close the art/UI gate.
