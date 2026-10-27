# PT24-27 installed service route — 27 October 2026

**Later same-batch C03 repair:** the finite-board wall fit now retains8 mm clearance after contact and brake/idle; [four actual before/after native frames](wall-contact-frames.md) pass with identical physical actor states. The historical false adverse-camera findings below are preserved against their original source. The current gate test adds actual mesh-vertex and strict camera assertions for impact and released standing; final required-suite admission belongs to the batch integration record.

The sign and shortcut geometry already have the earlier repairs. The current candidate adds bounded **actual Main mapped-input acceptance**, rather than rebuilding the gate or placing more signage. The focused witness passes11/0; final integrated-suite registration/admission remains with root.

## Existing repaired behavior preserved

[`service_gate.gd`](../../../game/features/service_gate.gd) uses one depth-tested billboard at local `(0,3.05,-0.3)`, with font32, pixel size0.004 and outline6. It names north/south streets and the service shortcut. [`feature_hub.gd`](../../../game/features/feature_hub.gd) supplies the open/close description; the ordinary HUD supplies the current remapped interaction binding. The new witness does not hardcode a keyboard letter or introduce another sign.

The existing west alley wall and east shop facade make the native gate control a useful passage between `(-48.5,2,-18)` and `(-48.5,2,12)`. [`pt24_connected_runs_tests.gd`](../../../tests/pt24_connected_runs_tests.gd) already checks18 real displayed/native wall sites and the open route's7 m saving over a supported closed-gate detour. Both street mouths remain open.

Existing separate-capsule [`remaining_feature_tests.gd`](../../../tests/remaining_feature_tests.gd) cover native blockage/traversal, reversal, occupied-close refusal, late sensor entry, resumed close and reset. Those controls are retained. They are distinct from an integrated Main input witness.

## Actual Main input witness

Starting once at the actual north street mouth, the candidate approaches the real closed shutter with mapped Push, observes native panel impact, sends a fresh mapped Interact, waits for ordinary Main polling to raise the gate, traverses to the south street, turns using ordinary stopped steering, returns through the opening, clears the sensor, sends mapped Interact to close, and continues to the original north street mouth.

No per-tick actor transform/velocity/heading, gate toggle/tick call, score injection, content override or personal Music access is used. Support, ordinary complete-body chase clearance, bails/recovery and unchanged zero trick/score counts are observed. Closing-sensor and restart behavior already covered by the separate fixture is not falsely presented as newly played physical-Mac acceptance.

## Retained first integrated witness

The first diagnostic intentionally drove into the **closed** shutter for up to420 ticks before using Interact. It is retained as a rejection:8/2 assertions, source-stable604 inputs,13.434 s. Mapped opening, both complete transit directions, the ordinary steering turnaround, closing, native support and zero score/bails/recoveries all passed.

Its first failure was a test assumption: the capsule truly stopped at Z−2.3706 against the north shutter face Z−2.09, but actual slide-contact reports totalled2 rather than an arbitrary required18. Its second failure is a real scope limit: the long shoe/front board extends beyond the capsule into the closed shutter at head-on impact; the strict camera observer detected shoe marker Z−2.0574 behind that opaque face. This is not fixed or relabelled as clear gameplay. The shutter's native capsule collision and closed route are working, but a general finite-body/front-board solid-wall overlap remains separate C03 evidence.

The initial diagnostic also retained one leaked test resource because its evidence dictionary stored closures capturing the same dictionary. That unnecessary cycle is removed in the next driver; this does not change production behavior.

The ordinary interaction witness now stops within the mapped prompt range, opens the shutter, then traverses. Existing native closed-gate collision controls remain; no camera assertion or geometry tolerance is relaxed. The intentionally sustained collision rejection remains distinct from a clean opened-route witness.

## Passing focused witness

[Normal-route receipt](focused/gate-normal/receipt.json) and [raw console](focused/gate-normal/console.log): **11 passed /0 failed**, exit0, clean log,605 unchanged inputs,15.489 s. This is9 route/adverse assertions plus2 Music/default-on fixture assertions. Manifest SHA256 `3a8997b3dd691de830316601de40810bf9d2331dfc4559cd4a625d528d835c6e`.

Command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-gate-route-normal ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/pt24_gate_route_focused.gd -- .local/pt24_gate_route_candidate.gd
```

The exact [test](focused/gate-normal/gate-test-source.gd) and [observer](focused/gate-normal/gate-observer-source.gd) used while staged under `.local/` are retained, with hashes checked against the raw before-map. The extra user argument makes the receipt include the ignored candidate as well as the observer. The passing test is published unchanged as [`tests/pt24_gate_route_tests.gd`](../../../tests/pt24_gate_route_tests.gd); root registers it in normal Main integration; that new path does not retroactively change this focused manifest.

The full normal north→south→north return passes native support and strict complete-body camera checks, with0 bails, recoveries, tricks and points. A separate adverse phase follows on the same rider: ordinary stopped steering turns it back toward the reclosed shutter; Push makes actual panel contact at `(-48.50099,2.000583,-2.373201)`. Braking stops at `(-48.50099,2.01402,-2.388814)`, then stays within1 mm for20 ticks. There is no new pose or gate-state assignment. Total witness length is2,029 physics ticks including this adverse control.

**Open C03 adverse finding:** the strict observer again detects a front shoe about30 mm through the shutter in the deliberate head-on impact (`markerZ=-2.059975`, opaque north face `Z=-2.09`). The adverse camera result is explicitly printed `false`; the normal route result is `true`. No capsule expansion, camera tolerance change, hidden ignored failure or production reset masks this finding. The [original8/2 rejection](focused/gate-first-rejected/receipt.json), its [raw console](focused/gate-first-rejected/console.log) and exact scripts remain unmodified.

No production geometry, prompt, gameplay or rendering change was needed for this acceptance slice. Mac/physical-controller readability, human purpose/fun and final visual acceptance remain open.
