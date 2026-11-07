# Rejected maximum-speed bank containment — FID-D012/P1

Actual native input exposed an unsupported escape through the new bank's retained upper boundary. This packet is a **failure receipt**, not bank acceptance. Four naturally accelerated charged Ollies were investigated in a fresh ordinary default Main, Godot4.6.3 Linux headless fixed60Hz, personal Music persistence disabled before tree entry. No position or velocity is assigned after each declared initial spawn `(66,2.08,73.5)`, yaw−PI/2. After40settling frames, mapped Push accelerates toward `(88,2,73.5)`. Ollie is held16ticks from the listed X gate, then all actions are released.

Command: `./tools/run.sh --headless --path . --fixed-fps 60 --script res://.local/bank_top_escape_probe.gd`. [Exact probe](probe.gd), [original log](native.log), [boundary source](boundary-source.gd) and [post-run source hashes](source-hashes.json) are retained. Exit1, two actual unsupported escapes. The original probe counted escaped bodies; the separate camera failure is also rejected here and must not disappear behind that narrower numeric result.

| Charge gate | Charge frame / reached speed | Release frame / native position | Outcome |
| --- | --- | --- | --- |
| X78.0 |144 /15.000m/s |160 /`(81.95163,2.639215,73.50021)` | At frame175 crossedX85.24483,Y5.586662 with support queryNaN. MaximumX100.17223; peakY6.421818; eventual1bail,0recoveries. Camera clear. |
| X78.7 |390 /15.000m/s |406 /`(82.61898,2.981450,73.50019)` | At frame418 crossedX85.26863,Y5.517178 with support queryNaN. MaximumX101.16420; peakY6.781970; eventual1bail,0recoveries. Camera clear. |
| X79.4 |640 /15.000m/s |656 /`(83.28633,3.323683,73.50017)` | Contained at maximumX84.40578,0bails; **camera occlusion** at body`(84.40578,4.260711,73.50012)`, actual marker`(84.72329,4.555975,73.50704)` behind native boundary atX84.7. PeakY7.124755. |
| X80.1 |994 /15.000m/s |1010 /`(83.72778,3.550068,73.50009)` | Contained at maximumX84.40576,0bails; camera clear. PeakY7.350649. |

All four scored an ordinary Ollie entry; no caught grind or manufactured state explains the escape. The two escaping inputs release at14.915/15.000m/s with native uphill velocityY6.806/6.845m/s. Existing no-jump8/12m/s bank rollback tests remain useful in their narrower scope, but cannot certify this input family. The current visible/native backing top isY5, slope kneeY4. The supported quay ends outside the wall.

Proposed repair is a coherent visible/native reprofile of the **same existing terminal wall** to contain the demonstrated uphill-pop envelope, preserving its four original shape slots, one display, finishes and80triangles, plus the supported diagonal Barras mouth. No invisible catch, out-of-world floor, input restriction or velocity clamp is acceptable. It still needs a bounded native rerun of these exact cases, body/model/chase witnesses, no-jump rollback/bypass regression and an inspected matching frame before acceptance. Parent runtime freeze remains respected while this receipt is written. The post-run hash sample is not a whole-source before/after stability claim.
