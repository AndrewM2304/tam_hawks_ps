# Settle menu input before returning to skating

**C09 · P1 · M06.** Circle Back previously resumed the skater in the same
physics update as a consumed gameplay edge. The modern input queue correctly
saw no new Grab, but native `just_pressed` history still armed legacy family
and steering-selection timers. A real fresh north-modified jump therefore
became Ollie instead of Nollie. Saved Circle mappings also caused actual jumps,
Manual entry, Reverts and locked-rail exits. Same-update Cross activation could
jump immediately after Start or Resume.

The repair keeps the modal and gameplay pause until all consumed menu presses
have released. It restores independently held mapped keyboard bindings, then
waits through a paused physics pass and its following idle boundary before
Start, Resume, Restart, mode switch or live-origin Back enables gameplay.
Nested Back that stays paused remains immediate. Holding Back deliberately
keeps the modal open until release.

An input revision invalidates a queued fence when another consumed press
arrives. A transition serial, originating page/revision, pause/finished state,
visibility and recorder input-block checks reject obsolete requests. Focus or
controller loss cancels the pending transition. Unique one-shot callbacks use
weak HUD references; duplicate Back cannot register an identical bound callback
or resume twice. Press/release receipts retire so the next genuine gameplay
press of that button works normally.

Unpause separately cancels an Ollie charge released while menus owned input.
An actual held charge and any already accepted jump buffer survive. Live
gameplay sampling, within-physics-tick quick taps, directional trick selection
and accepted trick queues retain their existing behavior. The earlier candidate
queue-membership API and legacy sampler guards were removed after this UI
boundary superseded them.

## Actual defects established

All observations below use bounded ordinary Main, native parsed input,
production geometry and disabled persistence before Main enters the tree.
No actor transform, velocity, award or score injection supplies a launch or
rail catch. The rail case declares an initial Exchange approach spawn.

| Frozen observation | Actual consequence |
| --- | --- |
| [Default family](focused/default-causal/receipt.json) | Escape Back followed by fresh north/Ollie emits Nollie; identical Circle Back emits Ollie at the same airborne position. Only Circle leaves the legacy 0.12-second Grab buffer. |
| [Saved mappings](focused/saved-map-causal/receipt.json) | Valid saved Circle→Ollie jumps; Circle→Manual enters Manual; Circle→Revert adds an award and turns heading by π; Circle→Grind exits an actual native 50-50. Matching Escape controls preserve state. |
| [Charge released while paused](focused/paused-charge-causal/receipt.json) | Released Space leaves charge/crouch active after Escape Back and accelerates the skater without Push. Keeping Space held is the valid control. |
| [Same-update Cross](focused/same-tick-cross-causal/receipt.json) | Native Cross press and release before one physics tick adds an unintended Ollie after title Start and Pause Resume. |
| [Independent keyboard holds](focused/alternate-binding-causal/receipt.json) | Circle Back ends Manual despite physically held M, and jumps despite physically held Space. Releasing the old Space charge while paused before Circle Back also jumps. |

These clean observation receipts establish faulty behavior; their `valid:true`
means the bounded observer ran correctly, not that gameplay was healthy.

## Admitted focused results

| Run | Result | Wall time | Manifest SHA-256 |
| --- | --- | --- | --- |
| [Integrated native controls, fixed 60](focused/accepted/receipt.json) | **33/0**, exit 0, clean/stable 646 inputs | 13.082 s | `48a3f859917f9f8480bde5d17285eaa61afe562aa2632f0917e37a67ecaf8bd5` |
| [Fixed 30 render-step control](focused/render30/receipt.json), physics 60 | **6/0**, exit 0, clean/stable 646 inputs | 8.976 s | `c1f923b808c7169c08bb7bb23cc7377c72b6e48fc7c36f14fc0d9816175e7560` |
| [Fixed 120 render-step control](focused/render120/receipt.json), physics 60 | **6/0**, exit 0, clean/stable 646 inputs | 9.074 s | `c1f923b808c7169c08bb7bb23cc7377c72b6e48fc7c36f14fc0d9816175e7560` |

The 33 native assertions cover actual Nollie selection and steering-spin parity,
genuine north Grab/Flip awards, immediate Manual→Pogo→Ollie with already consumed
family metadata, all four saved Circle mappings, held M/Space through paired
Back release, paused charge cancellation, a fresh genuine Circle Ollie, same-tick
Cross Start/Resume/Restart/mode switch, duplicate Back, later input between the
physics and idle boundaries, and page/restart/results/blocked/hidden invalidation.
The six rate controls retain the four actual Cross transitions, duplicate Back
and the late consumed press. Personal profile and Music isolation remain checked.

The raw `MENU_BOUNDARY.fixed_render_hz` diagnostic is historically misnamed: it
contains `Engine.get_frames_per_second()`, the accelerated measured throughput.
The receipt's `--fixed-fps 30/60/120` command specifies the deterministic rendered
step, and the logged `physics_hz` is 60. These are native scheduling controls,
not physical display refresh, frame-time or target-performance acceptance.

Root additionally checked both final scripts with `--check-only`: HUD exit 0
in 0.137 s and the menu test exit 0 in 0.135 s, with empty error scans. The later
root combined receipt owns whole-checkout admission, cold launch and packages.

## Retained rejected candidates

Raw rejected logs, validity fields and exact source remain unchanged:

- [Initial queue guard: 16/1](focused/default-queue-candidate-rejected/receipt.json).
  The failure was a wrong fixture label: genuine north Flip is Frontside
  Shuvit, not Hardflip. Actual Nollie/spin and extension controls passed.
- [Fixture inference failure](focused/fixture-type-rejected/receipt.json).
  A dynamic-Node boolean needed an explicit type; no gameplay result was admitted.
- [Fixed fence plus restored release: 30/2](focused/restored-release-rejected/receipt.json).
  Releasing consumed Circle recreated native edges and jumped while original
  Space remained held. The other failure incorrectly required the entire queue
  to be empty after Pogo; the correct observation checks only consumed Grab
  membership and preserves the unrelated Manual entry.
- [Release-first bound callbacks: 32/1](focused/duplicate-callback-rejected/receipt.json).
  Duplicate same-update Back hit Godot's duplicate callback-registration error.
  Unique weak-reference closures fix registration while preserving guards.
- [WeakRef inference failure](focused/weakref-type-rejected/receipt.json).
  Both weak-reference declarations required explicit `WeakRef` types under the
  project's warning-as-error setting. Cascading checks against a missing HUD
  are rejected and do not describe gameplay.

Every run retains its unmodified receipt, before/after maps, console and verified
`SNAPSHOTS.json`. [The index](source-snapshots.json) accounts for all 13 runs;
each input resolves to immutable Git parent `700e304861c282bb11dcd762c0cae04a06ec2642`
or an exact hash-matching retained snapshot. No input is unresolved.

From the repository root, with no other engine workload:

```sh
python3 docs/testing/pt24-continuous-2026-10-27/ui/observers/prepare.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/menu-launch-reproduction timeout 25s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/menu_launch_focused.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/menu-render30-reproduction timeout 15s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 30 --script .local/menu_boundary_rates.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/menu-render120-reproduction timeout 15s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 120 --script .local/menu_boundary_rates.gd
```

Actual Mac execution, physical controller timing/feel and human acceptance remain
open. This source/native repair does not close all C09 hardware work or certify
every possible simultaneous device binding.
