# Independent landing-window checkpoint

**47 checks, zero failures across fifteen actual Main cases.** The executed copy
contains 785 production inputs, with matching before/after/copy inventories. The
observer and wrapper bring the run inventory to 787 inputs; all are unchanged.
The original command, timestamp, logs and file hashes are in [the receipt](receipt.json).
This is a dirty-source checkpoint, not a final integrated main commit.

Each case starts from the real default spawn, uses mapped push/charge/flip/manual
input and records 96 consecutive native physics ticks. After the case-boundary
restart there are no per-frame body, speed, heading, balance or score assignments.
Actual floor contact occurs at tick 31. There are no bails. The [exact trace](candidate-matrix.json)
and [independent summary](independent-summary.json) preserve event order, queue,
support, earned combo and bank observations.

| Actual request | Result |
| --- | --- |
| Held 100, 200, 300 or 333.33 ms before contact | Manual enters at native contact; earned combo remains unbanked. |
| Held exactly 350, 366.67 or 450 ms before contact | Queue expires; no manual entry; original 800 banks once at tick 52. |
| At contact, 50 or 200 ms after | Manual enters at tick 31, 34 or 43; no early bank. |
| 400 ms after contact | Original 800 banks at 52; a separate manual starts at 55. |
| Request released before contact, or held stale since takeoff | No manual; original 800 banks once. |
| Actual two-tap gesture 200 ms before contact | Manual enters at contact; combo remains unbanked. |

The independently observed queue is airborne and unsupported; it does not invent
an early grounded manual. The [clean-main baseline](../manual-baseline/README.md)
rejected 200/300 ms early requests, so this retest establishes the intended wider
early window. It does not imply a wider late deadline or certify all pause, bail,
cooldown, speed-threshold, physical-controller or human-feel cases. Existing
author/integrated regressions and the remaining FID-304 clauses stay separate.

The reusable exact files are [the observer](observer.gd.txt) and
[the wrapper](wrapper.py.txt). They require an explicitly leased Godot slot and
a current imported source copy; do not run an editor import over another worker.
