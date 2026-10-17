# Classic trick controls, animation and transition loops

17 October 2026. Owner-requested research for the trick/quarter-pipe slice following `a2daebca397cd82313d94e034ea6fe5056f2ac0a`. This document proposes a control and animation contract; implementation, current acceptance and exact test results belong in STATUS/QE. The researcher changed no production code, downloaded no game executable/assets and launched no commercial game. Public manuals were read for factual control descriptions; compatible source was inspected separately. No paid service was used.

Read with [ARCADE-HANDLING-REVIEW](ARCADE-HANDLING-REVIEW.md), [TRANSITION-SKATING](TRANSITION-SKATING.md), [GRIND-FORGIVENESS-REVIEW](GRIND-FORGIVENESS-REVIEW.md), [runtime interfaces](../architecture/interfaces.md) and [continuation tasks](../planning/CONTROL-AND-FIDELITY-NEXT.md). Nollie/switch setup complexity is outside the owner's current request.

## What the classic manuals actually establish

The archived **Tony Hawk's Pro Skater 4 PlayStation 2 instruction booklet**, printed pages **4–7** / PDF pages **6–9**, was read as OCR and visually checked at the actual page images. The archived **THPS3 PS2 booklet** was also read as OCR around Gameplay Controls, Trick Controls, Grind Controls and Lip Tricks. These primary references establish the input grammar below; neither specifies physical yaw rates, camera distance, FOV or physics implementation.

| Mechanic | Inspected manual evidence | Useful behavior for Tam Hawks |
|---|---|---|
| Ollie/crouch | THPS4 p4: hold Cross to crouch, release to jump; crouching increases skating speed. THPS3 explicitly describes a longer crouch producing a higher ollie. | Visible compression while held; exactly one release pop with bounded charge. Keep explicit push input and finite top speed rather than introducing the excessive unattended acceleration the owner previously rejected. |
| Flips | THPS4 p4: airborne Square plus direction selects a flip. THPS3 gives Left + Square = Kickflip as an example. | Direction selects a finite, recognisable board animation. Fresh presses, completion/recovery and landing eligibility matter; changing the text alone is insufficient. |
| Grabs | THPS4 p4: airborne Circle plus direction selects a grab; hold Circle to sustain it and gain duration score. THPS3 gives Left + Circle = Melon. | Different hand contacts and board/leg silhouettes; hold sustains, release visibly recovers. A held button must not repeatedly create new trick entries. |
| Manuals | THPS4 p5, verified arrows: quick Up→Down = Manual, Down→Up = Nose Manual. Up/Down balances. THPS3 permits the sequence while skating **or landing**. | Opposite-truck lift and opposite body counterweight; early landing request with a finite expiry. Retain an accessible dedicated mapped Manual button as well. |
| Lip tricks | THPS4 p5: approach straight up a quarter-pipe, Triangle plus direction at the top; Left/Right balances. THPS3 explicitly says lip tricks differ by skater and are editable. | A stationary coping state, admitted from the matching curved transition and near the apex, with distinct balanced poses and a deliberate drop/pop back into that ramp. |
| Grinds | THPS4 p4: Triangle near a rail; neutral parallel 50-50, Up Nosegrind, Down 5-0; perpendicular board produces a slide. | Reuse the existing swept/clearance-aware admission. Select pose separately from capture, and distinguish travelling along coping from a perpendicular lip stall. |
| Air spins | THPS4 p7: L1/R1 spins faster; optional 180-spin-taps mode is described in Control Setup. | Shoulders remain readable explicit spin controls; lateral input should visibly rotate the rider when not consumed by a trick-selection gesture. Do not rotate the camera with a flip or rider spin. |
| Linking | THPS4 pp6–7: manuals link flat-ground sections; reverts link ramp aerials into the next trick. Repeated tricks lose value. | Keep distinct stable trick IDs and the authoritative existing banking deadline. Duration score cannot create a new multiplier every physics frame. |
| Camera | THPS4 p7 and THPS3 Starting Up: right stick can inspect the surroundings; R3 can lock/unlock an angle; THPS4 also describes selectable camera positions. | A stable readable third-person chase is essential; manual inspection is optional follow-up. These pages do **not** reveal the commercial camera algorithm or certify our chosen lens. |

