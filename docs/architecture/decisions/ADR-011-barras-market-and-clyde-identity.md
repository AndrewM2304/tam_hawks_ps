# ADR-011: Recognisable Barras market and Clyde riverfront

**Status:** Accepted under the owner's explicit direction. **Date:** 17 October 2026. **Owners:** A01 integration; A03 Glasgow research; A02 level design; A05 market/landmark production; A06/A07 delivery encounter; A09 independent verification.

The owner wants stronger ties to actual Glasgow landmarks, especially the Barrowland sign, a Barras market that can be skated through, a market-specific challenge and a Clyde that reads as Glasgow's river. This supersedes the earlier Exchange/gallery-first priority. The no-spend rule and all existing career/save contracts remain.

## Market and landmark

Inspect actual photographs and dated sources before modelling. Record observed sign spelling, silhouette, market entrances and river architecture in the research dossier. Author original geometry, lettering, materials and props; source images remain inspection material outside the game. The layout is a deliberately compressed interpretation rather than a surveyed reconstruction.

Replace the generic venue panel with the reference-derived singular Barrowland lettering, outlined tubes, stars, rays and gridded frontage. Reconfigure the four stalls into opposing rows at X108/120, Z2/13, leaving a clear X110..118 through aisle. Side canopies have an open centre sightline toward the landmark. Red market arches, continuous bays and varied merchandise establish a market enclosure. Preserve X103 inner and X126 outer routes, the Z18..28 career corridor, X86..101 stair/runout, all collections and the existing repair-hall bank loop. No compulsory unsupported skating mechanic is introduced.

## Gull-Proof Delivery — M04-010

Add the already-planned optional encounter under stable ID `gull_proof_delivery`, without adding a canonical career goal, reward or save field. Pickup is at `(105,1.5,-26)`; delivery at `(105,0,20)` stays west of the existing X114 rail. Accept with a settled combo and deliver within 60 active seconds inside X78..131/Z-38..30.

Require a real Manual entry followed by the existing `market_hop` gap and a positive clean bank in the same line. Main forwards only admitted skater trick events and actual GapTracker awards. An early bank clears incomplete line evidence while allowing another attempt within the deadline. The route then uses either the covered aisle gates `(114,0,-5) → (114,0,7) → (114,0,18)` or west lane gates `(103,0,-5) → (103,0,7) → (103,0,18)`, followed by physical arrival at delivery. The first gate commits the branch; gaps arm route progress, while completion also requires the qualifying bank. Each gate has a 2.2m radius and grounded-height tolerance; arrival radius is 2.6m. No callback-only, timer-only or proximity-only completion.

A bail, timeout, area exit or career expiry ends the attempt and returns the carried parcel. Pause freezes state. Restart/mode change resets it, retries are available, and accepting another side challenge cancels the active one. Objectives retain interaction priority and the closest of the three offers is selected. Steady numbered noncolliding world markers and a HUD bearing/distance cue expose the route, including the turn back from the fast stair landing to either entry. These cues observe configured positions without changing admission or scoring. An original courier parcel/bag follows the rider presentation. A bounded gull takes a spare parcel at delivery after a successful bank/arrival; its response waits for a nearby visible audience and has a static reduced-motion alternative. Original fictional people, props and animation require no paid asset, recording or service.

## Clyde

Use inspected South Portland Street suspension-bridge and Carlton Place riverfront features to replace generic river scenery. Keep the existing safe bridge at X-98, its 8m deck/colliding side rails and all approach surfaces. New sandstone portals, chain bundles and lattice are art-only, outside existing rail clearances; overhead opening stays at least 4.5m above board contact. Join the south backdrop into a convincing pale terrace with roofline/chimneys. OutdoorRoutes owns three matching wall/foundation collider footprints behind the yard, replacing the old five generic building bodies; the art helper remains collision-free and the facade gaps stay open. Retain the broken-bridge transfer at X35, water Y-2, quay approaches, recovery, south-yard exits and low hip. Do not confuse a static landmark treatment with new bridge physics or a surveyed street map.

## Verification and continuity

Independently drive both delivery branches with actual Manual/gap/bank/arrival, test negatives and lifecycle, and preserve the all-ten-goal route and both existing side encounters. Inspect actual sign/market/chase/river views and a real earned delivery response. Run the ordinary suite from frozen inputs, bind images and packages to source hashes, and rebuild local downloads. Keep the earlier bin-cat checkpoint historical after source changes. The same 75 full task records retain unfinished art, authentic frontage, human fun/listening and real Mac/controller/performance gates.
