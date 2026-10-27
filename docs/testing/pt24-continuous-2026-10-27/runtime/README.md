# Reuse camera visibility-ray parameters

**C10 · A04/A09 · P0 · M06.** The existing camera already caches exact query
answers within one synchronous update and reuses ground/shape parameters. Its
body/head/foot visibility and tiny endpoint-support rays still constructed a
fresh `PhysicsRayQueryParameters3D` on every native call. Previous camera-cache
witnesses retained29,400 such rays across96 paired updates; each still allocated
its own short-lived parameter object.

The repair retains one parameter object per camera and rewrites its endpoints
and exclusions before each sequential query. The exact mask1|8 and all original
native ray flags remain. Native call order, hit dictionaries, same-update answer
cache, visibility/support rules, body/board/head landmarks, frame/FOV calculations
and rider physics are unchanged. Query answers are not retained beyond the
existing cache scope. No visible resource, native-query-count reduction or
Mac frame-time/stutter resolution is claimed; this removes parameter-object
allocation, while retaining one extra query object per camera.

The new native suite pairs the full camera solver with a fresh-query control,
checks persistent identity through views/reset, then checks actual native
endpoint changes, layer1/8 versus player-only layer2, exclusion clearing, hit
result independence, immediate moved-obstacle invalidation and the tiny floor
support ray. The unchanged prior camera acceptance suite retains anatomical
head/board/foot occlusion, finite supports, moved blockers and cache boundaries.
A second observer compares against the exact immutable camera from main700e304,
not only an overridden helper inside the changed script.

## Admitted native results

[Focused current](focused/current/receipt.json): **76passed /0failed**, exit0,
clean/stable638 inputs,0.951s. This comprises16 new native reuse assertions and
60 unchanged camera-cache/head/board/foot acceptance assertions. Its manifest is
`af4cff5adc4410e6bdc45265bf839df55e98dcf5dc59210688fb782a276c33a5`.

[Immutable original camera](focused/immutable-parent/receipt.json): **5/0**,
exit0,clean/stable639 inputs,0.713s. Its manifest is
`d432e000f740bbcc6f4ed6785193b2a37833494b914be91339c5193a38e089f9`.
This independently compares the actual original700e304 script with the changed
camera; it does not infer old behavior from a newly written helper alone.

Both40-pair witnesses execute **11,264 unchanged native visibility rays** with
exact camera transform/FOV/semantic-state/query-count parity. The fresh original
constructs11,264 short-lived ray parameter objects; the changed camera retains
one. Native positive/negative hit/miss, rail-only/player-only layers, exclusion
clearing, direct call invalidation, prior hit independence and tiny endpoint
support all pass. The unchanged96-pair cache test also retains its existing
336cached/816uncached shape checks,29,568/44,352 visibility rays and336 sweeps;
this patch does not claim those prior caching savings as new work.

[Source-snapshot index](source-snapshots.json) resolves every outer input to an
immutable-parent blob or exact retained changed snapshot. Raw native logs and
source maps are unmodified. Full integrated admission belongs to root's later
combined receipt. These work counts and sub-second verification durations do
not certify target-Mac performance, stutter resolution or frame-time improvement.

From the repository root, with no other engine/render workload:

```sh
python3 docs/testing/pt24-continuous-2026-10-27/runtime/observers/prepare.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/camera-ray-reuse-focused timeout 60s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/camera_reuse_focused.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/camera-ray-reuse-legacy timeout 60s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/camera_reuse_legacy_parity.gd -- .local/camera_reuse_legacy_camera.gd
```

The explicit final argument binds the ignored legacy preload to the outer
source manifest. The preparation helper verifies its immutable source hash.

The subsequent [local trick metadata and HUD label slice](labels/README.md)
records its separate implementation, exact-source controls and admitted native
results. It preserves the camera receipts above and their earlier source scope.

The [single-slot rig grab fallback cache](grab/README.md) has a later independent
paired native output/count witness. Its source scope and results remain separate
from both earlier receipts.
