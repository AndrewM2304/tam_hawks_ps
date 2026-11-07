# ADR-034 — Fidelity studio and MacBook Air M5 rendering

Date: 6 November 2026. Status: active implementation; visual and hardware acceptance open.

## Context and authority

The owner requires a substantial increase in realism, character/material quality,
animation coherence and compact skating lines, backed by specialist agents,
durable skills, demanding tickets and independent BA verification. They explicitly
permit an engine rewrite if needed, provided the game runs on their MacBook Air M5,
and require changes integrated into main. Existing no-spend, original/compatible
licensed content, personal Music isolation and no hosted CI/release rules remain.

The supplied checkout was historical `315d245`. Before accepting a diagnosis,
the orchestrator fetched origin and discovered current main `0b62035`. All initial
specialist work was preserved, the shared checkout fast-forwarded, and only relevant
changes were reapplied after reassessment. The earlier cross-bank/interpolation
prototype and layout additions are not part of the current candidate: main already
contains those repairs and substantially newer native contacts and compact areas.

## Decision

Keep Godot 4.6.3 for the working game while repairing its demonstrated asset,
material, motion and layout defects. There is no demonstrated engine-level blocker
requiring a rewrite. An engine change remains authorised; require a playable
representative slice and an explicit gameplay/save/input/export parity plan before
replacing the current implementation.

Do not confuse the engine with the rendering backend. Godot 4.6 supports native
Metal through Forward+ and Mobile on supported Apple Silicon, while Compatibility
uses OpenGL. Compare the same scene and current shaders across paths before choosing
a new default; record the actual backend. Source-native exports and real Mac play
are separate from Linux shader validation. Default renderer selection will be
recorded with the final comparison evidence, rather than inferred from a screenshot.

Retain all current trial content and Music isolation. Use shared photographic
materials and existing culling/batching rather than multiplying decorative draws.
Any shader-specific batch admission must be exact and independently tested; unknown,
transparent, animated or multipass shader materials retain conservative rejection.
Recompose existing skate features where possible, with native support, guide,
terrain-query and public route records updated together.

## Quality and verification

[AAA_BENCHMARK](../../product/AAA_BENCHMARK.md) defines the demanding target.
[FIDELITY_TICKETS](../../planning/FIDELITY_TICKETS.md) owns assignments, dependencies,
acceptance and independent verification. The [studio guide](../../planning/STUDIO.md)
and repository-local role briefs/skills make the workflow reusable without claiming
that continuously running agents or an undocumented runtime configuration exist.

Preserve rejected frames and failing tests. Use the existing native natural-frame
capture and synchronization proof; manual `force_draw` readback is not accepted.
Freeze source for evidence, hash relevant assets/code, and label fixtures. Run the
required current regression and cold-launch/export checks after integration.
Measure draws, geometry, resident textures and frame-time tails with matched workloads.
No test count or software rendering result closes owner visual/fun or Mac acceptance.

The Linux environment initially lacked a Vulkan ICD. An official Debian 13 Mesa
25.0.7 package was downloaded with its advertised SHA-256 verified, and extracted
only into ignored task-local storage; no system install or paid service was used.
A native 320×240 Forward+ sphere probe rendered successfully on llvmpipe LLVM 19.1.7.
This proves local renderer availability only. A first attempt with unwritable
default user-data directories was rejected and retained; the corrected attempt uses
task-local XDG directories. It is not a game, Mac or performance result.

## Renderer comparison result — 7 November

The [independent renderer packet](../../testing/fidelity-2026-11-06/renderers/README.md)
retains all 17 original views from each backend, identical inventories of 781
inputs, unchanged source, native pixel hashes, camera/Canvas proofs and separate
61/0 capture results. It is one frozen candidate epoch, preceding subsequent
character, manual HUD and bank refinements; it is not final integrated acceptance.

Both paths render the scene without engine/resource errors. Forward+ changes
highlight/contact response and colour, but the angular character forms, repetitive
surfaces and flat architectural composition remain visible. The inspected result
does not justify an engine rewrite or a new default renderer. Keep Compatibility
as the current default. Conditional Forward+ lighting remains available for a
later measured Metal comparison on the actual Mac; neither Linux path establishes
Mac launch or frame rate. This is not an equivalent tuned maximum-quality trial
of every renderer feature.

Total capture durations include software shader compilation, diagnostic processing
and readback; they are not game frame times. No performance conclusion is derived
from their difference. Subsequent asset and architecture work addresses the
demonstrated limitations directly.

## Resource and timing boundaries

The first photographic-surface configuration exceeded its declared 32 MiB extra
texture budget. Keeping 2K colour and importing the three core normals at 1K yields
an independently checked native allocation delta of 32,768,403 bytes
(31.250384 MiB), within that budget. The same eight isolated draws and 96 primitives
are retained. Native 2K/1K normal pairs show no conspicuous static loss at the
captured chase/wall/paving views; source and per-frame metadata limitations remain
in their evidence packet. This is not target-Mac memory/performance acceptance.

A planned whole-world water timing epoch was deliberately stopped when software
rendering made its 1,296-frame workload impractical. Its overall receipt is rejected;
zero complete timing cells are accepted. Completed memory and image subsets retain
their own bounded evidence. A smaller isolated shader comparison, if executed,
must be labelled component-only and cannot substitute for the moving Main/M5 gate.

## References inspected

- [Godot 4.6 renderer overview](https://docs.godotengine.org/en/4.6/tutorials/rendering/renderers.html),
  inspected 6 November 2026: rendering backend capabilities and migration differences.
- [Apple MacBook Air specifications](https://www.apple.com/macbook-air/specs/),
  inspected 6 November 2026: M5 configurations. The owner's exact RAM, GPU variant,
  OS and sustained performance have not been measured.
- Current source-bound historical handoff: [STATUS](../../STATUS.md) and
  [28 October contact evidence](../../testing/turn-wall-2026-10-28/README.md).
