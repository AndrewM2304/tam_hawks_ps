# Merchant District: Glasgow neighbourhood replan — 7 November 2026

**Current direction: a medium, dense Glasgow neighbourhood with four adjoining skating spaces—High Street Steps, Market Cross, Depot and Roofs, and Foundry Bowls.** The owner likes the original concept sketches and asks that the result still feels like Glasgow. Streets/San Francisco, Los Angeles and London inform connected city skating; Glasgow supplies the architecture and identity. The earlier 112 × 88 m Warehouse plan, mandatory old 40 × 30 m skatepark reuse and long scenic climb are superseded.

The concept direction is endorsed. **The native layout, routes, art, full combos and target performance remain provisional.** The first private geometry runs expose a real stair-access defect that is being repaired; they do not establish a finished map.

[Interactive scaled construction plan](COMPACT-LEVEL-REPLAN-2026-11-07.html) · [SVG](COMPACT-LEVEL-REPLAN-2026-11-07.svg) · [machine-readable geometry and evidence](COMPACT-LEVEL-REPLAN-2026-11-07.json). Root preserves the original masterplan and four-section concepts under `docs/levels/MERCHANT-DISTRICT-CONCEPTS-2026-11-07`. [ADR-035](../architecture/decisions/ADR-035-san-francisco-scale-neighbourhood.md) records the authorised default-world change.

## What the owner has selected

The new default is **Merchant District** (`merchant_neighbourhood_v1`). The old broad world becomes separately selectable **City Tour** (`glasgow_legacy_v1`), retaining its content and progress. Only the selected world is instantiated.

The approximately **200 × 160 m** envelope is an original planning estimate, not a measurement of a Tony Hawk level. Buildings occupy the unused outer footprint; it is not a large paved rectangle. There is no 156 m empty quay, 103 m approach promenade or distant sightseeing district in the new default flow. The hill itself contains lines and returns rather than transporting the player to a skatepark.

Design from the desired skating experience first. Existing transition constructors, material maps and architecture are a parts library, not an obligation to preserve the old facility or its geography. Keep rider, board, stair and transition dimensions at real unit scale.

## Four adjoining spaces

| Space | Visual identity and skating purpose | Private construction targets |
| --- | --- | --- |
| **High Street Steps** | Sandstone tenements, sash windows, cornices, shop bays and tiled closes frame three overlapping stair terraces. Banked pavement, rails and retaining walls offer different uphill/downhill choices. | Local street rises Y4–12; three stair/handrail sets; upper quarter with its complete side-access apron; middle close and elevated cut. No global scenic hill. |
| **Market Cross** | A compact civic/shop intersection with seating ledges, a low manual island, short stair rail and corner bank. Clear spawn paving looks toward different lines. | Street Y4; low ledges, optional stair access and a separate four-metre flat ground corridor. Native camera framing and exact first-choice distances still need review. |
| **Depot and Roofs** | Brick goods buildings, original Merchant Foundry lettering and railway-arch treatment explain loading decks, roofs and a genuine lower passage. | Ground Y4, dock Y6, roof Y10; two real roof masses leave a two-metre channel. Bridge top Y9/underside Y8.5 gives 4.5 m ground clearance. Upper tricks remain open sky. |
| **Foundry Bowls** | A transition court is embedded directly in the streets, overlooked by brick fronts and shop/market edges. Both street entrances lead somewhere useful. | New arrangement of individual deep/shallow transition parts and a hip; rim Y4, lower entry street Y2.5, bowl floors Y1/Y2.5. The complete old skatepark is not instantiated. |

These dimensions translate the sketches into a testable construction proposal. They are not measurements inferred from painted perspective. Final facade details must use the existing Glasgow research; invented shop names are original composites, not verified premises at a real address. Keep Scottish street-sign cues and useful recognisable architecture without adding distant attractions.

## Runs before decoration

The current benchmark is **two genuinely different returnable lines in each of the four spaces**, plus **three closed cross-neighbourhood circuits** and supported novice bypasses. That is eight local line targets. The previous six-area and tiny three-court benchmarks are superseded **without being passed**.

