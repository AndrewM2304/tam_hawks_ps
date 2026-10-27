# Reuse each rig's current grab fallback metadata

**C10 · A04/A09 · P0 · M06.** `SkaterVisual.animate` previously called the pure
`TrickAnimation.grab_pose` function on every update, including ordinary grounded
skating. Each call created a new five-key dictionary of scalar/Vector3 fallback
values. The rig now retains one dictionary keyed by the exact current raw grab
ID. It refreshes on a changed ID or empty cache. Only `hand_side`, `deck_target`
and `tuck` are read from that dictionary; state/catalog overrides still evaluate
on every call. The original neutral animation during reset remains responsible
for restoring the Melon default. No global catalog behavior, pose math, contact,
physics, scoring, renderer, feature availability or Music changes.

The paired native test builds two complete actual rigs. One uses the cache and
counts distinct returned fallback objects; the control executes the original
fresh `TrickAnimation.grab_pose` call every update. Every compared pose includes
all Node3D transforms, all native skeleton bone poses, anatomical blend shapes,
and actual weighted cloth seam/contact samples. Coverage includes 60 ordinary
updates, every authored grab, unknown and empty raw IDs, same-ID live override
changes, reversed-deck release fading and explicit reset. A deliberately
corrupted cached tuck must produce a rejected full-output comparison. This is a
synchronous geometry fixture, not played input/controller or target-Mac evidence.

[Focused native result](focused/current/receipt.json): **8 passed / 0 failed**,
exit 0, clean and stable across 646 inputs, 0.952 seconds. All 248 paired updates
retain exact outputs. Including the two construction/reset poses, the cache
constructs 14 fallback dictionaries and the fresh control constructs 250. Across
60 ordinary updates, the cache constructs zero new fallback dictionaries and
the control constructs 60. The test covers eight authored grabs plus unknown
and empty IDs, preserving one retained dictionary slot. The corrupted-tuck
negative is detected by the actual output comparison. Manifest:
`c14cd60a2d7a521e579e8d035e20ad200c91bbb5b70eb7a8394ffc8b09f4e1ad`.

[Source index](source-snapshots.json) resolves every outer input to an immutable
parent blob or exact retained changed snapshot. The raw receipt, log and
before/after source maps are unchanged. This removes repeated fallback-dictionary
construction; these work counts and verification duration do not establish FPS
improvement or resolve the owner's reported target-Mac stutter.

```sh
python3 docs/testing/pt24-continuous-2026-10-27/runtime/grab/observers/prepare.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/grab-pose-cache-focused timeout 30s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/grab_pose_cache_focused.gd
```

Root owns final combined `tools/check.sh` admission, including the existing
real-input grab/manual/bail and deformed-cloth attachment suites.
