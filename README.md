# Tam Jaws Pro Skater

An original arcade skateboarding game in a fictionalised Glasgow. The working title follows the owner's request; the supplied design document used **Glasgow: Grind City**. This project aims for responsive skating, continuous combos, two-minute runs and an interconnected four-district playground.

**Current stage: M01 skating prototype in progress.** This is not the complete game. The current implementation targets a procedural Glasgow-inspired square, basic skating and aerial tricks, a camera, run scoring and a restartable session. Grinds, manuals, reverts, specials, a complete four-district world, goals and persistent progression remain release work. [Current status](docs/STATUS.md) records exactly what has been implemented and tested.

## Start here

1. Read [the current handoff](docs/STATUS.md), [the full task backlog](docs/planning/BACKLOG.md) and [agent instructions](AGENTS.md).
2. Run `tools/setup.sh` to verify the installed Godot 4.6.3 engine and run import/tests. This environment already provides the engine; no dependency download is required.
3. Run `tools/check.sh` for the project import and automated checks.
4. Run `tools/run.sh` to play from a graphical desktop, or open `project.godot` in Godot 4.6.3.

If Godot is absent on a future machine, install the free Godot 4.6.3 editor from the [official archive](https://godotengine.org/download/archive/) with normal upstream verification. On macOS, use `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot tools/run.sh` or import `project.godot` in the editor.

The cloud Linux machine is useful for development and automated tests. A rendered window requires a display. macOS export, Apple Silicon performance and a physical DualSense require separate hardware validation; no such result is implied by a Linux test pass.

## Prototype controls

| Action | Keyboard | Proposed DualSense mapping |
|---|---|---|
| Push / brake | W / S, or Up / Down | Left stick forward / back |
| Steer | A / D, or Left / Right | Left stick horizontal |
| Ollie | Space | Cross |
| Flip / grab | J / K | Square / Circle |
| Spin left / right | Q / E | L1 / R1 |
| Pause | Escape | Options |
| Restart | R | Triangle |
| Toggle free skate | F | Touchpad |

The controller layout is implemented through Godot's standard gamepad mapping and needs testing on a real DualSense. Final grind/manual/revert controls will be specified in M02 and verified with the user.

## Development and continuity

[The backlog](docs/planning/BACKLOG.md) has 48 local tickets covering the full first release. Every ticket includes ownership, dependencies, acceptance criteria and validation. [Requirements](docs/product/requirements.md) map the supplied vision to those tickets; [the design](docs/product/game-design.md) describes the intended rules. The original pasted plan is preserved in [original-plan.md](docs/product/original-plan.md).

Keep work on a feature branch in this existing checkout. Cloud tasks already have isolated environments; do not create extra Git worktrees unless explicitly requested. Before ending a session, update the status document and ticket evidence so another session can continue without chat history. The [resume guide](docs/planning/RESUME.md) gives the sequence.

## Cost and content policy

Use free local tools and original procedural assets. Do not purchase assets, call paid APIs, enable billing, provision hosting, trigger hosted CI, or run autonomous background agents. This repository has local issue/PR templates and local checks; it deliberately has no hosted workflow. Normal assistant use is subject to the owner's existing credit allowance; there is no unattended continuation after a session ends.

The game uses original characters, geometry, text and sounds. It must not copy another skating game's branding, level layouts, assets or music. [The provenance register](docs/licences/REGISTER.md) tracks dependencies and assets. The engine's MIT licence does not assign a licence to this game's original code or content.
