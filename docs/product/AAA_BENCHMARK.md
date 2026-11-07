# Fidelity and skating benchmark

Owner direction: 6 November 2026. **Target: a believable, detailed skating game that runs on the owner's MacBook Air M5. Acceptance: open.** The owner prioritises realism, continuous character forms, good textures, smooth movement and compact, connected trick lines, and authorises an engine rewrite if needed. This specification raises the earlier art direction's quality target; it does not claim the current alpha meets it.

“AAA” is the ambition, not a status awarded for completing tickets or running tests. The reference standard is the presentation and coherence of a polished commercial skating game, judged during ordinary play. No borrowed franchise assets, copied level layouts, paid services or unverified performance claims are part of the approach. The product name remains **Tam Hawks Pro Skater**.

The November work starts from main `0b62035`, which includes the `40a6615` steering/wallride gameplay repair and its historical 5,888/0 plus CLI Music-isolation 2/0 receipt. The much older October 17 alpha is not the active baseline. Native contact, 78-trick repertoire, compact-map, station/train, pond/ducks/cable and civic/green work already exist. Audit and refine them; do not recreate completed features. Keep merged trial content enabled in ordinary Main and preserve personal Apple Music isolation. Existing rejected facade/ornament timing cells remain rejected; completed diagnostic investigations do not become new implementation tasks without new evidence.

## Acceptance rule

Every gate below must have its own result: **Pass, Fail, or Unmeasured**. A release candidate has no open P0/P1 defects, passes the automated regression, has source-bound visual and motion evidence, and passes owner/hardware review. A specialist cannot supply independent acceptance for their own implementation. Linux software rendering can establish visible output and specific defects; it cannot certify the MacBook Air M5 or the owner's skating enjoyment.

The numeric limits below are **production targets to measure**, not results, engine limits or assertions about an untested machine. Where a target proves inappropriate, record the observed case and justify a revised target before accepting it. Lowering a criterion to close a failed ticket is prohibited.

## V1 — Human rider and board

| Requirement | Inspection and target |
| --- | --- |
| Continuous believable forms | At normal chase distance and a two-metre close view, the head, neck, shoulders, elbows, hands, hips, knees and ankles have anatomically credible silhouettes. No visible cuboid limbs, primitive joint balls, separated sleeves, open seams, inverted surfaces or visibly faceted face. Hidden simple collision is appropriate. |
| Adult scale and proportions | One consistent adult rider scale, measured against the approximately metre-based world. Document height, board dimensions and limb proportions. Neck/shoulder/hip widths and face placement must hold in front, side, rear and three-quarter views. |
| Character surfaces | Clothing reads as cloth through its shape, seams, folds, thickness and restrained material response. Skin, hair, soles, grip tape, deck wood, trucks and wheels have distinct believable responses. Detail must survive the ordinary camera rather than exist only in an asset preview. |
| Deformation | Crouch, deepest landing, push extension, grab and both specials show no collapsed crotch, broken elbow/knee, detached wrists or visible clothing/body penetration. Deformation is reviewed in motion and in the frame at the worst bend. |
| Board construction | Deck profile, trucks, wheels, grip, feet placement and board scale are coherent. No wheel visibly detaches, rotates around the wrong axle, penetrates the ordinary skating surface or hovers in an unsupported idle pose. |
| Grounding | In supported coast and ordinary grounded trick poses, planted shoe soles target at most 20 mm separation from their intended deck plane. Report maximum and 95th-percentile error where instrumented. Deliberate push/flip/bail separation is labelled and judged against the action. |

V1 passes only after reviewed front/side/rear close views, the normal spawn view and the complete V3 action reel. Improving a mesh does not close animation or hardware gates.

## V2 — City materials, light and detail

| Requirement | Inspection and target |
| --- | --- |
| Readable physical materials | Paving, concrete, sandstone, brick, asphalt, slate, painted steel, glass, grass and water have coherent scale and response under the same lighting. Large route-facing surfaces cannot remain featureless flat colours. Normal and roughness detail support the material rather than produce noisy sparkle. |
| Texture scale and resolution | Document metres per repeat and actual source resolution. Route-facing hero surfaces target about 256–512 source texels per metre at their intended close view, with sensible mipmaps and filtering. Upsampling does not count as added detail. Match adjoining modules within about 10% apparent scale unless construction calls for a difference. |
| Stable surface detail | No stretched UVs at banks, giant visible pixels on the normal path, shimmering grass, moiré, unintended normal-map inversion, z-fighting, detached decals or obvious discontinuities at pavement joins. Inspect both stationary and moving frames. |
| Architecture | Windows/doors have plausible scale, recess and thickness; roofs and cornices meet; no floating trims or regular blockout rows dominate an ordinary route. District silhouettes and credible close-up details identify the place without copied map layouts. |
| Light and contact | One coherent daylight treatment; wheels, rails and building bases read as grounded. Bright stone retains detail and shaded landings remain readable. No artificial bloom, excessive saturation or crushed blacks conceal missing detail. |
| Composition | At least one intentional foreground/middle/background composition on each primary line. Visible boundaries frame returns or destinations. Open space has a skating or visual purpose; clutter cannot replace deliberate composition. |

