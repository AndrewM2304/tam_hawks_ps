# Native rendered model clock under an OFF child

Reviewer: `/root/independent_qa`. **13 native assertions and 15 independent receipt/pixel checks pass.** A visible MeshInstance with physics interpolation OFF still renders its moving ON ancestor's interpolated transform. This proves the GPU model authority needed when diagnosing rigid-head/current-Skin clock separation; it does not establish that a particular fitted neck is fixed.

A real unshaded spatial shader encodes `MODEL_MATRIX[3].x * 10` into red. A moving ON parent alternates X ±20 mm; its visible OFF child has local X 50 mm. The native same-readback pixels therefore distinguish the renderer's actual model transform from the child's current global transform. Neither CPU seam arithmetic nor `get_global_transform_interpolated()` alone is the oracle.

| Interpolation fraction | Current child global X | Interpolated API X | Actual GPU model X from RGB8 |
| ---: | ---: | ---: | ---: |
| 0.22411 | 30.000 mm | 61.036 mm | 61.176 mm |
| 0.21050 | 70.000 mm | 38.420 mm | 38.431 mm |
| 0.20351 | 30.000 mm | 61.860 mm | 61.961 mm |

The GPU values agree with the rendered API within RGB8 encoding precision (one code value is 0.392 mm) and differ from current globals by more than 5 mm. All actual physics/process/fraction counters remain unchanged inside each readback. The three samples belong to different real physics epochs. Raw model/parent/local transforms, flags, fractions, original PNG hashes and native RGBA8 hashes remain in [report.json](report.json).

The [official Node3D implementation](official-node3d.cpp.txt), lines 529–566, explicitly handles an OFF node with an ON parent and returns the SceneTreeFTI rendered transform for visible instances. Source: <https://github.com/godotengine/godot/blob/4.6.3-stable/scene/3d/node_3d.cpp>. A rendered seam observer must not choose current globals solely because the child reports interpolation disabled. This does not justify disabling all interpolation or changing a contact tolerance.

The [native receipt](receipt.json) records actual Godot PID 66056 and Xorg PID 66052, start `2026-11-07T05:08:25.546270+00:00`, cleanup `05:08:38.012694+00:00`, exit 0, clean raw engine log and four unchanged source/wrapper/config inputs. This is an empty isolated Compatibility/llvmpipe 64×64 project with **diagnostic 10 Hz physics**, selected to expose fractional interpolation. It is not actual 60 Hz Main, a fitted-rider motion test, target-Mac measurement or performance/exclusivity claim. Root explicitly permitted qualitative headless overlap; this tiny wrapper does not record other process PIDs and cannot establish the actual overlap set.

The [executed observer](witness.gd.txt), [project](project.godot.txt), [wrapper](wrapper.py.txt), private Xorg configuration, raw logs and all three original PNGs are retained. Restore the `.txt` sources to their original names in a fresh private project and adjust the wrapper to a **new output epoch** to reproduce; never overwrite this packet. Run [verify.py.txt](verify.py.txt) with this packet directory for engine-free verification.
