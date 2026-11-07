# Independent native Skin bind precedence

Reviewer: `/root/independent_qa`. **Native witness: 18 checks, 0 failures. Independent receipt/pixel audit: 15 checks, 0 failures.** This admits the narrow name-first resolver correction for integration; it does not admit the fitted rider, natural motion, contact envelope or full game.

Actual Godot 4.6.3 `Skeleton3D.register_skin()` and the returned `SkinReference` populated a real Compatibility renderer skeleton buffer. `RenderingServer.skeleton_bone_get_transform()` read that native palette. A real weighted `ArrayMesh` then rendered the palette through the GPU at 64×64. Bone 0 translates 1 mm; bone 1 translates 3 mm. This is independent of either helper's CPU skinning arithmetic.

| Actual Skin binding | Native palette Z | Native centre red, RGB8 | Old helper | Candidate |
| --- | ---: | ---: | ---: | ---: |
| Valid index 0, nonempty name `named` | 3 mm | 204 | 0: wrong | 1 |
| Empty name, valid index 0 | 1 mm | 153 | 0 | 0 |
| Index −1, nonempty name `named` | 3 mm | 204 | 1 | 1 |

The two name-selected images have the same centre pixel, while the index-selected image differs. Every image retains the original PNG, native RGBA8 hash, PNG hash, actual native palette/bone transforms and before/after physics/process counters. All three readbacks preserve their counters. The [raw report](report.json) contains the actual measurements.

The candidate also rejects a missing nonempty name even when its numeric index is valid, invalid/negative unnamed indices and out-of-range bind slots. These malformed Skins were **not registered with the renderer**: their purpose is to prove helper refusal before native pose access, without manufacturing native errors. The official implementation logs an error and falls back to bone 0 for a missing named bind; the bounds helper deliberately fails closed instead.

The [official source](official-skeleton-3d.cpp.txt), lines 365–389, gives every nonempty bind name precedence. Source URL: <https://github.com/godotengine/godot/blob/4.6.3-stable/scene/3d/skeleton_3d.cpp>. Both the old and candidate full helper bytes are retained; only `_bone()` differs. The tested candidate SHA256 is `77f2a6a09a40055b644b91eed901afb1111b10b15684d9293f28689998cfaab2`.

The [wrapper receipt](receipt.json) records Godot PID 62587 and Xorg PID 62583, native start `2026-11-07T04:44:49.650593+00:00`, cleanup complete `04:45:02.222298+00:00`, exit 0, clean raw log and six unchanged source/observer/wrapper/config inputs. Architecture graphics had already stopped at 04:42:57, so the proposed overlap did not occur. No Main process, import or production mutation was used. Mesa llvmpipe pixels and a tiny diagnostic scene establish neither M5 cost nor ordinary gameplay quality.

For reproduction, restore the four project source files from their `.txt` archives into a fresh ignored project, preserving their original names; the executed [wrapper](wrapper.py.txt) shows the exact argv and XDG/Xorg isolation. Change its source/output locations to a **new epoch**, then inventory those new bytes before execution. Do not overwrite this evidence. The native invalid-name case must remain unregistered. Run [verify.py.txt](verify.py.txt) with this packet directory to recheck retained hashes and pixels without an engine.
