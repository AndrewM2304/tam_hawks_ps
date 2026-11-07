# Merchant District implementation tickets

Owner direction: replace empty travel with a dense medium city level, design from
overall/section sketches, use San Francisco/Los Angeles/London for spatial lessons,
and retain Glasgow identity. The [concept boards](../levels/MERCHANT-DISTRICT-CONCEPTS-2026-11-07/README.md)
were liked by the owner; that is visual direction, not native acceptance.
The [plan](COMPACT-LEVEL-REPLAN-2026-11-07.md) and
[ADR-035](../architecture/decisions/ADR-035-san-francisco-scale-neighbourhood.md)
own current contracts. These are repository tickets, not published remote issues.

| Ticket / priority | Implementation owner | Independent verifier | Current state |
| --- | --- | --- | --- |
| MD-101 / P0 — Four adjoining skating spaces | Level designer | Skate topology reviewer / BA | Installed four-space03a default; west/south actual building obstructions repaired, component24/0 each and same-rider dogleg8/0; production focused31/0 and complete full09; moving grade/whole-map line acceptance remains open |
| MD-102 / P0 — Selected world and compatible progress | Root + world integration engineer | Technical QE | Actual required06: Book65/0, lifecycle/recorder22/0, parsed keyboard/pad31/0 and full6,709/0; ordinary rendered13/0 and cold8/0; actual Mac save/relaunch unmeasured |
| MD-103 / P0 — Recognisable Glasgow architecture | Environment architect | Technical QE + BA | Civic clock and real retained street faces added; current static8/0 at279,452 total/154,802 net triangles and51 batches; five current service views31/0; repetitive facades/plain ground/props and independent final review remain open |
| MD-104 / P0 — Eight returned lines and three circuits | Level designer + combo engineer | Skate topology reviewer / BA | Current two-rail Market open link18/0: one root-derived4,459-point bank per run; capture discontinuity open; zero returned lines/circuits accepted |
| MD-105 / P0 — Believable rider and continuous contact | Rider artist + motion engineer; board artist as needed | Rigging/technical QE + BA | Forward-push film technically verified; arm carrier installed with independent176/0 and full regression; knee, capture and ground-transition fidelity remain open |
| MD-106 / P0 — Ordinary launch, cooked delivery and M5 cost | Root + rendering engineer | Technical QE; owner for actual Mac | Current source cold8/0; unsigned Linux/universal-Mac exports and native PCK resource checks pass; ordinary release headless startup passes; rendered title/Free Skate observed but full timing/exit/pushing trial rejected; actual M5 cost/play unmeasured |

## MD-101 — Build the spaces around the runs

Milestone: playable native composition. Dependencies: concept direction and stable
world/Catalog contract. Own the private Merchant world/layout, native support and
guide/route records; do not instantiate the legacy city or mandate the old park.

Acceptance:

- High Street terraces, Market Cross, Depot/Roofs and Foundry Court closely adjoin.
  Every primary space has multiple visible usable exits and a ground bypass.
- No long empty Kelvingrove climb, promenade or transport-only road is required.
  Hill travel itself presents stairs/rails, banks, ledges and useful returns.
- Every portal has a real matching native/display/support/guide cut. Roof access
  is skateable; a staircase drawn as an access route is insufficient.
- The depot's ground passage and upper path coexist with adequate actual trick,
  body and camera headroom; roof gaps have finite supported landings.
- Repair the reproduced0.8m unsupported bank end. The novice bypass must remain
  grounded without an Ollie across centre/shoulder paths in both directions.
- Check grade and body/head continuity at representative4/8/12m/s approaches.
  Preserve practical floor smoothness; an invented triangle ceiling does not
  justify visible contact jumps.

Verification: exact-source native static/negative probes and ordinary input runs,
with initial fixtures explicitly labelled. Later landing alone cannot pass the
no-jump bypass. Add moving rendered views before promotion.

Current [portal/service evidence](../testing/merchant-district-2026-11-07/portals-clock-01/README.md)
retains the real west wall12/12 negative and corrected south18/6 negative before
their24/0 component repairs. Six west centre/shoulder runs remain grounded with
about37.1mm maximum per-tick body-height step. The complete south dogleg succeeds
both ways on one rider with mapped steering,8/0. Ground routes are not returned
combo lines. Eight runtime route IDs are now unique; all seven source street
centrelines avoid front/rear building footprints, without claiming native
whole-route/prop/shoulder/camera acceptance.706 other native records stay exact.
Required08 is deliberately interrupted/eligiblefalse. [Full09](../testing/merchant-district-2026-11-07/required09-portals-complete/README.md)
passes6,740/0 plus CLI2/0,Book65/0,lifecycle22/0 and parsed31/0 on945 exact inputs.

## MD-102 — Integrate selection and safe per-level progress

Milestone: ordinary title-to-play in either world. Dependencies: MD-101's stable
interface and the corrected private career book.

Acceptance:

- Merchant District is the new default; City Tour remains ordinarily selectable.
  Exactly one chosen world and its actors are instantiated at a time.
- Keyboard/controller level selection respects menu press/release ownership,
  supports Back, starts a clean run and leaves no old contacts or activities.
- Settings, soundtrack session and earned cosmetics/specials remain global;
  completed goals and best scores/combos remain separate per level.
- Validated old `career.json` data migrates only into City Tour when the new book
  family is absent; preserve original/backup/temp bytes and newer/corrupt data.
  Deterministic late-file faults must not overwrite an observed foreign candidate.
