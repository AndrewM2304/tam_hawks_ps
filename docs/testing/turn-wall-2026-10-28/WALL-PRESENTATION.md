# Bounded wallride entry and exit — 28 October 2026

Local task **C03-WALL-28**, P0, owner wallride agent, M01/M05. This repairs the
reported janky wallride presentation while preserving the existing collision,
acquisition reach, motion, score and fixed connected figure.

The previous first-contact pose assigned the complete 0.65-radian lean in one
frame. It also pulled the whole figure immediately to the wall's 15mm tyre
bearing. After fixing rotation, the [first focused run](focused-first-rejected/receipt.json)
still rejects **193/8**: native pose markers move 250.374mm at the ordinary
0.65m approach and 500.372mm near the existing 0.90m entry reach. All eight
failures are the original 220mm pose-travel limit. Physics, clothing attachment,
native tyre bearing and once-only Wallride/Wallie events pass separately.

Entry now eases the actual incoming pre-trick support basis at the existing
4.5rad/s air-pose ceiling and 14/s response. Actual tyre vertices still define
the finite native wall plane. A positive gap approaches that bearing at most
4.5m/s; fresh penetration receives its immediate outward correction. The
original 15mm settled bearing remains exact. No collider or physical actor is
translated by this presentation fit.

The [late-exit cohort](focused-final/receipt.json) then passes **203/0**. Additional
real far-reach releases reveal another defect: the
[first early-exit cohort](early-wall-first-rejected/receipt.json) rejects
**134/8**. Releasing Grind at tick5, or pressing Ollie at tick1 and releasing it
at tick5, resets a still-live presentation translation and moves native pose
markers 352.328mm. These four motion failures and four small-angle observer
failures remain rejected evidence.

The wall controller now retains only the actual offset on a genuine
active-wall-to-air transition. Ordinary air decays it at 4.5m/s, after the
existing native board/shoe clearance check admits that offset against the
current actual pose. No remembered wall plane, predicted matrix or cooldown
can authorise it. Reset, bail, landing, new flight and movement-mode takeovers
clear it. The transient clearance adds at most three shape queries per frame,
restores the shared query and adds zero work after the earned vector clears.

A successfully acquired wall also clears the preceding ramp-air/vert-return
owner. Otherwise the later ramp-return pose could overwrite the wall pose.
The control declares initial ramp-flight metadata, then earns wall support
through real native probes; it is not a played ramp-launch route.

The [corrected wall cohort](early-wall-corrected/receipt.json) passes **153/0**,
exit0 with a clean log and **678 stable inputs** in **19.850432s**. Its
[parser](early-wall-parser-02/receipt.json) passes in0.904733s. Manifest
`41863b2cef50b99cdaa9a336ce4efe177959baccb1c9ccf4bb78be9ae59628ff`
binds670 immutable `21b0e86` Git inputs plus eight exact retained changed-input
snapshots. The 64 original native wall assertions and 89 presentation assertions
cover both sides, both approach distances, late/early release and Wallie, and
the declared ramp-flight takeover.

| Corrected native measurement | Maximum or bound |
| --- | ---: |
| Actor-relative head/feet/hand step, all13 cases |177.361mm, below220mm|
| Early-exit pose step |83.190–130.300mm|
| Independent relative-matrix rotation step |0.075000572rad, within0.075001rad|
| Raw quaternion angle, retained |0.075003333rad|
| Actual tyre gap, minimum |14.999941mm|
| First exact bearing, latest |tick4, before deadline8|
| Settled tyre gap, maximum |15.000075mm|
| Actual planted-shoe error |0.855296mm, below5mm|
| Skin-bound jacket/waist seam |55.911mm, below120mm|
| Torso/pelvis joint gap |0.219404mm, below60mm|
| Anatomical neck/collar gap |22.936mm, below50mm|

[Derived metrics](wall-presentation-metrics.json) retain every case. The raw
log preserves quaternion angles and exact before/after basis witnesses. The
independent `atan2(length(skew(relative_basis)), trace(relative_basis)-1)` metric
avoids the small-angle `acos(quaternion-dot)` cancellation; the 4.5rad/s bound
and1e-6rad allowance are unchanged. The older observer rejection is not relabelled.

[The inspected THPS research](../../research/THPS-LANDING-WALLRIDE-2026-10-28.md)
supports mirrored wall states, contact-owned orientation and distinct entry/exit
animation. It supplies no skeletal clips or portable timing. This original
patch preserves the existing37-degree authored lean; it does not claim THPS's
full wall-plane orientation or import reconstructed code/assets. Rendered
appearance and owner feel remain separate from this headless native receipt.
