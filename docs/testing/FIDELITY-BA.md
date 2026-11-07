# Independent fidelity requirements audit

Reviewer: studio-production agent acting as BA for runtime/assets it did **not** implement. Later delegated FID-304 combo implementation is explicitly excluded from this reviewer’s acceptance authority; root/QE independently verify it. The independent QE agent owns acceptance of the production documents written by this reviewer; this report cannot accept its author's own studio setup. Candidate is current main `0b62035` plus live November changes. The final integrated source is not yet frozen.

## Asset-contract epoch 01

Command:

```sh
python3 docs/testing/fidelity-ba/asset_contract_audit.py --output docs/testing/fidelity-ba/asset-audit-01.json
```

Result: **exit 1**, 15 source maps inspected, **0 raw identity/dimension errors, 1 import-policy error**. All **33 relevant inputs** had identical hashes before/after this bounded inspection. [The receipt](fidelity-ba/asset-audit-01.json) retains the actual timestamp, Git HEAD, source/import/script hashes and each measured cap. This is stability of those asset inputs during this inspection, not a whole-game freeze or a performance/visual result.

The manifest declares packed ARM maps limited to 1024. Pavement and sandstone match; `asphalt_02_arm_2k.jpg.import` still declares 2048. The environment author confirmed a concurrent editor overwrite and is coordinating correction/reimport after editor exit. Do not count the cap corrected until a new independent receipt passes.

## Direct source inspection

