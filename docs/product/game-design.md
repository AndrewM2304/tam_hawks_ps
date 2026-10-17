# Game design and staged rules

This document records implemented gameplay rules and remaining Release 1 acceptance work. The functional systems below have local automated coverage; current commands, results and limitations live in `docs/STATUS.md`. Implementation does not close human/hardware gates. Shared API names live in `docs/architecture/interfaces.md`.

## Core loop

Choose career or free skate, enter the connected Glasgow level, build speed, find lines, perform tricks and discover objectives. Career runs last 120 seconds of active play. Pausing freezes time and physics. A result screen shows banked score, best combo, completed goals and records, then offers immediate restart. Free skate has no countdown and clearly identifies which career goals cannot progress in that mode.

The title screen offers career and free skate. Tricks, landing links, objective collection, permanent career progress, unlocks and local persistence are wired into the active scene. Free skate supports exploration and trick practice, including both specials once its run meter is full, but does not advance career goals or permanent records. Complete career pacing, route discoverability and controller feel still require playtesting.

## Skating feel

The skater accelerates, brakes without accidental reverse input and has bounded arcade aerial steering. Buffered/coyote ollies begin from fresh input edges; holding trick buttons does not repeatedly award entries. Ramp departures preserve collision-adjusted momentum. Ramps provide launches and supporting surfaces, and the follow camera smooths travel while checking scenery occlusion. These behaviors have focused tests; subjective responsiveness and difficult real-controller lines remain acceptance work.

Controller-first responsiveness means actions register by the next eligible physics update; tune animation and input buffering only after measuring latency and playing with hardware. Do not delay a trick merely for an animation. Initial tuning belongs in central parameters so QE and gameplay can compare runs.

## Tricks and combo rules

| Mechanic | Implemented behaviour | Remaining acceptance |
|---|---|---|
| Ollie | Buffered grounded/coyote launch and forgiving landing | Controller timing/feel |
| Flip / grab | Finite original kickflip and melon-grab poses, with input-edge eligibility | Animation finish and readable contact |
| Spin | Completed half-turn awards at landing or rail capture; direction feedback | Human readability and tuning |
| Grind | Six authored rails, bounded descending capture, signed travel, release/cooldown and balance bail | Complete controller lines |
| Manual | Fresh eligible input starts ground balance; held manual links the combo, fore/aft input corrects balance | Sustained balance feel and exploit playtest |
| Revert | One turn in the 0.35-second landing window, with speed cost; does not refresh that window | Revert-to-manual controller timing |
| Special | Clyde Carousel and Tenement Tumble require full meter, eligible airborne state and career unlocks | Animation and reward tuning |
| Named gap | Ordered swept start/end crossings, airborne evidence and bounded timing award the three authored routes once per traversal | Human route discovery/flow |

Landing now opens a 0.35-second combo continuation window. An eligible manual, new launch or rail ride sustains the combo; releasing a ground manual resolves through the same bounded landing flow. Reverts spend the existing window without refreshing it. Manual and rail imbalance can bail, discarding unbanked points while retaining the banked score. A cleanly resolved combo banks exactly once. Repetition reduces same-trick value; unique eligible moves raise the bounded multiplier. Values live in the trick catalog and central tuning constants, with deterministic boundary/exploit tests.

Banked combos fill the special meter: one unit per 25 points, at most 50 units per bank, with capacity 100. Accepted specials consume the full meter and cannot repeat within the same airtime. Career unlocks gate availability; free skate permits both specials for practice while retaining meter/state checks.

At career timeout, new tricks and objectives stop. An existing air, rail, manual or pending-landing combo may resolve for at most three additional seconds, then the run enters results. Restart clears transient tricks, meter, gap state and run collections while retaining permanent profile progress. See ADR-006 and the current integration evidence for these contracts.

Default keyboard additions are L for held grind, M for manual, C for revert, U/I for the two specials, X for interaction and Tab for goals. Existing W/S/A/D, Space, J/K and Q/E cover skating, ollie, flip/grab and spin. Remapping updates saved keyboard/controller prompts; physical DualSense mapping still needs hardware verification.

## World and exploration

The four districts share one continuous level and visual identity. Real Glasgow streets, shopfronts and landmark relationships guide recognisable boundary facades; models and texture assets are created or reused with appropriate permissions. Use verified real business/venue references where they fit, with source dates and accurate placement. See `docs/research/GLASGOW_REFERENCES.md` for evidence and unverified leads. Streets are compressed for traversal; every connector should offer a skating choice. Use broad approaches and recovery space around difficult obstacles. Include routes accessible with basic skills plus higher-risk links for combo mastery.

