# ADR-007: Author Glasgow skating routes with terrain and an adult rider

**Status:** Accepted owner direction; implementation and verification in progress. **Date:** 17 October 2026. **Owners:** A01/A02, with A05 world/character, A08 navigation and A09 physical verification.

## Context and authority

The owner explicitly requested a substantial level redesign: recognisable Glasgow-inspired places and varied elevation, streets that skate like connected routes, a grindable fountain, a Clyde jump, hilly grassy Kelvingrove-inspired terrain, and a believable adult skater. The prior flat connected courts and stylized rider do not satisfy that direction. The reference is the enjoyable line-building of arcade skateboarding games; it does not authorize copying another game's map, artwork, branding or animations.

This request authorizes changes to playable terrain, route geometry and landmark placement. For this tracked redesign it supersedes the art-only collision-preservation language in ART_DIRECTION's delivery step 3, M05-001 and older handoffs. It does not waive collision, scoring, save or camera correctness. ADR-005's title, final visual ambition and mandatory M06-007 acceptance gate remain in force. No routine approval is needed before implementing the already requested changes.

## Decision

1. Build one original, geographically compressed composite level with **four existing career districts and two new exploration areas**. Preserve Royal Exchange, George Square, Central Station and the Barras; add Clyde Quays south of the core and a Kelvingrove-inspired park to the northwest. Relative positions support legible routes and do not assert real-world walking distances, survey accuracy or exact street adjacency.
2. Author terrain before dressing it: distinct supported terraces, graded streets and continuous returns; a curved fountain coping line; a physically clearable Clyde bridge opening with a safe alternative crossing; paved park climbs and descents embedded in visibly hilly grass. The [design brief](../../levels/DESIGN-BRIEF.md) records the agreed anchors, route criteria and deliberately invented features.
3. Reuse the existing production controller, rail geometry/riding, named-gap tracking, score banking, 0.35-second combo window and protected save model. Terrain queries, route polylines, checkpoints and hazard recovery become explicit world data consumed by gameplay, navigation and tests. Unsupported ground must be represented explicitly; water does not become an invisible skateable floor.
4. Preserve all **ten career goal IDs**, four career district IDs, collectible/event IDs, earned unlock IDs and save schema version 1. Moving physical markers is permitted if their identifiers and attainable meaning survive. `clyde` and `kelvingrove` are navigation/exploration region IDs, not two extra requirements for `across_toon`. A new optional Clyde gap can score through existing gap rules without silently expanding the career. Free skate continues to award no career progress or records.
5. Add a readable **CITY MAP & ROUTES** page using authored runtime route/checkpoint data, rider position/heading, elevation cues and distinct jump links. Reach it from pause/goals with existing navigation actions; do not consume another gameplay binding.
6. Replace childlike/cartoon anatomical cues with a visibly adult rider at coherent real-world scale. Preserve the board/contact origin, collision behavior, gameplay timing and tested rig/pose interfaces. Compatible free anatomical assets may be adapted only after source/licence inspection and provenance recording. Adult proportions alone do not certify convincing character art or animation.

## Reference and spending boundary

Landmark identity, masonry rhythm, skyline, station/market character and park/river landscape should read as Glasgow-inspired through authored form and materials. The fountain location, shortened river opening, elevated courts, park position and connecting streets are deliberate skating adaptations. The level is **not a current geographic survey**, a reconstructed proprietary game map or a copied Street View scene.

The existing reference dossier still records blocked official/map access and historical address leads. Uninspected source pages cannot substantiate current shop occupants, frontage order, topography or bridge dimensions. Continue independent original design while M03-006's reference work remains open; record later observations with source/date/confidence rather than relabelling the composite as surveyed. Reference imagery and map tiles are not bundled assets.

Zero additional spend remains binding: no purchases, paid APIs/generation, billing, hosted CI, paid signing, provisioned services or unattended agents. Use installed tools and original or explicitly compatible free assets; preserve required notices. Ordinary work occurs within the authorized session and its existing credits.

## Verification and consequences

The previous 778-check cleanup, 69.52-second automated career route, 1,085.69 m circuit and 1080p software-render baseline describe the **previous geometry**. They remain historical evidence, not a pass for this redesign. Recheck actual slope motion, terrace seams, fountain acquisition/curved travel/exit, Clyde takeoff/landing/miss recovery and the park climb/return. Complete the same ten career goals through actual physics within an ordinary 120-second run; explore all six areas separately. Direct automated ground-heading control must remain disclosed as an idealization.

Capture real chase views, overhead topology, the production map page and adult rider motion, with source/fixture details. Recompute rendered cost after the new terrain and assets settle. Automated tests and Linux software rendering cannot certify controller enjoyment, target-Mac 60 fps, real listening or final visual realism. Those acceptance gates remain open while independent implementation continues.

The eight durable work groups are M03-008–M03-012, M05-006, M06-008 and M07-006 in [BACKLOG](../../planning/BACKLOG.md). Update their implementation/evidence status rather than declaring the original roadmap complete. A01 maintains STATUS, ACTIVE_WORK and the final runtime interfaces; if the session ends, retain exact unfinished route/art defects and reproduction commands.
