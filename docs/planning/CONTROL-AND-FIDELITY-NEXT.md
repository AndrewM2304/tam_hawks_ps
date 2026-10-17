# Control, fidelity and efficiency continuation

17 October 2026. These are concrete work packages inside the existing **75 backlog records**, not extra game areas or a scheduled agent queue. The owner authorizes autonomous work without recurring task approvals, with no purchases, paid generation, APIs or hosted CI. Current-map hardening remains first priority.

**Superseded control first edits:** ADR-015 and [CLASSIC-TRICKS-NEXT](CLASSIC-TRICKS-NEXT.md) now implement tighter turns, release-pop crouch, directional trick poses, visible air spin/stance, latched rails, finite quarter/half-pipe and lip actions. The older review/control proposals below preserve why those changes were chosen; do not restart their completed first edits. The clothed hero, live facade/PBR/LOD integration, vegetation and target-performance work packages remain outstanding and authoritative. The original isolated [facade prototype](../../art_source/glasgow_bay/README.md) now has three audited GLBs and six actual Godot front/detail previews; it remains outside the live map. Continue at one real placement/LOD/material-sharing proof, rather than recreating its generator.

## Review and implemented slice

- [Arcade handling](../research/ARCADE-HANDLING-REVIEW.md): inspected pinned MIT Not Pro Skater and GodotSkate source/licences. Our current full-speed steering settles at 1.1rad/s: about 13.6m radius/27.3m diameter. The inspected reference's default at the same speed is substantially tighter; this is source math, not a played Tony Hawk measurement. Copying its low friction would reintroduce the owner's excessive-coast complaint.
- [Grind forgiveness](../research/GRIND-FORGIVENESS-REVIEW.md): completed-motion capture closes a between-tick miss while preserving the .65m/55°/height/speed/clearance admission gates. Root adds natural-input tests with lateral/heading/timing errors, keyboard remap and synthetic Triangle input. Physical DualSense ergonomics remain open.
- [Render efficiency](../research/RENDER-EFFICIENCY-REVIEW.md): exact sharing reduces world mesh-resource count from 1,419 to 324. Spatial tree candidates reduced some distant triangles but regressed close-park draw calls; they stay opt-in experiments. Frustum culling and 220m far/75m shadows already exist.
- [Rider fidelity](../research/RIDER-FIDELITY-REVIEW.md) and [environment fidelity](../research/ENVIRONMENT-FIDELITY-REVIEW.md): the existing head/hands/scalp already contain 15,888 triangles. UVs, clothing silhouette, animation, shading and too many material submissions are stronger next investments than blanket subdivision. One original four-surface/5,696-triangle GLB board proves the installed Blender export workflow.

The current slice also stops disabled/braked riders on slopes, admits reverse manuals, buffers fresh flip/grab/manual input for 120ms, removes live area-name text and changes default controller grind/revert/restart to Triangle/R2/R3. Full current results belong in STATUS/QE. No exact commercial-game feel, final art or Mac performance acceptance follows from scripted counts.

## Existing M01-002 — tighter controllable street turning

- **Owner / priority:** A04 gameplay + A09 independent QE, P0.
- **Dependencies:** current signed ground/contact response; current natural-input tests.
- **First edit:** construct a supported isolated turning court, measure full/half/quarter stick at 8/12/15m/s and test a moderately tighter ground curve before changing city tuning. Preserve the separate 0.50rad/s airborne travel correction and collision-adjusted momentum.
- **Acceptance:** useful full-speed turns within compact street lines, small analog corrections remain predictable, symmetric left/right behavior, no unexpected speed gain or camera orbit. Reset, disabled controls and hill braking stay stable.
- **Validation:** actual push/steer inputs with recorded turning diameter, path and heading; repeat at 30/60/120Hz; natural default-spawn turns, narrow street recovery and intentional missed lines. Human Mac keyboard and wired/Bluetooth DualSense judge responsiveness. Do not force heading per tick or use the commercial game's name as a tune certification.

## Existing M01-003 / M02-001 / M02-006 — ollie, visible spin and landing contract

- **Owner / priority:** A04 movement + A05 animation + A09, P0.
- **Dependencies:** street-turn baseline and current buffering; existing takeoff/collision fixes.
- **First edit:** prototype hold-to-crouch/release-to-pop in an isolated existing-surface fixture, with explicit short-tap behavior and crouch visual. Specify how travel heading, visible spin, fakie stance and landing alignment interact before altering production input.
- **Acceptance:** one pop per deliberate cycle, forgiving early/late requests, unchanged collision-adjusted outgoing speed, coherent board/body/travel direction and readable landing compression. Preserve an approachable input path for keyboard users. Overtime never starts a fresh trick/link.
- **Validation:** 50–500ms holds, presses just before/after lips and landings, low/high ramp speeds, reverse travel, incomplete flip, 180/360 landing, both spins and simultaneous actions. Re-run all named gaps, career routes and side challenges after deliberate migration of their input fixtures. Record real human mistakes and recovery rather than certifying only a rehearsed route.

## Existing M02-002 / M06-001 — latched grinds and real input margin