Four connected spaces now exist: the original Royal Exchange court, a broad George Square learning area, Central's canopy/elevated platform route, and a Barras market with the recording alcove. Paired entrances and northern back lanes provide alternate routes. Nine ramps, six rails, three named gaps and objective markers use shared world metadata. Collision sweeps, supporting floor checks and real captures establish functional geometry; they do not certify full-level human enjoyment. The compressed layout is original, and current official/StreetView frontage verification remains blocked. District dimensions, routes and secrets live in `docs/levels/glasgow.md`.

## Ten implemented career objectives

Thresholds remain tuning values pending human career play. Goals complete at most once per save, remain visible after completion and can be replayed without duplicating permanent rewards. Run-specific sets reset on restart; career mode is required for permanent progress.

1. **First shift:** bank 1,000 points in one run.
2. **Good shift:** bank 5,000 points in one run.
3. **Some shift:** bank 15,000 points in one run.
4. **One long line:** bank one combo worth 3,000 points.
5. **Letters round the square:** collect H, A, W, K and S in one career run.
6. **Cone duty:** interact beside the statue to visibly pop/tip its cone.
7. **Platform change:** clear the Central platform gap (`central_gap`).
8. **Market sweep:** collect all three distinct market items in one run.
9. **Across the toon:** visit a route checkpoint in all four districts within one run.
10. **Lost recording:** find the secret recording collectible in an optional area.

First shift unlocks the orange colour and Clyde Carousel; Some shift unlocks purple; One long line unlocks Tenement Tumble. Basic movement and the default blue colour are available immediately. The locker selects earned cosmetics. Goals, records, settings and unlock-derived state persist in the versioned local `user://career.json` profile, with validation and backup recovery. Unreadable/newer files are preserved instead of silently overwritten; a failed save leaves session progress available. Local persistence tests do not establish target-Mac relaunch behavior. No score threshold is claimed production-balanced.

## Audio, humour and presentation

Use original short observational humour without impersonating real people. Recognisable Glasgow business/venue references are welcome; verify their location and treat logo/photographic assets separately from factual names. Original locally synthesized PCM effects now react to rolling, grinding, ollie, landing, bail, combo banking and UI events, with bounded channels and district ambience. Music remains optional; no commercial track is included.

Three original short barks are shipped as WAV files generated with the inspected installed Flite `cmu_us_kal16` voice: “Some landing”, “Mind the cone” and “One more run”. Landing-near-bystander and cone-event playback hooks emit matching captions; global and per-line cooldowns prevent repeated chatter. Four static bystanders supply locations. This is a lawful free synthetic source with retained notices and a reproducible generator, not a claim of natural Glaswegian performance. Runtime needs neither Flite nor a paid service. Listening, mix balance, accent/style and ambient animation remain presentation work.

Follow `docs/product/ART_DIRECTION.md`: final art needs believable materials, proportions and animation, with polished controller-first UI. The initial procedural pass adds textured masonry/paving, detailed facade modules, pitched roofs, distinct landmarks, a rounded articulated rider and a redesigned HUD/menu system. It remains stylized, repetitive and subject to refinement; it does not establish the owner's requested final realistic appearance. Verified storefronts and **M06-007 final cleanup/signoff** remain required after core gameplay.

## Accessibility and UI

The title, pause, goals, results, locker, settings and controls pages now provide focusable controls alongside the score/combo/balance/special HUD. Persistent options include captions, master volume, combined skating/voice volume, ambience volume, interface scale, camera sensitivity and reduced motion. Keyboard keys, controller buttons and supported signed axes can be rebound; validation rejects conflicts/unsafe bindings, while Escape/menu recovery remains available. Prompt text follows the active saved bindings and defaults can be restored.

These screens and settings have local state/input coverage and actual rendered evidence. Complete mouse-free traversal with a physical DualSense, target-display legibility, comfort and controller disconnect/reconnect behavior still need hardware review. Restart preserves saved progression and does not perform a profile erase.

## Outstanding product decisions

Remaining acceptance covers controller feel, career thresholds/pacing, natural voice presentation/listening, verified current Glasgow storefront references, final art/UI cleanup, target-Mac export/launch and sustained 1080p/60 fps performance. The current implemented controls, timeout rule and free voice source provide concrete behavior to evaluate. Continue independent implementation and fixes under the owner's authorization without routine task-by-task approval; retain human gates honestly rather than using them to halt unrelated work or silently remove requirements.
