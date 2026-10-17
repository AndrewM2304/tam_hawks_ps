# ADR-006: Trick states, input and combo continuation

Status: Accepted engineering contract, implemented for ground/air/grind/manual/revert, the landing-link timer, two specials and three named gaps. Updated 17 October 2026. Owners: A01/A04 with independent QE. Physical controller feel, target-Mac performance and M01/M02 human acceptance remain open; they do not stop separately authorized implementation work.

## Decision and source boundary

Use Godot `CharacterBody3D`, InputMap and the adopted `GrindLine` geometry helper, with small original runtime systems for skating rules. Inspected state/input/rail/score patterns and upstream caveats are recorded in [SKATING_REUSE](../../research/SKATING_REUSE.md). The helper is an attributed MIT adaptation; the state, timing, catalog, manual/revert and scoring integration here are original implementation. No whole upstream game or its assets was imported.

Choose one explicit **0.35-second pending landing bank** owned by `ScoreSession`. Immediate banking prevents manual/revert links; copying an unrelated controller and its 0.5-second queue would introduce unnecessary coupling and tuning. Preserve the short tested ollie buffer/coyote behavior instead of introducing a general input queue. Movement confirms eligible transitions; scoring owns point totals and the banking deadline; main owns run expiry, career, special charge and persistence.

## Runtime ownership and transitions

The catalog's transition/state checks describe structural permission. They do not prove support, valid rails, charge, unlocks or fresh input. The player implements current state with contact/air/rail/manual flags and contextual timers. Revert is a timed cosmetic stance change during ground travel, not a replacement collision mode. Staying in a state produces no entry award.

| From | Destination | Runtime guard and effect |
|---|---|---|
| Ground | Air | Actual eligible buffered/coyote ollie or support loss. Only an accepted ollie awards 100 and emits link-start. |
| Ground | Manual | Fresh action, real floor support, speed ≥2 m/s, no incompatible ride, and 0.35-second reentry cooldown elapsed. Entry awards 100 once. |
| Ground | Revert | Fresh action within 0.35 seconds of actual air landing, no manual/rail and unused revert for that landing. Costs 15% speed and awards 150. |
| Ground | Bail | Confirmed recovery/hazard condition. Drop active score once and reset safely. |
| Air | Ground | Actual support transition. Resolve air spin once, clear air visuals and emit one clean landing. |
| Air | Grind | Held grind, eligible nearby rail and approach/speed/height, swept clearance and cooldown. Resolve spin and award rail entry without landing/banking. |
| Air | Bail | Confirmed invalid/hazard outcome. Ordinary heading-only landings remain forgiving. |
| Grind | Air / ground | Ollie-off, release, slow ride or open endpoint retains signed tangent motion; actual later support resolves the ground landing once. |
| Grind | Bail | Balance or travel obstruction failure clears the ride and loses unbanked score. |
| Manual | Ground | Release or insufficient speed ends the held link once; ordinary pending banking starts. |
| Manual | Air | Ollie ends the manual without a false ground-end and emits a valid link-start; support loss preserves physical airtime without an Ollie award. |
| Manual | Bail | Absolute balance reaches 1, or a hazard occurs. Clear state and emit bail once. |
| Revert | Ground / manual / air | Cosmetic turn finishes, an eligible manual starts, or an eligible ollie/support loss occurs. Revert itself never refreshes the original banking deadline. |
| Bail | Ground | Recovery/reset clears all transient movement, trick and visual state; no transition score. |

There is no ground-to-grind acquisition, airborne manual entry or manual-to-revert shortcut. A fresh manual press on the actual landing frame may be accepted after the player emits that landing. Restart is an out-of-band reset. Pause freezes timers/state. Results disable controls, and overtime rejects fresh trick entries while existing holds can resolve.

## Enabled inputs and movement rules

