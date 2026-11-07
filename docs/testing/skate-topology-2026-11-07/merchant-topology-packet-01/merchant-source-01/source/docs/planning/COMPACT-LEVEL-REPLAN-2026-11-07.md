# Merchant District: medium urban replan — 7 November 2026

**The latest plan is a 200 × 160 m Glasgow neighbourhood inspired by the organisation of San Francisco’s skating levels. The earlier 112 × 88 m, three-court Warehouse sketch is superseded and must not be implemented.** Keep the wider city feel, hills, intersections, rooftops and exploration, while replacing the old disconnected geographical islands and empty approaches with adjacent city blocks and short skating choices.

[Open the scaled interactive plan](COMPACT-LEVEL-REPLAN-2026-11-07.html), [standalone SVG](COMPACT-LEVEL-REPLAN-2026-11-07.svg), or [exact geometry/career JSON](COMPACT-LEVEL-REPLAN-2026-11-07.json). These show proposed geometry and flow, **not native playback, a proved combo or final art**. A private playable prototype is the next implementation step; no actual world replacement has occurred.

## Latest section-first correction

The owner has now asked us to sketch the overall map and each section from the desired skating experience, and added **Los Angeles and London** to the city-level references. The 200 × 160 m envelope remains a provisional medium-city estimate. The earlier global hill and complete old 40 × 30 m basin are **parts-library experiments, not approved requirements**. A new court can use different shared constructors or omit old features entirely. The old long skatepark climb must not return under a new name.

The original concept board and the following section experiences will guide the playable layout. Exact street elevations, portals and building footprints must be reconciled with that chosen sketch before native layout acceptance. Previously listed basin dimensions and portal arithmetic below remain the scope of the earlier exploratory arrangement only.

| Section | Intended view and skating experience | Different lines and useful return |
| --- | --- | --- |
| Market Cross | A warm stone intersection with three visible choices from clear spawn paving; approximately 38 × 34 m. | Bank → curved ledge → small stair gap → loading frontage; or kerb → finite wall → Wallie into a different street. Corner banks bring both back to the square. |
| Terraced High Street | Three adjoining hill landings, approximately 54 × 44 m across Y4–12. The climb itself is skateable, with no destination promenade. | Graded rail → stairs → retaining wall → upper ledge; or side bank → low roof cut → descent. An upper quarter and middle alley give different downhill returns. |
| Loading Works | A solid industrial block, delivery deck and genuine ground passage, approximately 42 × 36 m. | Bank → bent ledge → short channel gap → finite wall return; or lower rail → stairs → underpass Manual. Both reconnect with Market rather than ending behind the building. |
| Foundry Court | Approximately 30 × 26 m of transition embedded in the lower streets. Its exact form is designed first; two old bowls are not mandatory. | Street rail → bank → hip → opposing lip → arcade ledge; or low wall → corner quarter → second street opening. Two supported openings and a grounded bypass prevent a cul-de-sac. |
| Roof and Arcade Cuts | Readable roof, awning and street layers crossing each other, approximately 52 × 30 m. | Short roof gap → visible awning → wall → street rail; or lower ledge → bank → cross-street stairs. No blind eight-metre fall or cramped upper trick ceiling. |

Useful choices are targeted 7–16 m apart depending on the section; these are **design targets**, not measured events. Root is preparing original illustrated masterplan and section concepts. The first private source preserves generic world/API work but its complete old-basin experiment is paused until concept alignment. No source-only arrow, sketch or reference clip certifies a single-combo circuit.

## Latest owner decision and scale

The owner first authorised cutting/shrinking the sprawling map, then clarified that Warehouse was too small and asked us to think of San Francisco. This supersedes both the tiny enclosed-level sketch and the assumption that six broad geographical areas must remain the default. The new default is **Merchant District** (`merchant_neighbourhood_v1`). The full current world remains separately selectable as **City Tour** (`glasgow_legacy_v1`), loaded lazily; its saved progress and old content are preserved.

The proposed 200 × 160 m envelope is our own design estimate, **not a measurement of either Tony Hawk level**. It is about 3.25 times the tiny sketch’s area. At an illustrative 8 m/s, 200 m takes 25 seconds before turns/tricks. The longer street runs must offer real rail, gap, grade or branch choices every 12–16 m; they cannot repeat the old 156 m empty quay or 103 m access promenade. Reference distance is not measured native opportunity time.

