# Tam Hawks Pro Skater

An original arcade skateboarding game in a fictionalised Glasgow. This project aims for responsive skating, continuous combos, two-minute runs and an interconnected four-district playground.

**Current stage: M01 skating prototype in progress.** This is not the complete game. The current implementation targets a procedural Glasgow-inspired square, basic skating and aerial tricks, two grindable rails with balance, a camera, run scoring and a restartable session. Manuals, reverts, specials, a complete four-district world, goals and persistent progression remain release work. [Current status](docs/STATUS.md) records exactly what has been implemented and tested.

The first playable slice passes **260 automated checks** and has [reviewed gameplay captures](docs/testing/screenshots/air-tricks.png). Physical DualSense/Mac playtesting is the next acceptance gate. The [QE report](docs/testing/QE-REPORT.md) records the tested behavior and limitations.

**Visual direction:** the current blocky scene is temporary gameplay blockout. The final target is realistic-but-fun Glasgow graphics and polished UI, with recognisable real shopfronts/street edges. A required post-gameplay cleanup and owner visual signoff are tracked in M06-007; see [art direction](docs/product/ART_DIRECTION.md) and [Glasgow references](docs/research/GLASGOW_REFERENCES.md).

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
| Hold grind / balance | L / A-D | R2 / left stick |
| Pause | Escape | Options |
| Restart | R | Triangle |
| Toggle free skate | F | Touchpad |

The controller layout is implemented through Godot's standard gamepad mapping and needs testing on a real DualSense. Manual/revert controls will be specified in M02 and verified with the user.

To try the first rail, approach the orange rail on the right of the square, ollie onto it while holding **L** (controller candidate: **R2**), and keep the balance marker centred with left/right steering. Release grind to drop off or press ollie to jump off; land to bank the combo. The [rail test guide](docs/testing/GRINDING.md) records the exact repeatable route and remaining checks.

## Reuse and implementation research

We use Godot’s built-in engine facilities and prefer suitable existing components over rebuilding generic systems. [The inspected source shortlist](docs/research/SKATING_REUSE.md) includes GodotSkate and Not Pro Skater. An MIT rail-geometry helper now drives the first playable grinds; manuals, reverts and complete combo-flow acceptance remain M02 work. Attribution and the complete licence are retained.

## Development and continuity

[The backlog](docs/planning/BACKLOG.md) has 54 local tickets covering the full first release. Every ticket includes ownership, dependencies, acceptance criteria and validation. [Requirements](docs/product/requirements.md) map the supplied vision to those tickets; [the design](docs/product/game-design.md) describes the intended rules. The original pasted plan is preserved in [original-plan.md](docs/product/original-plan.md).

Keep work on a feature branch in this existing checkout. Cloud tasks already have isolated environments; do not create extra Git worktrees unless explicitly requested. Before ending a session, update the status document and ticket evidence so another session can continue without chat history. The [resume guide](docs/planning/RESUME.md) gives the sequence.

## Cost and content policy

Use free local tools and original or compatible free licensed assets. Do not purchase assets, call paid APIs, enable billing, provision hosting, trigger hosted CI, or run autonomous background agents. This repository has local issue/PR templates and local checks; it deliberately has no hosted workflow. Normal assistant use is subject to the owner's existing credit allowance; there is no unattended continuation after a session ends.

The game uses original characters, geometry, text and sounds. It must not copy another skating game's branding, level layouts, assets or music. [The provenance register](docs/licences/REGISTER.md) tracks dependencies and assets. The engine's MIT licence does not assign a licence to this game's original code or content.
