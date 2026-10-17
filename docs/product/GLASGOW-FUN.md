# Glasgow encounters and playful side challenges

17 October 2026. These are original encounters for Tam Hawks Pro Skater, alongside the ten stable career goals. Current implementation is a complete replayable busker slice; the other ideas below remain explicit design tasks. No new career IDs, unlocks or save schema are introduced.

## Design aims

The best local joke should also create a skating problem: choose a line, judge speed, use a landmark and commit to a finish. Give the person a reason to ask, show the result in the world, and make retry immediate. A short caption explains the task; the skater's real movement/tricks provide the evidence. Funny dialogue alone does not complete an encounter.

The historical [character/performance research](../research/GLASGOW-CHARACTERS.md) supports street music, dancing and recognisable public places. The people, requests, props and dialogue here are fictional.

## Implemented: Mo's Big Finish

**Character/place:** Mo, an original guitarist at the east edge of the Exchange fountain court, `(28, 0, 31)`, facing into the court. The visible NPC reuses the cleared anatomical head/hands and original skinned garments; a newly authored acoustic guitar, strings/frets and open case establish the occupation. Gentle head/strum animation responds to success. Props have no collision on skating lines. A quiet original synthesized plucked open-chord texture plays through one spatial audio source, fading with distance and ending at 28 m. It contains no melody, licensed song or copied performance recording. Master and ambience sliders both control it; menus pause it and run expiry stops it. Human listening quality remains unverified.

**Request:** “Gie it laldy! Bank 1,000 with 3 trick types in this court. 35 seconds.” One clean line must contain three distinct trick families. A real ollie, flip and grab followed by a clean bank is one achievable route; a grind/manual/spin route offers replay variety.

**Trigger and rules:** Interact within 4.2 m horizontally and 2.5 m vertically. The player must first resolve any existing combo. During the 35-second active attempt, trick events and the resolved bank must remain within 34 m of Mo horizontally and 10 m vertically. Only positive real trick callbacks contribute. The entire qualifying combo must be observed during the attempt; leaving the court invalidates it until it resolves. Repeating the same family does not supply additional types. A short clean bank clears the candidate and leaves time for another line. A bail or timeout fails the attempt. Career expiry visibly ends an unfinished attempt.

**Feedback/replay:** The HUD retains timer, type count and the 1,000-point target independently of combo and transient dialogue. A world sign shows active progress or the result. Success says “Ya dancer!” and the guitarist plays an excited strum. Return to Mo and interact to replay after success/failure. Restart/mode changes clear the session-local attempt and result.

**Score/save behavior:** The encounter observes existing score callbacks and never manufactures an award, advances a career goal, grants an unlock or writes a profile. Existing career scoring remains authoritative: the skating bank can still earn the ordinary career score goals, while the side-encounter completion itself adds no goal or unlock. The challenge works in free skate and career, with the same pause and run-end gates.

**Runtime contract:** `game/characters/glasgow_encounters.gd` is a pausable `Node3D`. Main owns wiring. `configure([{id, position, heading}])` accepts `busker_big_finish`. `poll(position, interact, delta, combo_value)` runs only during active play. `on_trick(name, points, position)`, `on_bank(points, position)`, `on_bail()`, `finish_run()` and `reset_run()` receive actual gameplay transitions. `nearby_prompt(position)` returns action wording without a hardcoded key. `status_snapshot()` returns `id`, `title`, `state`, `remaining`, `family_count`, `required_families`, `target_points`, `attempts`, `wins`, `reason`, `detail`, `hud_text`, `position` and `combo_valid`. `feedback(text)` supplies transient captions; `reduced_motion` freezes decorative performance animation. `set_mix(master, ambience)` accepts raw gains, clamps each to 0–1 and controls the spatial instrument with their product. Native pausable processing controls playback during menus. `busker_sound.gd` caches one bounded eight-second, 22,050 Hz mono PCM loop across instances; the Dummy audio driver skips playback while retaining inspectable sample data.