Review all six areas and connecting streets in the ordinary chase view, plus close material/facade views and a matched bright/shaded pair. Static beauty shots alone do not pass V2.

## V3 — Animation, physics and camera coherence

The action reel must show idle, coast, push, brake, crouch, ollie, spin, flip, grab, rail entry/travel/exit, manual, revert, both specials, clean landing, bail and recovery. Add left/right carving, uphill/downhill, rollback, bank takeoff, support loss and a wall-adjacent camera turn. Record accepted input, actual state transitions and whether any setup fixture is used.

- Input must affect eligible gameplay on the existing physics tick; animation never adds a gameplay waiting period. The rider anticipates, extends and compresses in a way that agrees with actual takeoff/landing events.
- Ordinary state transitions must have no single-frame pose pops, unexplained body rotation or camera cuts. Instrument discontinuities and distinguish the physical event from cosmetic smoothing. A camera may resolve collision promptly, but must not oscillate or cut through scenery.
- The board and shoes agree in grounded poses; push-foot ground contact follows the support height. Grabs meet the deck within 50 mm at full extension. These are measurable targets; no “smooth” status is awarded from source inspection.
- Wheel/ground response, skater lean and landing compression must support the movement. Do not disguise physics defects by sliding an independent visible model over them.
- The owner-requested push stroke faces and follows actual travel: shoulders/hips open naturally, the supporting foot stays on the deck, the pushing leg extends behind travel and visibly lifts into recovery. Forward/reverse and carving strokes must avoid a side-sweeping leg, lateral foot skid or abrupt torso snap. Review the cycle in normal-speed chase/front/side views, not just a contact marker or static pose.
- At the normal chase view the complete rider, board and immediate landing remain visible through a 30-second natural-input wall/undercroft/turn sequence. A deliberately excluded close-up camera is labelled.
- Restart, pause, slow speed, reverse travel and repeat inputs must not leave stale trick poses or timers. Reduced motion preserves legibility while removing nonessential camera motion.

Visual transitions and physical regression are separate gates. Preserve validated takeoff momentum, grinding, combo deadlines, career IDs and save behaviour unless a documented design change and fresh evidence justify revising them.

### Manual links and balance feedback

After the fidelity candidate, explicitly review manual continuity using real air→manual→air and air→manual→ground-bank inputs. Document admitted early/late requests, held/gesture semantics, release and cancellation; observe actual support/link/landing/bank events. No per-tick manual/balance/score/velocity assignment can create the claimed link. Unsupported, expired, low-speed and stale requests must fail deliberately; valid admission must not lose a combo through event-ordering or premature banking.

Balance feedback reads the authoritative state and shows its actual correction axis and direction. Ordinary and nose manuals must actually correct fore/aft with W/S or Up/Down and map nose/tail/stance correctly; relabelling an unchanged lateral control does not meet the owner's request. Grinds use lateral correction/display, and special balance variants follow their modelled support/axis with documented controls. Neutral/risk/bail endpoints and both correction signs must map correctly with current remaps/device prompts. Do not correct balance and unintentionally carve or accelerate with the same control. Keep the moving rider/landing clear, use non-colour risk cues, and clear stale meters at mode exit/restart. UI fixture checks supplement actual-input moving play; they cannot replace it.

## L1 — Compact, connected skating lines

Research Tony Hawk levels as examples of spatial and mechanical principles. Record inspected sources and distinguish direct observation from design inference. Implement original Glasgow arrangements; do not recreate a franchise map.

