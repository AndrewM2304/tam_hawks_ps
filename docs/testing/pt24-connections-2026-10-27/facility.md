# Promenade practice, hill access and sunken-facility return

C04-L06 continuation on `main` from `69fcbc8`, 27 October 2026. This slice is one
real practice combo and bank, followed by an ordinary supported journey to the
sunken facility and back. It does not promise an uninterrupted 200m uphill combo.
The focused native witness passes **11/0**; the exact receipt and retained
rejections are recorded below. Root owns final combined-source registration and
admission.

**P1 · M03 · Owners: level design/skating/QE · Dependencies: supported C01/C03
contacts, existing promenade quarter, summit access and beginner return.**

## Existing layout reused

The promenade quarter at approximately (−96,6,−130) already supplies a finite
native vertical-air return. The proposed input earns two genuine air-trick
entries, returns to native quarter support and banks once. Its independent
catalog/repetition/hold receipt is checked before beginning ordinary travel.

The same rider then uses the promenade's north through lane near Z−124, the east
hillside loop near X−145, the summit/viewpoint spur and the existing
`kelvingrove_summit_skatepark` access. Its actual ramp runs from (−173,17,−182.5)
through (−179,17,−182.5) and (−183.25,15.75,−182.5) to the mapped entrance at
(−187.5,14.5,−182.5).

Inside the park, the route uses the actual `get_safety_routes()[0]` beginner
circuit. It stays on the arrival deck before turning through the intended gap
near X−190/Z−179 onto the ten-metre gentle bank. A direct diagonal from the
entrance into the lower street would cross an intentionally retained wall.
The circuit returns through the same finite bank, then the rider follows the
whole access/hill/promenade route in reverse. Existing entry and beginner tests
are reused as source contracts; their reset-based fixtures are not called to
simulate completion of this longer journey.

No bench, tree, fence, native floor, ramp, guide, material or other runtime
resource is moved or added by this candidate. No global skating or score rule
changes are proposed. Main's station/train, pond, green and civic return remain
on, and Music persistence is disabled before the focused fixture enters the tree.

## Acceptance strategy

- One declared initial spawn/facing only. There are no actor transform, velocity,
  heading or score writes during the journey, no mid-trip restart, and no direct
  transition/gate ticking.
- Independent fixed full-width native floor rays and short two-way capsule
  sweeps check the promenade/hill/summit access against public ground queries.
- Real mapped Push, Brake, steering and air-trick inputs earn the practice bank.
  Every subsequent journey metre uses ordinary mapped controls; no extra trick
  or duplicate bank may be manufactured by transit.
- Strict complete-body/board chase checks run throughout, including the real
  beginner arrival and return. The older local beginner fixture checks the head
  only, so it cannot substitute for this stronger evidence.
- Before committing to the entrance and beginner bank, the actual ordinary chase
  must show their next-choice points without a native opaque obstruction. The
  actual summit-link and East-roll-in HUD cues must match the rider's positions.
- The same rider must arrive at the actual facility, complete the beginner loop,
  return to practice, stay supported during ordinary transit and incur no bail
  or recovery. Initial placement is restored only after the test is complete.

Actual Mac motion, physical-controller feel, target performance and human route
readability remain separate acceptance. A source/native witness is not a claim
that every possible cutback, bowl or continuous-combo branch is accepted.

## Native receipt

[Final receipt](focused/facility-entry-arrival/receipt.json) and
[raw console](focused/facility-entry-arrival/console.log): **11 passed / 0 failed**,
exit 0, clean log, 616 unchanged inputs, 32.280s. Source-manifest SHA256:
`db88ca82b9327dee265c10706cd12aec129d836766559664708f95006f85df00`.

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-facility/entry-arrival timeout 100s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/pt24_facility_connection_focused.gd
```

The [observer](observers/facility_connection_focused.gd) preloads the published
[`tests/pt24_facility_connection_tests.gd`](../../../tests/pt24_facility_connection_tests.gd).
Copy the observer to the ignored command path to repeat it. The wrapper hashes
that command file and every game/test/tool input. Each focused directory retains
its exact test/observer snapshots, verified against the recorded before-map.

The actual promenade-quarter Kickflip and Melon Grab earn **1,100 once**, from
catalog points 300+250 and multiplier 2. The same rider then travels **385.421m**,
including 1,101 observed beginner-circuit ticks and 6,535 ordinary transit ticks.
It reaches the real entrance at Y14.5723, completes the lower-basin entry and gentle
bank return, and returns to the initial practice approach. There are zero bails,
recoveries, additional trick entries or duplicated banks. Strict full-body chase,
ordinary native support, entry/landing visibility and both actual location cues
pass throughout their declared scopes.

The independent 483 full-width support samples have maximum native/public query
error 0.0463mm; two-way capsule sweeps are clear. Separately declared 6/17/15.75/
14.5m waypoint levels agree within 58.7mm, preventing a lower matching floor from
standing in for the intended access. The final actual entrance approach uses an
18cm XZ target radius and retains the independent 15cm height requirement.

Retained rejections:

| Case | Result | Diagnosis / correction |
| --- | --- | --- |
| [First](focused/facility-first/receipt.json) | 6/4; stable 616 inputs; 9.776s | Practice bank passes. The driver steers while the real quarter toe exit still carries backward 14.4m/s momentum; its detour reaches the side roll-in and strict camera correctly rejects occlusion. No production defect established. The driver now uses actual mapped Brake to stop before the next turn. |
| [Stopped quarter](focused/facility-stopped-quarter/receipt.json) | 10/1; stable 616 inputs; 32.024s | The whole journey, circuit, return, camera/support and cues pass. A generic 65cm XZ waypoint radius stops 60cm before the entrance on the descending ramp, giving actual Y14.7033. The new independent height assertion correctly refuses that incomplete arrival. The driver moves closer to the endpoint; the 15cm height requirement is preserved. |

Neither correction changes a game rule, native geometry, resource budget,
camera threshold, score or support allowance. No new runtime implementation was
needed for this connected route slice. Its bank is a practice result followed
by ordinary travel; it is not relabelled as a single 385m combo.
