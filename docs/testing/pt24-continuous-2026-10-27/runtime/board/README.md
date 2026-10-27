# Reuse native board-support ray parameters

**C10 · A04/A09 · P0 · M06.** Two sites inside `_native_board_floor` created a
new `PhysicsRayQueryParameters3D` for every real-wheel support ray. Ordinary
planar support uses four rays; a complete nonplanar fit uses sixteen. The repair
retains one factory-created parameter object per skater and rewrites the current
endpoints, live collision mask and self-only RID exclusion before every sequential
native call. All original factory flags remain. Only these two support sites
use the new helper.

The centre-floor query, fitting passes, finite support decisions, floor-angle
limit, wrapped-bowl ownership, real tyre landmarks, shape checks, native call
order/count, resulting fit and body/presentation behavior remain unchanged.
There is no stored hit answer or cross-update result cache. Self-exclusion arrays
and native hit dictionaries are still created as before. The change removes the
repeated parameter-object construction while retaining one extra object per
skater; it does not remove all allocations or reduce native query counts.

The test uses one actual native skater and one isolated world. A fresh-query
control runs the same full fitting function on that same rider with newly
constructed original parameters. It compares exact native request endpoints,
mask, exclusions, flags, hit dictionaries, order/count and fit results, along
with unchanged body/capsule/visual state. Fixtures include flat and bank support,
a six-centimetre split step, missing finite support, an unreachable lower step,
an unrelated steep plane and absent floor. Three existing exact bowl witnesses
retain valid finite fits; removing their wrapped ownership must reject the same
real steep faces. Direct native controls cover layers 1/8 versus 2 and areas,
live mask changes, stale exclusion replacement, an actual unexcluded self-hit,
moving blockers and independence of earlier hit dictionaries.

[Parser-only result](focused/parser/receipt.json): exit 0, clean and stable across
650 inputs, 0.604 seconds. This is a parse check with zero native assertions.

[Focused native result](focused/current/receipt.json): **23 passed / 0 failed**,
exit 0, clean and stable across the same 650 inputs, 0.801 seconds. Thirteen
same-rider paired fits retain exactly **77 native support rays** with identical
request/result/order/count, returned fit and body/presentation state. The fresh
control constructs 77 ray parameter objects; the changed solver retains one.
The ordinary flat and bank cases retain four rays each; the six-centimetre split
step and all three wrapped-bowl fits retain sixteen each. Missing edges, the
unreachable lower step, unrelated steep support, absent floor and unwrapped-bowl
negatives retain their original rejection behavior. All direct flags, layer,
area, mask, exclusion, actual self-hit, moved-blocker and prior-result controls
pass. Both runs bind manifest:
`d4d952cff70346569df5064018e61f5e9b78dd8b4845a18e633a4b205aee903c`.

[Source index](source-snapshots.json) resolves all 650 inputs to 643 immutable
parent blobs at `cd661ca5b1e08a1a803570b1bd6e936ac0c9aed8` and seven exact retained
changed snapshots. Raw receipts, logs and before/after maps are unchanged. These are
parameter allocation counts and equivalent native outcomes, not target-Mac
timing or a claim to resolve the reported stutter. Root owns final integrated
admission and the existing real-input manual/bowl/wall/attachment suites.

```sh
python3 docs/testing/pt24-continuous-2026-10-27/runtime/board/observers/prepare.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/board-floor-ray-parser timeout 15s ./tools/run.sh --headless --audio-driver Dummy --check-only --script .local/board_floor_ray_focused.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/board-floor-ray-focused timeout 30s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/board_floor_ray_focused.gd
```