| Space | First line target | Different second line target |
| --- | --- | --- |
| High Street | Graded handrail → stairs/gap → retaining-wall ride → Market ledge. | Side terrace → elevated close → roof cut, with a different downhill/ground return. |
| Market | Seating ledge → Manual island → short stair rail → corner bank. | Corner bank → depot rail → loading stairs → dock edge → ground return. |
| Depot | Upper close → roof gap → bridge rail → staged wall/street return. | Dock ledge → stair rail → underpass Manual/rail → Foundry bank. |
| Foundry | Entry bank → deep lip → hip → street-deck ledge → west exit. | West entry → lower rail → shallow turn → north exit → underpass connection. |

The three macro targets are a ground-street circuit, a roof/loading circuit and a Foundry/Market circuit. **None is a completed native circuit or a demonstrated single combo.** The roof route currently needs a genuine authored/proved return; closing a coloured polyline does not provide it. The west uphill return also needs real intermediate contacts; it cannot be sold as a 38–43 m unpowered uphill Manual.

At an illustrative flow speed of 8 m/s, the target is another meaningful choice in **1.5–2 seconds / 12–16 metres**. Actual input timing must replace this reference estimate. A novice at 4 m/s can coast only about eight metres in a flat Manual before the unchanged 2 m/s minimum; longer links require a different feature or a clearly labelled faster line. Grounded travel can be a bypass without being advertised as a combo. Reversed duplicates and repeated flatland pops do not establish varied lines.

## Real floors, openings and landings

The depot has a real lower passage and separate elevated support. Floor queries must select support below/near the caller, not promote a grounded rider onto the overhead bridge. A two-metre roof channel is a visible native void above the lower ground. No blind eight-metre fall or two-metre-high upper trick ceiling is approved.

The Foundry court uses actual clipped deck polygons around each transition and port. Its north and west banks meet the lower street, while the original bowl floors remain excavated. No upper terrain plane may fill the bowls, bridge a port or secretly catch a missed roof jump. Native collision, display, support queries, guides and audio must agree.

The upper close requires an actual opening in intervening building footprints; a slab cannot pass through an unchanged solid building. The quarter's full face/deck/side-roll-in envelope needs a supported apron, not merely a correct centre height. Main grounded bypasses remain at least four metres clear, including shoulders and camera runout.

## Current private evidence and open defect

The first concept-led source is `.local/compact-level-replan/graybox/compact_world.gd`; its copied native project is separate from actual main and its imported payloads are copied by value. It exposes the 24-method world contract. No new world has been installed into actual gameplay.

- Native epoch02: **26 passed / 1 failed**, clean engine execution and 722 unchanged source/cache inputs. It sampled actual ground, both bowl floors, clipped deck, roof slabs/gap, two entrance banks, 4.5 m underpass clearance and 33 unique guides. Initial inventory: 204 static bodies, 204 shapes, 122,434 static triangles.
- The actual mapped Ollie was airborne at physics84–116 and landed at117 on Market paving. Later, a stair-access bank crossed the spawn path and terminated 0.8 m above the paving at Z0. Departure195–196 exposed a real unsupported re-entry.
- Epoch04: **27/0 limited component/smoke** with actual input/trick timestamps and a coast tail. The tail observed the later landing; it **does not admit the flawed bypass**. Epoch03's observer signal-arity error is also preserved separately.
- The private repair moves the optional bank crosswise west of the real upper stair landing, keeps the east four-metre lane flat, and expands middle/lower terrain pads across complete feature envelopes. This repair awaits fresh edge/shoulder and no-jump native verification. The playable terrain remains a one-metre mesh; curved transition resolution is unchanged.

These subsets do not prove full figure clearance, final art, current moving presentation, smoothness at all speeds, complete score receipts or target performance. Keep every rejected epoch and source hash; do not relabel the old failure as a harmless hop.

