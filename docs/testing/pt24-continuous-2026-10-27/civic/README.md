# C02/PT24-01 civic witnesses 2 and 3

**27 October 2026 · QE/environment · P0 · M05/M06.** The exact two owner camera
positions/orientations/FOVs omitted from the later matched set now have bounded
current-source native evidence. Parent is pushed main
`cd661ca5b1e08a1a803570b1bd6e936ac0c9aed8`. This is a Linux shadow/material
diagnostic, not a new production repair or target-Mac acceptance.

## Executed method and result

[Native execution](executions/native/receipt.json): **55 passed / 0 failed**,
exit0, clean/stable647 outer inputs,64.024s. Manifest SHA256:
`7e0447d28e1674dc0220acd70e9e824613b66fc7864c8566b9e88f7faea3d80e`.
The [native manifest](frames/manifest.json) binds648 inner inputs and all36
1440×900 PNGs. Every image SHA/dimension was independently verified after the
display process exited. [The source index](source-snapshots.json) resolves the
649 unique outer/inner inputs to647 immutable parent files and two exact ignored
observer snapshots, with no unresolved input. Exact original owner
[report2](reports/issue-0002.json) and [report3](reports/issue-0003.json) are retained.

The observer constructs ordinary Main with persistence false before tree entry,
no feature override, and confirms all merged trial content remains enabled.
Balanced settings are applied without persistence. Twelve normal setup ticks
precede paused gameplay and hidden HUD; physical actor, velocity, score and timer
remain frozen throughout observation. Personal Music control/persistence/worker
remain disabled. A separate authored camera uses each report's exact starting
position, forward/up and FOV. Its1440×900 viewport matches both reports; near/far
come from current Main. The rider stays at the ordinary setup location rather
than being assigned the historical report pose.

Each camera warms six completed native draws, records six stationary frames,
then twelve completed frames over a one-metre horizontal approach. The normal
render loop and `frame_post_draw` supply actual readbacks; there is no forced
manual draw, input route, long movie or entire-helper bypass. Normal directional
shadows remain enabled:45m range, bias0.1, normal bias2; MSAA2x,3D scale1 and
occlusion off. The process-local shadow-off option was **not run**.

## Independent image observations

The [read-only stationary comparison](stationary-comparison.json) verifies PNG
hashes, exactly equal camera dictionaries and increasing completed process-frame
IDs. Across all five consecutive pairs at **both** witnesses, changed pixels
are zero; channel maximum/mean absolute differences are zero and changed bounds
are null. The descriptive0/2/8 channel levels are observations, not pass gates.
The first moving PNG is also byte-identical to the first stationary PNG for each
exact starting camera.

Comparison SHA256:
`09f7f62179a7eae64a17d014bb5eeb11a9b470088300bfb9c31e1ba040928289`.
Comparator SHA256:
`42cfc0e6e70dbe3b21545e0aa41fbf34fe3177005cd0a13886924b72ce0604b5`.

QE inspected stationary00 and moving05/11 at both cameras; the independent
[environment review](environment-review.md) additionally inspects moving06.
Current asphalt/tile joins are continuous in those frames. No new missing face,
open gap, duplicated stripe or obvious isolated seam pop supports another source
repair. Moving images contain ordinary parallax; no moving-pixel differences
were labelled flicker or assigned a cause. Existing translated native/ownership
checks already protect theZ=-56 join and its56m² duplicate-display subtraction.
Those repairs and production light settings remain unchanged.

| Exact witness | Stationary start | Mid approach | End approach |
| --- | --- | --- | --- |
| Owner2 | [PNG](frames/issue-0002-stationary-00.png) | [PNG](frames/issue-0002-moving-05.png) | [PNG](frames/issue-0002-moving-11.png) |
| Owner3 | [PNG](frames/issue-0003-stationary-00.png) | [PNG](frames/issue-0003-moving-05.png) | [PNG](frames/issue-0003-moving-11.png) |

All per-frame native draw/primitive/object/memory counters and lighting/camera
values remain in the manifest. Its draw-wait intervals are observer scheduling
measurements: PNG/readback work and Linux software rendering prevent target
frame-time conclusions. Six paused stationary frames and a short authored camera
approach cannot close the owner's moving-Mac shadow report, human temporal
acceptance or ordinary chase/play acceptance. No speculative shadow toggle,
global bias change or repeat capture was justified by these current images.

## Startup control and reproduction

The [first attempt](executions/display-bind-rejected/receipt.json) is an
environment startup rejection: restricted network sandboxing prevented Xorg
binding its local display socket, before Godot started. Exit1, stable647 inputs,
no image or gameplay result. Its original console/receipt/maps remain unchanged.
The display-specific Xorg logfile was reused on successful startup; it is not
presented as a retained first-attempt log.

The [parser-only check](executions/check-only/receipt.json) then exits0 with
clean/stable646 inputs in1.157s and no world construction. The unchanged native
observer succeeds with the required local-display network permission. The
rejection and success have identical source-map hashes; environment permission
does not become a renderer/game repair. Display cleanup runs before handing the
engine directly to the next scheduled Manual observer.

From the repository root, under the root-owned serial engine lease:

```sh
python3 docs/testing/pt24-continuous-2026-10-27/civic/observers/prepare.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/civic-shadow-check-repeat timeout 15s ./tools/run.sh --headless --audio-driver Dummy --check-only --script .local/civic_shadow_witness.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/civic-shadow-repeat bash .local/civic_shadow_witness.sh .local/civic_shadow_witness.gd --mode=normal --output=res://.local/civic-shadow-witness/normal
python3 .local/inspect_civic_stationary.py .local/civic-shadow-witness/normal
```

The extra `.gd` user argument binds both ignored producer files into the outer
source map. This environment requires execution network permission for the local
Xorg display socket; no external service is contacted. Repeated results certify
only their newly recorded source. The commands document reproduction and are
not instructions to replace this result with a threshold-seeking rerun.