Both manuals say tricks can be configured differently for each skater. There is no universal direction→trick-name table to reproduce. We should document our own useful defaults, preserve the familiar family buttons and make the movements truthful to their names.

## Implementation status

The tables below were research recommendations. The integrated defaults, including six flips, five grabs and the exact four lip poses, are in [PLAYER-GUIDE](../PLAYER-GUIDE.md) and ADR-015. The implemented threshold is 0.35; rails use buffered tap-to-lock, not the optional retained hold-only scheme discussed below. This research is a reference basis, not the current binding specification.

## Concrete first-pass mapping and animation targets

The table is an **original recommended mapping**, informed by that grammar. Neutral preserves the previous simple Kickflip/Melon paths. It is not a claim that every named franchise skater uses this setup. Up/Down/Left/Right are board-relative **raw control directions**, never world compass or chase-camera directions. A neutral press chooses the neutral entry deliberately; do not reuse an old direction indefinitely.

| Input direction at the request | Square / J: finite flip | Circle / K: held grab | Triangle / L at eligible coping: lip |
|---|---|---|---|
| Neutral | Kickflip | Melon | Rock to Fakie |
| Left | Kickflip | Melon | Axle Stall |
| Right | Heelflip | Indy | Disaster |
| Up | Frontside Shove-it | Nosegrab | Nose Stall |
| Down | Pop Shove-it, or a separately animated Impossible | Tailgrab | Tail Stall / Blunt to Fakie |

Choose one Down flip and one Down lip in the implemented table and state the exact choice in the player guide. An Impossible needs the board to wrap around the back-foot region; merely reversing a shove-it does not depict an Impossible. Starting with two opposing deck flips and two opposing shove-its provides four clear motions without that extra rig work. Diagonals, double taps and stance-specific variants can wait; they are not needed to deliver useful variety.

- **Kickflip versus Heelflip:** opposite full rotation around the deck's nose-to-tail axis, with feet visibly separating then returning to their own trucks. Crouched knees, timed front-foot flick and a recovery beat distinguish a trick from a board spinning through the shoes.
- **Frontside versus Pop Shove-it:** deck yaws through 180° in opposite directions beneath a substantially stable torso; correct final deck/contact orientation. Add a modest original scoop/pop arc. Do not label the deck yaw as a rider 180.
- **Melon:** front hand to heel-side edge between feet, knees tucked; **Indy:** rear hand to toe-side edge between feet. The board has different roll and rear/front arm geometry. Hand targets are board-local contact points transformed into the rider frame, with coherent elbow bends.
- **Nosegrab/Tailgrab:** appropriate hand reaches the corresponding deck tip; pitch and leg extension distinguish the two. A target at the board centre is not a credible nose/tail grab. Keep the other arm free for balance.
- **Manual/Nose Manual:** rear-wheel versus front-wheel support. Pivot the visible board/rider around the supported axle so the grounded wheels remain on the surface. The nose/tail lift must not visibly bury the opposite wheels. Up/Down balance is more familiar than using the steering axis, and allows actual carving while balancing.
- **Axle Stall:** both trucks on coping, board parallel to it, torso facing the ramp. **Nose/Tail Stall:** the named truck/end is on the lip, board directed up the face, opposite end lifted. **Disaster:** board approximately across its centre on the coping, nose/tail straddling ramp/deck; distinct from a truck-supported 50-50. **Rock to Fakie:** brief deck-centre rock over the lip and a backwards return. Handplants require additional hands-to-coping contacts and are a later family.

Each clip needs enter, active and recover phases driven by elapsed time, a stable trick ID, its duration/hold type and explicit contact/pivot data. State and animation must agree: no grab awarded while hands remain in the rolling pose, no flip awarded repeatedly by holding Square and no pose continuing into a reset. Original procedural poses can establish this contract now; a later original rig/GLB animation pass must preserve it rather than replacing the selection/scoring rules.

## Requests, direction and imperfect human input

At the **fresh button edge**, snapshot `{family, direction, requested_at}`. If a 120ms request is later admitted after takeoff, it must retain that selected direction even when the player has released or moved the stick. Read mapped gameplay actions after deadzone handling so keyboard, controller and remapped physical inputs share the same path. A recommended directional threshold is 0.45 with a neutral band/hysteresis; this is our candidate, not a franchise constant. Cardinal dominance makes diagonals deterministic for this slice.