## Runtime and save compatibility

Root owns Main/HUD/FeatureHub selection and ADR-035. Current City Tour has 22 custom world methods after the native gap-destination merge. The new provider preserves those and adds `get_level_manifest()` and `get_activity_layout()`—**24 public methods**. `get_gap_grind_destinations()` returns a **Dictionary**; Merchant initially returns `{}` and retains strict ordinary gap policy.

The canonical metadata-only `level_catalog.gd` supplies IDs, labels, world paths and career definitions without loading either world. The new world returns `Catalog.career(DEFAULT_LEVEL)`, rather than another handwritten runtime goal list. Explicit activity layouts prevent old-coordinate optional actors from being built; omitted callbacks are guarded. Letter markers keep namespaced IDs and separate H/A/W/K/S labels.

Use a per-level versioned career book at `user://career-v2.json`. Preserve the existing `career.json`; read/migrate it once into City Tour's domain without overwriting it. Merchant has ten new goal IDs and separate completion/bests: three score goals, one combo, five letters, cone interaction, roof gap, three market items, four local zones and secret recording. Old clears never become new map achievements. Shared settings, cosmetics, unlocks and personal Music behaviour remain global and isolated as before.

City Tour retains its old67 HUD routes, eight score-gap IDs, missions, train/pond/cable/green content and fixed-coordinate fixtures. Those old tests must explicitly select City Tour; they do not establish new default-world completion.

## Reference scope

- **THPS1 Streets:** the [publisher manual](https://db.hfsplay.fr/files/2020/06/20/Tony_Hawks_Pro_Skater_-_1999_-_Activision_igSnFrK.pdf) and [original guide](https://planettonyhawk.gamespy.com/View3650.html?id=9&view=thps_faqs_guides.Detail) support urban hills, rails, central street skating and elevated cuts. The [Streets remake guide](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-streets-all-park-goals-gaps-and-challenges) is separately labelled; modern Manual mechanics are not attributed to the1999 game.
- **THPS4 San Francisco:** the [original-game guide](https://www.tonyhawkguide.com/pro-skater-4/san-francisco.html) describes courtyard steps, quarter-to-roof transfers, roof gaps, wires and wall connections. Root inspected the original Streets fan map and separately records its actual image observations.
- **THPS3 Los Angeles:** the [original-game guide](https://www.tonyhawkguide.com/pro-skater-3/los-angeles.html) describes quarter-to-roof access, ascending-rail jumps to descending rails and a slope/roof/elevated-road progression. The inference is to share street and roof arrivals rather than isolate elevated rewards.
- **THPS4 London:** the [PS2/GC/Xbox guide](https://planettonyhawk.gamespy.com/Viewd033.html?id=6&view=thps4_faqs_guides.Detail) describes ledge → Manual → quarter → upper ledge → wire links, a broken upper return and a concentrated Southbank obstacle pocket. Keep the PS1 version and2025 remake distinct.

LD opened these text sources; it does not claim to have watched their gameplay frames. Root's [reference record](../research/SAN-FRANCISCO-LINE-REFERENCE-2026-11-07.md) preserves the actual inspected map/video scope. The Warehouse sample is edited footage with timer resets, not a continuous combo. No franchise images, layouts or assets are bundled in the game.

## Budget and next gates

Reuse existing licensed material maps, rider and constructors. Add no photography, shader family or second live world. The provisional static ceiling of200k triangles is a design budget, not a reason to degrade floor normals/contact. Measure the actual facade delta; retain finer playable terrain or justify a modest budget revision if needed. Texture/memory/draw cost, smooth current moving views and the owner's MacBook Air M5 remain separately measured gates.

Next: verify the repaired native bypass and every section's floor/portal envelope; inspect the Glasgow architecture prototype; assemble the private new Main/profile/world scene; then execute the eight different returned lines and three continuous circuits with actual input, physical-step intervals, meaningful contacts and independently recomputed banks. Continue iterating failures. Concept approval and documentation checkpoints are not completion.
