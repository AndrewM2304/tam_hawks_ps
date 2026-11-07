---
name: gap-combo-validation
description: Verify actual scored-gap triggers, finite rail-destination finishes and single-combo chains with source-bound mapped inputs and original-state score/gap observation.
---

Use for a missed named gap, rail→jump→rail transfer, source/actual line inventory,
or a claimed cross-area single combo. Read `AGENTS.md`, current `docs/STATUS.md`,
`docs/architecture/interfaces.md`, `docs/product/AAA_BENCHMARK.md`,
`docs/planning/GAP-LINE-TICKETS.md` and
`docs/research/GAP-LINE-CONNECTIVITY-2026-11-07.md`. Load the level-design and
combo-usability skills for geometry or controls work. The orchestrator owns
Git/main integration and shared engine/source leases; actual implementations stay
default-enabled under the owner's mandate. Do not create background schedules.

1. **Bind the actual source.** Find every constructor feeding
   `world.get_gap_definitions()`, world/HUD route feeds and actual live grind IDs.
   Distinguish registered score gaps, unscored physical transfers, navigation
   guides and native mapped-input lines. Runtime edge cropping/curve bakes cannot
   be completely counted with regex. Reuse a pure getter export from an existing
   ordinary Main rather than spawn a second world just for registry data. Retain
   stable IDs and the exact source/currentness layer of historical evidence.
2. **Trace the true authority.** Inspect Main's actual tracker call and order
   relative to child Skater physics, native capture and score calls. Do not trust
   a header saying board contacts when the caller passes actor origin. Record
   current/previous position, air, floor, capture, physics counter, tracker phases
   and returned awards at the call itself. A matching physics number does not
   mean Main and Skater sampled the same phase. Keep detector window, maximum
   sample step and ordered scoring volumes separate from combo-link deadlines.
3. **Classify the real miss.** Compute swept segment→sphere minimum distance,
   ordered entry parameters, forward travel and elapsed time. A trajectory that
   never enters a sphere is a geometric/timing miss; it cannot demonstrate a
   finish-air rejection. A retimed trajectory can expose a different boundary:
   genuine airborne travel followed by expected native rail capture before the
   finish call. Preserve both trajectories and causes instead of replacing the
   original diagnosis. One-way gap definitions do not imply reverse awards.
4. **Use faithful observations.** Prefer original methods plus read-only event
   records. If a private observer subclass is necessary, install it on a freshly
   created Main before tree entry, call the actual `super` methods and compare a
   separate untouched tracker against every actual input/state/result. Shadow
   awards must never enter scoring. Bind observer code, source/import cache,
   process/command/deadline/exit and error scan; preserve failed or scope-corrected
   receipts verbatim. Explicitly close output and defer cleanup outside physics.
5. **Observe every score path.** Main awards named gaps directly with
   `ScoreSession.add_trick(gap.name, gap.points, "gap:" + id)`; a receipt listening
   only to `skater.trick_performed` misses them. Observe actual trick/hold/spin/
   upgrade/bank/drop/reset calls as needed, retaining stable identities, native
   gap awards and source point definitions. Recompute score independently,
   including run-long repetition across banks, declared halving saturation,
   multiplier/score caps and upgrades. Do not invent a Catalog gap definition,
   add scores from separately reset fixtures or silently omit unsupported events.
6. **Preserve legitimate input.** One initial fixture may define spawn/facing;
   after movement starts use registered actions only. Current Manuals balance
   with W/S while A/D steers independently. A speed helper must not overwrite
   Manual balance. Repeated brake/push threshold switching may select a genuine
   Nollie/Boneless gesture; preserve that trace and try coasting/quiet setup before
   blaming geometry. Never assign actor pose, yaw, speed, velocity, balance,
   trick/capture IDs, gap awards or score to manufacture a chain.
7. **Change finish policy only with explicit scope.** Ordinary airborne gaps and
   their grounded-finish negatives stay strict. Any native-destination exception
   must be authored opt-in, tied to expected live bearing IDs and inspected
   native body/RID/integer shape/contact authority, and fresh capture covering
   the actual sampled interval. Reject wrong target/owner/shape, generic or stale
   capture, no prior air, reverse travel, radius/window misses, malformed state,
   pause/restart/bail and repeated awards. Do not widen spheres/windows/deadlines
   or globally accept any grounded finish. Prototype and independently review
   the real caller plus native positive/negative cases before actual promotion.
8. **Keep score and physical acceptance separate.** A scored capture does not
   prove full board/tyre/sole/rider/capsule/chase clearance or believable movement.
   Use current finite contact contracts; never borrow loaded solver tolerance
   for an actual tyre intrusion or an unloaded flight. Record consecutive real
   physics steps, exact launch/landing/support/bearing, meaningful event spacing,
   bails and recoveries. Inspect actual moving output after native proof.
9. **Report the correct line.** Exactly one positive terminal bank and no earlier
   bank is required for a single-combo claim. Label a spatial loop with two banks
   as two combos. A through-run, reverse copy, transport return or guide cycle is
   not a distinct returned line or completed cross-area circuit. Keep the
   two-distinct-lines-per-six-arenas and three-cross-area-circuits benchmark open
   until the complete source-bound runs pass independent QE/BA. Untimed overlap
   yields no frame-performance/M5/human-feel result.

The durable baseline example is
`docs/testing/line-design-2026-11-06/gap-combo-native-2026-11-07/README.md`:
southbound WEST/EAST entry awards and single banks, northbound no awards,
zero-wait return geometric miss, and separate WAIT12 finish-policy rejection.
It is not itself admission of a later production policy or whole-map quality.
