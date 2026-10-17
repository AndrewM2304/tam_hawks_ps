# Tam Hawks Pro Skater — agent operating rules

Read `docs/STATUS.md`, `docs/planning/BACKLOG.md`, and `docs/architecture/interfaces.md` before implementation. The supplied plan is preserved in `docs/product/original-plan.md`.

## Budget and scope
- Do not purchase anything, enable billing, use paid APIs, trigger hosted CI, provision infrastructure, or launch background agent loops. Use installed tools and original or compatible free licensed assets. Ordinary work stays within the current user-authorized session; stop with a durable handoff when it ends.
- Godot 4.6.3, GDScript, single-player, macOS/Apple Silicon target, DualSense first and keyboard fallback. The Linux development machine cannot certify macOS, physical controllers, or Apple Silicon performance.
- Build original content. No copied franchise branding, music, voices, layouts, models, or animations. Record third-party assets and dependencies before use.
- Keep the skating-first roadmap intact. Scope changes belong in an ADR and material creative/hardware changes require the user.
- The correct title is **Tam Hawks Pro Skater**. Current cuboid/procedural art is temporary gameplay blockout, not the release look. The owner requires polished UI and believable, detailed, realistic-but-fun visuals after core gameplay is stable; read `docs/product/ART_DIRECTION.md` and complete the explicit cleanup gate.
- Research recognisable Glasgow streets, shops and venues for level-edge facades. Prefer verified location relationships and distinctive architecture over generic shop rows. Record source/date/confidence, including Street View capture dates when inspected. Maps/Street View are reference material, not bundled textures; use no paid Maps API.
- Prefer built-in Godot systems and suitable existing open-source components before writing substantial new movement, trick, camera or tooling infrastructure. The owner explicitly authorizes free, compatible reuse and adaptation. Read `docs/research/SKATING_REUSE.md` and ADR-004; inspect actual source/licences, pin revisions, retain notices and test adaptations. Review code and asset permissions separately; a publicly visible repo alone is not a reuse licence.

## Coordination
- Work on a feature branch, never directly on `main`. Cloud tasks are already isolated: use the existing checkout; do not create Git worktrees unless the user explicitly requests them. Parallel agents must own disjoint files and agree shared interfaces first.
- The orchestrator owns integration and shared interfaces; specialists own assigned paths. QE reviews gameplay independently.
- Track every task with ID, owner, priority, milestone, dependencies, acceptance criteria, and test strategy. Keep statuses honest: automated checks cannot certify fun, real hardware, or an untested export.
- Use local task documents as the source of truth until GitHub issue/PR publishing is available and explicitly recorded. Do not claim a local ticket is a remote issue.
- Before ending a session, update `docs/STATUS.md` with completed work, exact commands/results, defects, next tasks, and resumption instructions. Update backlog statuses and record material decisions.

## Quality
- Run `tools/check.sh` for production GDScript changes. Tests must report counts and fail nonzero on assertion failures.
- Do not change production behavior to hide a failing test. Investigate failures and keep missing hardware/exports distinct from passing Linux checks.
- Graphical changes need a captured frame or an explicit rendering blocker. Do not fabricate screenshot evidence.
- Ignore generated `.godot/`, `.local/`, exports, and editor caches. Commit source and task records, never credentials.