**Evidence:** The focused construction/state smoke ran Godot 4.6.3 headless, built the actual NPC and exercised a successful bank with clean engine logs. An audio-data probe inspected the cached 352,800-byte, eight-second PCM: peak 0.219916 of full scale, zero clipped samples. This does not establish audible quality. The source-stable level capture subsequently performed real interact → ollie/flip/grab → clean landing/bank, asserting three families and exactly one win. [Offer](../testing/screenshots/level-redesign/11-busker-offer.png), [active line](../testing/screenshots/level-redesign/12-busker-active-line.png) and [success](../testing/screenshots/level-redesign/13-busker-success.png) show the actual 1,950-point result; the [medium view](../testing/screenshots/level-redesign/18-busker-medium.png) inspects the NPC. Independent gameplay tests are owned by QE in `tests/glasgow_encounters_tests.gd`; final aggregate results belong in the handoff. A stationary ollie/flip/grab currently qualifies, so rule completion does not prove line difficulty, discovery or fun.

## Authored next encounters

| Encounter | Glasgow setting and character | Real skating task and visible payoff | Follow-up acceptance/test |
|---|---|---|---|
| **Cone on a Cruise** | Clyde quay; a fictional festival steward with a floating foam cone mascot | Build speed, launch the foam cone from an agreed stunt point into a marked floating ring, then land a trick on the quay. The cone pops onto its own little raft and waves. An explicitly harmless prop gives the river prank a readable payoff. | Actual rigid-body trajectory must cross the water target; a button alone cannot win. Water recovery, miss/reset, leaving the area, pause and repeated attempts must be bounded. No human or animal goes into the river. |
| **Cat's Got the Beat** | Civic close or St Enoch-inspired pocket; fictional tinkerer and an original geometric mechanical cat | Grind three marked coping segments in the order of a short light pattern. Each real segment capture powers another part of a small mechanical dance stage. Completing the sequence starts a brief original animation. | Verify ordered physical captures and wrong-order reset; do not copy the historical performer's cat, routine, music or personal likeness. Provide a non-flashing reduced-motion display. |
| **Gull-Proof Delivery** | Barras lane; fictional breakfast-stall owner | Carry a sealed breakfast parcel through a choice of market lanes, bank one clean manual-to-gap line and arrive before the gull steals a spare parcel. The comic gull targets props, not the skater. | Actual route/gap and clean bank required; no time-only auto win. On bail the parcel returns to the stall immediately. Forked routes should trade time against trick opportunity. |
| **One More Lap, Hen** | Kelvingrove rolling paths; fictional park regular timing a community event | Link fountain coping, downhill path and a grass-bank transfer, choosing a safe return or a harder shortcut. The character pretends to be unimpressed until the final replay. | Physical start/finish gates, safe uphill return and legible landmark sequence. Test both route choices; record human readability and fun separately from automated completion. |

The river, mechanical-cat, parcel and park encounters are **not enabled features** yet. Keep each as a full task with owner, dependencies, scene/collision needs, dialogue, visual payoff, retry rules and independent physical checks. Prioritize the complete busker slice and terrain navigation before adding more mission infrastructure.

## Resumable follow-up tasks

The full task records live in [BACKLOG](../planning/BACKLOG.md), with owners, priorities, dependencies, acceptance criteria and test strategies:

- **M04-008 — Cone on a Cruise:** physical floating-prop river prank.
- **M04-009 — Cat's Got the Beat:** ordered coping grinds and an original mechanical dance payoff.
- **M04-010 — Gull-Proof Delivery:** a real manual/gap delivery through a choice of market lanes.
- **M04-011 — One More Lap, Hen:** a landmark-based park lap with a safe return and harder shortcut.

All four remain **Planned**, with no enabled-content claim. Prioritize the complete M04-007 busker and M03 terrain gates before selecting another slice. These names refer to original fictional encounters, not licensed depictions of the historical performers.

## Human review still required

Have a Glasgow reader assess whether the dialogue sounds natural and affectionate. Have a player attempt the busker goal without knowing the test route: can they find Mo, understand “three trick types,” see the court boundary and retry without frustration? Measure success/fail reasons and adjust the timer/radius from that evidence. Neither automated success nor historical research establishes fun, local authenticity or final character-art quality.
