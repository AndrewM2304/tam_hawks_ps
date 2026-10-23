# Named grind contacts: production and evidence review

23 October 2026. Review of the local `bootstrap/m00-m01` candidate over `ef0eb9f4d0eaefa6fa2d54ef30792fa3820390e4`. First aggregate required01 remains rejected at 2,556/1; the test-fixture correction passes 38/0 and final required02 passes **2,561/0**, clean and frozen. Native PNG decoding passes **16/0**.

**Finding:** no remaining blocking production correctness defect identified within this first 50-50/boardslide slice. Focused native evidence and the final required aggregate support the stated bounded mechanics. The first complete aggregate exposed an obsolete over-budget index fixture; its correction preserves the old refusal and adds bounded positive coverage. The recorded A/B/A comparison passes its unchanged numerical timing gates, but background CPU activity prevents a claim of uncontended performance acceptance. Continuous acquisition, owner feel, physical controller and export acceptance remain separate gates.

## Review independence

The reviewer did not implement the production controller, contact solver, author metadata or benchmark/capture scripts. I did author `tests/named_grind_integration_tests.gd` earlier in this session and helped identify clearance/release defects during integration. This is therefore a separate production-source and artifact review, **not a fresh blind review by a person uninvolved in the tests**. It must not be used to close the broader independent QE or human acceptance gate by itself.

For this review I read final production changes, the observer/analyzer code and original logs/manifests, recomputed source hashes, and visually inspected all sixteen original PNGs from capture02 and capture03. I ran no Godot process and changed only this report. I did not alter tests, tools, observers or either running suite.

## Production claims checked

- `GrindLine` preserves original travel points and requires explicit finite support metadata. Upright unit author frames are eligible; unsupported scale/reflection/tilt/shear and changing-grade radial joints retain generic classification. Semantic solid-edge and slatted families remain generic instead of being presented as solved named contacts. Final semantic-edge authoring has no diff against the preceding checkpoint.
- `GrindStyle` separates the actual board heading from signed travel. A 50-50 solves two fixed hanger-underneath anchors without stretching the board; a boardslide solves central deck contact with signed sideways yaw. Short or unsuitable geometry can decline. This does not implement the complete grind roster or distinguish lipslide crossing history.
- `Skater` snapshots selection before clearing airborne spin, installs one style and emits one original rail-ID event and one style award. Both new entries retain base 200. Root/camera travel remains signed tangent motion. Catalog-based grind recognition covers audio and encounter consumers without a compatibility second award.
- Named supported-but-obstructed or oversized contacts now reject; a solved world-overlap cannot bypass clearance through the generic fallback. Existing unsupported neutral geometry may remain explicitly generic. Named active travel, including final end/slow steps, checks both the capsule path and the conservative continuous board enclosure before installing the next root position.
- The enclosure uses the previous orientation, midpoint of board origins, translation extents and a 0.457 m model-origin corner bound. Its angular expansion accounts for rotation as well as translation. It reuses and restores the query box. It is deliberately conservative and can refuse tight bends; this is preferable to certifying an unchecked corner crossing. Native translation/rotation clearance units test this query contract; they are not played-input claims.
- Release preserves the solved yaw and visible translation separately from scored spin. Physical carry remains the native signed tangent, with the existing independent ollie impulse when actually requested. Fresh drop, reset and bail clear named state. Swept body admission retains the approach/speed/vertical gates and adds explicit current correction ≤0.85 m and preceding native sample-to-target ≤0.99 m bounds.

Earlier review found generic-fallback clearance bypass, unchecked final steps and a 0.106 m boardslide release snap. The final source and focused witnesses cover these corrections. I did not identify another blocking defect in the reviewed paths. This is not a proof that arbitrary unverified/generic map edges possess named board contact or that every possible contact geometry has been exercised.

## Frozen functional evidence

[Focused03 receipt](evidence/focused-03/receipt.json) records **333 passed / 0 failed**, clean log, 395 unchanged inputs and 43.309859 monotonic seconds. At the initial review all current input hashes matched focused03, compare03 and capture02. After the aggregate-fixture migration, I recomputed the manifests again: focused03, compare03 and capture03 differ only in `tests/grind_index_tests.gd`; capture02 additionally differs in its subsequently refined, historically retained `capture.gd` observer. Production hashes remain unchanged. Recursive literal `res://` dependency inspection finds the index test outside the focused, comparison and capture runners' loaded closures; it is loaded by the aggregate instead. This is an explicit unloaded-test exception, not a claim that every broad current manifest hash still matches. Compare03, capture02 and capture03 retain their stable 15-file observer manifests and exact loaded sources. Focused counts overlap the required suite and are not additional independent coverage counts.

The [focused log](evidence/focused-03/console.log) contains actual mapped charge/push/descending-catch trials with native post-rider sampling:

