# ADR-005: Tam Hawks and the required Glasgow visual finish

Status: Accepted direction; production art remains planned. Date: 17 October 2026. Owner: A01, recording the owner's explicit correction and visual requirements.

## Decision

The title is **Tam Hawks Pro Skater**. Use it consistently in the project, game UI, documentation and future packaging.

The visible M01 cuboid environment and primitive rider are a temporary gameplay blockout. After core gameplay acceptance, produce believable detailed Glasgow environments, a proportioned animated skater and polished UI. Build one representative polished scene and HUD treatment before expanding it. Free compatible models, materials, animation and UI resources may be adapted with provenance; no paid tools or assets are authorised.

Research real shops, venues and street layouts for recognisable boundary facades. Verify current or deliberately historical frontage references, preserve useful adjacency and label adaptations for skating. Street View may support research through free public access, but its images are not approved game textures.

## Delivery and acceptance

[ART_DIRECTION.md](../../product/ART_DIRECTION.md) specifies the target, and [VISUAL_ACCEPTANCE.md](../../testing/VISUAL_ACCEPTANCE.md) defines evidence. M03-006 verifies references; M03-007 integrates recognisable edges; M05-001/M05-002 replace blockout environment/skater; M06-002 finishes UI. **M06-007 is the mandatory final graphics/UI cleanup and owner acceptance gate**, feeding M06-006 and release readiness. Incomplete art or unavailable review remains open if a session ends.

The dated address leads and network blocker are preserved in [GLASGOW_REFERENCES.md](../../research/GLASGOW_REFERENCES.md). No map layout or Street View imagery has yet been inspected. Do not present the current generic shops as researched reconstructions.

## Consequences

Retain the existing Godot engine and accepted gameplay contracts while improving presentation. Evaluate visual quality in real rendered gameplay, then measure 1080p/60 fps on the declared target Mac. A title rename, screenshots, passing automated tests or a playable blockout does not close the final visual gate.
