# Connected clothing during the existing tow

**C03 / PT24-28 · P0 core attachment maintenance · A04/A09.** This fixes an
existing rider-body defect; traffic/skitch feature expansion and polish remain
deferred. No vehicle behavior, controls, score policy or route is changed by
the proposed visual repair.

## Confirmed baseline

The visual controller applies an initial up to 12 cm toward-handle translation
to the torso, then a separate palm-reach translation. Neither reaches the pelvis
before the leg solve. Original palm/sole contact tests therefore pass while the
actual Skin-bound torso and trousers separate.

The [direct native pose diagnostic](focused/rig-before/receipt.json) is clean and
stable on 638 inputs, 0.852 s. Both original authentic yaw fixtures show148.4 mm
maximum hem/waist-centre separation on entry and151.8 mm on release, with120.1 mm
torso/pelvis joint separation. Neutral cloth-centre distance is51.6 mm and joint
distance 3.45 mm. These ring-centre distances are not a claim that every visible
cloth opening has the same width. The diagnostic records metrics rather than
asserting this defective state is healthy.

The [ordinary default Main diagnostic](focused/native-before/receipt.json) is
clean and stable on 638 inputs, 8.673 s. All **seven unchanged existing native
input/contact/score checks pass**, including moving-cart catch, pause,
Ollie→fresh Grab→native landing and the exact once-only catalog bank. Additional
actual clothing samples cover 228 updates, 79 while caught:142.1 mm maximum
cloth-centre distance and120.0 mm torso/pelvis separation, with finite neck/body
geometry. This establishes a real runtime defect beyond the authored pose test.

Each raw receipt/log/map is immutable. Its exact non-parent/command source
inputs are retained in its `source-snapshot` directory and verified in
`SNAPSHOTS.json`; unchanged files resolve to Git parent 700e304. These receipts
belong to that frozen intermediate source, not the later integrated candidate.

## Approved narrow repair and admission

Share the sum of the existing toward and palm-reach translations with the pelvis,
refresh hips_y, then retain the original fixed-length leg fitting. First preserve
the existing torso path and iterative weights exactly. If unchanged continuity
fails, reject that candidate before considering a once-weighted complete solve;
never relax palm/sole/limb/marker/cloth limits. The earlier grab and Pogo fixes,
original meshes/Skin binds and all normal trial features remain.

The minimal shared-translation candidate is implemented and its
[focused run](focused/candidate/receipt.json) passes **195/0**, clean/stable on
644 inputs in 13.538 s. The new checks add 18 attachment assertions while
retaining the seven actual native contract checks, plus 170 unchanged
AuthenticPose assertions. They cover
both yaws, entry/hold/release, the existing tow→Melon fixture, ordinary Main,
actual tow interruption through bail/get-up, and restart. The 22 cm continuity
metric tracks head/feet/hands; it is not labelled a knee measurement.

The first approved candidate passes without changing the existing torso path,
iteration weights, contacts, limb lengths or test tolerances. Direct entry
maximum cloth-centre distance is 60.0 mm and torso/pelvis gap 4.0 mm; release
maxima are 59.1 mm and 4.0 mm. Existing head/feet/hands step stays below its
220 mm limit at 180.0 mm; original palms remain within 0.0026 mm, visible hand
vertices within 7.89 mm, soles within the unchanged 5 mm limit and limb ratio
within 1.0000004. The declared tow→Melon fixture moves the rider transform before
sampling; its reported 498 mm first marker jump is not a runtime continuity
assertion. Its actual garment/joint and fresh palm controls pass.

Ordinary Main retains the same 228 sampled updates and 79 caught updates:
maximum cloth-centre distance improves from 142.1 to 64.7 mm, torso/pelvis gap
from 120.0 to 32.9 mm. The independently requested actual tow interruption
records all fall/slide/get-up/ready phases across 180 updates, maximum cloth
surface gap 7.64 mm, joint gap 80.04 mm and neck gap 22.98 mm, within the original
bail limits. Restart during recovery restores neutral attachment.

The [exact old-visual negative control](focused/old-visual-negative/receipt.json)
deliberately exits 1 with **18 pass / 7 fail** on 649 stable inputs in 10.081 s.
Only the seven new attachment assertions fail: entry, release and tow→Melon at
both yaws, plus actual ordinary-Main clothing. All seven original native
input/contact/score checks still pass. Its raw `valid:false`/`clean_log:false`
are retained honestly; this is a successful defect-detection control, not a
healthy-game test pass. `legacy-sources.json` records the exact immutable old
visual and preload-only redirects of the current fixture/controller/Main.

Each new receipt retains exact non-parent inputs in `source-snapshot` and a
verified `SNAPSHOTS.json`; unchanged inputs resolve to Git parent 700e304.
These focused receipts precede the separate grab fallback cache. The later
matched frames below preserve that cache in both controls. Root's required
combined checks remain pending; these bounded results alone do not admit the
whole current checkout.

## Four matched native garment controls

The [render receipt](render/receipt.json) is clean and stable on 650 inputs in
14.902 s. Four completed native `frame_post_draw` readbacks produce 960×800 PNGs
with zero capture failures. The exact [capture derivation](render/capture-sources.json)
reverses only the three attachment hunks once in an ignored copy of the frozen
current visual. The current grab fallback cache and every other visual/controller
change remain in both controls. This is distinct from the immutable 700e304
negative-control run above.

| Actual native frame | Cloth-centre distance | Torso/pelvis gap |
| --- | ---: | ---: |
| [Before, held](render/before-held.png) | 141.17 mm | 120.05 mm |
| [After, held](render/after-held.png) | 59.45 mm | 3.49 mm |
| [Before, six release updates](render/before-released.png) | 152.10 mm | 117.80 mm |
| [After, six release updates](render/after-released.png) | 59.00 mm | 3.82 mm |

I inspected all four saved native images. The old held/released controls show
the trousers displaced from the jacket at the waist; the corrected controls
bring the trousers under the same torso while preserving planted shoes and the
existing upper-body/hand position. This is bounded attachment evidence, not final
anatomy, whole-animation quality or human feel acceptance.

The declared static fixture uses the same real native Skater, garments, Skin
binds, original handle targets and visible bar, camera, light and floor in each
control. Automatic controller processing is disabled; 60 neutral and 60 held-tow
rig calls, optionally followed by six release calls, construct the frame.
It is not a running vehicle or a native-input motion recording; the separate
ordinary-Main cases above supply that input/contact/score evidence.

All four frames report 88 draws, 62,092 primitives and 22,675,745 texture bytes.
Video memory is 30,974,961 bytes on the first frame and 30,993,017 on the remaining
three; this startup difference is retained and is not labelled equal memory or
performance acceptance. No mesh, Skin, shape, material, texture or query is
introduced by the attachment repair. The [native manifest](render/manifest.json)
records image hashes and exact scene/source/settings; the outer render receipt
retains 32 exact non-parent source snapshots.

Actual Mac behavior, physical feel, moving visual/hardware acceptance and deferred
optional feature development remain separate. Source and ordinary-native checks
cannot supply those results.