| Witness | Recorded result |
| --- | --- |
| Parallel, right slide, reverse-line sloped left slide | One expected style and rail ID; actual mounted contact errors ≤0.00000382 m; sole/deck error <0.0068 m; rear alignment 1.0 |
| Pop origin continuity | Relative first step 0.005275 m for 50-50 and 0.032811 m for both slides; below unchanged 0.04 m bound |
| Board-only walls | Parallel catch remains reachable beside the outside-capsule sidewall; sideways attempt refuses. Narrow below-capsule obstacle independently clears the actual capsule yet refuses all grind awards/captures |
| Continuous clearance units | Both exact endpoint boxes clear; actual midpoint obstructed; continuous query refuses; distant control clear; box size restored in both cases |
| Natural finite endpoint | One boardslide capture; release at exact authored Z=16; signed −11.27229 m/s carry; no invented Ollie or spin award |
| Original semantic families | Played Planter, MarketCounter, StreetBenchSeat and BridgeRail captures/travel/exits remain reachable; 159 semantic and 24 slatted edges stay generic |

The log also covers pause/fresh second press, reset/bail, generic legacy guides, input cleanup and consumer behavior. These are automated native/mapped-input checks, not physical DualSense trials. Routes01's rejected 220/9 record and the failed earlier observer attempts remain preserved; no failed result is relabelled as passing.

[Required01 receipt](evidence/required-01/receipt.json) records **2,556 passed / 1 failed**, exit 1, 394 frozen inputs and 1,370.327775 monotonic seconds. Its sole `ERROR: FAIL:` is the old index test expecting a historical swept catch from X=−0.8/Y=2.66 to a guide at X=0/Y=2. The nearest possible guide target is already `sqrt(0.8²+0.66²)` ≈1.03711 m from the preceding sample, exceeding the new 0.99 m limit before any Z difference. Refusal is the intended production behavior. This is a failed aggregate, not a clean pass.

The reviewed fixture-only change keeps that old full/indexed refusal as a negative, preserves actual candidate availability, and adds X=−0.65 as a bounded missed-window positive. It independently requires both point endpoints to refuse, both full/indexed sweeps to select the same guide/point across the negative cell boundary, and both correction budgets to hold. No production gate or original negative is loosened. [Index01](evidence/index-01/receipt.json) subsequently passes **38/0**, clean/frozen, in 0.314068 monotonic seconds.

[Required02 receipt](evidence/required-02/receipt.json) and [complete log](evidence/required-02/console.log) now record **2,561 passed / 0 failed**, exit 0, clean log, 394 frozen inputs and 1,370.473095708 monotonic seconds. The recorded London interval is `2026-10-23T22:18:03.218135+01:00` through `2026-10-23T22:40:53.688459+01:00`; command is `./tools/check.sh` through the checked native wrapper. I read that receipt/result and independently recomputed its 394 input hashes: zero current mismatches. This closes the aggregate automated gate for this source, without changing the rejected required01 record or the separate acceptance limits below.

## Native timing and resource evidence

[Compare03 comparison](evidence/compare-03/comparison.json) and [receipt](evidence/compare-03/receipt.json) pass: 106.181239 monotonic seconds, frozen 395 inputs, clean 3/0 observer result. Each phase has five actual Exchange captures, ten Ollie awards, the expected single grind-family awards, five supported returns, no input reassertions, zero bails and zero unsafe framing samples. Candidate styles alternate 50-50/boardslide/50-50/boardslide/50-50 at the same capture ticks as both controls. Original Main/Skater/GrindRide paths are pinned to `ef0eb9f`; preload and timing redirects are disclosed. Shared current map/metadata and intentionally different named board views limit equal-frustum claims.

| Metric | Original before | Candidate | Original after |
| --- | ---: | ---: | ---: |
| Render samples / sampled seconds | 5,775 / 30.217 | 6,437 / 30.217 | 6,391 / 30.215 |
| Frame p50 / p95 / p99, ms | 5.105 / 7.683 / 10.199 | 4.250 / 6.218 / 9.275 | 4.261 / 6.345 / 9.950 |
| Frames >33.333 ms / maximum ms | 2 / 48.274 | 0 / 13.096 | 0 / 13.419 |
| Active grind p95 / p99, µs | 31 / 33 | 41 / 47 | 30 / 31 |
| Successful capture maximum, µs | 89 | 129 | 75 |
| Rig animation p95 / p99, µs | 51 / 59 | 46 / 49 | 46 / 50 |
| Global physics p95 / p99, µs | 2,676 / 5,286 | 637 / 680 | 659 / 675 |
| Draw calls p95 | 1,148 | 1,148 | 1,149 |
| Primitives p95 | 819,321 | 817,293 | 820,233 |
| Static memory p95, bytes | 104,803,560 | 104,812,580 | 104,808,772 |

