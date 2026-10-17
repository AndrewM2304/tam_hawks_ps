# Current-map control and fidelity verification

17 October 2026. This review follows gameplay checkpoint `86d286c512fc3e0a541ececfc970b28401f80f7f` and handoff `315d245`. The previous coasting/contact/camera repairs remain useful. They did not establish Tony Hawk-like control semantics, human rail comfort, final art or Apple Silicon performance. Five completed [research handoffs](../planning/CONTROL-AND-FIDELITY-NEXT.md) inspect pinned MIT implementations, official Godot documentation and current assets, with concrete continuation inside the existing 75 task records.

## Implemented and checked

- Ground slope acceleration precedes deliberate braking; disabled controls retain a horizontal stop. Actual supported 20° fixtures check brake hold, disabled hold, release rollback and reverse manual admission. The last trace records −2.522m/s after 3.955m of rollback, with a valid manual.
- Fresh flip/grab input is consumable for 120ms into eligible airtime. A fresh held manual just before real contact can link after landing; expired requests, failed at-rest input, cooldown, reset, disable and overtime cannot manufacture entries. Requests 0/50/100ms before an ollie succeed once; 150ms expires.
- Grind admission checks the actual completed movement as well as the previous point, preserving reach/angle/height/speed/clearance constraints and actual collision-adjusted velocity. Helper tests cover 30/60/120Hz, offsets to 0.55m, approaches to 45°, 4–17m/s, endpoints, wrong heights and obstructions. Production-body approaches add ±0.22m offset, ±2° heading, early/later presses, synthetic Triangle and a remapped physical P key; a 0.90m miss and press after passing refuse. Initial placement/heading is a fixture; movement has no per-tick heading/pose/speed assistance. These synthetic error cases do not replace real DualSense trials.
- Defaults now use Triangle grind, R2 revert and R3 restart. Existing custom overrides retain normal validation; Reset defaults adopts the current layout. Holding grind still sustains the ride; released-press buffering and tap-to-lock are documented next work.
- Live location text is removed. Career visits still record quietly; physical signs, landmarks and pause/map context remain.
- Exactly equal world PrimitiveMeshes share resources: 1,419→324 unique meshes with unchanged instances/materials/physics. This does not prove VRAM bytes or FPS. Both rendered tree-partition candidates are rejected as defaults after close-park draw-call regressions.
- One original Blender GLB board carries 5,696 triangles across four material surfaces, replacing 25 procedural MeshInstances. Actual feet/grab/flip views are in [fidelity-review](screenshots/fidelity-review/README.md). Clothing, shoes, animation, paving/facade/park materials still need the required final-art work.

## Commands and receipts

`./tools/check.sh` is the required aggregate; its final count and complete log/hash are in STATUS/QE. The focused input/rail/manual modules pass **144/0** in [human-input-focused.log](logs/human-input-focused.log). Those cases are also included in the ordinary suite; do not add counts together.

The [fresh-source launch](source-launch-playability/README.md) passes four phases with **188 stable inputs**, including ordinary cold/warm Main, actual normal-title wrapper **44/0**, and deliberate broken-copy refusal. Only the disposable negative case logs parser errors.

`./tools/playability_capture.sh --private-display` passes **19 frames / 0 failures**, source-stable, from the actual title-to-play branch. [The manifest](screenshots/playability-repair/manifest.json) identifies the new board node and every frame. An initial capture attempt failed because its inspection path still named the replaced procedural deck; updating the tool to the actual imported mesh path fixed that diagnostic. No failed capture was published as current evidence.

`./tools/rider_capture.sh` completes exit 0 with **0 errors, 44 rider MeshInstances and 10 garment bones**. It exercises actual action states, with authored inspection close cameras and explicit full-meter special fixtures; its source guard preserves 129 unchanged inputs. No timing or final-art acceptance follows.

The first broad test attempt exposed a manual-buffer bug: a rejected at-rest press could activate after accelerating while held. The production fix only arms an eligible ground press or an airborne request; the existing fresh/held/cooldown tests remain intact. The focused pass and final aggregate were run after that fix.

## Open acceptance and next edit

Use CONTROL-AND-FIDELITY-NEXT: measure tighter fast turns first, then implement coherent hold/release crouch, visible stick spin/stance-aware landing and buffered tap-to-lock grinds. Preserve actual takeoff, combo deadlines, scoring, world support and current goals while migrating controls. Build one clothed skater and one existing Glasgow facade/PBR/LOD proof, with actual material submissions and near/mid/far views before broad conversion. Blender MCP is optional; installed free Blender already produces reproducible GLB assets without a new service.

Linux headless/software rendering does not certify Mac GPU shaders, physical input ergonomics, human fun, exports, listening or a ten-minute moving-route 60fps target. Keep those gates open. No new area, paid service, API, purchase or hosted CI was added.
