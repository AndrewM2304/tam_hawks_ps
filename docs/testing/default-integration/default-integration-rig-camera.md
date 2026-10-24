# Rig / camera reconciliation contract

Owner: /root/wallride. Only production skater_visual.gd + chase_camera.gd; no staging/commits or test edits.

Reviewed complete stage2/default d28c8f4 and stage3/work b001fd3 sources, actual original GLB manifest/generator/materials and unchanged default Garments. Runtime foundation is default GLB/native named-contact/interpolated quiet camera/local bail; work supplies contact-aware setup/catch, manual styles, wall/tow/lip/special repertoire.

## Root controller adapter

- Keep default native interpolation and get_camera_support_frame()->Basis, get_camera_support_up()->Vector3, _ramp_air, _ramp_launch_forward and RAMP_AIR_GRAVITY. Camera preserves default ramp/apex framing, reversal confirmation, fixed ground-jump height window, orbit sweep/volume/endpoint protection, maximum motion and roll limits. Work additions supply actual displayed sole/toe mask9 rays and native-platform completed travel; no old six-metre/high-angle camera replacement.
- Rig accepts work animate(delta,state) fields, plus default crouch float, ramp_turn float and bail float. bail_phase may remain the native controller's string; no rig float conversion. begin_bail() clears handplant/tow caches; default local pose blends/fixed-length shared pelvis replace obsolete work world-space falling transforms.
- Pass native_grind_contact=grinding && _grind_contact.valid. Native GrindStyle already solved the real model frame; Rig leaves Board at restY=.12 rather than double-applying work support offset. Legacy unverified fallback remains available.
- Exact floor adapter: .local/native-board-floor-integrated.gd.txt. Three-pass original work finite-floor fit retained, real GLB wheel centres/vertices replace direct primitive children and analytic Cylinder extents. No physics-body position/velocity is changed.

## Actual board API

rig.board_contact_geometry() returns board-local read-only shared arrays:

- grip_faces: actual rendered GLB Griptape triangles.
- wood_faces: actual rendered MapleAndRiverInk triangles (including bevels, underside and rim).
- wheels: four dictionaries {center:Vector3, points:PackedVector3Array}, selecting actual outer Urethane wheel vertices only (inner bushings excluded).
- support_points: native convex extreme points of the complete real rendered model.
- meshes: actual visible DetailedSkateboard MeshInstance3D references. These nodes are under Board/DetailedSkateboard; no fake hidden Griptape/Wheel primitives exist.

Default original asset is unchanged:5696triangles/one mesh/four surfaces, original atlas, Y-up identity transform and original licence/provenance. Wheelcentres(±.115,-.088,±.255), radius.032. Cast hanger underside(0,-.103,±.255); maple bellycentre(0,-.014,0). Work prior procedural −.104/−.020 anchors do not apply to the native GLB. Contact queries and Pogo/HangTen support use actual material surface geometry, not reconstruction of the old procedural mesh.

Default fixed-length leg pelvis projection and bounded free wrists are retained alongside actual planted shoe/setup contacts. Native charge crouch/ramp anticipation and ordinary-air support-height exclusion are retained. This reconciliation is not new visual polish or acceptance; combined source tests must determine remaining integration issues.

## Focused integration receipts

- Standalone native GLB rig:9/0 (.local/default-rig-camera/probe.log), actualnormalsolegap.853mm and wholecupsoleminimum−.839mm, four realtyrecomponents160verticeseach.
- ActualcombinedSkater mappednative50-50/Boardslide/reversedsloped and featureBowl:11/0 (combined-pose-driver.log); namedanchorerror≤3.82µm, normalframealignment≥.99999988, realsolecontact≤.872mm.
- Work-added authentic_pose_tests adapted to nativeboard/defaultlocalbail:167/0 (authentic-native-final.log). Unchangedsole1mm/completeshoe1.5mm/palm25mm/reach1.12 bands. Pogo checks real triangles instead of proceduralradialvertex coincidence; lipbelly/hanger datums reflectactualnativeGLB. Retainedmodel SHA validatesunchangedhardware instead of superseded eightSpherebolt topology/flush assertion.
- Pose union repaired shareddefaultvisualyaw (committedstance/nativegrindrelease), nonaccumulatingauthoredolliepitch,45ms namedgrindreleaseoffset and minimum.35heldchargecrouch.
- Camera combinedreview52/2: only projectedaxis5.32–5.37% viewport vs6%band fails. Quietollies/turns/reversal/spin/4nativeapexorbits/0occlusions/actualbodyrotation allpass. Unchangeddefaultcamera/currentSkater reproduces5.315148% (7/1 natural-return subset), so actualfootrays are not causal. Raw default Skater + default rig + default camera also reproduces exactly 5.315148% / 7 passed, 1 failed (full-default-camera-baseline.log). Classified as pre-existing default/headless readability-band failure; no band or arm changes.

- Current actual Main moving-cart Boneless: 3/0 platform checks, palm error 0.95 micrometres / planted sole 7.6 micrometres, shoulder-to-contact reach 0.5674 m (moving-boneless.log). No rig edit was necessary; the earlier 259 mm result did not reproduce on current merged source.

All owned rig/camera/test sources and the two delegated Skater functions are frozen pending combined acceptance. No source staging or commits were performed by this agent.

## Final native grind transfer hook and regression

The exact named-grind presentation block now chooses `GrindTransfer.board_transform` only while the helper is active; otherwise it retains the existing native `ContactPose.board_transform`. Board rest Y remains .12 and the rig's native pose-control flag prevents a second bearing offset. It introduces no new pose interpolation or support certificate. Native body movement and commit/scoring remain controller-owned. A single torso-only balance lean preserves rider feedback while loaded board frames retain real rigid bearing geometry.

Actual per-tick regression exposed a 49.154-degree rotation / .524196m hand step in the first transfer timing. The helper owner added an angle-aware duration with a 15rad/s bound; the same native sequence now has a .200257m maximum marker step, including both first completed frames, under the unchanged .24m limit.

Tracked tests/native_grind_transfer_tests.gd (+UID) is frozen at 10 passed / 0 failed. It reuses Overnight._rail_process's actual Central17m rail, declared initial descending contact and bounded mapped inputs; observers never assign ongoing transforms, velocity, balance, support or score. Receipt: .local/default-rig-camera/native-transfer-regression.log. Observed51 transfer physics frames +2 first completed frames,53 camera frames, zero displayed board-frame error, real sole maximum.854501mm, limb scale1.0000004, native-body/rail error0 and no blocked/out-of-frustum displayed head/sole/toe points. The retained named-contact / bowl driver also passes11/0 after the torso balance change. No camera or contact thresholds changed; no staging or commits were performed.
