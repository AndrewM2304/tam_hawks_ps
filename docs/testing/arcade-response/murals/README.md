# Original mural experiment: retained evidence, normal-play admission rejected

**18 October 2026:** capture integrity is accepted; the mural candidate is **not admitted to normal play**. The strict p95/p99 A/B/A gate fails in Exchange, George, Station and the botanical-wall view. The world now defaults `arcade_murals_preview` to `false`, so ordinary startup does not construct these paintings. Explicit diagnostic fixtures retain access. No FPS improvement, final realistic-art acceptance or Mac performance pass is claimed.

The paintings are original **Clyde Heron** and **Printworks Bloom**, placed on existing fictional/compressed building rear walls. They are not reproductions of Smug's or Rogue-One's murals and are not attributed to those artists. [Research, locations and source provenance](../../../research/GLASGOW-MURALS.md) records the official City Centre Mural Trail, the directly inspected Rogue-One interview and source photograph hashes. No downloaded artwork or Street View texture is bundled.

## Actual candidate and fixture

The measured candidate has **539 + 553 = 1,092 triangles**, two wall-local one-surface meshes and one shared material. It uses original vertex-colour shapes on a single plane **18 mm** outside each existing wall. The material is unshaded, alpha 1, routed through the transparent painter pass with **depth testing ON and depth writes OFF**. Polygon submission order resolves overlapping paint; no layered paint depths compete. Cast/receive shadows are OFF. There are no new textures, custom shaders, lights, labels, physics objects or frame-by-frame callbacks. Native visibility range is **45 m**. Two draws are the maximum authored mesh cost, not the measured draw addition in every view.

The retained run was `.local/mural-review-20261018T102853Z-gX7w3T`, executed by `tools/mural_review.sh`, from **11:28:59 to 11:38:06 Europe/London**. [source.json](source.json) records **172 unchanged inputs**, an empty changed-input list, exit 0 and an accepted clean log. Godot **4.6.3**, Compatibility/OpenGL, Mesa llvmpipe LLVM 19.1.7, four Mesa threads, **960×600**, MSAA OFF, FOV 68°, near/far 0.2/220 m, directional shadow distance 45 m. The driver reported that changing VSync mode was unsupported; this warning is preserved in [capture.log](capture.log).

Eight authored stationary observer views each use **OFF → ON → OFF**, 15 warm-up frames and **120 measured native frames per phase**: **24 records / 2,880 measured frames** in [measurements.json](measurements.json). Screenshot readbacks are outside the measured sample windows. This is a world-only fixture with processing disabled, no player, no HUD and no mapped input. It measures steady rendering with both mural resources already constructed, not their startup cost or a full gameplay workload. Aggregate frames over 100 ms: **2,072/2,880**, on this software renderer.

### Metadata discrepancy retained without rewriting raw evidence

`measurements.json` contains `normal_default_enabled: false`. That field was a literal recipe value, **not a sampled world-default assertion**. The frozen candidate world source used during this run actually defaulted `arcade_murals_preview` to **true**. The fixture explicitly set that metadata to **true before construction in every phase**, then changed only the shared mural root's visibility for OFF/ON/OFF. Consequently the within-run rendering comparison is still visibility-only; the inaccurate default field must not be used as evidence that normal startup was disabled during profiling. Root changed the actual default to **false after the failed gate**. The raw JSON and source hashes are preserved, including this discrepancy.

The captured world source SHA-256 was `80bb53b2cc7246a3db3a25c34d401b485bd05b999b05c561ef9a3873b358219e`; mural helper SHA-256 was `18a84ea587868fbfdc06626a0eaab323ec25a86ac0a7b98b297a92c9608c5ee1`. [source-start.json](source-start.json) and [source.json](source.json) bind the complete executed source/asset/helper set. Their stability statement concerns that capture interval, not subsequent default changes.

## Strict admission outcome

For each metric, with OFF controls `A0`, `A1` and ON result `B`, both conditions must pass:

`B ≤ midpoint(A0,A1) + abs(A0−A1) + 0.05 × midpoint(A0,A1)`

`B ≤ 1.05 × max(A0,A1)`

Both p95 and p99 must pass at every view. The values below are milliseconds in **OFF / ON / OFF** order; [admission.json](admission.json) retains exact unrounded thresholds and decisions.

