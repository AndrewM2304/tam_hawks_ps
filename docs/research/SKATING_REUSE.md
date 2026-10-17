# Skating implementation research and reuse

Inspected 17 October 2026 after the owner explicitly encouraged using existing projects and implementation articles. Free public HTTP/Git reads only; no paid services, downloads from asset stores, or engine replacement. This record distinguishes inspected code from untested whole projects and unread article leads.

## Decision and actual code reuse

Keep Godot 4.6.3 and its `CharacterBody3D`, collision, input, rendering and curve APIs. Evaluate existing implementations before writing further skating infrastructure. The current controller remains a playable reference for comparisons; a larger upstream game's scene hierarchy is not a drop-in replacement.

**Adopted:** `game/tricks/grind_line.gd`, adapted from [Not Pro Skater's isolated rail helper](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/skater/grind_line.gd). It reuses Godot `Curve3D` for nearest points, distance-based sampling and full 3D tangents. The source is MIT licensed, Copyright 2026 Austin Ginder; the [complete notice](../licences/third-party/not-pro-skater-MIT.txt) is retained.

Local changes add safe handling for empty, single-point, collapsed and non-finite geometry; snapshot and remove consecutive duplicate points; clamp tangent queries before finite-difference sampling; and provide a factory that transforms authored local points into world coordinates. Distances then remain world metres under translated, rotated or scaled level parents. Rebuild the helper when that parent transform changes. The helper is an authored polyline, not a smooth Bezier importer.

Independent checks first exposed two compatibility/edge-case failures: duplicate vertices caused Godot bake/sample errors, and tangent queries beyond a bent rail's ends returned the whole-line chord. Both were corrected in the adaptation; the focused suite now passes 42 assertions without those engine errors. See the QE report for the integrated result.

Follow-up: M02-002 now uses this tested building block for the first playable rail slice. Original `grind_ride.gd` and player integration add signed travel, balance, capture/travel clearance sweeps and air→rail→air→landing scoring. Manuals/reverts and complete combo acceptance remain open; see [the grinding record](../testing/GRINDING.md). No upstream levels, characters, animations, audio or autonomous-agent scripts were imported. The upstream whole game specifies Godot 4.7.2; only this small built-in-API component is being validated against our pinned 4.6.3.

## Inspected shortlist

| Source and pinned revision | Evidence actually inspected | Fit and decision |
|---|---|---|
| [TinyBitAdventures/not-pro-skater](https://github.com/TinyBitAdventures/not-pro-skater/tree/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988) | Root `license` (MIT), `readme.md`, `game/project.godot`, `grind_line.gd`, skater/input/trick/scoring scripts, `art_credits.md` | Adopt isolated rail helper. Study signed grind travel, candidate ranking, balance and combo grace. Full controller is over 2,000 lines and coupled to its game/rider systems; project specifies 4.7/Jolt/120 Hz and README 4.7.2. Whole-game compatibility is untested. |
| [3deric/godot-skateboarding-game](https://github.com/3deric/godot-skateboarding-game/tree/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928) | Full `LICENSE` (MIT, 2024 Eric Schubert), README, Godot 4.5 project, controller/state/trick/helper scripts | Strong broader reference for ground/air/grind/pipe/lip states and buffered tricks. Selectively adapt after corrections and focused tests. README identifies modified Epic MetaHuman characters: repository code licence is not sufficient evidence for importing every asset. No assets imported. |
| [oh-ashen-one/grindline](https://github.com/oh-ashen-one/grindline/tree/2c0932270778ee1392f72d9815860987b0b4080c) | Full MIT code licence (2026 Hari), README, project, attribution, grind/air scripts and simulation bridge | Secondary test-harness reference. README recommends 4.7.1. Observed grind script uses X/Z-only axes and lacks endpoint release and actual application of its described lateral snap. Attribution includes CC-BY music/OFL font despite broad CC0 wording elsewhere. No import. |
| [JackQuentinForde/Street-Skater](https://github.com/JackQuentinForde/Street-Skater/tree/e4fa696402e78150c35fd1f56244084e1df80987) | README, Godot 4.0 project and basic player script; root/script permission search | Constant-speed movement, turn-rate control, ray alignment and kickflip are useful comparison ideas. No licence granting reuse found in inspected locations; no copying. |

These are source inspections, not claims that upstream games were played, tested on a Mac, or satisfy our acceptance criteria. Stars, screenshots and a public repository are not substitutes for those checks.

## Reusable mechanics and concrete caveats

### Rails and grinds

[Not Pro Skater's controller](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/skater/skater.gd) ranks rail candidates after distance/height/approach-angle gates, preserves signed direction, advances curve distance, applies slope gravity/friction and exits endpoints. Its helper calculates full 3D tangents, so a sloping handrail keeps its vertical direction. Use those patterns when connecting our adopted geometry helper to movement; choose our capture/balance values through tests and controller feedback rather than copying all tuning.

[3deric's helpers](https://github.com/3deric/godot-skateboarding-game/blob/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928/Skategame/Scripts/skategame_helpers.gd) show nearest baked offset and velocity/tangent projection. Source inspection also found a tangent that zeroes Y and a nearest-rail comparison mixing a local sample with a world position. Its [grind state](https://github.com/3deric/godot-skateboarding-game/blob/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928/Skategame/Scripts/Player/Player_States/player_grind.gd) invokes balance twice during one physics update. These are reasons to extract and verify specific behavior, not copy the whole controller untouched.

Required M02 integration checks: both travel directions; sloped/curved/transformed rails; bounded snap distance and angle; obstacle clearance; endpoint release; jump-off momentum; same-rail reacquisition cooldown; invalid geometry and reset/bail behavior. Open rails must not silently wrap.

### State transitions, trick input and combo links

[3deric's state machine](https://github.com/3deric/godot-skateboarding-game/blob/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928/Skategame/Scripts/Player/character_statemachine.gd) and [input buffer](https://github.com/3deric/godot-skateboarding-game/blob/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928/Skategame/Scripts/Player/character_input_buffer.gd) separate movement states from timed trick recognition. Inspected buffering holds four entries with 0.5-second aging; trick matching favours longer sequences. These are candidates for M02-001, with our own explicit transition/input contracts.

[Not Pro Skater's score keeper](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/skater/score_keeper.gd) separates unique-trick multipliers, repeat degradation, capped hold scoring and a 0.5-second link window. At the initial inspection, `main.gd` banked immediately on landing. ADR-006 now defines the implemented 0.35-second pending-bank window owned by ScoreSession, with manual/launch links and non-extending reverts. Original integration tests verify the chosen behavior; the upstream score keeper was used as a design reference rather than copied wholesale. Neither a copied timeout nor an upstream README establishes that it feels right in this game.

### Ground, air and vert

Our controller already uses built-in plane projection, `move_and_slide`, floor snap and constant slope speed. Keep those engine facilities. Source review initially identified a risk: the first airborne frame reconstructs horizontal velocity from full surface speed. A 45-degree 15 m/s slope tangent has about 10.61 m/s horizontal speed, so replacing that with 15 could introduce a takeoff boost. M01-008 subsequently reproduced and fixed actual takeoff boosts, downhill damping and restored wall-impact momentum. Independent real-physics regressions now pass; [before/after measurements](../testing/TAKEOFF-MOMENTUM.md) preserve the evidence.

The existing 56-degree floor-angle limit makes steeper surfaces walls. Vert/quarter-pipe riding therefore needs an explicit surface-support state and transition rules; increasing a floor angle alone is not an accepted implementation. 3deric's pipe/pipesnap/lip states are a useful design reference, with their coordinate/input contracts reviewed before reuse.

## Official engine references actually read

Inspected Godot's official source XML at `4.6.3-stable`, resolved to `35e80b3a8822a9df9be390814b62f44c0a9c69e8` (documentation source revision, not a replacement for the installed binary's version):

- [CharacterBody3D](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/doc/classes/CharacterBody3D.xml): collision-aware movement, requested versus real velocity, floor classification, rising velocity suppressing snap, and constant-speed slope behavior.
- [Curve3D](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/doc/classes/Curve3D.xml): `get_closest_offset` expects curve-local coordinates; baked sampling uses distance, and bake interval controls approximation. The imported helper intentionally constructs its curve from world coordinates to make its whole API world-space.
- [PathFollow3D](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/doc/classes/PathFollow3D.xml): progress is distance and `loop` defaults to true; explicitly release at open-rail endpoints.
- [Vector3](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/doc/classes/Vector3.xml): projection, plane sliding, normalization and finiteness checks used by these systems.

## Unread leads and access limits

Candidate Mick West [“Skating on Air”](https://cowboyprogramming.com/2007/01/05/skating-on-air/) and a [Game Developer URL](https://www.gamedeveloper.com/programming/skating-on-air) returned proxy CONNECT 403. Their text, exact URL/title and authorship were not independently verified here; no mechanics or quoted content above are attributed to them. Direct documentation pages and the GitHub API were also blocked; official GitHub source files and public repository pages were accessible. Article access is optional follow-up, not a blocker to the inspected implementation work. No network policy bypass or paid lookup was used.

## Provenance of the imported file

- Upstream revision: `d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988`.
- Original file SHA-256: `7f1737037c69ccfb5962e8022556bb89ef5c6107105c74fa476b2a855197589b`.
- Original licence SHA-256: `14829cfdb6a0ca3bf9f95be6ca9e6dae34ad3563f7e747047f4894d99e3d9773`.
- The file header, provenance register and full MIT notice identify the adaptation. Future source/native distributions must retain the notice. The upstream licence applies to the imported component; it does not choose a public licence for the game's other content.
- Runtime validation and exact test totals belong in [STATUS](../STATUS.md) and the QE report. Source copies used only for research remain outside the checkout in `/tmp/tam-jaws-research` and are not required to resume.
