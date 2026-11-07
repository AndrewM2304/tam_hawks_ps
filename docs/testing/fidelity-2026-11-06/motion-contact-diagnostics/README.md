# Contact-fix development diagnostics

Independent QA inspected the producer's original before/after logs for
[FID-D009 and FID-D010](../../FIDELITY-REVIEW.md). The exact files and their hashes
are preserved in [the independent review](independent-review.json).

At the six overlapping relay ticks, physical tick, state, body position and
velocity match exactly. The lowest measured real GLB clearance changes from
−26.300 mm to +2.849 mm. At the twelve overlapping bank ticks, physical tick,
position and speed match exactly; the lowest recorded wall clearance changes
from −30.392 mm to +8.006 mm, and all recorded after-fix model-clear checks pass.
These are useful observations of presentation changes that preserve the sampled
physical trajectory.

This packet is **development evidence, not acceptance**. The producer did not
take complete source inventories before and after these runs. Scripts are copied
as inspected at review time; they are not asserted to be the exact historical
executed scripts. The independent reviewer has not inferred unrecorded ticks,
strict convex-query results, camera clearance or normal-speed appearance from
the sampled gap values. A later every-physics release witness still reports an
unclear model check at the loaded release input and first airborne pose. Both
defects remain open pending strict native finite-geometry diagnosis, a frozen
current-source replay and actual rendered review.

No capsule path, camera bound or contact tolerance was relaxed by this review.
