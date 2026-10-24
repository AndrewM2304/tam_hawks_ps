# Sunken skatepark navigation UI

These two 960×600 images support the new Kelvingrove navigation presentation.
They use a standalone HUD viewport populated from the actual World facility and
route APIs. They are separate from the complete Main motion capture and do not
prove a natural journey, final-movie coverage, target-hardware performance or
physical-controller/human acceptance.

| Image | Recorded scope |
|---|---|
| [City map](sunken-skatepark-map.png) | Actual World routes and district checkpoints; the orange diamond marks the authored east skatepark entry. The rider arrow uses Main's real initial position. |
| [Entry cue](sunken-skatepark-entry-cue.png) | Explicit standalone UI fixture at the actual World entry position. The complete location cue fits without inventing an Interact action. No natural approach skating is claimed. |

Both frames were visually reviewed. The northwest facility label is distinct
from the existing Kelvingrove district marker. The prompt reads “SUNKEN SKATEPARK
/ East roll-in to street & bowls”. The menu retains normal scrolling for its
full map and directions.

[Navigation UI checks](navigation-ui.log) pass **30/0**, covering three viewport
sizes at enlarged interface scale, non-default metadata coordinates, exact
entrance mapping, complete text allocation and prompt priorities. The
[render capture](navigation-render.log) passes **8/0**: five actual World/Main
data-contract checks and three pixel/save checks. The earlier
[World log](original-world-checks.log) retains its original **4/0** result before
an explicit facility-instance guard was added. The existing
[HUD allocation checks](hud-regression.log) pass **76/0**, and the
[route-availability checks](route-availability-regression.log) pass **9/0**.
These focused counts supplement other evidence and must not be added to the
project aggregate.

The [archive receipt](archive-receipt.json) maps **11 byte-identical copies** to
their original paths and SHA-256 hashes. Both PNGs passed complete chunk CRC and
decompressed-row validation. Original logs and recipes were not rewritten.
Recipes use `.gd.txt` to preserve their bytes without adding runnable scripts:
[capture](capture-recipe.gd.txt), [UI](ui-check-recipe.gd.txt),
[World](world-check-recipe.gd.txt), and [display wrapper](display-wrapper.sh.txt).
The capture uses Godot4.6.3 Compatibility with Mesa llvmpipe and disables profile
writes.

The original short capture did **not** record a before/after source-hash guard.
The receipt's nine source hashes are explicitly a post-capture, archive-time
context snapshot; they do not retroactively certify unchanged inputs during
capture or the later whole project. Natural summit/entry skating, complete
source-bound movie review and final acceptance require the separate QE evidence.
