# ADR-035 — San Francisco-scale original skating neighbourhood

Date:7 November2026. Status: direction authorised; implementation and validation in
progress. This does not admit an unbuilt map or certify AAA quality/M5 performance.

## Problem and authority

The owner reports too much flat travel between occasional rails or jumps. They
explicitly permit cutting/shrinking areas and request online reference research
and a replan. Their subsequent correction rejects Warehouse as too small and asks
us to think of San Francisco. The112×88m Merchant Yard proposal is superseded;
its independent portal and headroom defects remain historical failed design facts.

## Decision

Build **Merchant District**, an original medium urban Glasgow neighbourhood.
Use [the inspected San Francisco references](../../research/SAN-FRANCISCO-LINE-REFERENCE-2026-11-07.md)
for adjoining street/court spaces, elevation, roof routes and overlapping returns.
Do not copy franchise geometry, maps or assets. Its proposed200×160m envelope is
our starting design estimate, not a measured commercial-game dimension or a final
approved size. Test actual line cadence, landings and traversal before final art.

Remove long empty transport stretches from the default. Buildings should bound
interconnected streets and courts, with useful banks, ledges, wall exits and
elevated crossings. Count achievable next contacts and returned combos, not props
or route-label totals. Preserve realistic character/board/feature scale and clear
beginner bypasses. Ground/roof overlap needs real support voids and trick headroom.

Keep the existing city as **City Tour**, available through ordinary level selection.
Load/instantiate only the chosen world; a hidden live legacy city is not acceptable.
The owner authorises this change of default content. Earlier trial-default rules
continue to apply within City Tour and do not require a sprawling combined world.

## Integration contracts

- Default identity `merchant_neighbourhood_v1`; legacy `glasgow_legacy_v1`.
- Retain the22 current world query signatures, including the newly integrated
  `get_gap_grind_destinations()` dictionary. New worlds additionally expose
  `get_level_manifest()` and `get_activity_layout()`; root owns Main/HUD selection,
  the level designer owns geometry/manifest and the integration engineer owns
  persistent progress. Activities must use explicit current-world coordinates;
  absent optional legacy actors must not spawn at old hardcoded locations.
- Preserve existing `user://career.json` and backup source bytes. A missing new
  `user://career-v2.json` may migrate validated version0/1 progress into the City
  Tour domain once. A damaged/newer new book must not silently fall back to old
  data. Per-level completed goals, best score and best combo remain independent.
- New Merchant goal/event IDs are namespaced. Settings, control bindings,
  cosmetics and genuinely earned special unlocks remain global. Never grant an
  old City Tour completed goal merely to unlock a new-level reward.
- Scripted launch/profile and personal Music isolation remain in force.

## Delivery and verification

The [working plan](../../planning/COMPACT-LEVEL-REPLAN-2026-11-07.md) owns the scaled
diagram, feature placement, resource budgets and implementation tickets. It must
lead to a playable native prototype, not merely another diagram. Native probes
verify portals, voids, ramps, landings, real guide support and accepted heights.
Ordinary-input runs and moving views verify linked choices and returned circuits.
Closed-combo acceptance requires one uninterrupted score chain and one bank.

Run the legacy regression explicitly against City Tour; preserve its old source
scope and failures. Add separate new-default, level-selection and progress tests.
Changing the old six-area requirement is a supersession, not a passed old gate.
Rendered fidelity, fun, actual M5 startup/performance and final art remain separate
requirements. Continue authorised implementation after a passing checkpoint.
