# ADR-004: Prefer inspected reusable skating components

Status: Accepted. Date: 17 October 2026. Owner: A01. Implements the owner's explicit direction to research and reuse existing movement/trick implementations.

## Decision

Use existing Godot engine facilities and evaluate suitable open-source projects before writing new generic skating systems. Keep the 4.6.3 engine pin and current playable controller while adopting small compatible components with licence/provenance records and focused tests.

Adopt Not Pro Skater's MIT `GrindLine` geometry helper at pinned revision `d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988`, preserving its notice and adding malformed-data guards and transformed world-space authoring. The helper is preparatory work for grinds; it does not complete M02-002. Use 3deric's GodotSkate state/trick architecture and Not Pro Skater's grind/combo patterns as evaluated references for M02.

## Evidence and alternatives

[The research record](../../research/SKATING_REUSE.md) identifies actual inspected files, versions, licences, limitations and the imported file hashes. Whole-project replacement would couple our game to different scene hierarchies, engine versions, control rules and assets. Rewriting every reusable component would ignore the owner's requested efficiency. Selective extraction lets us validate a useful piece under our existing tests.

## Consequences

AGENTS now requires a reuse check for substantial new systems. Code licence and asset licence are reviewed separately; free compatible code can be adapted without asking for repeated permission. Keep attribution/modification records and include notices in eventual exports. No paid tools/services or engine upgrade is introduced. Physical Mac/DualSense and feel gates remain unchanged. ADR-002's initial custom-prototype choice is historical, not a requirement to keep building everything ourselves.