| View | p95 ms | p99 ms | ON draw / primitive delta | Result |
| --- | --- | --- | --- | --- |
| Exchange | 358.847 / 533.213 / 453.820 | 639.746 / 591.984 / 717.017 | 0 / 0 | **Fail p95** |
| George | 254.863 / 303.982 / 280.399 | 360.314 / 409.913 / 424.736 | 0 / 0 | **Fail p95** |
| Station | 152.377 / 170.915 / 174.895 | 222.630 / 329.386 / 300.921 | 0 / 0 | **Fail p99** |
| Barras | 323.989 / 351.988 / 399.660 | 622.022 / 417.542 / 536.026 | 0 / 0 | Pass |
| Clyde | 127.306 / 139.941 / 142.038 | 254.761 / 231.680 / 270.449 | 0 / 0 | Pass |
| Park | 155.562 / 205.588 / 245.870 | 267.015 / 264.954 / 389.978 | 0 / 0 | Pass |
| Heron wall | 383.545 / 340.567 / 236.483 | 556.867 / 467.308 / 443.533 | +1 / +539 | Pass |
| Botanical wall | 203.973 / 375.477 / 367.621 | 368.594 / 636.641 / 534.947 | +1 / +553 | **Fail p99** |

Raw per-frame timing/counter samples, p50, long-frame counts and reported static/video memory remain in `measurements.json`. Reported video memory is 26,034,337 bytes in all phase summaries; this is an engine counter, not a complete or isolated mural GPU-residency measurement. Accumulating sample arrays also affect reported static memory, so its drift is not a mural allocation delta.

Exchange and George OFF/ON PNG hashes are identical; their draw and primitive counts are unchanged. Station likewise has no extra reported mural submission. These culled/out-of-view results and large OFF-control variation **do not establish that mural rendering caused those spikes**. They also do not justify relaxing the unchanged gate or declaring a performance pass. The candidate stays OFF. A passing heron view is not an FPS improvement claim.

## Images and art disposition

[admission.json](admission.json) records successful decoding, dimensions and SHA-256 for **all 22 generated PNG files**: 16 paired OFF/ON files across eight views plus six composition views. Some front-view files contain identical pixels/hashes to their corresponding ON measurement view; this is not 22 independent compositions. The six selected files retained here are byte-identical to their source-receipt hashes; the complete original batch remains in the ignored local run directory above.

| Retained actual image | Purpose |
| --- | --- |
| [Heron front](heron_front.png) | Full bird silhouette and attachment to the existing rear wall |
| [Heron approach](heron_approach.png) | Oblique street composition and existing route context |
| [Heron close](heron_close.png) | Eye, feather and paint-overlap detail |
| [Botanical front](bloom_front.png) | Thistle/leaf silhouette and wall footprint |
| [Botanical close](bloom_close.png) | Fine strokes and the current coarse painted shapes |
| [Botanical oblique](bloom_oblique.png) | Building return, adjacent supported street and paint placement |

Root reviewed front/approach composition; the artwork author inspected all six retained images. The paintings are recognisable original bird/botanical designs attached to existing walls, with no floating labels or newly implied route. They remain **stylized prototypes**: broad flat fields, coarse close-up contours, limited tonal detail and little convincing interaction with masonry do not yet meet the owner's realistic mural target. Static captures do not certify temporal flicker under a moving gameplay camera, 1080p appearance, human enjoyment or target Mac comfort.

Keep this candidate disabled. Future work under the existing place/art/performance tasks needs a concrete improvement, an explicit resource budget, fresh frozen-source matched evidence and unchanged admission gates. Do not rerun the unchanged candidate until favourable timing appears. Any faithful reproduction of a particular real mural needs separately verified artwork rights and credit requirements; public source visibility alone was not treated as permission here.

## Evidence hashes

| Retained raw file | SHA-256 |
| --- | --- |
| `measurements.json` | `8f9c791632e04e25c2a6efb94f6301c037908bc71dbc868632bdde6d70fd9823` |
| `admission.json` | `c0b25c5eb062af197b980d6369fb77a78f40de243c0d26aa15bac4416488488c` |
| `source.json` | `ff5b57b229d8532ed11334e501bbe008dd4e8f7424ff5bd1b5a224fbdb681480` |
| `source-start.json` | `398f4b97ad77a478fd696f8eb7c6d4296e47ae69a3943b6947aae88dd2c83a24` |
