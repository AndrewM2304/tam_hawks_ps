# ADR-009: Core-court place design and an ordered coping encounter

**Status:** Accepted implementation slice under the owner's instruction to continue. **Date:** 17 October 2026. **Owners:** A01 integration; A02 lead design; A05 geometry/art; A06/A07 local encounters; A09 independent QE.

## Authority and scope

Continue the already authorized M06-007/M05-001 place/visual cleanup and M04-009 mechanical-cat prototype. ADR-007/008 and the lead review require architectural islands, graded corners, nearby ledge/bank chains and supported returning routes within the broad core courts. This is the next bounded slice, alongside honest six-area profiling under M06-004. No purchases, paid APIs, new hosted services or public release.

## World contract

- George civic garden/workshop pocket: approximately X−18..18, Z−98..−80 on Y4 ground. Preserve X±22 through routes, the Z−74 crossline and the existing civic stair/bank approaches. New low elements remain at or below 0.8m; this does not introduce vert mechanics.
- Barras western market-hall edge: approximately X50..80, Z−2..17, with an original angled architectural island and useful ledge/bank choices. Preserve the Z18..28 career approach, X86..101 stair landing and X126 outer route. Keep a continuous beginner bypass and readable returns.
- The mechanical-cat workshop stands on a supported 0.65m stage near `(0,4.65,−98)` and faces south. Three separate eastbound six-metre coping segments at Z−91/Y4.60 span X−16→−10, −4→2 and8→14, with six-metre landing/relaunch gaps. Exact IDs are `Grind_Cat_A`, `Grind_Cat_B`, `Grind_Cat_C`. Skating and actor placement must share actual runtime world data. A route line or decorative marker is not physical support evidence.

These are compressed original game-authoring coordinates, not surveyed Glasgow facts or copied classic-level geometry. Materials, foundations, stage setbacks and skyline should make the new elements belong to a place rather than float on a flat test floor.

## Cat's Got the Beat

An original fictional tinkerer, Rae, demonstrates a copper/teal clockwork cat. Accept near the workshop using the existing interaction binding, then capture the three marked coping segments in order within 60 active seconds and a 32m local area centered at `(0,4,−91)`. Offer radius 4.2m/vertical 2.5m; attempt vertical limit 10m. Existing pending combo must resolve before accepting.

Each segment must be admitted by the production grind controller. `Skater.grind_captured(rail_id)` emits once only after a successful capture and installed ride state, before the ordinary grind trick award. Main forwards that ID and the actual player position to `game.cat_encounter.on_grind_capture`. No proximity, visual contact, per-tick rail observation or injected score can advance the sequence.

Intermediate clean banks are intentionally allowed: this is a readable ordered-grind exploration challenge, not a required single extended combo. After the third capture, the next positive actual clean bank inside the area completes once. A duplicate of the most recently accepted marked segment is ignored. A wrong marked segment resets the sequence, with the first segment allowed to restart at 1; unrelated rails are ignored. Bail, timeout or leaving the local area fails the attempt. Wrong-order/progress feedback and steady A/B/C indicators explain the current state. Replay is immediate at the actor; restart/mode changes reset run-local attempts/results.

The real bank earns the win immediately and queues a short original 3.2-second dance. An ordinary return within 10m horizontally/2.5m vertically starts it once only when the actual active camera frustum contains the stage point; the HUD/sign explain returning. There is no forced camera move or second award. Replay/reset clears the queue, and run end cancels queued/playing animation without removing the win. Reduced motion shows a static raised paw and steady progress instead; enabling it mid-dance stops the motion without replay. This corrects the first rendered review, where an immediate dance finished behind the player’s camera. No copied real performer, animal, routine, music, recording or new third-party asset is introduced. Completion adds no score, canonical goal, unlock or profile write. Ordinary skating banks retain their existing career behavior.

## Shared interaction, timing and UI

Objectives retain their interaction priority. Nearby side offers choose the closest eligible actor. Accepting one with no pending combo cancels the other active side attempt, then starts the selected offer, so the HUD has one active challenge. Cancellation is a retryable result, not the end-of-run/audio shutdown operation. Prompts use current input bindings.

Pause freezes attempt clocks and decorative animation. Both side encounters end when career time first reaches zero; the separate existing up-to-three-second normal-combo overtime can still resolve ordinary score, but cannot prolong a side attempt or accept a new one. A bank resolved in the last positive gameplay step remains valid. Free skate retains no career progression.

## Verification and continuation

QE verifies real production captures/order/clean final bank, independent intermediate banks, wrong order/duplicates, bail, boundary/timeout, pause, switching offers, career expiry and save isolation. Traverse each new court return and bank with actual collision/movement; retain the unchanged all-ten-goal route and existing score/takeoff tests. Inspect source-stable actual chase/overview/map/actor/offer/progress/success images. State fixtures and direct-ground-heading idealizations explicitly.

Extend profiling to all six authored checkpoints with real supported riders and bounded rendered samples. Record exact software renderer/workload/source identity; no comparison with historical four-view numbers or target-Mac acceptance is inferred. Real Mac/DualSense, human listening/route discovery/fun and final realistic presentation remain open. Full vert/lip/wallride/traffic/changing-route and the other three encounters remain separate Planned work.

Before the checkpoint ends, run current-source regression, commit/push source and documentation, rebuild/audit native candidates, refresh source/checksum downloads and leave exact continuation tasks. No recurring routine approval is required.
