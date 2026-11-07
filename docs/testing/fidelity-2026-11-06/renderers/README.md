# Independent Compatibility / Forward+ review

Reviewed by independent QA on 7 November 2026. **Both backends render this static
default-Main workload; no default renderer change is justified by the inspected
result. Overall fidelity, motion, performance and Mac acceptance remain open.**

Root executed the same source copy and observer through both renderers. QA
independently opened all 17 paired views, decoded all 34 original PNGs, compared
every RGBA8 buffer hash with its native receipt, checked all six Canvas swatches
and independently recomputed eight projected head/board marker centroids. All
checks agree. The 17 view records have exactly matching camera/player/fixture
metadata across backends. Both runs have identical inventories of 781 inputs:
779 game/test/tool/project files plus the exact observer and wrapper retained here.
Before/after inventories are unchanged within each run. Changing Git status in
the ancestor working checkout does not describe a mutation of the isolated copy.

[Independent review JSON](independent-review.json) contains the full per-image,
projection, source and view-matching results. [Preservation hashes](preservation.json)
bind the retained originals, logs, receipts, manifests and exact observer/wrapper.
`renderer-gl/` and `renderer-forward/` retain every original 1280×800 PNG; no
resized image or contact sheet substitutes for the native evidence.

[Compact four-view comparison](comparison-preview.webp) is a labelled derivative
for navigation only. [Exact independent verifier](independent-verifier.py.txt)
retains the QA decoding/source/projection method; its original paths refer to the
ignored comparison copy and can be adapted to the preserved packet.

Each engine exits 0 with a clean error scan and final **61 checks / 0 failures**.
Each `snapshot.json` records 60 checks because it is constructed before one last
writable-receipt assertion; the final stdout result includes that assertion. These
are two separate capture epochs, not an additive whole-game regression count.

## Actual findings

- Both backends preserve the complete view geometry, actual rider position,
  ordinary spawn, material bindings and diagnostic camera/Canvas synchronization.
  No missing district, rejected shader or failed asset load appears in these logs.
- In the unchanged lighting setup, Forward+ makes the ordinary square and district
  overviews darker and less saturated, while foliage appears paler. Compatibility
  has stronger bright-stone/shadow contrast. The material and silhouette defects
  survive the switch; neither output meets the full benchmark.
- Skin/hands and photographic stone/paving improve over the clean-main baseline.
  This earlier rider still has an angular torso/hip silhouette, thin garment
  detail and abrupt shoulder/waist transitions. Later continuous-garment changes
  are outside this source epoch and need new motion/close-view review (FID-D001).
- Paving repeats remain obvious across large courts; shop windows still read as
  flat regular panels. The shared room shader is already bound in this source
  copy; the observation concerns the visible result, not an absent shader.
  Forward+ alone does not supply architectural recess or surface variety
  (FID-D002 / FID-201 / FID-203).
- The east-quay benches give a more readable sequence than the original layout,
  but broad transport space and weak end staging remain apparent from this view.
  This copy precedes the final two-metre bank-return geometry; its rollback,
  misses, sightlines and continuous return must be replayed separately (FID-D003).
- Water response differs, including the strong bright reflection in the
  Compatibility west-quay view. Still images cannot judge moving bands, shimmer
  or cost. The separate source-stable water experiment owns that question.

QA independently opened the [official Godot 4.6 renderer overview](https://docs.godotengine.org/en/4.6/tutorials/rendering/renderers.html)
on 7 November 2026. It distinguishes the OpenGL Compatibility path from
RenderingDevice-based Forward+/Mobile with Vulkan, Direct3D 12 or Metal. Its
advanced-feature differences support further targeted experiments; this capture
does not enable or test a representative GI/reflection upgrade. The documentation
also warns that switching paths can need lighting/environment adjustments. This
comparison therefore demonstrates current-scene capability, not equivalent tuned
maximum quality or an engine-level limit.

## Reproduction and limits

Original project: `.local/renderer-comparison-source`, Godot 4.6.3 official,
Debian 13 x86_64. Compatibility uses OpenGL 4.5 Mesa 25.0.7 llvmpipe LLVM 19.1.7;
Forward+ uses Vulkan 1.4.305 llvmpipe LLVM 19.1.7. These are software devices.
The native Metal backend and the owner's M5 Air were not exercised.

From that isolated project, root ran:

```sh
python3 .local/qa-fidelity/capture.py renderer-gl gl_compatibility
python3 .local/qa-fidelity/capture.py renderer-forward forward_plus
```

The exact receipts contain UTC, command, OS, backend, environmental overrides,
Git ancestor scope and fixture disclosure. The original observer extends the
existing full-fidelity natural `frame_post_draw` pipeline. Ordinary spawn follows
40 native settled ticks; seven overviews, three camera/Canvas proofs, three
authored 3.3-metre idle rider views and three environment views are diagnostic
setups. Idle native motion is frozen for inspection. They are not a completed
physical route, a two-metre benchmark rider review or a normal-speed action reel.

Initial shader/pipeline compilation and concurrent permitted CPU diagnostics
affect Forward+ wall time. Fixed-fps software captures and their readback timings
are **not comparative performance or Mac FPS evidence**. No renderer cost gate,
sustained pacing, physical controls, human enjoyment or final revised production
source is accepted here. The original isolated source copy remains under ignored
local storage; this packet preserves inventories and exact observer/wrapper
without duplicating the entire production source/assets.
