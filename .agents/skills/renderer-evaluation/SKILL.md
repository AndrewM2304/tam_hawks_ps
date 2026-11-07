---
name: renderer-evaluation
description: Compare Godot rendering paths and evaluate engine changes for Tam Hawks Pro Skater on the owner's MacBook Air M5 using matched visual, gameplay and performance evidence.
---

Read AGENTS.md, docs/product/AAA_BENCHMARK.md, docs/planning/FIDELITY_TICKETS.md and the current STATUS before acting. Reconcile origin/main first. Work on main, preserve other agents' ownership, spend nothing, and retain personal Music isolation.

The owner permits an engine rewrite if needed. Treat that as implementation authority, not evidence that migration is required. Establish the actual limitation: asset quality, shader capability, animation/contact, frame pacing, portability or production workflow. Inspect the existing renderer before recommending another engine.

Use the pinned engine's official renderer documentation and retain exact links/date. Compare the same frozen source, camera, resolution and input trace. Compatibility uses OpenGL; Mobile and Forward+ use RenderingDevice and can use native Metal on supported Apple Silicon. Record the actual selected backend rather than infer it from project settings.

Declare geometry/draw/texture/memory budgets before changing rendering cost. Reuse shared resources, existing culling and LOD. Capture ordinary chase views and close material/character views with the existing proven natural frame_post_draw pipeline; do not reintroduce manual force_draw readback. Separate diagnostic fixtures from real-input gameplay. Retain logs, hashes and failed comparisons.

On Linux, local software Vulkan can validate rendering and shader compatibility. Keep any extracted driver and SDK outside tracked source, verify distribution hashes, and use inherited network policy and CA trust. Such measurements do not establish Mac frame rate. Never change default renderer solely because the software preview looks better.

For a renderer default change, verify shader parity, current regression, native exports and a route through the actual default scene. Provide an explicit fallback and keep Mac/hardware acceptance unmeasured until observed. For an engine rewrite, retain the working source, asset provenance, control/trick/career/save contracts and evidence; require a reviewable playable vertical slice, portable build and a concrete migration/parity plan before replacing the game.

Report the visible benefit, actual costs, defects, tested scope and exact remaining gates. A successful compile, export, screenshot or benchmark table cannot certify AAA fidelity.
