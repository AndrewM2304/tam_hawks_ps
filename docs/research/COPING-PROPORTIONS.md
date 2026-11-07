# Bowl coping proportions — 7 November 2026

Owner: LD; independent source/arithmetic review: QE. This is a construction-reference
and **private geometry proposal**, not native riding, visual or whole-game acceptance.
Root requested the review while investigating FID-D014. The construction evidence
is independent of whether the changed profile fixes that contact defect.

The inherited shared constructors use a 45 mm pipe radius with its centre 25 mm
above the concrete deck. They therefore expose a crown **70 mm above the deck**
and a front face **45 mm into the vertical transition**. No inspected primary
source supports that arrangement as ordinary steel skate-bowl coping. A deliberately
oversized obstacle could use different proportions, but these constructors describe
ordinary quarter-pipes, bowls, a half-pipe and a spine rather than such an obstacle.

## Primary references and their limits

All references were inspected on 7 November 2026. Numerical statements below are
paraphrases; no source plans, photographs or PDF pages are bundled with the game.

| Reference | Located evidence | Interpretation for this game |
| --- | --- | --- |
| [City of Edmonton, Playspaces and Wheeled Sport Facility Design and Construction Standard](https://www.edmonton.ca/sites/default/files/public-files/Playspaces_and_Wheeled_Sport_Facility_Design_and_Construction_Standard.pdf), version 03, 11 August 2022, Appendix E, PDF p42 / printed p41, “Copings and Profile Edges” | Maximum 12 mm projection from the platform/riding surface; 40–80 mm pipe outside diameter; at least 3 mm wall thickness. | A municipal construction comparator, **not Glasgow law or a universal current rule**. The inherited 90 mm OD is above its diameter range; 70 mm deck and 45 mm transition projection are substantially above its projection limit. |
| [The Skatepark Project, Skatepark Best Practices Guide 4.0](https://skatepark.org/s/Best-Practices-Guide-40.pdf), Appendix A, p72, construction/material tolerances | Average coping/round-rail outside diameter 2–2.5 inches (50.8–63.5 mm). The illustration suggests 1/8–1/4 inch reveal (3.175–6.35 mm), allowing interpretation. | Primary skatepark-development advice. It establishes a plausible scale, not a mandatory specification. This is a retrieved edition, not a claim of a new 2026 standard. |
| [Regional District of Nanaimo, Huxley Community Park Skatepark Construction](https://www.rdn.ca/sites/default/files/2021-03/21-027%20Huxley%20Community%20Park%20Skatepark%20Construction.pdf), New Line Skateparks, 2021 tender, drawing SK-007 revision E “STEEL”, PDF p197 | Typical round coping detail identifies 73 mm pipe, transition-face reveal 6 mm minimum / 9 mm maximum and top reveal 9 mm typical. | An actual constructed-project detail, not a universal dimension. The nominal pipe-size label and actual 73 mm diameter must not be treated as the same exact unit conversion. The PDF's unrelated first 60 mm text occurrence concerns fencing. |
| [Gnarchitect, Stokeside Private Skate Bowl](https://thegnarchitect.com/stokeside-skate-bowl/) | The designer describes 60 mm outside diameter coping, 12 mm up and 10 mm out. The same account discusses dimensions as rider preferences. | Direct precedent for the exact private candidate. It differs from the smaller reveals in the other references; that variation is explicit rather than averaged away. |
| [The Skatepark Project, Ensuring Quality](https://publicskateparkguide.org/design-and-construction/ensuring-quality/) | Coping exposure and the orientation/layout of built details affect how an obstacle works. | Supports treating exposure as a skating characteristic. It supplies no extra quantitative limit. |

The PDF bytes and extracted texts remain in ignored `.local/coping-research/` for
inspection. Their actual download receipts and hashes are preserved in
[coping-source-receipts.json](coping-source-receipts.json). QE independently verified
the three PDF hashes and the Edmonton, TSP and Gnarchitect numerical evidence.
Do not cite an inaccessible secondary mirror as an additional verified standard.

## Concrete private profile and constructor axes

The selected prototype follows the documented Stokeside dimensions: **60 mm OD,
12 mm deck reveal and 10 mm transition reveal**. It is a gameplay/realism choice
within the observed variation, not a claim that one profile suits every skater.

Let pipe radius `r=0.030 m`, deck reveal `u=0.012 m` and inward reveal `f=0.010 m`.
The pipe centre is `u-r=-0.018 m` below the deck and `r-f=0.020 m` behind the
concrete's vertical tangent. The highest crown is 12 mm above the deck and 20 mm
outward from that tangent. Pipe diameter is separate from the exposed height.

| Actual constructor | Concrete lip | Pipe centre | Crown / published guide datum |
| --- | --- | --- | --- |
| `transition_feature.gd`, local approach along −Z | `(lateral, radius, −radius)`; vertical face normal +Z | `(lateral, radius−0.018, −radius−0.020)` | `(lateral, radius+0.012, −radius−0.020)` |
| `bowl_feature.gd`, `inner=floor_radius+radius` | Radial distance `inner`, local Y=`radius`; vertical face normal inward | Torus major radius `inner+0.020`, minor radius `0.030`, centre Y=`radius−0.018` | Radial distance `inner+0.020`, local Y=`radius+0.012` |
| `sunken_bowl_feature.gd` | Same bowl tangent, with its existing port cut | Same parent torus, existing native/display port filtering | Existing retained angular samples use the same `lip_frame()` crown; the port is not bridged by a new guide. |

In world space the shared formula is
`concrete_lip + UP*0.012 − inward_face_normal*0.020`.
This is **58 mm lower and 20 mm farther behind the transition** than the inherited
guide/crown. The transition and concrete ground-height samples themselves stay on
the actual concrete. They must not be raised wholesale to the steel crown.

The private candidate updates CylinderMesh/CylinderShape radii and placement,
TorusMesh radii and placement, `lip_frame()` and every affected authored coping
guide together. Native bowl triangles still come directly from the displayed
torus faces. Existing source IDs, angular segmentation, body/shape slots, mesh
resources, materials and district mouths are retained. Quarter support normals,
concrete sampling, deck depth and transition radius stay as constructed. The
movement helper reads the real native cylinder or torus profile; no guessed new
movement radius or tolerance is substituted.

Changing the shared quarter also changes `halfpipe_feature.gd` and
`spine_feature.gd`, which construct quarters. The separate hand-built
`transition_park.gd` system has its own coping constructor and is **not changed**
by these three files. Its tests remain useful neighbouring regression checks.

## Why investigate this change

A 70 mm proud crown places a large steel obstacle across the transition/deck
interface. Reducing it to a documented reveal should make entering and leaving
the deck read like a built skatepark, reduce the inherited abrupt obstacle and
keep a distinct exposed edge for bearing and stalls. Those are design hypotheses,
not evidence of improved feel. The changed circumference/crown must remain a
real contact surface for grinds, not a lowered visual shell around old collision.

FID-D014 independently records actual truck vertices inside the old pipe.
[The retained native diagnostic](../testing/motion-fidelity-2026-11-07/coping-crown-contact-diagnostic/engine.log)
must remain rejected even if the new arrangement later passes. This proposal does
not authorize truck penetration, a larger fit budget, different velocities or
an ownership exception for coincident foreign floor geometry.

## Required native and route verification

The private copy is `.local/coping-proportion-source`. Its creation receipt reports
801 stable actual source inputs with no copy mismatch. Only the three constructors
change; the copied controller SHA-256 is
`f04253f745780ce8793828a9e6414c5e7f72617b8f235319eefc54574c093ab3`.
Original constructors remain in `.local/baseline-70mm/` inside that copy. Current
candidate/source manifests must accompany each native run; no prior result applies
to this geometry.

| Verification scope | Existing tests / witness | Required result before promotion |
| --- | --- | --- |
| Primitive dimensions and exposed surfaces | New private profile witness plus `connected_transition_tests.gd::_bowl_geometry`, `_transformed_bowl`, `feature_transition_ride_tests.gd::_surface_geometry` | Measure actual transformed native/display pipe axis, radius, deck/top/front reveals, normal and triangle parity; native crown rays at original and rotated/translated fixtures; finite same-owner support. Preserve counts/IDs and reject original 70 mm profile against the new specification. |
| Actual wheel, truck and full board clearance | `pt24_bowl_contact_tests.gd`, original D014 exact phases, Motion's native diagnostic and mixed coincident-floor Main witness | Fresh native finite wheel bearings and actual GLB component clearance at every relevant physics step, including the original failed phase and the separately higher foreign floor. Preserve the old negative, ownership guards, fit budgets and actual actor trajectory record. A tube-dimension check alone cannot pass this row. |
| Lip / grind / air handoffs | `feature_transition_ride_tests.gd::_lip_release`, `_lip_failure`, `_transfers`, `_grind_handoff_clearance`, `_continuous_capsule_turn`; `connected_transition_tests.gd::_upright_coping_contact`; metadata tests | Native crown guide agreement, real stalls/release and named catches, actual board/tyre/sole/model fit, body clearance and correct collision restoration. Keep existing unsupported-frame, obstruction and mode negatives. |
| Bowl laps, half-pipe, spine and supported misses | `connected_transition_tests.gd` lap/access/rollback/half-pipe/spine/obstruction cases | Actual native movement through the changed family, supported exits/landings and real transfer gaps; unchanged physical and scoring thresholds. The shared quarter's two dependent modules must not be omitted. |
| Clyde excavation and ordinary return | `clyde_surface_tests.gd::_check_sunken_bowl`, `pt24_clyde_flagship_tests.gd::run_bank_return`, `compact_clyde_lines_tests.gd` | Update only the obsolete 70 mm crown expectation to independently derived actual 12 mm/up, 20 mm/out geometry; retain all 330 concrete pit rays, exterior support, guide/score/chase/return limits and exact failed D014 approach. |
| Sunken ports and park transfer | `kelvingrove_skatepark_tests.gd` geometry/open-port/lower-carve/blocked-port/beginner/hip cases; civic/park connected-run tests | Native port edges, gaps and cropped guides still agree after the radial shift; optional exits/through lanes, hip and civic-quarter routes remain clear. |
| Public contracts and wider game | `grind_contact_metadata_tests.gd`, `skate_edges_tests.gd`, `surface_coverage_tests.gd`, full-density/career/facility and complete required check | Stable guide/feature IDs and exact permitted metadata; no new inherited obstructions, lost route, relaxed score/camera limit or terrain cap. Full current-source regression after focused acceptance. |
| Visible plausibility | Matched original/candidate close side/front/overhead and moving chase frames | Clearly recessed credible pipe, no open port seam, detached surface, sunk guide or jittering handoff. Native counts are not a visual approval. Actual target Mac performance and human preference remain separate. |

The [first original-Main candidate receipt](../testing/motion-fidelity-2026-11-07/coping-researched-profile-main/receipt.json)
now records a clean parse and **6/0** native return witness with the unchanged
controller: 250 bowl samples, 472 clear camera observations, no bails, preserved
100-point bank and supported return. Its 790 production-source inputs remain
unchanged; the copy-creation corpus is broader (801), so these are separate
inventories. The trajectory legitimately differs after the physical profile
change. Root-authorized untimed rendering overlap is disclosed; the duration is
not a performance result.

The [private primitive/guide component witness](../testing/line-design-2026-11-06/coping-proportion-private-development-2026-11-07/README.md)
also passes **24/0**, exit0 with 806 unchanged exact inputs. Actual native/display
sections, placement, crown/front rays, guide datums and port miss agree; the
original 70 mm quarter is retained and rejected against the new specification.
Its preceding parser/incomplete-inventory attempt remains explicitly rejected.

The unchanged shared Feature/Connected family then passes **98/0** on 806
unchanged exact inputs: real quarter/bowl coping hold/release/refusal, native
grind/capsule-turn admission, half-pipe opposing crossings and spine transfer.
That native capsule scope does not replace production tyre/truck/GLB contact
classification or sunken-port/civic/park gameplay.

The separate [original-defect contact witness](../testing/motion-fidelity-2026-11-07/coping-researched-profile-physics/README.md)
then passes **10/0** with the same controller and 790 unchanged production inputs.
All seven consecutive physics ticks 179–185 clear all 32 actual board components
and four tyre volumes. Independent per-vertex native rays record signed face
gaps of 7.320–20.865 mm on actual paving/steel. The packet's original `loaded`
label means only that signed near-contact band: two steel normals have Y≈0.195,
with vertical separations about 37.608/107.194 mm, so these are not certificates
of weight bearing or absence of flotation. Bounded ray misses remain unknown.
All 503 trajectory rows match the preceding same-profile Main replay. This
covers the original defect envelope before authored attachment, not every later
curved tick. Physical loading and moving flotation review remain open.

The candidate has **not been rendered or promoted**, and the remaining wider
contact/route, whole-source and visual gates above remain open. Root owns
admission/integration. The actual 70 mm production profile stays unchanged until
that evidence is reviewed.


The later [reconciled contact cohort](../testing/line-design-2026-11-06/coping-proportion-private-development-2026-11-07/README.md#reconciled-historicalcurrent-contact-cohort)
passes **68/0**, exit0 with 806 unchanged exact inputs. It retains the original
pipe-specific controls on explicit native/display/guide-consistent historical
90/70 geometry and verifies the current clear phase without demanding an
unnecessary corrective-fit return. The seven current static snapshots preserve
unknown rays and signed face proximity rather than claiming physical loading.
The actual controller and production geometry remain unchanged; the precise
three-constructor/two-test bundle awaits final QA review and root integration.
The Clyde crown expectation is prepared but its ordinary full suite has not run
on that bundle. This focused result does not close full regression, wider routes,
matched moving visuals or physical loading.
