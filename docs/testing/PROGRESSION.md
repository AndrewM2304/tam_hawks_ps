# Career goals and local persistence foundation

Implemented for M04-002/M04-004/M04-005 integration. `game/progression/career_progress.gd` is an original `RefCounted` class (`CareerProgress`) using Godot's built-in JSON, FileAccess and DirAccess. It requires no plug-in, account, server, paid API or imported dependency. Goal thresholds and rewards are provisional until M04-006 play/balance evidence; these checks do not close the owner/controller or full-career gameplay gates.

## Public integration contract

- `begin_run(free_skate: bool)` starts event admission and resets partial score/collection progress. Completed goals, records and settings remain intact.
- `record_score(total: int, best_combo: int) -> Array[String]` accepts **banked** current-run total/best combo and returns newly completed goal IDs. Call after score banking, not with pending combo previews. It updates personal records monotonically during an eligible career run. Negative scores clamp to zero; a combo cannot exceed the run total. Profile scores are capped at 2,000,000,000 for validated JSON integer precision and bounded display input.
- `record_event(kind: String, id: String) -> Array[String]` accepts a validated world event. Root/world code owns actual collision/proximity/route detection. Unknown or repeated events do not increase progress.
- `finish_run(total: int, best_combo: int) -> Array[String]` records final banked results, then closes event admission. Duplicate finish calls cannot award anything.
- `goals_snapshot() -> Array[Dictionary]` returns copies containing `id`, `title`, `detail`, `done`, `progress` and `target`. Completed goals display full progress even after run reset.
- `unlocks() -> Array[String]` derives cosmetic/special availability from completed goals; basic skating never depends on an unlock.
- `load_profile(path = "user://career.json") -> Error` and `save_profile(path = "user://career.json") -> Error` perform explicitly requested local persistence. Construction and run APIs do not read or write disk automatically.
- `recover_profile(path = "user://career.json") -> Error` is an **explicit player-selected reset**. It archives existing primary, backup and temporary files before writing a fresh profile. Never invoke it automatically when load/save fails.

Public data: `completed_ids: Array[String]`, `best_score: int`, `best_combo: int`, `settings: Dictionary`, `last_load_used_backup: bool`, `last_error: String`. The explanatory last error contains no secrets. Load before starting a run; a successful load clears transient run state. A failed load leaves existing in-memory career data intact.

Both `record_score` and `record_event` ignore events before a run, after finish, and throughout free skate. Free skate cannot complete career goals, accumulate partial career collections or change career records. Existing completion remains visible. Collectibles gathered before an ordinary bail remain gathered for that run; a new run or mode change resets partial collections. Settings may still be saved while in free skate.

Do not save every rendered frame. Root should save after meaningful banked record/goal changes, run completion or setting changes and report actual persistence failures in the UI. The model's in-memory completion does not mean a failed disk save succeeded. Automated main/scene tests must disable persistence before the game starts; focused model tests use only isolated `.local` paths.

## Goals and canonical event IDs

| Goal ID | Goal / target | Event or banked-score condition |
|---|---|---|
| `first_shift` | First shift — 1,000 | Current career-run total ≥ 1,000 |
| `good_shift` | Good shift — 5,000 | Current career-run total ≥ 5,000 |
| `some_shift` | Some shift — 15,000 | Current career-run total ≥ 15,000 |
| `one_long_line` | One long line — 3,000 | One banked combo ≥ 3,000 |
| `letters` | Letters round the square — 5 | Kind `letter`, unique IDs `H`, `A`, `W`, `K`, `S` in one run |
| `cone` | Cone duty — 1 | Kind `interaction`, ID `cone` |
| `platform_change` | Platform change — 1 | Kind `gap`, ID `central_gap` |
| `market_sweep` | Market sweep — 3 | Kind `market_item`, IDs `market_1`, `market_2`, `market_3` in one run |
| `across_toon` | Across the toon — 4 | Kind `district`, IDs `george_square`, `royal_exchange`, `central_station`, `barras` in one run |
| `lost_recording` | Lost recording — 1 | Kind `collectible`, ID `secret_recording` |

Each goal completes once per profile. Completion is independent of callback order: a score jump can complete multiple score tiers in definition order. Repeating an event cannot duplicate reward IDs.

`color_blue` is always available. `first_shift` adds `color_orange` and `special_clyde_carousel`; `some_shift` adds `color_purple`; `one_long_line` adds `special_tenement_tumble`. These IDs match the trick catalog's special IDs. This module supplies availability; root/player/UI apply the colour or special mechanic. No default movement or ordinary trick is locked.

## Settings and schema

Schema version **1** stores `version`, `completed_ids`, `best_score`, `best_combo` and `settings`. Every version-1 top-level field is required. Valid score values are finite nonnegative integers, and best combo cannot exceed best score. Goal IDs must be strings; unknown IDs are ignored and duplicates removed. Unknown root/settings keys are ignored safely. Missing known settings get defaults.

