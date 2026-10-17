# Game design and staged rules

This document describes intended Release 1 behaviour. Prototype implementations must be checked against `docs/STATUS.md`; an entry here is not a completion claim. Shared API names live in `docs/architecture/interfaces.md`.

## Core loop

Choose career or free skate, enter the connected Glasgow level, build speed, find lines, perform tricks and discover objectives. Career runs last 120 seconds of active play. Pausing freezes time and physics. A result screen shows banked score, best combo, completed goals and records, then offers immediate restart. Free skate has no countdown and clearly identifies which career goals cannot progress in that mode.

M01 supplies a restartable skating experiment and basic score feedback. M02 establishes complete combo continuity and bail rules. M04 adds career progress and save persistence; prototype totals are not a complete progression system.

## Skating feel

The skater accelerates predictably, brakes without accidental reverse input, steers responsively at speed and has forgiving aerial steering. An ollie starts on a fresh input edge when grounded; holding trick buttons must not generate unlimited points. Ramps create usable launches and landing surfaces, with stable floor contact and no collision tunnelling at supported speed. The follow camera looks along the skating line, smooths sudden rotations and must eventually avoid geometry occlusion.

Controller-first responsiveness means actions register by the next eligible physics update; tune animation and input buffering only after measuring latency and playing with hardware. Do not delay a trick merely for an animation. Initial tuning belongs in central parameters so QE and gameplay can compare runs.

## Tricks and combo rules

| Mechanic | Intended behaviour | Stage |
|---|---|---|
| Ollie | Reliable grounded launch with controlled landing | M01 |
| Flip / grab | Recognisable original named aerial actions with finite duration and input-edge gating | M01 foundation, M02 polish |
| Spin | Count completed rotation, communicate direction and landing safety | M01 foundation, M02 scoring |
| Grind | Explicit eligible rails, forgiving acquisition, travel and release, balance risk | M02 |
| Manual | Ground balance move linking landed tricks without a fresh jump | M02 |
| Revert | Short landing window for a deliberate turn that preserves eligible combos | M02 |
| Special | Earned meter unlocks clearly signalled special input; no free repeated score exploit | M02 |
| Named gap | Authored start/end crossing produces a bonus once per valid traversal | M02 / M03 |

The M01 implementation banks an aerial combo on landing. M02 replaces this with documented continuity windows linking landings, manuals, reverts and grinds. A bail discards unbanked points and recovers promptly at a safe location; banked score stays intact. A cleanly ended combo banks exactly once. Repetition reduces same-trick value; multipliers reward successful eligible actions. All values are data or central tuning constants and must have deterministic tests.

At career timeout, stop admitting new tricks. Final combo treatment must be explicit and tested before M04 acceptance: the proposed rule allows an already active combo to resolve with a short upper limit, then enters results. This proposal requires A04/A08/A09 agreement through an ADR before changing M01's simpler timer behaviour.

## World and exploration

The four districts share one continuous level and visual identity. Real locations provide architectural and cultural reference, but geometry, routes, signs and characters are original. Streets are compressed for traversal; every connector should offer a skating choice. Use broad approaches and recovery space around difficult obstacles. Include routes accessible with basic skills plus higher-risk links for combo mastery.

The prototype square establishes a mood and reusable geometry; it does not constitute four completed districts. District descriptions, route tests and planned secrets live in `docs/levels/glasgow.md`.

## Ten career objectives (proposed definitions)

Thresholds and rewards are provisional until M02 and M03 produce stable score distributions. Goals complete at most once per save, remain visible after completion and can be replayed without duplicating permanent rewards.

1. **First shift:** reach the beginner score threshold.
2. **Good shift:** reach the intermediate score threshold.
3. **Some shift:** reach the advanced score threshold.
4. **One long line:** bank a target single combo.
5. **Letters round the square:** collect five original letter tokens in one career run.
6. **Cone duty:** perform the original statue/cone interaction.
7. **Platform change:** complete a named Central route gap.
8. **Market sweep:** collect a set of scattered market items in one run.
9. **Across the toon:** visit a route checkpoint in all four districts within one run.
10. **Lost recording:** find the secret recording collectible in an optional area.

No score thresholds are production-balanced yet. Temporary UI text must not imply career goals or saves exist before those systems are implemented. Reward proposals are district secrets, cosmetic colour variants and a special trick; basic movement is available from the start.

## Audio, humour and presentation

Use original short observational humour without impersonating real people. Fictional shop names avoid lifting commercial logos. React to speed, wheel contact, jump, landing, bail, combo banking and district ambience. Generated local SFX are valid initial assets and must have reproducible source. Music is optional polish, not a licence to reuse commercial tracks. Ambient NPC barks require an approved zero-cost voice source and captions before acceptance; paid voice generation is prohibited.

## Accessibility and UI

Provide keyboard equivalents, controller focus indicators, readable high-contrast score/timer text, subtitles for all barks, separate audio controls, reduced camera shake and configurable sensitivity. Settings persist locally. Pause and results must be navigable without a mouse. Recovery and restart should be fast without accidental erasure of saved progression. Rebinding and glyph behaviour are M06 work, not certified prototype features.

## Outstanding product decisions

The exact M02 trick button combinations, special input, final timeout resolution, voice source, and final title need evidence or owner feedback at their assigned gates. No such uncertainty blocks foundation or M01 development. Do not silently solve a difficult requirement by removing it.
