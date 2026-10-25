# Priority torso/leg attachment repair —25 October2026

The owner reports the torso detaching and lying at the ground while skating
after tricks/bails. This matches an independently reproduced residual-grab bug:
the fading grab value never becomes exactly zero, while the reach solver applied
its entire torso translation for any positive value. The same torso-only shift
also detached the jacket during an active grab.

The repair weights the solved reach displacement by the actual grab influence
and moves pelvis and torso together before the existing fixed-length leg/foot
fit. No generic reset, snapped pose, altered limb length, bind/asset change,
physical movement, score/input or camera change is used. World trial features
remain on by default and Music behavior is preserved.

**Focused checks290/0**, including18 new real skinned-mesh/bind checks plus272
unchanged AuthenticPose/TrickPose/BailRecovery assertions. Actual mapped inputs
reproduce grab/release and grab→bail→get-up→Push. Fixed-body/cloth alignment also
covers full and partial grabs, post-grab Kickflip, real manual failure, repeated
bail requests and restart during fall. [Independent witnesses](rig-witnesses.md).
Old code reaches668mm garment-centre/614mm torso-pelvis separation; repaired
post-grab skating is65mm/25mm, consistent with neutral garment geometry and sway.
Folded-bail actual hem-to-waist surface gap is at most7.4mm; its121mm ring-centre
distance is not a visible cloth opening.

[Eight native rendered controls](captures/manifest.json) compare immutable old
visual source from`b7d9aa6` with the fixed source, using identical real Skaters,
skins/binds/assets and declared direct Rig.animate sequences. Physics/automatic
actor processing is disabled: these are static causal garment views, not a
recorded flight or performance benchmark. [Before release](captures/before-released-skating.png),
[after release](captures/after-released-skating.png), [after active grab](captures/after-active-grab.png).
Old controller differs only in its visual preload; provenance hashes are retained.
The native mapped-input tests provide the complementary controller evidence.

**Required combined admission5,062/0**, plus actual Music script guard2/0;
exit0, clean log,601 unchanged inputs,445.051s. [Receipt/log/source maps](validation/receipt.json).
Manifest SHA256`302ac737841520240c270bc84d254ab6fd8ebc176e84c7a974a3d9feaf1f7daa`.
Four [cold-source phases](cold/SOURCE-LAUNCH.json) pass with507 stable inputs,
normal no-script title-to-play50/0 and deliberate broken-source refusal.
Current unsigned packages follow the clean source commit. Gallery
entrance→angled ledge→Manual→stair rail→Manual→fountain coping→dry Manual now
passes8/0 focused checks on ordinary Main, earning12,888 once with393 Manual
ticks, zero bails/recoveries and strict camera/support. The ordinary no-jump
miss passes too. [Gallery witness](gallery-entrance.md). No new geometry or
production trick/scoring change was needed.
Earlier5,038/0 certifies its prior source, and earlier unexplained photos are not
blanket-closed without a matched cause. No target-Mac/performance/human result is
invented, and no feature is hidden pending those results.