The exact four-metre planning-grid partition is 32,000 m²: **13,152 m² solid building footprints and 18,848 m² reserved streets, local playing spaces and supported shoulders; zero unassigned exterior cells.** Conservative clearance reservations keep whole building cells outside road corridors. This plan-grid calculation does not prove native collision, camera clearance or that every reserved flat is already interesting.

## What changes spatially

- A looping urban street network wraps actual solid building blocks. Streets climb from the lower district at Y0 to a hilltop around Y12, with short intersections, backstreet cuts and different uphill/downhill returns.
- **Upper Steps** concentrates terraces, stairs, a handrail, a quarter and roof access. These are adjacent to the street rather than at the end of a separate scenic journey.
- **Market Cross** is a raised/sloping central square with a fountain/curved ledge, banked approaches and three visibly different exits. It is an arrival and branching space, not a huge blank transport plaza.
- **Warehouse Row** combines a loading forecourt, the existing bent hall ledge, a real loading drop and elevated open-sky routes. Roof → awning → wall → street gives a staged descent; there is no claimed safe eight-metre blind fall.
- **Foundry Court** is now designed from the desired transition/street experience. The earlier complete 40 × 30 m basin arrangement below is an optional experiment; its reuse and size are not requirements.

The map stays Glasgow. San Francisco informs organisation, grades and layered connections; no franchise arrangement, landmark, screenshot, texture, clip or layout is bundled.

## Three proposed returning circuits

The coloured paths in the diagram are **macro flow proposals**, not physically executed one-combo traces. Long macro legs need actual authored intermediate choices and must be revised if real input cannot link them.

| Circuit | Different actions and return | Remaining evidence |
| --- | --- | --- |
| Hills / Market | Upper graded rail → stairs/gap → fountain or bank → west wall/ledge → switchback/quarter return | Native grades, short opportunity intervals, uphill speed management, meaningful reverse choices and one bank where advertised. |
| Loading / Roof | Market approach → loading ledge → upper access → roof gap → lower awning → finite wallride/Wallie → street return | Real elevated support, launch/landing speed, headroom, exact finite contacts, score and native moving proof. |
| Basin / Arcade | Low rail/gap → entry bank → bowl/hip → lower arcade wall/ledge → uphill return to Market | Actual doorway cut, bowl port/void preservation, supported return and deliberate misses, then a complete mapped-input circuit. |

Each primary landmark pocket needs two genuinely different returnable lines and a grounded main bypass. Every long street must have a continuous skateable frontage plus useful branching/transfer opportunities; a long grind or repeated flatland pop alone does not establish varied spatial design. Maintain distinct novice 4–6 m/s, flow 7–9 m/s and expert 10–12 m/s options without changing physics, the Manual minimum, native tolerances or score deadlines.

## Basin portal and headroom: explicit geometry, not arrows through walls

The unit-scale basin is rotated π at `(54,0,49)`, giving bounds **X34…74 / Z34…64**. Its lower street occupies X34…74 / Z34…45.5 at Y−1.5. The existing 4.5 m entry faces the west street around `(34,0,44)` and retains the real ten-metre beginner bank.

The proposed north entry at `(58,−1.5,34)` is **new required geometry**: a six-metre opening in the rotated retaining wall plus a matching eight-metre bank from road datum Y1 at Z26 to lower floor Y−1.5 at Z34. Split/crop the unsupported SouthRim guide interval, update native/display/support/audio together, and preserve the real bowl/port voids. It is not the blocked portal of the superseded tiny sketch. The adjoining urban street provides access; we do not pretend an eight-metre grade spans a distant warehouse court.

Bowl and elevated roof lines are open to the sky. Any canopy is limited to explicitly defined ground lanes with full body, board, sole and trick clearance. A Y2.2 mezzanine beneath a Y4.2 underside is **not** approved trick headroom. Upper routes need an actual opening or higher ceiling; supported floor queries must choose the correct level below/near the actual player height, rather than returning a roof above a lower rider.

## Source-compatible world and save contract

Root owns Main/HUD/FeatureHub selection and ADR-035. The private new world will implement the current world interface, including the pending native gap-destination getter, plus `get_level_manifest()` and `get_activity_layout()`. Current source has 21 old custom public methods; the gap-finish addition makes 22, and the two data getters make a 24-method provider contract. Do not replace methods with hardcoded old coordinates or uniformly scale the current city.

`level_catalog.gd`, owned by the world-integration specialist, is the canonical source of world IDs, script paths, labels and career definitions. The world returns the catalog’s career data instead of maintaining another goal list. FeatureHub must use explicit level activity layout and guard omitted optional cart/lap/cone-water objects; an empty route array cannot fix its old unconditional calls.