The official [Poly Haven asset licence](https://polyhaven.com/license) was independently opened on 6 November 2026. It identifies downloadable assets as CC0 and permits commercial use and redistribution. This applies to the texture files, not provider logos, page copy or example renders. No provider page/example image is included by this work.

The inspected provider pages identify Rob Tuytel and published physical widths of **1.5 m** for [Pavement 01](https://polyhaven.com/a/pavement_01), **3 m** for [Sandstone Blocks 04](https://polyhaven.com/a/sandstone_blocks_04), and **3 m** for [Asphalt 02](https://polyhaven.com/a/asphalt_02). Those match the material manifest's scale metadata. The [pinned ZC licence](https://github.com/DaZCDude/ZCs-Spectacular-Textures/blob/a866769b0ccb5e041f8855a52223d7d1a1166125/LICENSE) was independently opened and is CC0 1.0 Universal. Grass/wood scale is explicitly authored rather than represented as a provider measurement.

The local asset manifest records exact source/download URLs, creator, licence, per-file SHA-256, bytes and decoded dimensions. All 15 raw map files match that declared identity in epoch 01. `docs/licences/ENVIRONMENT-FIDELITY.md` describes use/permissions. A link from the central provenance register and a final source-bound asset inventory remain integration checks.

At the later integration cold-read, central [REGISTER ART-004](../licences/REGISTER.md) was present and linked the appendix, named both CC0 providers and disclosed 15 maps plus separate visual/performance acceptance. That register-link subcheck passes. A complete final-candidate asset inventory remains distinct from this environment subset.

The declared additional resident-texture ceiling is 32 MiB. It is a budget, **not a measured GPU-memory result**. The live source uses mipmaps, VRAM compression and shared material resources; actual memory, frame pacing and visual quality remain unmeasured by this BA inspection.

## Acceptance matrix — epoch 01 findings

| Ticket/clause | Expected observable outcome | Evidence actually inspected | Finding | Result / next action |
| --- | --- | --- | --- | --- |
| FID-201 B, source metadata | Chosen files have explicit identity, source resolution, creator, licence and metres per repeat | Current manifest, 15 decoded map files, epoch 01, official asset/licence pages | All raw bytes/dimensions match; three provider widths match; authored grass/wood scale disclosed | **Pass for this metadata scope**; recheck after asset changes |
| FID-201 B, import policy | Import caps and repeatable tooling preserve the declared contract | Manifest, 15 `.import` files, fetch script | Asphalt ARM cap differed; repeat script dropped authored metadata/policy fields | **Failed in epoch 01**; corrected/retested below |
| FID-201 E, permission/provenance | Included source licences and notices are compatible and registered | Direct official CC0 pages, pinned ZC licence, local appendix/manifest; later central ART-004 cold-read | Source permissions and central appendix link verified; complete final-candidate inventory still pending | **Pass for inspected environment permission/register subset**; complete final inventory remains integration work |
| FID-201 A/C/D, visible surface quality | Credible/stable surfaces in ordinary moving and close views | No new frozen candidate frames inspected in this epoch | Raw file integrity cannot establish the rendered result | **Unmeasured**; independent QE/BA review current capture |
| Q1/H1, cost and MacBook Air M5 | Matched cost admission and sustained target performance | Declared 32 MiB budget only | No new GPU-memory/frame-time or target-machine result measured here | **Unmeasured**; root/RE/QE evidence and actual Mac run |
| FID-002, production setup | Independent A–E cold-read of roles/skills/tickets/resumption | Reviewer authored the production setup, but not native gameplay-QA skill | This reviewer cannot accept their own production documents; the one QE-authored skill receives the separate cold-read below | **Split independent reviewers**, main matrix in [FIDELITY-REVIEW](FIDELITY-REVIEW.md) |

No full FID-201, V2, H1 or overall AAA acceptance follows from this bounded audit.

## Defects

| ID | Severity / clause | Reproduction and actual versus expected | Owner | State / exact retest |
| --- | --- | --- | --- | --- |
| FID-D801 | P2 · FID-201 B / import-budget consistency | Epoch 01: declared ARM cap 1024, actual asphalt ARM cap 2048; expected all included maps follow their declared cap | EA | **Resolved in epoch 03**: all 15 caps match, independent auditor exit 0; failed epoch 01 retained |
| FID-D802 | P2 · FID-201 B / repeatability | Original fetch script regenerated manifest without `source_dimensions_px`, `maximum_dimension_by_map` and `added_texture_budget_mib`; expected repeat tool to preserve/regenerate its published contract | EA | **Resolved in epoch 03**: full manifest rebuild equals saved manifest; independently trapped CLI verifier performs no network or file writes |
| FID-D803 | P1 evidence gate · FID-101/102/501 | Rider studio uses manual `force_draw` without same-frame native-pixel proof; engine log reports a failed `head_normal.png` load although receipt reports zero failures | RA + QE | **Open for final evidence**: preserve diagnostic, correct import/log accounting and use the existing natural `frame_post_draw`/pixel-proof capture on frozen source |

## Corrected asset-contract epoch 03

The environment author corrected the asphalt ARM cap to 1024 after coordinated editor exit, made manifest generation preserve/regenerate the full dimension/import-budget schema, and added `--verify-only`. The BA reviewer independently reran:

```sh
python3 tools/fetch_environment_materials.py --verify-only
python3 docs/testing/fidelity-ba/asset_contract_audit.py --output docs/testing/fidelity-ba/asset-audit-03.json
```

Both commands exited **0**. The verifier checked **5 materials / 15 exact maps / stable repeat schema / import contracts**. [Epoch 03](fidelity-ba/asset-audit-03.json) independently checked 15 decoded maps with **0 identity errors, 0 policy errors and 33 stable relevant inputs**. The intermediate [epoch 02](fidelity-ba/asset-audit-02.json) also records a successful bounded asset audit; it is not an additional gameplay pass.

A separate BA probe imported the fetch module, asserted `manifest_for(saved_materials, saved_retrieval_time) == saved_manifest`, and executed the real `--verify-only` argument route with `urllib.request.urlopen`, `Path.write_text` and `Path.write_bytes` trapped to raise on use. It completed successfully. This establishes no network/file-write calls through those paths during verification, rather than relying only on the author's output text.

**Current bounded verdict:** FID-D801/802 are resolved; the asset identity/import-policy/repeat-schema scope passes, as does the later central environment-register link. FID-201 visible surface quality, runtime memory/cost, complete final-candidate inventory and full-ticket acceptance remain separate. The reviewer did not implement either production correction.

Later epochs append rather than overwrite failed evidence. Current visual, motion, line-design and target-hardware gates remain in the separate integrated review and ticket ledger.

## Environment derivative audit — 7 November

The environment author added four replacements after their visual inspection: muted/de-lit reflected grass albedo, normal and AO at 1024², and de-lit paving albedo at 2048². BA independently read the generator, runtime bindings, source/derived manifests and licence appendix. Grass explicitly contains two authored 1.5 m source tiles per axis for a 3 m derivative repeat; paving retains its provider 1.5 m width. The runtime replaces four map bindings and introduces no Python dependency.

An independent `python3 -B` probe invoked the actual `tools/build_environment_derivatives.py --verify-only` CLI route with network, `Path.write_text`, `Path.write_bytes` and `os.replace` trapped to fail, then independently decoded and hashed all four saved outputs. It passed **4/4 identities**, complete in-memory repeat-generation/import contracts and **42 unchanged relevant inputs**. [The derivative receipt](fidelity-ba/derivative-audit-01.json) retains actual UTC, source/output hashes, decoded dimensions, byte counts and trap scope. The original verifier also passed 5 materials/15 raw maps within that invocation. This reviewer did not implement the derivative production work.

This passes only the inspected derivative provenance/identity/import/rebuild subset. The reflected normal channels are explicitly sign-corrected in authoring; their visible seams, grass repetition/colour, paving response, moving stability and actual resident memory/frame cost still require current captured and measured review. It does not close FID-201 or V2.

## Independent supporting-skill cold-read

The independent QE agent authored [gameplay-qa](../../.agents/skills/gameplay-qa/SKILL.md), so this BA reviewer independently inspected that component of FID-002 B. It **passes the reusable-instruction scope**: current benchmark/PT24 loading, exact existing natural `frame_post_draw`/native-pixel/source proofs, explicit fixture and source-freeze rules, Music/default-content preservation, no injected natural-route movement, both directions/bypass/return intervals, independent defect handoff and honest human/M5 limits are all present. The skill is linked from the roster and explicitly loads the shared quality-verification workflow.

This reviewer did not author that skill. Conversely, the QE reviewer must accept the production documents/quality-verification skill authored here. These split reviewers preserve independence; neither review certifies the underlying game's visuals, playability or hardware performance.

## Renderer-decision cold-read

This reviewer independently read [ADR-034](../architecture/decisions/ADR-034-fidelity-studio-and-m5-rendering.md), current AGENTS and RESUME. The decision preserves the advanced main history, the working Godot game, default trial availability and Music isolation; distinguishes missing asset/animation work from a demonstrated engine limitation; retains authority to migrate; and requires a playable representative slice and gameplay/save/input/export parity before replacement. It does not claim the sphere probe establishes game fidelity or Mac performance.

| FID-010 clause | Independently observed decision/evidence | BA result |
| --- | --- | --- |
| A — Diagnose actual blockers | ADR identifies asset/material/motion/layout work and states no engine-level rewrite blocker is demonstrated | **Pass for decision framing**; concrete candidate defects remain in specialist/QE evidence |
| B — Compare retained and Metal-capable paths | Official versioned renderer references and planned same-scene comparison are present; ADR describes a local sphere availability probe | **Unmeasured for representative game comparison**; this BA did not inspect/run a full scene/backend comparison or the sphere's raw receipt |
| C — Migration/parity protection | No engine/default-renderer migration is claimed complete; fallback/parity requirements are explicit | **Pass for preservation policy**, migration validation remains conditional if selected |
| D — Honest M5 limits | Exact RAM/GPU/OS and sustained performance remain unmeasured; Linux probe is explicitly local availability only | **Pass for honest reporting**; actual target gate remains Unmeasured |
| E — Reviewable decision | Context, authority, decision, alternatives, preservation constraints, references and next comparison are recorded | **Pass for ADR availability**; final default selection and measured costs remain open |

FID-010 remains open for the representative renderer comparison/decision evidence. The existence of an ADR is a production milestone, not a completed realism or target-hardware outcome.

## Level-study and baseline cold-read

This reviewer independently read [THPS-LINE-DESIGN](../research/THPS-LINE-DESIGN.md), opened its [Mick West interview](https://corecursive.com/game-programming-with-mick-west/), [Warehouse guide](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-warehouse-all-park-goals-gaps-and-challenges), [School II guide](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-school-ii-all-park-goals-gaps-and-challenges) and [Marseille guide](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-marseille-all-gaps-and-collectibles). The sources support the brief observations used: a shift toward local repeatable skating, linked ground/elevated choices, and reciprocal rail/ledge connections. The dossier clearly separates observations from original design inferences and does not claim to have played or measured the commercial levels.

The reviewer also opened the original current-main [Exchange overview](fidelity-2026-11-06/baseline/overview_exchange.png) and [Clyde east-quay view](fidelity-2026-11-06/baseline/clyde-east-quay.png) and inspected their [source receipt](fidelity-2026-11-06/baseline/receipt.json). Those actual images substantiate the diagnosis: isolated Exchange obstacles across a broad repeated paving field, and a long sparse east-quay corridor with weak destination/return composition. They are baseline evidence, not the November candidate or an owner-fun assessment.

| FID-401 clause | Independent finding | Result / remaining action |
| --- | --- | --- |
| A — At least three sourced level examples | Three player guides plus developer testimony directly opened, with sources/dates in dossier | **Pass for research-source coverage** |
| B — Explain line/enclosure principles and distinguish inference | Source observations and original implications are explicitly separate and supported | **Pass for written design analysis** |
| C — Quantify current opportunity spacing/dead travel | Route-polyline inventory and approximately 58 m east-quay diagnosis exist; actual input/event intervals including the return leg are not yet supplied in this scope | **Unmeasured for the full interval criterion**; retain inventory observer/inputs and measure actual choices/events |
| D — Original proposals tied to actual positions/clearance | Specific bank rotation and seating relay positions/footprints/bypass are documented | **Pass for reviewable proposal**, physical/flow admission remains FID-402/403 |
| E — Original implementation/content | Dossier contains paraphrased principles and original Glasgow arrangements, with no copied commercial diagram/asset | **Pass for inspected research/proposal scope**; final asset/source inventory remains integration work |

FID-401 stays open for its remaining measured-interval scope. Moving one bank and two benches is a bounded local experiment. It cannot by itself close L1's two distinct lines per retained core arena, useful returns/bypasses and three cross-arena circuits. Their actual approach/capture/landing/bank/return events, imperfect inputs, camera and matched candidate frames still need independent evidence. FID-203 architectural finish also remains open: better PBR maps alone do not complete visible facade/ground/composition cleanup.

## Rider diagnostic review — rejected as final evidence

This reviewer opened the original diagnostic [full rider](fidelity-ba/rider-studio-rejected/idle-front.png), [face](fidelity-ba/rider-studio-rejected/idle-face.png) and [push still](fidelity-ba/rider-studio-rejected/push.png). The detailed facial and hand forms are a visible improvement over baseline. The close face view still exposes a sharp cylindrical collar, a long bare neck, a cap-like hair silhouette and a separate sleeve/torso shoulder read. Smooth tubular trousers and the complete shoulder/hip deformation still need ordinary moving-world review. A single push still cannot establish the requested forward-facing stroke or foot-contact cycle.

These pictures are a **diagnostic only**, not accepted current-frame or clean-engine evidence. The [preserved observer](fidelity-ba/rider-studio-rejected/observer.gd.txt) changes camera and manually calls `RenderingServer.force_draw`; it does not retain the existing natural-frame/pixel-synchronization proof. The [original engine log](fidelity-ba/rider-studio-rejected/engine.log) reports `Failed loading resource: res://game/art/rider/head_normal.png`, while the [receipt](fidelity-ba/rider-studio-rejected/receipt.json) reports `failures: 0`. This does not prove the displayed images have the wrong camera or identify the final import state; it rejects an unsupported final-evidence claim. It is FID-D803, independently sent to RA, root and QE for correction/retest.

The receipt's selected inputs were stable during its own run, but two of its 32 recorded inputs (`game/art/rider/manifest.json` and `game/player/skater_visual.gd`) already differed at the later BA inspection. The packet cannot represent the final combined candidate. [Preservation hashes](fidelity-ba/rider-studio-rejected/preservation.json) identify six exact copied original files; they are an archival operation, not a new render. Full current-source capture, import-error scan, natural-frame proof, ordinary chase and continuous deformation/contact review remain open.

## Footwear source study — 7 November

The rider artist supplied six original shoe thumbnails and corresponding MakeHuman material headers for an offline source comparison. This reviewer opened all six images, independently fetched the official [MakeHuman system-asset catalogue](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html), and verified the supplied records against all **12 local file hashes/byte counts**. Each material explicitly declares its September 2020 release as CC0; the catalogue links the CC0 system-asset pack. The reviewer did not independently download or hash the complete archive. [The bounded receipt](fidelity-ba/footwear-source-study-01.json) records catalogue identity, exact member identities, source URLs, observations and limitations.

**Shoes02 is the best candidate for a fitting experiment**: it has a low collar, laces, layered casual-trainer construction and muted material. Shoes06 is a plausible alternative with a stronger blue running-trainer appearance; the thumbnail does not establish identical topology. Shoes01/04 read as moccasin or dress shoes, Shoes03 as a formal slip-on, and Shoes05 as a running shoe. These are visible source-selection judgments, not claims that any candidate is already a realistic skate cupsole.

Shoes02's rounded/tapered forefoot and sole still require actual mesh inspection. Before acceptance, the rider artist must inspect dependencies and any branding, fit the anatomical foot/trouser hem, preserve ankle movement, establish the actual flat loaded outsole/deck contact, and review push, landing, manual and bail motion at normal speed. Topology/surface/texture budgets and matched cost admission remain required. This source study changes no runtime assets and closes neither V1 nor FID-101/102.
