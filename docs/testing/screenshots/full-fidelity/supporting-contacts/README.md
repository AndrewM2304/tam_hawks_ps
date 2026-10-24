# Core-checkpoint board and manual contacts

These four stills show actual Main states admitted through native movement and the existing controls, viewed with inspection cameras. They record the 24 October 2026 core checkpoint before the later Kelvingrove facility/Main integration. They support the specific contacts below; they are not a complete final-build movie, gameplay-camera review, target-Mac performance result or physical-controller/human acceptance.

| Image | Visible contact |
|---|---|
| [Caught shoes and flat deck](caught-shoes-and-flat-deck.png) | Flat stance area, closed wood top, curved kicks and planted shoes. |
| [One-foot Manual](one_foot_manual.png) | Rear foot loaded over the tail trucks; front foot raised. |
| [One-foot Nose Manual profile](one_foot_nose_manual-profile.png) | Front foot loaded; rear shoe visibly clear of the raised deck. |
| [Hang Ten](hang_ten.png) | Both shoes face forward and cluster over the nose. |

The original strict contact bands remain: ordinary planted sole to actual griptape under **1 mm**, complete-shoe penetration no greater than **1.5 mm**, and grab palm contact under **25 mm**. The measurements are:

| Check | Recorded result |
|---|---|
| Ordinary caught sole / complete shoe | +0.900 mm centre gap; minimum vertex gap −0.890 mm. |
| Eight bolt caps | Flush with actual grip triangles (measured cap-height gap 0). |
| Captured Nose Manual profile | Native floor true; front sole 0.899 mm from grip; rear sole 159.387 mm from grip (signed 159.425 mm). |
| Hang Ten heel and forefoot | Both real bearings approximately +0.150 mm; both shoes at functional deck Z approximately −0.2448. The sole centre bridges the kick concavity. |
| Complete manual motion | Minimum complete-shoe gap −1.0013 mm; maximum limb scale 1.000001. |
| Release continuity | Maximum animation movement relative to native travel 0.18135 m; Hang Ten first ordinary-frame steps 0.22465 / 0.22936 m. The full absolute peak, including real travel, is 0.24806 m. |
| Actual banks | 800 / 900 / 900 for the three normal entries; 3200 / 3400 / 3400 after a genuine Shove-it and reversed-deck landing. Zero bails. |

[Pose checks](pose-checks.log) report **239 passed, 0 failed**. The [six native cases](native-six-cases.log) report **24 passed, 0 failed**, including both deck facings and the first ordinary frame after release. The [three-image capture](original-three-capture.log) reports **28/0**; the single [profile capture](profile-capture.log) reports **6/0**; the [board capture](board-capture.log) reports **4/0**. Capture counts include their image/source-stability assertions and do not represent additional independent gameplay cases.

## Unmodified receipts and recipes

[Board](board-manifest.json), [original three-image](original-three-manifest.json) and [profile](profile-manifest.json) manifests retain their original paths, hashes and scope exactly. Each capture reports unchanged listed inputs before and after. The manual captures hash nine scoped inputs; the board capture hashes eight. Their shared rig hash is `4f37b671e31554367467742fcf124404f040d72e4c249694865a0ae62dab7993`. This is a scoped checkpoint, not a claim that later whole-project inputs match it.

The [archive receipt](archive-receipt.json) maps every copied file to its original path and byte hash. Recipe copies use `.gd.txt` to preserve their original bytes without registering extra runnable project scripts: [board](board-contact-recipe.gd.txt), [original three](original-three-recipe.gd.txt), [profile](profile-recipe.gd.txt). Each recipe hash matches its own original manifest. The original three-image recipe was preserved separately when the single-case profile was added. The [local display wrapper](display-wrapper.sh.txt) and engine logs record Godot 4.6.3 / Compatibility with Mesa software rendering.

Only the four selected images are archived here. The original receipts also list one redundant board angle and the less clear original Nose Manual angle; their original paths/hashes remain intact, without claiming those omitted PNGs are included in this directory. No original receipt path or hash was rewritten.