| Setting | Default | Accepted range/type |
|---|---:|---|
| `audio` | 0.8 | Master level; finite number clamped 0–1 |
| `sfx_volume` | 1.0 | Finite number clamped 0–1 |
| `ambience_volume` | 0.6 | Finite number clamped 0–1 |
| `captions` | true | Boolean only |
| `reduced_motion` | false | Boolean only |
| `ui_scale` | 1.0 | Finite number clamped 1–1.4 |
| `camera_sensitivity` | 1.0 | Finite number clamped 0.5–2 |
| `bindings` | `{}` | Validated per-action numeric key/button/signed-axis overrides |
| `cosmetic_id` | `color_blue` | Known colour ID; an unearned known selection falls back to blue |

`bindings` stores action dictionaries with `key`, or `button`, or `axis` plus `axis_value`; keyboard and controller slots can coexist. The pure schema check rejects unknown actions/fields, invalid numeric IDs, reserved keys, invalid axis directions and explicit duplicate assignments without constructing arbitrary resources or mutating InputMap. `InputProfile.apply_saved()` additionally checks the complete candidate against untouched default aliases and rejects conflicts atomically. Keyboard changes preserve the controller slot; controller changes preserve keyboard fallback. Built-in menu actions remain intact, Escape remains available, and remapped controller events match any device index. See `tests/input_profile_tests.gd` for the 27 focused input checks. Physical DualSense reconnect behavior remains unverified.

Known cosmetic IDs are `color_blue`, `color_orange` and `color_purple`. Orange requires `first_shift`, purple requires `some_shift`; a known but unearned saved selection becomes blue on load/save normalization. Unknown cosmetic names reject the profile. Main still guards selection against current unlocks.

Strings pretending to be numbers/booleans and nonfinite numbers reject the profile rather than executing/coercing arbitrary data. The reader caps files at 1 MiB. Explicit version **0** accepts `completed_goals`, `high_score`, optional `best_combo` and optional `settings`; it migrates to current fields/defaults in memory, and a later save writes version 1 while backing up the prior file. This is a documented supported prototype format, not a claim that an earlier game shipped it. Unversioned data is not guessed. Future versions return `ERR_UNAVAILABLE` and remain protected.

## Save and recovery behaviour

1. Validate and normalize the in-memory data. Invalid memory returns `ERR_INVALID_DATA` before touching files.
2. Inspect existing primary, `.bak`, `.tmp` and `.bak.tmp` for future versions. Any newer version locks writes, including a future backup beside an otherwise valid older primary.
3. Write and flush a same-directory `.tmp`, then reopen and validate it.
4. If the primary is valid, copy it to `.bak.tmp`, verify it and rename that candidate to `.bak`. A failed backup operation leaves the primary unchanged.
5. Atomically rename the verified `.tmp` to the primary path. A valid recovered backup is retained when the previous primary was corrupt.

A missing primary and backup returns `ERR_FILE_NOT_FOUND`, a normal first-profile state that allows an initial save. A corrupt or missing primary falls back to a valid `.bak`, returns `OK` and sets `last_load_used_backup = true`. A future primary does not fall back to an older backup. Unrecoverable primary/backup data locks writes until a successful explicit load after external repair, or an explicit `recover_profile` reset. A damaged backup can be replaced when a valid primary exists; the valid primary is the recoverable source. A newer backup is always protected.

Explicit reset archives original bytes using `.recovery-<timestamp>-<tick>` suffixes; it does not delete the evidence. If an archive step fails, no fresh profile is written. Old-version partial `.tmp` files never shadow a valid primary. A newer pending `.tmp` is protected from replacement.

The implementation uses same-directory rename and Godot flush, and was exercised on the Linux filesystem. It does not claim a power-loss/fsync-directory guarantee or multi-process merge semantics. Actual macOS filesystem paths, permissions and relaunch persistence remain target-hardware tests. The caller must display a load/save error, preserve the current files and avoid assuming backup recovery means the latest run survived.

## Evidence and remaining checks

`tests/progression_tests.gd` exposes `static run(check: Callable)`. It ran independently through the pinned Godot 4.6.3 headless executable: **60 assertions passed, 0 failed**. Fixtures are created under a unique `res://.local/progression-tests-<tick>/` directory and removed afterward; no default `user://career.json` was opened.

Coverage includes all ten goals, threshold boundaries, duplicate/unknown events, per-run resets, free-skate gating, immutable snapshots, derived rewards, repeated finish, score normalization, save round trips, three-generation backup rotation, corrupt/missing-primary fallback, interrupted writes, version-zero migration, future-version protection for primary/backup/temp, malformed schema/types, excessive file size, explicit archive-and-reset, failed parent/backup writes, invalid in-memory settings, saved binding overrides, explicit duplicate binding rejection and earned/unearned cosmetic selection. Independent QE identified the future-backup overwrite risk; the corrected preflight and its regressions are included.

This suite is integrated into `tests/run_tests.gd`; root owns complete `tools/check.sh` results in STATUS. Independent `tests/career_integration_tests.gd` adds 23 passing checks for actual mapped letter/cone interactions, a push-driven Central platform gap, free-skate isolation and gated special execution/charging/reset. That scene suite keeps persistence disabled. Completing every goal through ordinary play, all-screen UI/colour review, target-Mac relaunch and balance/fun acceptance still need their separate evidence. Model and Linux integration tests do not close those human/hardware gates.
