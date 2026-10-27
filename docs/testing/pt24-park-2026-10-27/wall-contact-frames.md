# Finite board/shoe wall contact — native frame witness

**Four native frames /0 failures**, with unchanged source and exact old/new physical-state parity. This is completed Linux native rendering evidence; target-Mac and played-motion acceptance remain open.

[`prepare_legacy.py`](observers/prepare_legacy.py) reconstructs the exact controller from `c82ffac26265de4a379d5079ad61ece08075fa0e` into ignored `.local/`. Its SHA256 is `07ea10f46f28f95a0e1e5e3a0e8c06eaada9c7aca9fc61c09e18e572e99eaa26`. There are **no edits** to that old controller. The observer preloads its ignored path for the old actor and the normal current controller for the repaired actor. Both preload the same current visual; the preparer checks that this body-fixed visual remains byte-identical to the old commit (`f0e3f3287dacff041cdf3b82a6f7ce8629025472822870ee923c470f9d0dbde7`).

The native fixture uses the actual `ServiceGate.configure` with a2.3 m shutter centred at the origin, north face Z−0.09, on a declared20 m native/display floor. The two actors run sequentially from the same initial `(0,0.04,-3)`/headingπ, with10 settling ticks, ordinary mapped Push0.55 until a reported native panel collision, mapped Brake20 ticks, then released idle20 ticks. No actor transform/velocity/heading, rig animation or gate state is assigned after initial placement.

After the last completed native update, actor physics/process are frozen and interpolation reset. Identical side and low cameras capture two completed `frame_post_draw` readbacks per variant, four960×640 PNGs total. The observer records actual and interpolated rendered board/shoe mesh vertices, minimum signed north-face clearances, input/contact ticks, physical transforms/velocity, visual displacement, image hashes and static render-counter snapshots. Physical position, velocity, heading and first-contact tick must agree between old/new actors. The old board's penetration is a required negative control; the repaired board/shoes must both retain at least7 mm clearance.

These are frozen completed native input poses after contact and brake/release. They do not constitute a motion reel, whole-map rendering budget, frame-time benchmark, target-Mac evidence or a physical-controller claim.

Commands, from the repository root:

```sh
python3 docs/testing/pt24-park-2026-10-27/observers/prepare_legacy.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-wall-contact-rendered .local/wall_contact_capture.sh
```

The shell reuses the existing local Xorg dummy-display setup when no display is available. Engine execution remains serialized with the other agents.

## Results

[Frame manifest](captures/wall-contact/manifest.json) and [outer receipt](validation/wall-contact-rendered/receipt.json):4 frames,0 failures, clean log,609 unchanged outer inputs,24.464 s. The manifest also independently hashes all game inputs and the ignored legacy/capture files. Outer manifest SHA256 `5685616bb51ff1d7800efb6a40e4939dd4651ae4d0d59734488632779f5e8777`.

All four images were visually inspected. The old board's front disappears into the shutter; the repaired rounded nose remains visible, and the complete rider remains connected to the same board. [Before side](captures/wall-contact/before-side.png), [after side](captures/wall-contact/after-side.png), [before low nose detail](captures/wall-contact/before-low.png), [after low nose detail](captures/wall-contact/after-low.png).

| Observed after real contact→Brake20→idle20 | Old controller | Repaired controller |
| --- | ---: | ---: |
| Minimum actual board north-face clearance | −121.542 mm | +8.00002 mm |
| Minimum actual shoe north-face clearance | +10.078 mm | +139.620 mm |
| Physical position | `(0.000000395,0.011666665,-0.385957718)` | Exactly equal |
| Physical velocity | `(0,0,0)` | Exactly equal |
| First-contact Push loop index |58, zero-based |58, exactly equal |
| Side frame draw calls / primitives |102 /65,108 |102 /65,108 |
| Low detail draw calls / primitives |80 /40,800 |76 /40,416 |
| Video / texture bytes |27,940,827 /19,644,703 |Exactly equal |

Each geometry sample covers17,088 actual rendered board triangle vertices and6,744 shoe triangle vertices. Per-frame actual/interpolated board clearances agree exactly. The repaired figure moves horizontally0.129542 m away from the wall while the physical actor, speed, heading and native contact history stay unchanged; it retains the existing vertical floor skin.

The low-camera counter difference comes from different visible/occluded parts after the figure moves relative to the shutter and close crop. It is not a resource reduction or a performance improvement claim. The static side workload has identical counters. These tiny snapshots do not admit whole-map stutter or target-Mac timing.

The historical [gate rejection and pre-repair normal witness](gate-route.md) retain their original false adverse-camera observation. Their records are not rewritten as passes for the repaired source. The new gate regression additionally requires actual board/shoe geometry and strict camera clearance at impact and after brake/idle; its final required-suite result is owned by the batch integration record.
