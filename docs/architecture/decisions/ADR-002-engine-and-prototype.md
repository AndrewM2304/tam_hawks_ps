# ADR-002: Godot procedural skating prototype

Status: Accepted for M00/M01. Date: 17 October 2026. Owner: A01.

Follow-up: [ADR-004](ADR-004-selective-reuse.md) records the owner's direction to prefer inspected reusable components. This initial prototype choice is not a restriction on third-party reuse.

## Context

The owner's plan specifies Godot 4.x, arcade skating and a macOS/Apple Silicon target. The repository is empty, and responsiveness must be assessed before investing in a large world or polished assets.

## Decision

Pin Godot 4.6.3, use native GDScript and the Compatibility renderer, and start with an original procedural square. Separate skater, world, scoring and session/UI responsibilities through `docs/architecture/interfaces.md`. The first slice includes movement, ollies, simple aerial tricks, camera, banked landing score and a restartable run. It establishes foundations for M02; it is not the final combo system.

## Alternatives

A third-party controller would introduce licensing and fit risks before the core feel is understood. A full four-district art build before controller feedback would make route redesign expensive. Native dependencies and imported asset packs are unnecessary for this proof.

## Consequences

M01 can be tested locally with minimal dependencies. The engine pin must be shared by setup scripts and documentation. Actual controller feel and target performance remain human/hardware gates. Procedural geometry is scaffolding for design, not evidence that M03's four districts are complete.
