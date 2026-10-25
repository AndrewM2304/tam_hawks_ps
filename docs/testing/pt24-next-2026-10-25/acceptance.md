# Next-batch integration acceptance — 25 October 2026

Current implementation and validation are recorded in [README](README.md). The
read-only baseline review below preceded implementation; its Music/contact/line
findings now have concrete fixes and focused results. Actual Mac/human gates remain.

Independent read-only review from main `258fec4`, after the Apple Music merge.
This note covers Music isolation, the proposed C04 input lines and current-source
smoke/package boundaries. It is not another backlog audit or an implementation
receipt. No Godot run or external Music command was issued by this reviewer.
All 76 full task records, including M05-008, remain intact.

The merged-main [4,910/0 soundtrack receipt](../apple-music-main-merge/README.md)
belongs to its recorded source. It does not admit this next batch or establish
actual Mac playback, controller feel or six complete flagship runs.

## Music isolation and actionable integration checks

[`apple_music.gd`](../../../game/audio/apple_music.gd) owns Music preferences,
commands and its bounded worker. Main configures it during `_ready()` and calls
`begin_session()` on `start_mode()`/free-skate mode entry. Consequently, a line
fixture may invoke the session hook many times even though it only intends to
reset skating. The existing production guard prevents this from controlling
Music when the game is non-persistent or launched with canonical `--script`.
`request()` checks `_can_control` before both Apple Events and `open_default`.

The reviewed baseline guard checked `args.has("--script")` in Main and
Music configuration. Godot also accepts the short `-s` script option. That
alternate entry must receive the same inert treatment before advertising that
all scripted games are isolated. Existing backend tests exercise `configure(true)`
under canonical `--script`; they do not establish the `-s` case. Root owns any
shared guard/test correction. Never validate it by permitting real Music calls.

Root accepted this finding and owns a shared Music engine-argument helper used
by Main's persistence/title decisions and Music configuration. Its acceptance
must cover both script spellings, stop interpreting engine flags at the `--`
user-argument boundary, preserve the normal owner's default/autoplay, and include
an actual isolated `-s` invocation. Root subsequently implemented this shared guard. The permanent
`tests/support/music_launch_guard.gd` passes actual short-option2/0 and long-option
33/0; the required check now executes the short guard as a separate named phase.
Preference spies prevent real profile reads even when an isolation regression
is deliberately tested. These results do not establish Mac playback.

For every new Main-based observer:

- Set `game.persistence_enabled = false` **before** adding it to the tree. A
  later assignment does not reconfigure the already-created Music node.
- Assert the actual backend is inert (`_can_control == false`, `_persist == false`)
  before a fixture's first `start_mode()`; do not infer that from Linux support
  being false or from a UI snapshot alone.
- Keep real account/preferences, `open_default` and worker creation out of line
  tests. Music UI/integration tests already use synthetic metadata and a spy.
- Preserve Main's Music snapshot cache/change signal and the restored player
  after any spy test. Pause/restart must continue to leave Music's queue alone.

No direct coupling from Music into world movement, trick scoring, grind contacts
or the chase camera was found in this source review. Its `_process`/artwork/menu
work is separate; that finding does not establish target-Mac performance.

## C04 line proposals and precise proof boundaries

| Slice | Current proposed input contract | Independent acceptance boundary |
| --- | --- | --- |
| L01 gallery→fountain | Initial `(9.1,2.08,-24)`, southward charged stair-rail departure; rail pop toward fountain tangent, fresh manual/ollie/coping catch, outward dry manual and one bank | Proves the driven gallery-terrace/stair-rail→fountain continuation if successful. It does not include the entrance ledge unless that feature is actually captured. Record exact native guide IDs and no intermediate bank. |
| L02 station→city | Initial `(−126,2.08,35)`, eastward spine air/fresh transfer plus flip; manual via existing bank near `(−80,2,40)`, north turn to south street, east descent to `(−26,0,22)` | Long manual speed/balance/turning and fresh transfer clearance are actual proof uncertainties. Do not replace a failed link with per-tick heading/speed correction or label a partial spine transfer as the complete city run. |
| L06 park approach | Existing east-lower and gateway seats reoriented along the supported descent near X−148; initial Z≈−147, upper catch→manual→gateway/promenade choice | A local descent can prove the relocated seat/manual handoff. It does not prove summit/cutback→city or facility arrival/return unless those portions are actually driven. Preserve the ordinary two-way road bypass. |

