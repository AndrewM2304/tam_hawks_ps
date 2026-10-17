# Resuming development

A new session should be able to work from this repository alone. Treat local files as authoritative; a chat promise is not an implementation result.

1. Read `AGENTS.md`, `docs/STATUS.md`, the relevant backlog tickets and `docs/architecture/interfaces.md`. Check `git status --short` and the current branch before editing. Preserve existing changes.
2. Inspect the most recent recorded command results and defects. Run `tools/check.sh` once the engine is available. If the environment was replaced, use `tools/setup.sh` to verify the installed engine and run checks. If the engine is missing, obtain free Godot 4.6.3 from the official archive with normal artifact verification, then set `GODOT_BIN` if needed; the setup script does not download it.
3. Select the earliest ready ticket whose dependencies are complete. A milestone's human playtest gate cannot be passed by synthetic tests. Independent planning and test work may continue while hardware feedback is pending.
4. Use the existing isolated checkout and a feature branch. Do not create a worktree unless the user explicitly asks. Assign disjoint files before parallel edits; the orchestrator owns shared interfaces.
5. Implement the smallest complete acceptance slice. Record any changes to gameplay contracts in an ADR before dependent agents implement against it.
6. Run appropriate local automated checks. For visible changes, capture an actual rendered frame or record the exact rendering blocker. Document manual steps and platform limitations separately.
7. Update `docs/STATUS.md` and the ticket: files changed, command and result, unresolved defects, next action, and dependency state. Mark Done only with acceptance evidence.
8. Leave source, decisions and tests reviewable. Do not purchase anything, enable hosted services, trigger hosted CI or start unattended agents. Publishing issues, pushing changes and release distribution must follow the owner's current instructions; this initial session's ticket templates are local.

## Minimum end-of-session record

- Branch and commit if one exists; dirty/untracked files intentionally left for review.
- Completed ticket IDs with exact command outcomes and evidence paths.
- In-progress ticket ID, implementation state, failing cases and the next concrete edit.
- Outstanding human/hardware tests; name the device and scenario required.
- Missing credentials or dependencies, without secret values.
- New assets/dependencies and their provenance.
- Known product omissions and any scope decisions awaiting the owner.

A low-credit stop should prioritise recording these facts over starting another feature. Do not mark work complete merely because the current session has ended. Do not turn the backlog into a schedule of paid model runs.

## Roles

A01 orchestrates and owns integration; A02 owns requirements; A03 investigates tools and licences; A04 owns skating; A05 owns world/art; A06 owns goals/progression; A07 owns audio/narrative; A08 owns UI; A09 independently verifies. These are nine logical responsibilities (the supplied plan's heading says eight, but enumerates A01–A09), not nine permanent paid workers.
