# ADR-014 — Human input margins and current-map rendering

- **Date:** 17 October 2026
- **Status:** Accepted bounded implementation; human feel and Mac performance remain open.
- **Scope:** Existing M01/M02 handling, M05 assets and M06 performance/presentation; no new area.

The owner asks for research into arcade skating controls, real human rail errors, higher fidelity assets and more efficient rendering. Prior perfect-route checks establish reproducibility but do not establish a comfortable capture envelope or commercial-game feel.

This slice fixes slope gravity restarting a disabled/braked rider, admits rail capture across completed collision-adjusted movement with the same reach/angle/clearance gates, and gives fresh flip/grab/manual requests a short bounded pre-contact buffer. Held inputs cannot repeatedly score and overtime/reset/disabled controls clear pending requests. Controller defaults place grind on Triangle, revert on R2 and restart on R3 so the expected grind button cannot reset the run. Saved custom bindings retain their existing validation and warning behavior.

Remove live floating district identification; the map/pause retain readable location context, and existing landmarks supply place identity. Preserve career district visits and real world signs.

Rendering changes must preserve current geometry, materials, collisions and gameplay. Godot already culls outside the camera; use spatially bounded batches and shared geometry where measured, rather than hiding whole districts. Compare actual rendered draw/object/primitive counters before/after. More triangles alone do not remedy UV/material/animation issues. One original Blender-generated GLB skateboard is a bounded pipeline proof with recorded provenance and unchanged contact dimensions.

Pinned MIT source inspection informs the research; no commercial code or assets are copied. Hold/release ollies, latched grinds, travel/stance-aware landing and a tighter turn curve require a coherent controller follow-up with real input routes and human tuning. They remain documented next work, rather than being inferred complete from this slice's automated checks.
