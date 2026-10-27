# Native practice-location cue frames

**Two native frames, zero failures.** The current-source normal Main and its
actual map modal now identify both practice starts as Kelvingrove Park.
The PNGs were inspected: the normal location description is readable and the
real route map/player marker remains visible.

The existing practice feature identifies itself as Kelvingrove, but the outdoor
public district query omitted the authored practice-apron footprint. The quarter
approach (−85,6.08,−130) and manual-pad point (−82,6.08,−135) therefore fell through
to Central Station. The repair supplies the existing exact apron to that query;
it does not add art, collision, a new district identity or a fabricated HUD label.

## Actual UI capture method

[`practice_location_capture.gd`](observers/practice_location_capture.gd) constructs
two independent actual Main instances. Persistence is disabled before each enters
the tree, and no design-content override is assigned. Each declared initial
spawn/facing is followed by **30 ordinary native updates** with the normal chase
and Main/HUD processing. The observer records the resulting actual actor position,
native floor, public district/location and Main's actual HUD location state.

The normal gameplay HUD retains location in its state; its map modal is the
existing place where the text is rendered. The observer calls the production
`HUD.show_map()` path, allowing it to pause the real game and build its normal
"You are in KELVINGROVE PARK" description from that actual state. After 20 normal
UI process updates, a completed `frame_post_draw` supplies each 1280×800 PNG.
No HUD state snapshot, label text, camera transform, route data or world feature
flag is assigned to manufacture the result.

The native image/manifest records include hashes, actual visible modal text,
source hashes, renderer, camera and actor positions, and draw/primitive/memory
counter snapshots. These are normal map-modal cue stills, not unobscured gameplay
art views, temporal motion, a route-completion proof or Mac/performance acceptance.
The headless route witnesses provide the separate actual-input evidence.

Reproduction commands from the repository root:

```sh
cp docs/testing/pt24-connections-2026-10-27/observers/practice_location_capture.gd .local/practice_location_capture.gd
cp docs/testing/pt24-connections-2026-10-27/observers/practice_location_capture.sh .local/practice_location_capture.sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/practice-location-rendered .local/practice_location_capture.sh
```

The shell uses the existing Xorg dummy-display configuration if no display is
available. Native engine workloads remain serialized.

## Actual results and exact evidence

[Native manifest](captures/practice-location/manifest.json),
[quarter approach](captures/practice-location/practice-quarter-map.png),
[manual-pad point](captures/practice-location/practice-manual-pad-map.png).
The [outer receipt](validation/practice-location/receipt.json), raw console and
before/after maps record exit 0, clean log, **618 unchanged inputs**, 65.944s.
Source-manifest SHA256:
`c2f70aad8e0336bd88af3fe77e0ea6b951e046ba473e6a3da0f99a73fb0ce82a`.
The inner native manifest binds 252 game/capture/config inputs. Both PNG hashes
and the exact archived observer/shell hashes were checked against that manifest.

Both actual public districts are `kelvingrove`; World and ordinary Main HUD
location strings are `KELVINGROVE PARK`. The visible normal modal text is exactly
"You are in KELVINGROVE PARK. Explore the city, river and park." Both actors are
natively grounded, not bailing, and keep their real chase camera current.
The quarter actor settles at Y6.00016 on the Y6 floor. The manual-pad actor
naturally resolves its declared initial placement onto the actual pad at Y6.40864,
with native hit Y6.4; no post-spawn correction is assigned by the observer.

| Declared case | Draw calls | Primitives | Video bytes | Texture bytes |
| --- | ---: | ---: | ---: | ---: |
| Quarter approach | 660 | 832,316 | 84,076,387 | 56,844,613 |
| Manual-pad point | 662 | 832,884 | 84,076,387 | 56,844,613 |

These are per-frame snapshots from different camera/actor positions, not a
before/after resource delta or frame-time benchmark. Rendering used Godot 4.6.3,
Compatibility, Mesa llvmpipe LLVM 19.1.7. The real map modal intentionally darkens
its normal world/chase background; these are cue proofs rather than unobscured
world-art screenshots. Actual Mac, moving shadows, physical controls and target
performance remain unclaimed.