- **Owner / priority:** A04 controls + A09, P0.
- **Dependencies:** current swept capture, protected collision/score contracts and Triangle/R2/R3 defaults.
- **First edit:** specify then prototype a fresh grind-press buffer around 120–140ms and tap-to-lock ride semantics. Define explicit drop/ollie/endpoint/balance exits and prevent a held key or trigger from repeatedly recapturing. Current production still requires holding L/Triangle; this larger semantics change is not yet implemented.
- **Acceptance:** a reasonable near miss captures predictably, a wrong floor/behind/blocked rail does not. One admission and one score event; collision cannot restore lost velocity. Bindings never turn an intended grind into restart; old conflicting saved overrides remain readable/recoverable.
- **Validation:** expand the current physical approach matrix across ±0.1/0.25/0.5m offsets, ±5/15/30° approach errors, ±50/100/150ms press timing, low/top speed, 30/60/120Hz, straight/curved/sloped/stacked rails. Keep deliberate out-of-envelope and wall/ceiling cases. Exercise remaps, partial trigger travel, stick drift and real reconnect on Mac. Report misses/bails, not just successful admissions.

## Existing M05-001 / M06-007 — authored clothed skater and animation

- **Owner / priority:** A05 character art + A04 animation + A09, P1; visible movement weight P0.
- **Dependencies:** original board/contact proof and coherent movement state contract.
- **First edit:** author connected clothed topology, proper shoulder/cuff/hem/knee folds and outfit UVs; use one shared 2K outfit PBR set and preserve cosmetic colour hooks. Treat the research budgets as trial allocations: approximately 25–45K triangles for the complete nearby rider, 10–20K mid, 2–5K far; measure actual export vertices/surfaces.
- **Acceptance:** recognizable adult skater silhouette and weight at ordinary chase distance; no neck/cuff gaps, foot skating or hand/board clipping. More polygons must improve visible silhouette/deformation. Keep the 15,888-triangle anatomy budget under review rather than subdividing it blindly.
- **Validation:** real idle/push/brake/ollie/flip/grab/grind/manual/revert/landing/bail states plus fixed close inspection; imported glTF material/rig/LOD audit, source/licence manifest and matched renderer metrics. Physical movement and contact dimensions remain authoritative.

## Existing M05-001 / M06-007 — one detailed foreground Glasgow kit

- **Owner / priority:** A05 environment art + A02 design + A09, P1.
- **Dependencies:** researched current Exchange frontage; no new playable footprint.
- **First edit:** replace one existing foreground facade bay and nearby coping with original bevelled, correctly scaled Blender geometry, shared sandstone/paint/metal 2K PBR trim and explicit near/mid/far LOD. Trial roughly 12–20K/2–5K/300–800 triangles per bay and at most 2–4 opaque surfaces. Preserve skyline/Barrowland/bridge identity at distance.
- **Acceptance:** silhouette, recessed windows, roughness/wear and texture density visibly improve both a close and normal chase view. Keep collision/grind paths and camera clearance unchanged. No precise shop identity is asserted without inspected dated reference evidence.
- **Validation:** retained source/generator, exported GLB and provenance; check normals/UV seams/mipmaps/texture memory, 4–8m LOD hysteresis and reverse approaches. Compare the same rendered route and close view before rolling the kit across the current map.

## Existing M05-001 / M06-004 — park ground and vegetation materials

- **Owner / priority:** A05 materials + A09 performance, P1.
- **Dependencies:** representative PBR pipeline and existing stable grass shader.
- **First edit:** add grass/soil/path contact variation, textured bark and two or three tree silhouettes. Use near-only small clumps initially within 10–15m; retain terrain collision. Verify CC0 asset files and hashes separately from inspected source listings.
- **Acceptance:** credible scale/material response without hiding landings, shimmer, foliage overdraw or frame spikes. A broad green shader plus extra terrain triangles does not close this task.
- **Validation:** park crest, near taper, shadowed path and reverse approach; selected opaque/alpha-scissor method on the real Mac. Keep the measured 48/96m tree batching regressions as comparison evidence, not default optimizations.

## Existing M06-004 — material submissions, LOD and target performance

**Completed first optimization slice:** the 64 m compatible architecture merge, HUD cache, displayed-rider/chase interpolation, saved graphics budgets and actual source-bound after/control/moving measurements are now preserved in PERFORMANCE-HARDENING/STATUS. Do not recreate that implementation or enable rejected native occlusion/tree partitions. Continue from secondary-detail HLOD/material sharing and target-Mac evidence; final performance acceptance stays open.


- **Owner / priority:** A05 rendering + A09 + owner hardware, P0.
- **Dependencies:** current static mesh-sharing baseline and one proof asset.
- **First edit:** audit cross-parent opaque facade batches using actual transformed geometry bounds, material/layer/shadow state and movement ownership. The research found an approximate upper bound of 414 mergeable submissions; this is not an implemented or certified saving. Improve authored modular meshes and shared atlases before global draw-distance cuts.
- **Acceptance:** matched useful view quality with fewer actual submissions and acceptable memory. Preserve gameplay/AI/collisions outside view. Any 160–180m detail profile needs a persistent low-detail landmark/skyline layer and fog; never hide districts solely from rider district ID.
- **Validation:** matched resolution/renderer/views, draw/object/primitive and texture-memory counters, then moving-route median/p95/p99 frame times. The user's Apple M5 Mac is known from the launch log; record actual model/memory/macOS/settings. Run ten minutes at 1920×1080 and assess the 16.67ms/60fps target. Software Linux counters/cross-export cannot certify it.
