# ADR-012 — Source startup and ordinary-play repairs

- **Date:** 17 October 2026
- **Status:** Accepted implementation direction; current verification belongs in STATUS/QE.
- **Owners:** A01 integration/startup, A04 movement, A05 world/camera, A09 independent QE.

## Problem and evidence

The owner played source on an Apple M5 Mac with official Godot 4.6.3, launching `GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot" ./tools/run.sh`. The skater was always absent, rolling persisted too quickly, and ordinary exploration fell through parts of the world. The first console errors were `Identifier not found: GrindLine` and missing imported anatomy meshes, followed by failed `Anatomy.new()` calls and repeated Nil animation errors. These are defects, not acceptance of unfinished gameplay.

A fresh source copy without `.godot/` reproduces that dependency chain under the same engine on Linux. `run.sh` previously launched without the editor's initial asset import/class discovery; the cloud checkout already contained those generated files. The source archive correctly excludes platform caches. Prior cached-source checks, scripted route captures and pack construction did not exercise a fresh source user's exact command. Imported Linux native normal gameplay does display its rider, so there is no demonstrated Mac renderer defect.

Independent normal-frame probes also reproduce a shopfront camera collapsing to 1.04m from the rider's chest, losing head/board framing in 45/60 samples, and four input-driven departures through unsupported north/south closes. A clear chest ray alone did not establish a visible rider. Natural-input movement measures nearly 20s / 148m of ordinary flat coasting from top speed and strong midair trajectory steering.

## Decisions

1. **Prepare source play automatically.** Before an ordinary game launch, `tools/run.sh` uses the pinned free editor for a headless import, reads its actual exit code and scans its log for errors. Failed preparation stops launch even when Godot itself returns zero. Editor/test/export operations retain their existing explicit preparation sequence. The owner's normal launch command stays valid. Do not bundle `.godot/` or hide dependency failures with missing-body guards.
2. **Use measured original street response.** Preserve pushing, braking, maximum speed, immediate ollie, takeoff/collision momentum, scoring and input bindings. Ordinary released rolling uses speed-dependent resistance; manuals retain their balance-specific coast. Smooth ground turning and bound air correction separately. Camera sensitivity controls the camera, never physical steering. The helper is original code informed by already-inspected MIT references; no additional upstream code or assets are imported.
3. **Keep a visible third-person rider.** Use Godot native collision queries with camera volume, actual chest anchor and usable alternate views when the rear arm is blocked. Validate head and board framing, line of sight, turns, ceilings and restarts through ordinary callbacks. Preserve reduced motion and avoid unsafe interpolation through walls. Do not claim every possible camera view or human comfort from these probes.
4. **Repair real openings and finite edges.** Build visible supported north/south close joins and matching collision; close unsafe finite boundaries visibly while retaining deliberate river hazards, bridge transfers, station overlap and existing ports. Avoid an invisible world-wide catch floor. Preserve the ten career/save IDs, three side acts, all original routes and intended optional risks.
5. **Verify the actual missing paths.** Add a fresh-source launcher regression, a normal CLI scene that reaches Main's real title branch, complete actor construction checks and natural input-only movement/camera routes. Initial test fixtures are declared; no per-frame heading, position, speed or camera injection may substitute for ordinary play. Retain before diagnostics and bind after checks/renders/packages to exact inputs.

## Boundaries and continuation

These repairs precede the earlier gallery-side cleanup and are part of existing startup, movement, camera, world and quality tickets. Keep all 75 full task records. The supported close joins also advance that documented boundary task. Full vert/bowl/lip/wallride, charged ollies, traffic, new encounters and final realistic art remain separate unfinished work. Do not use their absence to excuse source launch, invisible riders or accidental ground holes.

The owner's Mac run is real failing pre-repair evidence. Linux repair checks and cross-export cannot certify the repaired Mac experience, physical DualSense, listening, human fun or Apple Silicon moving frame times. The updated source should be retryable with the same command, without another paid dependency or repeated task approvals. No purchase, paid API, hosted CI or unattended work is authorized.
