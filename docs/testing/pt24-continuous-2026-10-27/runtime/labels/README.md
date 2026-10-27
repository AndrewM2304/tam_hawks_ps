# Reuse local trick metadata and current HUD labels

**C10 · A04/A09 · P0 · M06.** The pose update already obtains a detached manual
definition before calculating its deck angles. Four later fields in its
synchronous rig-state dictionary repeated that same catalog lookup/deep copy.
They now read the existing update-local definition. Rig only reads these values;
there is no persistent definition cache or public catalog change.

Main's rendered HUD refresh also looked up and copied both grind and manual
definitions every call. Two independent ID/string slots now retain only the
current labels. Each exact raw-ID change refreshes that label immediately;
the grind and manual fallbacks remain respectively `""` and `"Manual"`, including
the first empty IDs. Canonical and compatibility identities still go through
the original catalog. The slots retain no catalog dictionaries or global
mutable data. Timers, state refresh frequency, scoring, physics, Music and
feature availability retain their existing behavior.

The added test exercises the real Main refresh and real HUD using an unparented
counting Main that temporarily borrows the existing scene's dependencies.
It checks first-empty and unknown fallbacks, immediate independent changes,
all canonical/compatibility labels, unchanged-call read counts and a changed
timer snapshot. Temporary metadata IDs and the entire live HUD snapshot restore
synchronously before any next physics frame. The fixture does not start another
world or write a profile/control personal Music. Existing HUD efficiency tests
own actual timer/encounter/menu/settings flow acceptance.

The separate legacy observer extracts Main from immutable parent
`700e304861c282bb11dcd762c0cae04a06ec2642`, verifies its SHA256, and instruments
only the two label lookup expressions with a counter. Its full refresh body
uses the same current scene dependencies as the changed Main. It compares full
HUD snapshots across empty IDs, 31 unchanged calls, every canonical/compatibility
ID, unknown IDs and a changed timer snapshot. This control does not claim the
entire historical game was rerun.

[Focused current](focused/current/receipt.json): **33 passed / 0 failed**, exit 0,
clean and stable across 644 inputs, 7.370 seconds. This comprises 10 new label
assertions, 22 unchanged HUD efficiency assertions and one pre-construction
isolation guard. The new tests cover all 87 canonical and compatibility IDs.
Manifest: `c6e97c5f7ab9609753159ed3fea3044345ccb4914de74a604ca730611ddf2c2f`.

[Counted immutable Main](focused/immutable-parent/receipt.json): **6 / 0**, exit 0,
clean and stable across 646 inputs, 7.469 seconds. All 122 paired refreshes
preserve the complete HUD snapshot. Across 31 unchanged known-ID pairs, the
original performs 62 label reads and the changed Main performs two. Across the
whole deliberately changing-ID sequence, the counts are 244 and 180. Retained
storage is two ID/string slots. Manifest:
`78e7af9b356ad7eb19914fae4a6b7cd9ebdade7a99d890d2140f61f919db9a1d`.

[Source index](source-snapshots.json) resolves all 647 unique outer inputs to
618 immutable-parent blobs and 29 exact retained snapshots. Raw receipts, logs
and before/after maps are unchanged. [Original-source identity](immutable-original-main.json)
records the immutable Main hash and the derived two-call counter hash.

These are metadata lookup/allocation reductions; neither these work counts nor
verification durations establish a target-Mac frame-time improvement or resolve
the reported stutter. The four update-local aliases require the existing
pose/manual/grab integration checks in root's combined production admission.

From the repository root, with no concurrent engine/render workload:

```sh
python3 docs/testing/pt24-continuous-2026-10-27/runtime/labels/observers/prepare.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/hud-labels-focused timeout 45s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/hud_labels_focused.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/hud-labels-legacy timeout 45s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/hud_labels_legacy_parity.gd -- .local/hud_label_original_main.gd .local/hud_label_original_counted_main.gd
```

The explicit final arguments bind both ignored legacy-source files to the outer
source manifest. Root owns integrated production admission via `tools/check.sh`
and the existing manual/pose/grab integration suites.
