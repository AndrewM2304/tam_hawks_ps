# Released-board collision cost — private, not adopted

This follows [the contact diagnosis](../native-construction-02/README.md).
The production game is unchanged. Forty-nine payloads plus the952-input initial
closure and subsequent exact probe deltas preserve four epochs on main7a3a234.
All referenced Git blobs were checked against that commit's tree. Each native
receipt has exact before/after inputs, exit0, no errors and a90s external bound.
No body movement is forced after the declared initial conditions of each fall.

Cost03 alternates three box/component pairs,12 identical tilted native drops per
epoch,2,160 observations each. The same1mm private-space allowance applies to
both. Existing native32 shapes are reused, adding31 nodes and no shape/mesh/
texture resources or script queries. Measured incremental node/registration
allocation is106,344bytes initially, then87,848–87,880bytes, versus3,012–3,016bytes
for the box. Below the declared128KiB component gate; not whole-game residency.

**Native TIME_PHYSICS_PROCESS readings are rejected.** The monitor updates on a
different cadence, repeats values between samples and retains initialization
cost. These are not per-tick measurements. Complete headless harness intervals
are preserved separately: component p95=1,367–1,406µs versus276–305µs for the box;
total identical-drop workloads take1.130–1.189s versus0.347–0.356s. That added
cost is substantial. It does not justify the declared250µs/p95 native-cost gate,
and neither the monitor nor harness proves target-Mac physics performance.

Inventory04/05 exports the actual cached component bounds and points. SciPy
ConvexHull planes show nine whole hulls fully inside one other hull: grip and
eight bolt heads are contained in the existing wood convex hull. This is a
containment proof of existing **collision hulls**, not a claim that solid wood
fills the real concave deck top. No exposed geometry is deleted or expanded.
The point-in-hull arithmetic allowance is1nm; original floating native points
and the exact containment map remain in inventory05.

Cost06 reuses23 shapes, removing only those nine contained hulls. Extra retained
node registration falls to62,920bytes after warmup (initial76,224). Identical-drop
workload falls to0.805–0.838s; p95 harness intervals remain1,207–1,261µs versus
286–306µs. The stale native monitor remains invalid. This is useful development,
**not performance acceptance**, so neither alternative is installed.

Next: a bounded physically justified collision simplification or engine-native
optimization, fresh actual-geometry void/contact tests, uncontended native-cost
proof and ordinary bail/recovery/cone checks. Any global solver change affects
the festival cone too. Do not widen tolerances or translate the visible board to
hide burial. FID-103 and complete contact/motion/independent QA stay open.