| Action | Keyboard default | Standard DualSense candidate | Current behavior |
|---|---|---|---|
| Push / brake / steer | W/S/A/D or arrows | Left stick | Ground movement; push/brake correct manual balance and steer corrects grind balance. |
| Ollie | Space | Cross | Fresh press with 0.12-second buffer and 0.10-second coyote allowance; accepted launch only. |
| Flip / grab | J / K | Square / Circle | Fresh eligible air press; current implementation permits each once per air segment. |
| Spin | Q / E | L1 / R1 | Held visual rotation; completed half-turns resolve once on ground landing or rail capture. |
| Grind | L | R2 positive trigger | Hold to acquire/sustain; release or ollie exits. |
| Manual | M | L2 positive trigger | Fresh supported entry, held sustain, explicit balance and reentry cooldown. |
| Revert | C | R3 | Fresh press during landing eligibility, once per landing; no window reset. |
| Clyde Carousel / Tenement Tumble | U / I | D-pad up/right | Fresh main input; career unlock, full meter and eligible player airtime required. |
| Interact / goals | X / Tab | D-pad down / Create | Nearby deliberate interaction and goal view. |
| Restart / pause / free skate | R / Escape / F | Triangle / Options / touchpad | Explicit session actions. |

Mappings are enabled candidates through standard Godot/SDL events, with device -1 and default deadzone 0.2. `InputProfile` permits validated physical-key/controller remaps, rejects conflicts before applying changes, preserves `ui_*` menu actions and persists accepted overrides. Axis capture needs magnitude 0.5. Wired/Bluetooth DualSense mapping and ergonomics remain unverified on physical hardware. A controller disconnect pauses an active session.

Manual balance starts at 0.05 and has deterministic outward drift `0.18 + 0.08 × elapsed` per second. Fore/aft control contributes `(brake − push) ×1.5` per second. The manual coasts with rolling drag; those controls do not simultaneously accelerate/brake normal travel. Left/right steering remains available. Exit cooldown is 0.35 seconds, and holding through a rejected entry, cooldown or airtime cannot create a fresh press. Holding does not generate duration points.

Revert animation lasts 0.18 seconds, rotates visible stance by 180° and preserves accepted travel heading. The skater's `revert_remaining` is input eligibility only; the score's `landing_remaining` is authoritative for banking. An already spent/expired revert cannot be renewed by pressing again, scoring a gap or adding a trick.

## Trick definitions and scoring

`TrickCatalog.definition(id)` returns a deep copy or `{}`; unknown IDs score zero through lookup. Definitions include stable lowercase ID, display name, positive base value, allowed state and activation type. Validation rejects malformed records, duplicate IDs/states, invalid field types and unsupported state/activation values. `can_perform`/`can_transition` are structural guards, never substitutes for runtime checks.

| ID | Base points | Enabled award event |
|---|---:|---|
| `ollie` | 100 | Accepted physical launch |
| `kickflip` | 300 | Accepted fresh air action |
| `melon_grab` | 250 | Accepted fresh air action |
| `spin_180` | 200 per half-turn | One ground/rail contact resolution with direction/rotation in the display label |
| `rail_grind` | 200 | Successful attachment |
| `manual` | 100 | Successful supported entry |
| `revert` | 150 | Eligible once-per-landing press |
| `special_clyde_carousel` | 1,000 | Charged/unlocked eligible air request accepted by the player |
| `special_tenement_tumble` | 1,200 | Charged/unlocked eligible air request accepted by the player |
| `named_gap` | 500 catalog default | World-authored routes provide their actual named values: 300 / 600 / 350 |

`ScoreSession` deliberately retains **display-name repetition identity**, including distinct dynamic spin labels and named gaps. Stable catalog IDs are not falsely described as the current score key. Repeat value is `max(1,floor(base/2^min(previous_repeats,4)))`; non-positive values/blank names reject. The distinct-name multiplier caps at 8. Events cap at 1,000,000 points; combo/base/total scores saturate at 2,147,483,647 rather than overflow. Repetition state clears on bank, bail or reset.

No grind/manual per-frame hold awards exist. Later duration scoring would require its own cap and exploit checks. Existing entry cooldowns, input freshness and physical eligibility prevent held-button repetition. Catalog entries alone cannot enable future tricks.

