# Private per-level career book — native proposal

**Private source only. No game/runtime or ordinary profile files are changed.**
The world/progress integration engineer authors metadata-only `level_catalog.gd`
and `level_career_book.gd` under `.local/world-integration/proposal/`. A code-only
private Godot project uses its own XDG/user-data directory. Native tests pass
**56/0**, with clean parser/runtime logs, exit 0 and all 14 source inputs unchanged.
No Main, world, HUD, audio or Apple Music object is constructed by this cohort.

The successful run is 11:34:13.232–11:34:14.167 UTC, within the separately approved
45-second aggregate bound. Parser PID 126462 and native PID 126475 both stop before
the explicit release. A first run printed 48/0/exit 0 but is **rejected**: two
fixture methods aborted on untyped Array literal assignments to `Array[String]`
fields, skipping legacy parity/roundtrip cases. Its exact logs, partial result and
executed source are retained under `rejected-first-fixture`. The corrected fixture
uses the same typed saved-array assignment contract as existing legacy callers;
the wrapper now rejects script errors regardless of process exit/result text.

## Runtime interface

`LevelCatalog` contains no world imports. `definition(id)` returns copied metadata
`{id,label,description,world_path,world_script,career}`; `career(id)` and `ids()`
return copies. `DEFAULT_LEVEL` is `merchant_neighbourhood_v1` / Merchant District;
`LEGACY_LEVEL` is `glasgow_legacy_v1` / City Tour. Root/LD use the same canonical
career dictionary rather than duplicate runtime goal tables. World paths are
strings for root's lazy selection.

`LevelCareerBook` exposes writable `completed_ids: Array[String]`, `best_score`,
`best_combo`, `settings: Dictionary`, `last_error`, `last_load_used_backup`,
`last_load_migrated_legacy` and `selected_level_id`. Its facade methods are:

- `configure_level(career: Dictionary) -> bool`, checking canonical metadata.
- `select_level(id) -> bool`, stashing the active public fields, closing all run
  state, restoring the selected domain and invalidating presentation even for
  empty-to-empty selection.
- Existing `begin_run`, `record_score`, `record_event`, `finish_run`,
  `goals_snapshot`, `unlocks`, `presentation_revision` semantics.
- `load_profile(path = "user://career-v2.json", legacy_path = "user://career.json")`;
  an empty explicit legacy path disables migration for isolated consumers.
- `save_profile(path)` and explicit user-selected `recover_profile(path)`.
- `_profile_data()` retains the active City Tour v1 view used by existing graphics
  fixtures; real persistence uses separate `_book_data()` version 2.

The constructor only allocates in-memory records/Base and registers protected
path strings through `ProjectSettings.globalize_path`. It never opens, reads,
hashes or writes any profile and never starts Music. The native constructor test
poisons both default files inside isolated user data, verifies no application or
scene/file changes, then exercises an explicit no-migration custom-path flow.

City Tour run operations delegate the existing unchanged `CareerProgress`.
Merchant uses the exact schema-1 ten-goal metadata and namespaced accepted events.
Native full-run parity tests compare City Tour against the existing class; both
domains' records remain independent through selection/save/reload. Settings and
earned cosmetics/specials are global. Genuine Merchant rewards are validated using
temporary internal reward witnesses in the existing settings validator; those
synthetic old goal IDs are discarded and never stored in City Tour records.

## Version 2 and preservation

```json
{
  "version": 2,
  "levels": {
    "merchant_neighbourhood_v1": {"completed_ids": [], "best_score": 0, "best_combo": 0},
    "glasgow_legacy_v1": {"completed_ids": [], "best_score": 0, "best_combo": 0}
  },
  "settings": {"audio": 0.8, "cosmetic_id": "color_blue"}
}
```

The settings example is abbreviated; all existing validated defaults/bindings are
retained. Both level records are required; unknown levels/newer versions reject
without replacement. Score/record fields must be finite whole numbers in the
existing range, combo cannot exceed score, goal IDs must belong to their domain
and duplicates reject. The book retains the existing 1 MiB input bound and settings
validator. It never stores per-run unfinished collections or chooses a world from
the profile: caller-selected level survives load.

Only when **all four new-book primary/backup/temp/backup-temp slots are absent**
does explicit load read validated v0/v1 legacy data via existing CareerProgress.
It copies those records into City Tour and globals into memory, never modifying
any legacy source/backup/temp. A new save writes only the separate v2 path.
Default and explicitly supplied legacy paths are protected from book save/reset.

A newer version in any new-book slot blocks load/save. A valid backup may populate
memory, but a corrupt primary remains protected against autosave. A valid primary
with corrupt backup/temp remains readable while saving is blocked. Existing
temporary candidates, including valid interrupted candidates, are preserved.
An orphan valid backup can be loaded and then create a primary without rotating
that backup. Explicit selected recovery archives all known slots before resetting.
Healthy saves write/read-verify a temp, verify/rotate a healthy primary backup and
rename the candidate. Stored file signatures reject stale writer replacement;
this is optimistic protection, not an inter-process lock protocol.

## Meaningful native coverage and limits

The 56 checks cover both complete goal domains, exact legacy delegation, wrong/
duplicate/late/free-skate event refusal, writable field restoration, v0/v1
memory-only migration and source-byte preservation, global earned cosmetics,
save/reload/backup rotation, selected-level retention, future data in all four
slots, corrupt sibling preservation, backup recovery, interrupted-only fallback
refusal, explicit archival recovery, stale writer refusal, invalid/cross-domain/
duplicate/fractional/out-of-range records, bindings and oversized files.

`preservation.json` binds 24 retained files, including exact executed source and
the rejected first epoch. Independent QA review, further adversarial file-system
checks and root's ordinary title/pause/level selection integration remain pending.
Pure profile tests do not prove one selected live world, reset physical contacts,
explicit activities, new-map playability, fun, final visuals or M5 performance.
