# Thin-board native LOD diagnosis — private

The bright fragment on the5996-triangle physical-board prototype is reproduced
at native1280×800. Four matched native LOD-bias epochs each pass22/0, with no
source/cache changes or engine errors. Root reviewed all four ride-quarter views
and bias2's side/underside. The instance setting remains private and unadopted.

Bias1 shows the pale wood-shaped fragment inside the black grip. Bias2 removes
it; bias4/16 also remove it. Draw calls, allocated buffers and textures are exact
across the four cohorts. Submitted ride-view primitives increase from7,234 to
8,534 at2/4 and11,534 at16, including the identical scene/shadow workload.
This is a real rendering-cost increase, not zero work. Side and underside stay
at the control's8,534/8,530 at bias2; higher bias changes them. All resources
still contain the same5996 full-source triangles, four surfaces and one atlas.
This isolates native LOD selection as the cause of this visible defect; it does
not establish that bias2 fixes every distance/view or is the best final policy.

Source-ray11's automatic bright-pixel search selected the legitimate wood rim,
so that witness is rejected. Corrected12 tests explicitly selected interior
fragment pixels and nearby dark controls. Full-resolution source grip lies
about1.05–1.11mm vertically ahead of the wood at those rays. These offline GLB
observations support the diagnosis but do not alone prove native GPU visibility.
Their original numeric results are preserved; the exploratory inline ray
implementation was not retained and is not claimed as a reproducible verifier.

The static renderer was admitted alongside headless required09. This packet
makes no uncontended frame-time, Main, M5, motion or final visual claim. The first
parser attempt used a nonexistent private run.sh and failed before engine entry;
the corrected explicit Godot invocation with writable XDG directories parses
cleanly. No production files changed.

`source-closure.json` resolves all40 frozen inputs, including references to
verified payloads in native-construction02. Generated native caches and the
original imported baseline control retain identity-only hashes; reimport the
preserved source/policy instead of treating those hashes as portable payloads.
Payload compressed/original hashes were independently reopened and verified.
The physical board's29.225mm mounting migration, complete native contact family,
released-board collision cost and independent QA remain open. The production
5696-triangle board remains installed.
