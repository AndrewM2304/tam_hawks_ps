# Station compatibility development — 7 November 2026

[Native plan and actual traces](native-plan-04.svg) show the current proposal.

The private candidate opens the existing halfpipe's west end towards the manual
bank and leaves a clear north-turn apron. It is **not promoted**: the final
compatibility aggregate is **28 passes / 3 failures**, and a follow-up identifies
a real tyre/coping contact. Actual production source was not edited.

The current candidate keeps the pipe at `(-65,2,35)`, yaw zero, and reflects the
positions of each existing side roll-in and its matching landing. Bases remain
rigid and positive. The bank moves to `(-88,2,37.2)`. Its east toe is X−82.8;
the untouched original canopy column's west face is X−76.24. A north-going
centre lane at X−79.5 now has a supported four-metre body-centre band. The
original X−82 north bypass also retains its four-metre band. No column, roof,
feature ID, gap ID or resource is added.

The final inventory is exactly the frozen baseline: **574 bodies, 1,755 shapes,
1,187 mesh nodes, 503 MultiMesh nodes, 531 unique visual meshes and 106 override
materials**. Earlier experiments moved and reshaped a column, creating one
extra unique mesh; that rejected epoch is preserved, and the column is restored
byte-for-byte in the current candidate.

`reviewable-proposal-04/guard.json` binds the two geometry files and the legacy
C04 input-coordinate adapter. In the C04 driver, only `_station` and the bank
coordinate predicate in `_step` differ; every other static function body,
score/one-bank calculator, physical threshold and camera oracle is exact. The
north turn is completed with mapped inputs before a real charged pop; no actor
pose, speed or balance is assigned per frame.

The complete `epoch-04` run records:

- The original spine transfer → bank Manual → city continuation and its
  independently calculated **exactly-one-bank** receipt both pass. Its late
  trace contains 993 consecutive physics frames and 124.205m of actual travel.
- All 14 career and grade-combo compatibility checks pass, including every
  career goal and both directions across the three district grades. The legacy
  career driver uses its existing grounded yaw aiming; it is preserved career
  feasibility, not a new strict L1 circuit.
- The separate mapped no-jump apron miss and supported return pass.
- The reused, separately initialised bank → open flat → opposing pipe faces →
  bank return scores 7/1. Both faces exceed 35 degrees (68.101° north, 46.413°
  south), actual bank Manual lasts 42 physics steps, no bail/recovery occurs,
  and every sampled full-body chase, actual board component and shoe is clear.
  One final loaded deck capsule query overlaps by a very small amount and
  remains a failed raw diagnostic.

The pipe passage has 703 consecutive physics frames and 76.104m of observed
travel. Bank toe → first native curve is 154 actual physics steps / **2.5667s /
20.1887m**. Toe → actual north face≥35° is164 / **2.7333s /21.4093m**,
using the first real qualifying pose rather than an input or guide. Opposing
south-face return → bank approach is164 / **2.7333s /17.7054m**. The 3.1s between first curve and south return includes riding the
opposing features; it is not a 3.1s empty-land interval. Charge input is never
counted as a meaningful feature. These figures describe one local return, not
all six arenas or three cross-arena circuits.

Three failed diagnostics remain separate:

1. An experimental four-metre band along the original career diagonal collides
   with an inherited canopy column on one shoulder and the relocated pipe's
   rear wall on the other. The original centreline remains clear in both
   directions and the actual career route completes. This added band was never
   an inherited four-metre contract; its failure is retained rather than
   replacing the original route assertion.
2. The full-prefix raw volume test finds 16 zero-margin capsule contacts. The
   exact existing `LineDesign._loaded_capsule_contact` independently accepts the
   15 bank-grade contacts, measuring about **0.241mm** penetration within the
   existing native solver contract. The unchanged spine-ingress contact at
   physics 115 is refused and remains unclassified. The observed depth is not a
   new tolerance and does not excuse any board/shoe or airborne overlap.
3. At physics **319**, one real model component **27** (a 160-vertex tyre)
   overlaps `Grind_Ledge_station_low_manual/NativeGrindBearing`, **integer shape
   3**, a visible and native cylinder of radius 70mm and length 2.2m centred at
   `(-91,2.31,37.2)`. The actor is in grounded Manual at 7.4026m/s. Independent
   offline projection of the rounded point/frame dump places a tyre vertex
   about **2.333mm inside** its finite radial section. This exceeds rounding
   uncertainty and is a real rejection. Loaded capsule authority cannot excuse
   it. Exact raw native overlap/shape identities and the bounded approximation
   are preserved in `contact-diagnostic-05`.

The early-stop contact diagnostic deliberately exits at the first model failure
and retains its resource-in-use shutdown warning. It is rejected **0/1**, not a
clean successful gate. The four previous native epochs, before/after manifests,
actual wrapper receipts and available matching source revisions are preserved.
`reconciliation.json` records **176.668 seconds** of the root-authorised 180s
native allowance. No more engines were started under that allowance.

There is no production install, final visual proof, performance claim, reverse
line admission or whole L1 acceptance here. Next work is exact tyre/coping
presentation repair or an independently justified physical design change,
classification of the inherited spine contact against unchanged geometry,
matched captures, then focused ordinary C04/route/feature admission. The older
bank-at-X−80 functional 8/0 packet remains immutable and narrower in scope.