These are agent proposals, not passing results. Record changed geometry and
actual input receipts before changing their acceptance state. Existing
[`pt24_connected_runs_tests.gd`](../../../tests/pt24_connected_runs_tests.gd),
[`compact_clyde_lines_tests.gd`](../../../tests/compact_clyde_lines_tests.gd)
and the [native proof driver](../../../tests/support/compact_clyde_lines_driver.gd)
provide useful established input, contact, bank and return patterns.

Two concrete pitfalls in reusing those helpers:

1. `trick_performed` supplies raw points. Main applies repeat identity/degradation
   in `ScoreSession.add_trick()`. L01 proposes repeated Ollies and Manuals, so
   summing fresh catalog values and multiplying by event count is incorrect.
   Independently account for repetition identity, hold awards and spin extensions;
   spins extend an entry rather than adding a multiplier. Observe one positive
   total-score change, then a stable bank and empty pending combo. Do not call
   award/bank methods to make the fixture succeed.
2. `Driver.drive()`/`stop()` release actions and brake around sharp corners.
   They are suitable for an ordinary return **after** the earned bank, not proof
   of uninterrupted manual continuation. The production manual turn axis uses
   mapped spin actions; use real input rather than assigning yaw.

Native samples should show consecutive physics ticks, finite transforms,
physical guide identity, actual support/landing, zero bails and the expected
event order. Preserve contact/clearance thresholds, protected ports, novice
bypasses and original goal/save/route/rail identities. Feature proximity or a
supported path alone cannot establish a continuous combo.

## Camera observation timing

`SceneTree.process_frame` emits before node `_process` callbacks. A helper that
awaits physics then `process_frame` can compare the new physical rider against
the previous camera update. Observe frustum/occlusion after a zero-duration
non-physics timer (`create_timer(0.0, false, false).timeout`) or an equivalent
completed-presentation barrier. Keep the full actual hull/foot/tyre checks; do
not change position, FOV, contact margins or assertions to compensate for timing.
The timer respects pause, so use it in the active unpaused line fixture.

## Source smoke and package boundaries

The scene-based [`playability_boot.gd`](../../../tests/playability_boot.gd)
deliberately omits `--script` to exercise Main's normal title branch, but correctly
sets persistence false before `_ready()`. This is the model for normal-branch
test games. The export pack inspector loads/instantiates/frees Main without
adding it to a tree, so it does not configure or start Music.

[`source_launch_smoke.py`](../../../tools/source_launch_smoke.py) cold/warm phases
launch normal Main at the title without a script flag; they do not call gameplay
entry, so source inspection found no automatic Music command there. They may
still load normal preferences on macOS. Their XDG isolation and recorded limits
are Linux source diagnostics; do not treat them as isolated Mac-account tests
without addressing Mac's actual user-data path first. Use explicit test-game
configuration for any automated Mac gameplay phase.

Native packages from before the soundtrack merge do not certify that merge.
A new artifact needs current source/resource/notice/hash checks and inspection
of its actual `NSAppleEventsUsageDescription`/Apple Events entitlement metadata.
Existing unsigned/no-notarization settings remain. Main loading its Music script
is package dependency evidence, not consent or playback acceptance.

## Real remaining blockers

Actual Mac Music Automation consent, application dictionary execution, subscription
playback/shuffle, natural track changes, artwork and controller transport behavior
remain open under [M05-008's existing checklist](../APPLE-MUSIC.md#target-mac-acceptance-still-open).
Likewise, C04's proposed lines need real production-input results and source-bound
camera evidence. Human fun/steering, target-Mac stutter, final art and standalone
Mac play remain separate gates. No new feature, service, broad audit or additional
optional challenge is proposed by this review.
