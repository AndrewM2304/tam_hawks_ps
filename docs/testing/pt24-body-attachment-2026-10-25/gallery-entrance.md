# Gallery entrance ledge → stair rail → fountain

25 October 2026. Prepared from main `b7d9aa60b895`; the torso/leg attachment
repair has priority. This bounded secondary slice adds acceptance source only,
with no engine run until root releases that priority lease.

The existing Gallery representative starts at the stair apron and banks8,000
through the stair rail, flatland Manual and fountain coping. It does not prove
the earlier entrance-bank/angled-ledge handoff. This test adds that missing entry
while retaining one continuous earned combo and the existing native/camera gates.

## Declared line and deterministic risks

Start on supported paving near(−18,2.08,−35.3), facing east. Push up the existing
west entrance bank, charge/release an actual Ollie, and capture
`Grind_Ledge_GalleryEntrance`. Follow its real bend from(−5,3.2,−35) through
(−1,3.2,−35)/(0,3.2,−34) to the south-facing end at(0,3.2,−33.4).
Pop south onto the entrance apron/front-bank landing and enter a fresh Manual.
Shoulder-carve through approximately(6.5,2,−26)/(9.1,2,−23.8), align with the
existing stair-rail approach and charge/pop onto `Grind_Rail_GallerySteps`.
Continue the successful outward stair pop→Manual→fountain tangent→Ollie→coping
ride→outward dry pop→Manual sequence, then release and bank once.

The short final ledge segment, manual turn and remaining approach speed are
concrete timing risks. Source inspection finds no missing ground in the planned
apron/rail handoff. Fixed independent native-width/capsule checks cover those
sites before a route is claimed. No new ramp, rail, catch volume or score award
is proposed to fill a route that has not yet been driven.

## Acceptance and fixture limits

`pt24_gallery_entrance_run_tests.gd` reuses the existing flagship driver helpers,
scoring receipt, contact limits and post-process full-rider camera check. The
legacy entrance fixture's direct ground-heading helper is not used. Only the
initial spawn/facing is assigned; all subsequent movement, turning, catches,
manual balance and tricks use production mapped inputs. There is no mid-run
reset or per-tick pose/heading/velocity/speed/score assignment.

The earned capture sequence must be exactly entrance ledge→stair rail→fountain
coping. Catalog identities/repetition/hold points independently determine the
one bank; bail/recovery, extra banks, hidden rider and unsupported manual travel
fail. The protected miss uses the existing X−22/Z−22 cross-court bypass and the
continuous X14.6 east-side descent into the fountain court, with actual ordinary
Push/Brake/steering and no jump required.

Construction delta: zero production edits, new props, meshes/draws/materials,
textures/lights or bodies/shapes. Human difficulty/fun and target-Mac moving
acceptance are separate from this bounded input test.

## Rejected first invocation

The first granted call used actual Main defaults, with persistence disabled
before attaching Main and no content override. Both pre-mode Music-isolation
and enabled-content assertions pass. The test itself did not execute: a local
`hit` variable inferred from dynamically typed `game.world` required an explicit
Dictionary annotation. The running observer was terminated after diagnosis;
the source-bound rejected receipt retains600 unchanged inputs, exit−15 and an
unclean parser log at `.local/pt24-gallery-entrance-first/`.

Only that test variable annotation was corrected. No gameplay/source geometry,
physics, input or assertion change followed from this compile failure.

## First actual attempt — rejected directional takeoff

The first actual input attempt records **5 passed /3 failed**, exit1,
**600 unchanged inputs**,13.331s. Receipt:
`.local/pt24-gallery-entrance-first-input/receipt.json`, manifest SHA256
`009eb8eb30d82bbb8426fe91bd0b7b7881c3d4573710283d63b24a3c46c93b56`.
Music isolation, default trial content, finite ledge identity, native full-width
support/clearance and the actual ordinary miss bypass all pass.

The first failed phase is `entrance_bank_pop_catch`: the new approach driver
selects **Boneless**, then never captures the ledge. The reused speed cap releases
Push while applying Brake, introducing a fresh South cue just before release.
The production selector correctly interprets that cue as Boneless. It is not a
missing-ground result or evidence that a new ramp/rail is needed. One bank of250
with zero bails and no captures/manuals cannot establish the requested combo.
That rejected attempt also retains a strict camera endpoint contact against
`GalleryEntranceWestBank`; it is not dismissed by loosening an assertion.

Root authorized one input-only follow-up. The approach now keeps Push held at a
stable strength while equal-strength Brake controls the same6.5m/s cap. This
preserves normal braking without manufacturing a fresh South takeoff cue. No
production trick gate, launch force, capture/geometry, score rule or camera
tolerance changes. A failed upstream phase now stops the candidate immediately;
downstream navigation occurs only after its genuine prerequisite contact.

## Accepted bounded extension

The revised source-bound run passes **8/0**, exit0, clean,
**600 unchanged inputs**,15.491s. Command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-gallery-entrance-revised-input timeout 180s ./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_gallery_entrance_focused.gd
```

Manifest SHA256:
`d9806eefc9492b292fe382468e9c0eff15faa160b1124e9fe8192d77ae8cc01c`.
The receipt's parent HEAD is `b7d9aa60b895`; the complete input hashes bind the
working body-repair/test source actually used. Root owns portable copying of
the observer, receipts, source manifests and logs from all three attempts.

The ordinary Ollie rides0.274m up the bank before takeoff. It catches the actual
entrance guide and follows its angle for62 ticks into the real south-facing
exit. Its south pop lands into a Manual near(0,2.012,−30.586), then actual
shoulder controls reach the stair approach near(8.973,2.012,−23.473) without
reset. The three earned guide captures are exactly:

1. `Grind_Ledge_GalleryEntrance`
2. `Grind_Rail_GallerySteps`
3. `Grind_Coping_ExchangeFountain`

All three Manual links total393 physics ticks. The twelve actual catalog
entries, repetition decay and350 genuine grind-hold points independently
calculate **12,888**, banked **once**, with **zero bails/recoveries**. Strict
complete-rider/board camera checks and supported manual travel pass unchanged.
The line ends on dry court paving near(7.959,0.012,15.504).

The separate ordinary no-jump miss bypass also passes with no trick entries,
bank, bail or recovery and a clear chase camera, ending near(14.600,0.010,22.815).
No production placement fix or additional object was needed. This closes the
specific automated entrance→angled ledge→stair→fountain link missing from the
earlier8,000 representative; it does not certify every optional later branch,
human difficulty/fun, target-Mac timing or the separate torso/leg visual repair.