## Authoritative landing window and event order

The enabled flow is:

1. Actual clean landing or a supported manual release calls `ScoreSession.begin_landing()`. A nonempty combo receives one 0.35-second pending bank. An empty combo creates no timer; duplicate begin calls cannot extend one.
2. Accepted manual/ollie/rail entry emits `combo_link_started` before its award. Main routes it to `continue_combo()`. Main also holds pending banking while actual air, rail or manual is active, so natural support loss can sustain an existing combo without awarding Ollie.
3. `add_trick()` only adds points. Revert adds its award without link-start, leaving the same deadline. A valid manual or ollie within the remaining window continues it; a revert by itself does not.
4. Main calls `score.tick(delta)` during active play. Ground expiry banks exactly once; bank routes through goal evaluation, special charge, audio and save feedback. Bail drops pending score; restart clears it. Pause consumes no deadline time.

Main's physics callback updates an existing pending deadline before the child's new movement input. If that deadline has already expired in the tick, it banks before a later accepted launch starts a new combo. Tests cover inside/outside-window ollies, duplicate events and revert timing; do not silently grant a late input the old combo.

A supported manual release creates a new window for that new ground transition. An already active pending window cannot be stretched by repeated releases/landing signals or repeated trick awards. Natural support loss is handled through actual physical air state, not a fabricated combo-link event.

## Specials, gaps and career boundaries

`SpecialMeter` earns only banked points, at points/25 with a maximum gain of 50 per bank and capacity 100. Main first checks unpaused active play, career unlock (bypassed in free skate) and full charge, then calls `skater.try_special(id)`. Only a `true` result consumes charge. The player rejects unknown IDs, ground/rail/manual state, disabled controls/entries, pause and a second special in the same air segment. The two 0.65-second original visual animations leave velocity/collision unchanged. Landing/capture/reset clears animation; an actual new air segment reopens eligibility.

`GapTracker` snapshots validated world-space definitions, detects ordered swept start/end crossings within 4 seconds and returns named award records. Required airborne travel must be established between triggers and at the end; a final airborne sample alone is insufficient. Wrong order/direction, expired traversal, bad geometry and displacement over 20 m reject. Completion/failure locks until both triggers have been left; first observation establishes position only. Main resets it on bail/restart and routes accepted records to scoring/career. Current authored values are Exchange Air 300, Mind The Gap 600 and Barras Basket Hop 350.

Career accepts only recognized events during an active career run. Ten goals include three banked score levels, a banked combo, letters, cone interaction, Central gap, market items, district visits and a recording. Free skate can exercise mechanics but does not advance career records/unlocks. Unlocks and meter are separate prerequisites. Profile versioning, backup preservation and remapping/settings contracts are documented in [interfaces](../interfaces.md); no runtime network/paid service is involved.

## Bounded run overtime

At 120 seconds main rejects all fresh trick/capture/manual/revert/special entries. An already active air/rail/manual/pending-ground combo has at most **3.0 seconds** of active-play overtime to resolve. Existing manual/rail balance and release continue; no entry can extend the deadline. Clean resolution banks once. Bail or hard deadline loses remaining unbanked score and enters results. Pausing freezes both timers. Restart resets the run clock, overtime, score, charge and transient movement while retaining career data.

Banking is evaluated before the remaining-run timer is processed for that tick. Results are guarded against repeated finalization. A pending clean ground window is eligible to finish in overtime; an indefinitely held rail/manual cannot prevent results.

## Verification and acceptance

Dedicated catalog, combo-resolution, manual/revert, special/gap, takeoff, rail-state, real-game combo, progression and input-profile suites are invoked by `tools/check.sh`; newest counts belong in STATUS and QE-REPORT. Visual capture is separate from headless state/physics verification. The authored rider uses procedural articulated parts; quarter-pipe/vert support, specialized grind animation, human controller feel and final art/hardware acceptance are not implied by these implemented mechanics or passing Linux tests. Continue authorized engineering while keeping those acceptance gates explicit.