The new book uses per-level progress. Preserve old `career.json` and migrate/read it once as City Tour’s domain without overwriting it. Merchant District has ten **new** goal IDs, separate completion/bests, and accepted events listed exactly in JSON: three score thresholds, one combo, five letters, one cone interaction, one named roof gap, three market items, four local zones and a secret recording. Never mark a new compact achievement complete because an old geographical tour was finished. Settings, cosmetics, earned unlocks and personal Music behaviour remain global and unchanged.

The old 67 routes, eight gap IDs, missions, train/pond/cable/green, and fixed-coordinate regression fixtures remain City Tour’s content. They are not silently advertised as present at new default coordinates. Old tests explicitly selecting City Tour cannot substitute for new normal-default Main acceptance.

## Online reference evidence

These are distinct references; no franchise physical dimensions were inferred:

- **THPS1 Streets (1999):** the [original publisher manual](https://db.hfsplay.fr/files/2020/06/20/Tony_Hawks_Pro_Skater_-_1999_-_Activision_igSnFrK.pdf) identifies urban skating spots, hills and rails. The [original Planet Tony Hawk guide](https://planettonyhawk.gamespy.com/View3650.html?id=9&view=thps_faqs_guides.Detail) describes central street skating and a multi-stage elevated route. These support a city-scale network, not a measured metre footprint.
- **Streets in THPS1+2:** the [Push Square guide](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-streets-all-park-goals-gaps-and-challenges) describes slopes, the plaza/fountain, building ledges, wall access and rooftop progression. This is the remake’s player guide, not evidence that the 1999 game had modern Manual mechanics.
- **THPS4 San Francisco (2002):** the [original-game walkthrough](https://www.tonyhawkguide.com/pro-skater-4/san-francisco.html) describes courtyard/curved-step skating, quarter-to-roof transfers, roof gaps, wires and wall grinds crossing intersections. The inference is to join lower, upper and returning paths around adjacent buildings.
- Root independently inspected the fan Streets top-down reference and twelve sampled Warehouse video frames; the research lead owns those exact visual observations. LD inspected the linked source text and does **not** claim to have watched San Francisco gameplay from text descriptions. The [root-owned reference record](../research/SAN-FRANCISCO-LINE-REFERENCE-2026-11-07.md) preserves its actual inspection scope. No franchise media is committed.

## Additional city references: Los Angeles and London

The [original THPS3 Los Angeles guide](https://www.tonyhawkguide.com/pro-skater-3/los-angeles.html) describes quarter-to-roof access, a slope/roof/elevated-road progression, an ascending-rail jump to a descending rail, and wallride-to-ledge access. Our transferable lesson is to let a street obstacle open a higher route with another usable arrival, rather than treating the roof as a remote reward. This is a text observation from the original-game guide; no franchise dimensions or footage timings are inferred.

The [original THPS4 London PS2/GC/Xbox guide](https://planettonyhawk.gamespy.com/Viewd033.html?id=6&view=thps4_faqs_guides.Detail) describes a ledge → Manual → quarter → upper ledge → wire chain, two breaks in a returning high light line, and a Southbank pocket combining ledges, rails and quarters. Our inference is to give the street both a lower branching obstacle pocket and a broken upper return, with short Manual links between different features. The PS1 version and the 2025 remake are separate references; this source does not establish their geometry.

These lessons alter the section concepts rather than adding more geographic districts. They support layered crossings, shared arrivals, close local choices and useful returns. They do not justify copying either map or claim that the proposed routes work with our native physics.

## Private playable build, budget and acceptance

The next deliverable is a **private playable native graybox**, not another inventory document: actual Skater and unchanged controls, continuous graded native terrain, explicit solid blocks/streets, selected steps, rails, transitions and street/roof connections following the chosen section concepts. It will expose the world contract for root’s lazy selection and profile integration. Prototype art is labelled; final route-facing architecture/material work follows native topology proof.

Use existing concrete, brick, paving, steel/slate and rider assets. Target zero new texture bytes or shader types, one instantiated world, and lower resident body/shape/triangle/draw/memory cost than the current broad scene. The provisional ceilings in JSON are targets, not measured results. Actual default Main, native landings/catches, misses, consecutive physical paths, score banks, moving views, cost and MacBook Air M5 each need their own current evidence.

The old six-arena L1 geography and tiny three-court draft are superseded **without being passed**. The proposed medium neighbourhood retains the ambition of distinct returned lines and three connected circuits. Current focused134/0 and the full03 run retain their own unchanged-source scope; none proves this new layout.