Context determines who consumes a direction: lip/grind/manual balancing has priority while in those states; a face-button request consumes its trick-selection gesture; ordinary grounded input carves; unconsumed airborne lateral input can spin the visible rider. Shoulder spin remains available during a held grab. This prevents selecting a Left Melon from also commanding an unexpected full air rotation. Up/Down used for a grab must not produce airborne push/brake impulses.

For Up→Down / Down→Up manual sequences, require real zone edges, a short first tap and a bounded sequence window. Not Pro Skater's inspected `_stick_combo()` records the duration of the first zone, so holding Up for several seconds to push then braking is not a manual gesture. Consume an admitted sequence once. A buffered landing sequence expires and clears on reset, disable, bail, pause/mode boundaries and hard run expiry. Keep the prior invariant that a rejected Manual press at rest cannot remain held and activate later merely because speed becomes eligible.

An early held Triangle request can arm the next nearby capture; it must not teleport across the deck, survive indefinitely or capture behind the rider. A lip request and rail capture request share an eligibility decision, not two score awards. Keep current-origin clearance for any historical sweep, along-coping velocity for rail direction, and explicit recapture cooldown after a drop/pop. A complete tap-to-lock redesign can remain separate if the present held-grind semantics are retained and documented.

## Quarter-pipe / half-pipe loop that delivers useful tricks

The previous 35° Clyde bank is not a quarter-pipe. A visible curved wall needs matching curved collision and a full 3D support frame before these tricks become playable. Use the original [transition fixture proposal](TRANSITION-SKATING.md) and one clearly visible quarter plus opposing half-pipe faces **inside an existing skating area**, with a continuous side approach/deck bypass and no new district.

1. Roll through the toe with actual momentum. Transition contact must rotate/support the board and coherent body/capsule, project gravity into the tangent plane and honour velocity discarded by real collisions. A material tag alone is not support. Mere curvature changes must not create repeated landings or new trick windows.
2. Low-speed no-input approach climbs then rolls back. It must not stick to a vertical wall or gain energy on each seam. Held crouch/push can add a documented, capped arcade pump so a player can repeat the half-pipe loop without accidentally braking at every crossing.
3. A release near the steep lip produces a readable air above the coping. Preserve along-coping drift; show both the rider and lip. A bounded return-plane assist and automatic down-ramp reorientation are reasonable accessibility choices, but automatic return rotation must not award a Spin 180. No hidden unbounded attraction or scripted position arc.
4. Released grab/finished flip recovers before the return. Actual descending contact triggers one landing and a bounded revert opportunity. Natural visual orientation should resolve forward/fakie coherently; do not force the old uphill heading and reconstruct forward speed after landing.
5. A perpendicular eligible Triangle+direction request near the coping/apex instead enters a stationary lip pose with Left/Right balance. Along-coping travel remains a grind. A normal street rail, the far side of a deck, a flat roof and a fast low approach must reject lip admission.
6. A deliberate ollie release or drop exits back toward the **same ramp** with tested clearance; recapture delay prevents instant reattachment. Return, cross the flat bottom and climb the opposite wall without per-frame test-driver heading/velocity injection. A six-cycle ordinary-input run should not stall, tunnel, create unlimited points or progressively increase unpumped energy.

The key distinction is support, air, travelling grind and stationary lip. Prefer explicit exclusive state contracts. The current 0.35s ground banking and bounded overtime rules still apply; riding an ordinary supported ramp cannot indefinitely keep an existing combo alive. A new explicit lip can hold a live combo while physically balancing, with an independent finite safety maximum if chosen, and never extend hard overtime.

## Camera and turning recommendations

Not Pro Skater's inspected MIT `chase_camera.gd` separates camera direction from the drawn board: it chases horizontal **travel**, follows only part of airborne height, remains world-up and frames steep air from outside the ramp near coping height. Its default reference numbers are 4.4m back, 1.65m high, 1.05m look height and 68→80° FOV; these are **that open-source project's parameters**, not measured THPS values or a prescription to replace our existing volume-clearance camera.