- Namespaced Merchant IDs never appear as letter labels and never falsely clear
  old goals. Cone interaction and every new goal use the intended current world.
- Scripted launches retain profile/Music isolation. Historical map fixtures
  explicitly select City Tour; the new default receives its own checks.

Verification: native book controls plus combined actual Main/HUD/world tests,
ordinary title-to-play capture and save/relaunch on isolated profiles. The private
book's65 checks alone do not verify level selection.

## MD-103 — Make the composition feel like Glasgow

Milestone: convincing street-facing art around accepted skating geometry.
Dependencies: MD-101 envelopes/openings and the inspected Glasgow references.

Acceptance:

- Use credible sandstone tenement proportions, sash/cornice detail, tiled closes,
  original shop/market bays, ironwork and brick depot/railway arches.
- Readable, deliberately authored local signage and useful landmark silhouettes
  establish Glasgow. Fictional tenants are not described as verified businesses.
- Existing licensed PBR materials keep physical scale and useful detail; avoid
  plain repeated textured cuboids at the main skating viewpoints.
- Keep openings, landings, sightlines, roof gaps and camera paths clear. Decorative
  recesses must not pretend to be traversable doors or create invisible obstacles.
- Initial added-art budget:90k source triangles. Before full-detail expansion,
  root approved145k for shared revision03's109 native units,170 exposed faces
  and620 projected upper windows. Actual757-window construction exceeded that
  forecast (207,877 art triangles), and the original gate remains rejected.
  Root removed buried/back faces and simplified tiny stock detail, declaring
  **155k net added triangles** before those edits while retaining the280k combined
  static ceiling. The first revised pilot passes9/0,279,109 total/154,459 net added;
  the later joined depot steel edge removes redundant duplicate factory labels.
  Retain48 submitted batches,4MiB actual mesh/instance buffers and zero added
  maps/material objects/lights/colliders. This is a declared private ceiling,
  not target performance acceptance. Measure rendered shadow/draw costs and the combined
  world total too; no target-Mac frame rate follows from these budgets.

Verification: matched native approach/close views, exact geometry/collision
invariants and actual resource counters. The first vector-sign trial exceeded
cost; retain that rejection. Concept images are not rendered-game evidence.

## MD-104 — Prove connected lines, not route counts

Milestone: eight distinct returned lines, two in each primary space, plus three
closed neighbourhood circuits. Dependencies: MD-101/102 and current mechanics.

Acceptance:

- Each returned line joins different useful contacts; a reverse traversal of the
  same rail is not a second distinct line.
- Three circuits cross primary spaces using real grinds, air/gaps, manuals and
  appropriate wall/transition contacts, returning to an attainable continuation.
- At least the prescribed combo circuits retain one actual score chain and bank
  once. Never add banks from separately reset runs and call them one combo.
- Prove short manual links at their real approach speed. From4m/s the current
  manual reaches its2m/s minimum after roughly8m on flat ground;12–16m feature
  spacing is not automatically novice combo connectivity, especially uphill.
- Gap exits aim at a visible next choice. Record skill/speed requirements and safe
  misses; expert routes may be demanding, but ordinary traversal remains usable.

Verification: frozen-source ordinary-input replays with actual event/score ledgers,
clear route diagrams and moving views. Current two closed macro sketches and an
open roof path51m from its start do not pass the three-circuit target.

## MD-105 — Preserve realism through the whole movement

Milestone: convincing connected rider/board animation in real skating views.
Dependencies: authenticated fitted rig/current contacts and MD-101 terrain.

Acceptance:

- Pushing faces signed travel, keeps the leading foot correctly planted and uses
  a plausible pushing/recovery foot path in regular/fakie/from-rest cases.
- Smooth the reproduced brisk arm recovery without changing foot cadence,
  physics or final grab/handplant contacts.
- Repair the conspicuous raised-knee cloth cap without folds, reversed helpers,
  detached seams or fake source identity. The PN11 appearance trial is rejected.
- Repair grounded bowl/lip pose jumps while retaining current native component,
  shoe/head and finite support authority. Missing bearings stay unknown.
- Resolve visible tyre/ground gap and credible board construction with protected
  grip/truck/wheel contacts; do not relax collision checks to hide a visual fault.
- Manual/revert linking and physical fore/aft versus lateral balance retain their
  ordinary mapped-input behavior and honest meter/control presentation.

Verification: actual deformed geometry and source-bound native motion plus viewed
worst frames/real-time human review. The351-frame film and full regression are
bounded technical evidence, not a declaration of final realism.

## MD-106 — Deliver and measure the actual result

Milestone: source and cooked builds of the integrated neighbourhood. Dependencies:
accepted implementation slices above; no hosted CI, paid service or release.

Acceptance:

- Current full `tools/check.sh` passes on frozen integrated source, including old
  City Tour regressions and new-default/selection/book/route coverage.
- Ordinary cold/warm source launch and title-to-play work with current imports.
  Both worlds/layout JSON, licences and model provenance survive cooked export.
- Fresh Linux package boot and unsigned universal Mac package inspection pass;
  actual Mac launch/control/save/soundtrack remain explicitly target-side checks.
- Measure representative moving workload and long-frame tails on the owner's
  MacBook Air M5 at the chosen resolution/preset. Keep the benchmark's60fps/frame
  pacing targets and resource budgets; software capture duration is not FPS.

Verification: source-bound native package/cold-launch tests and actual target
measurements. Missing target results remain open while independent work proceeds.