Candidate p95 6.218 ms is below both its 8.7027 ms control envelope and 8.06715 ms 1.05×worse-control ceiling. Candidate p99 9.275 ms is below 10.827225 ms and 10.70895 ms respectively. Gates are unchanged. Per-skater constructor static-memory delta is +985.6 bytes, below 65,536; this does not measure complete `_ready`/native allocation cost. All phases report identical render buffer/texture/video counters of 15,446,036 / 52,233,902 / 67,679,938 bytes. Raw distributions, including all-attempt CPU and maximum counters, remain in the packet. Five successful entries per phase are too few for broad capture-latency distribution claims.

The [103 system-load samples](evidence/compare-03/system-load.jsonl) show unrelated CPU bursts: Code Helper Renderer reaches 181.3%, Codex Renderer 120.5%, WindowServer 41.1%, and other processes remain active. These percentages may exceed 100% across cores. The comparison's numerical pass is valid for the recorded workload, but **uncontended rendering, long-play stutter resolution and general target-performance acceptance remain open**. Better candidate frame numbers do not prove a rendering optimization or establish which background process caused a particular frame.

## Original image inspection

I viewed all eight 1280×800 originals from historical [capture02](evidence/capture-02/capture.json) and all eight from current [capture03](evidence/capture-03/capture.json), including every contact/release profile and chase. Capture02 is clean/frozen 2/0 over 18.152240 monotonic seconds; capture03 is clean/frozen 2/0 over 18.311443 monotonic seconds. Each trial has the exact Exchange ID, one expected style, two actual Ollies, supported return, no bail and no unsafe sample.

The [native PNG decoder receipt](evidence/png-audit/receipt.json) records **16/0**, exit 0, clean/frozen 395 inputs and 0.530789 monotonic seconds for both retained capture directories. Its 395 current input hashes also match on independent recomputation. Decoding establishes valid native image files; the visual findings below come from inspecting those originals.

- [Current 50-50 profile](evidence/capture-03/50-50-contact-profile.png): deck/trucks align along the orange rail; both shoes remain on the deck. The [chase](evidence/capture-03/50-50-contact-chase.png) remains behind travel with rider and board visible. Contact composition agrees with capture02.
- [Current boardslide profile](evidence/capture-03/boardslide-contact-profile.png): deck crosses the rail, with wheels on either side and central underside at the support. The [chase](evidence/capture-03/boardslide-contact-chase.png) retains the same travel-facing composition while the visible skater turns sideways. Contact composition agrees with capture02.
- Historical capture02 [50-50](evidence/capture-02/50-50-release-profile.png) and [boardslide](evidence/capture-02/boardslide-release-profile.png) release pairs are **early launch frames**, with body origin still at rail height. They remain useful launch evidence, not continuing-air images.
- Current capture03 [50-50 profile](evidence/capture-03/50-50-release-profile.png) / [chase](evidence/capture-03/50-50-release-chase.png) and [boardslide profile](evidence/capture-03/boardslide-release-profile.png) / [chase](evidence/capture-03/boardslide-release-chase.png) visibly clear the rail during ascent. Numeric metadata independently records body Y=1.22333348 m versus rail/body guide Y=0.92000002 m, vertical velocity +5.50000429 m/s, airborne true, grinding/contact-valid false and style cleared. Both have scored air-spin 0; the boardslide retains −1.57079637 rad as its separate unscored heading. These frames establish rising release, not an apex or full motion-smoothness verdict. Continuing carry and landing remain supported by native traces/tests.

Profile cameras were explicitly placed and restored while paused; chase images use production camera behavior. PNGs are static evidence, not a substitute for continuous animation or frame-time analysis. The procedural rider still has a stiff crouch/arm presentation and temporary world art. This report does not certify believable human motion, polished UI/art, fun or THPS3 animation fidelity.

## Remaining gates

Acquisition is currently a bounded discrete snap with capsule-path and final named-board clearance. The continuous board enclosure applies to an already active ride; **there is no board-envelope sweep through the acquisition translation/rotation**. A board-only corner obstacle can be clear at both acquisition endpoints and outside the capsule sweep yet lie on an interpolated nose arc. This review has not executed a native/rendered reproducer, so it is an unverified acquisition hardening case rather than a demonstrated blocker against the declared discrete-entry contract. Track a separate G01-07 native/rendered reproducer and bounded policy decision before claiming continuous visible acquisition or no intermediate acquisition clipping. The passing active-travel clearance units do not certify that missing entry path.

Required02 now closes the frozen aggregate check; required01 remains rejected. Keep a fresh independent reviewer/owner playtest, physical DualSense behavior, current exports, uncontended rendering and long-play performance open. Keep G01-07 acquisition hardening, broad solid-edge contact, the rest of the grind styles/style changes, wallrides/wall plants, landing assistance and all existing map/UI/art tasks in their recorded queues. This bounded review does not close them.