Preserve our sphere sweeps, head/board/chest visibility tests and minimum useful arm. Evaluate a lower/closer chase without putting the camera inside a ramp or the skater. A rolling 180/360/flip should not orbit the view through the character; use actual horizontal travel with a near-zero fallback and delayed reverse-facing change. For transition support, aim from the body's support-relative chest but retain a world-up horizon. Above the lip, an air/vert anchor should show deck, coping and landing face together. Reduced motion should suppress FOV kick and camera bounce. Right-stick inspection can remain a later mapped camera feature; do not silently reuse the current R3 Restart control for camera lock.

At baseline our fast yaw is 1.1rad/s at 15m/s (~13.6m radius), while pinned NPS has 3.3rad/s at 12m/s. Those facts justify trying a tighter high-speed response, **not** copying its entire tune. Compare 1.6/2.0/2.4rad/s candidates at 8/12/15m/s using full/half/quarter mapped-stick inputs; retain low-input precision and collision momentum. An actual half-pipe must allow lining up the next wall without a huge street-sized orbit. Do not claim exact franchise parity without played reference measurements and owner/controller acceptance.

## Sources, retrieval and permissions

All source requests were ordinary public HTTPS on 17 October 2026. Temporary cache: `/tmp/tam-hawks-classic-controls`; raw pinned code is reproducible if the cache disappears. Full code licences were reread from the previous research cache.