| Requirement | Route evidence and target |
| --- | --- |
| Useful density | Audit travel time between meaningful trick opportunities, rather than counting decorative props. On authored primary lines at an 8 m/s reference speed, target an opportunity at least every 3 seconds and avoid an unpurposed flat stretch longer than 24 m. Measure actual natural-input traversal separately from the reference calculation. |
| Connected set pieces | Preserve the existing density requirement: each retained core arena has at least two genuinely distinct original returnable lines and a safe bypass. Each line connects a launch, a rail/ledge/manual choice, a landing and a turnaround/re-entry. Reversing the same perimeter is not a second line. Across the six-area world, at least three independently demonstrated circuits must also connect arenas with useful next choices. A prop that cannot be approached and exited at useful speed is not a completed set piece. |
| Enclosure and reversibility | Architectural edges, banks, courts and end pieces should return the rider toward another opportunity rather than leave them facing an empty boundary. Primary decision points target spacing within roughly 35 m, subject to the specific line's speed and view. |
| Landing and approach | Mark approach, takeoff, trick, landing and runout volumes. Ordinary intended landings target at least 3 m clear width. Preserve wider clearance where speed/camera/alternate approaches require it. Scenery and collision match; no invisible obstacle occupies the line. |
| Discoverability | From each primary decision point, a useful next feature or destination is visible or deliberately revealed by a short turn. At least one easier bypass accompanies a technical route. Interesting geometry, material wear and lighting guide the line without compulsory floating arrows. |
| Supported world | Inspect route centres, both shoulders and deliberate misses. No visible dry ground hole, arbitrary invisible catch slab or abrupt false wall may substitute for authored support and understandable boundaries. River hazards retain deliberate recovery. |
| Existing game | All ten goals, three core encounters, existing enabled station/train, pond/ducks/cable, park/civic/green content, stable gap/rail IDs, saved progression and district connections remain usable. Preserve personal Music isolation and other implemented content. Further development of traffic/skitch, Cone on a Cruise and the extra park-lap challenge remains deferred under the existing queue. New line density cannot obstruct physical approaches or hide required interaction prompts. |

Layout compression starts with the current shared resources: target zero new texture bytes and zero unique shader/material resources for topology work, with non-increasing mesh/collision totals unless a measured exception is documented. Art upgrades have their own explicit resource budget and matched cost admission. Never optimise a density proxy by scattering decorative curbs, cutting useful recovery flat or weakening native support.

The primary-line report contains start/end positions, ordered features, direction, input method, simulated time, distance, largest opportunity interval, actual jump/grind/manual/landing events, bails/stalls, and a source-bound clip or image sequence. Structural route metadata alone does not prove a playable line. Human discoverability and replay appeal remain explicitly reviewed outcomes.

## Q1 — Evidence and defects

1. Capture before and after from matched position, camera, renderer, resolution and lighting whenever the comparison is meaningful. Preserve failed diagnostic frames.
2. Freeze the changed source while capturing. Record Git SHA, dirty status, hashes of relevant source/assets, Godot version, render backend, GPU/driver, OS, resolution, settings, command, output, timestamp and manifest hash. A commit label alone is insufficient if source was dirty.
3. Keep fixture-only closeups separate from ordinary title-to-play and mapped-input playback. Label teleports, full-meter setup, camera overrides and slowed playback. Do not present a fixture as a completed physical run.
4. Run `./tools/check.sh` for GDScript changes after integration. Count and nonzero failure status must be retained. Focused tests, full regression, visual review, hardware performance and human acceptance receive separate results. Extend the existing native full-fidelity capture/receipt pipeline instead of creating a weaker replacement; its 78-trick catalogue, actual contacts, fixture disclosure and render/pixel synchronization proofs remain valuable.
5. Log defects with reproduction, expected/actual behaviour, evidence, severity, owner, affected ticket and retest. A count of passing assertions cannot cancel a visible failed frame.
6. Independent BA review maps every acceptance clause to an evidence item or an open gap. QE verifies technical behaviour. Owner review judges visual finish, feel, discoverability and fun. Evidence remains honest when one of those reviews is unavailable.
7. Before adding render cost, declare baseline and proposed draw, geometry, texture/buffer memory and frame-time budgets. Compare frozen, matched, uncontended original/candidate/control workloads, including p50/p95/p99 and long frames. Retain current culling, skyline and offscreen gameplay. Reject a failed cost cell; fewer triangles/draws alone do not prove smoother play. Existing rejected results cannot be relabelled as a pass.

## H1 — MacBook Air M5 delivery

The owner's MacBook Air M5 is the target. RAM, OS version, display mode and sustained performance are **unmeasured until recorded from that machine**. No Linux result establishes a target-Mac pass.

- The intended target is 1920×1080 at 60 fps during a representative ten-minute moving circuit through all six areas, including tricks, rail contacts, crowded views and menus. Record warm-up separately, average, median, p95/p99 frame times, worst stalls, memory and thermal/power conditions where observable.
- Production targets are p95 frame time at or below 16.7 ms, p99 at or below 22 ms, and no steady-play stall above 100 ms. State the observed frame pacing and visual preset; do not turn an export or an average alone into a 60 fps claim.
- Verify cold source launch or the delivered native package, offline play, save/relaunch, keyboard and intended DualSense navigation, reconnect, pause/restart and reduced-motion settings on the actual Mac.
- An engine or renderer change is permitted when evidence identifies a material blocker or benefit. Compare a representative rider, material/light scene and full playable route with Mac export/portability implications, measured workload and remaining migration cost. A rewrite is not completion unless the gameplay and delivery gates return to parity or better.

This benchmark is closed only when each gate has current evidence and its named reviewer has recorded a result. Until then, report the specific delivered improvements and remaining defects rather than “AAA achieved.”