| Source inspected | Evidence / rights boundary |
|---|---|
| [THPS4 PS2 manual, Internet Archive item](https://archive.org/details/ps2_Tony_Hawks_Pro_Skater_4_USA), [direct text PDF](https://archive.org/download/ps2_Tony_Hawks_Pro_Skater_4_USA/Tony_Hawks_Pro_Skater_4_USA_text.pdf) | Printed pp4–7 / PDF6–9 checked, including actual visual arrows/buttons; Control Setup read as OCR. Copyrighted reference, not reusable art/code. No manual pages, screenshots, logos or text chunks are bundled in the game. |
| [THPS3 PS2 manual, Internet Archive item](https://archive.org/details/ps2_Tony_Hawks_Pro_Skater_3_USA), [OCR](https://archive.org/download/ps2_Tony_Hawks_Pro_Skater_3_USA/Tony_Hawks_Pro_Skater_3_USA_djvu.txt) | Starting Up and gameplay/trick/grind/lip sections read. OCR button glyphs are lossy; ambiguous icons cross-checked against visually inspected THPS4 pages. Copyrighted reference only. |
| [Not Pro Skater `tricks.gd`](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/skater/tricks.gd) and [camera](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/camera/chase_camera.gd) | Exact revision `d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988`, MIT ©2026 Austin Ginder. Entire files read, plus skater air 1098–1207, manual gesture 1435–1520 and lip 1730–1865. Names/tables here are a reference implementation, not proof of franchise defaults. Code adaptation needs retained full notice and scope in licence register; no new extraction made by this researcher. |
| [GodotSkate pipe](https://github.com/3deric/godot-skateboarding-game/blob/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928/Skategame/Scripts/Player/Player_States/player_pipe.gd), [lip](https://github.com/3deric/godot-skateboarding-game/blob/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928/Skategame/Scripts/Player/Player_States/player_lip.gd), input/air scripts | Revision `4fad39ecfb21e79ca4799b90e77ef6c1edfa7928`, MIT ©2024 Eric Schubert. Explicit ground/pipe/air/lip separation, release-driven Jump buffer and fixed-lip balance/exit inspected. Its direct position assignment and state-specific assumptions are not a clearance-safe drop-in; see prior transition review. Modified MetaHuman assets are not cleared by MIT code licence. |

SHA-256 retrieval identities:

| Inspected file | SHA-256 |
|---|---|
| THPS4 text PDF | `ec53d1882d21905e5c86f3422fb95c72f782871286b7837046b9cffc1cbbdf5e` |
| THPS4 `_djvu.txt` | `2017d0cd225751c0badd669fb6aff6beeab3535120baa178a21525bb5206fe56` |
| THPS3 `_djvu.txt` | `ba54eb6af87abe0624d658af6e0068d6d12cf199cf30ca74e6a2e544298f0002` |
| NPS `tricks.gd` | `acc060ccb3ecf705dfc2a285c5070544f5f7a2535a308333d1c1b1cff6907533` |
| NPS `chase_camera.gd` | `0f6ced836eba1ec186529238686c43597c9b9224a7e4ae44379cbea0e0211b73` |
| GodotSkate `player_lip.gd` | `c8cc4b9ef3e209ef0e232eb755c9b889f074b1968ec9234b851f13564a6d99fe` |
| GodotSkate `player_pipe.gd` | `6406f3cbf4d8fa3cba1546a3259dc2bd3a38537953e025ab53000859f278ce0f` |

The attempted current Activision controls URL redirected to an error page; guessed official/PushSquare and GamesDatabase manual paths returned 404; IGN was blocked and Fandom returned an access error. Search results were not substituted for inspected content. The accessible archived manuals and pinned MIT code above are the evidence used. No proprietary physics source, ripped animation or unlicensed third-party character was used.

## Verification needed before claiming this slice complete

- Table-driven requests prove every cardinal/neutral binding and stable ID through keyboard, synthetic physical controller events and one remapped event; include a direction changed during the buffer, diagonal/neutral input and held-button repeat refusal.
- Actual gameplay proves at least two opposing flips, four grabs with sustained/released holds, Manual/Nose Manual, and more than one admitted lip pose. Capture enter/active/recover motion from the ordinary chase and declared close inspection; text and static screenshots alone do not prove animation.
- Manual tests cover Up held to push then Down brake (reject), short Up→Down / Down→Up on ground/landing, expiry, speed eligibility, reset/disabled/overtime and steer/balance independence.
- Quarter/half-pipe tests cover low-speed rollback, a no-push energy baseline, real multi-cycle return, lip versus along-coping grind, missed/high/late/offset lip approaches, side exits, deck clearance, deliberate drop, occluded ramp camera, reverse near-zero camera and no automatic Spin score.
- Run the full production suite and source-cold import/launch, then capture all new families and a natural half-pipe pass. Actual Mac, wired/Bluetooth DualSense, comfort, feel, fun and final-art acceptance remain human/hardware gates.

## Owner-provided links reviewed during implementation

The owner supplied GodotSkate again and the Godot sports guide. Both were inspected on 17 October 2026 without installing a service or copying new upstream code/assets.

- [GodotSkate README](https://github.com/3deric/godot-skateboarding-game/blob/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928/README.md), revision `4fad39ecfb21e79ca4799b90e77ef6c1edfa7928`, confirms separate pipe colliders, ordered per-rail polylines and a glTF/Blender import convention. Its pipe/lip/input source was already inspected above. Those ideas inform our explicit transition contact and rail paths; our new geometry and controller integration are original. Its stated Godot 4.5 compatibility does not establish 4.6.3 behavior. The code's MIT licence does not clear its modified Epic MetaHuman characters for reuse; none were imported.
- [Godot sports guide](https://github.com/ahmet-cetinkaya/dotfiles/blob/3bab7c380a9ad0f2ef941e879656d0bfd6555cf0/agent-ctrl/profiles/godot/skills/godot-genre-sports/SKILL.md), revision `3bab7c380a9ad0f2ef941e879656d0bfd6555cf0`, is mostly a ball/team-sport blueprint. Useful principles are fixed-step physics, collision-safe fast travel, contextual actions and input magnitude discipline. Our existing 60 Hz physics, bounded capsule sweeps, exclusive pipe/lip/rail states, direction snapshots and tests address those principles. Its blanket suggestions to use 120/240 Hz, root motion and multiple character colliders are not skate-specific evidence and were not applied. Higher physics frequency multiplies CPU work; any change needs measured tunnelling/latency benefit and target-Mac cost. Do not normalize away analog stick magnitude, which our partial-input tests deliberately preserve. Ball Magnus force, goalkeepers, formations and authoritative multiplayer goals do not apply to this single-player skate slice.

Retrieval SHA-256: sports guide `81c45d1c0f6c6904b71b858bbf24fee1524e47c49fd2bafe6c60df46c1b62b4b`; dotfiles MIT licence `d8f2b55ec0a76076b5b5a8bdd5d494f0f9eeb9ef34cba10a1d5c28f5daa832a3`; GodotSkate README `633c6ba5549aef03388b50f1a6f3489f3e093e3b4c3ac5ec0c3b624065ef3eb5`; GodotSkate MIT licence `9b646934ce371139c3813793a3d094aca34713175e7a7f81d3da0d22bcb7b264`. The pinned sports guide was verified byte-identical to the initially inspected main URL. These are reference observations; no remote skill was installed or given authority over repository/budget rules.
