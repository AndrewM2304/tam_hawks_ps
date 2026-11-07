---
name: world-integration
description: Integrate separately loaded skating worlds, explicit activity layouts and safe per-level progress while retaining global settings, unlocks and personal Music isolation.
---

# World and progress integration

Use for the original Merchant District replacement and preserved City Tour, or
future level additions. Read the active plan and current Main/CareerProgress,
HUD, FeatureHub and persistence tests. Audit actual public methods before adding
an interface; do not build a second movement, score or Music system.

## Contracts

- Default `merchant_neighbourhood_v1`, label `Merchant District`; optional
  `glasgow_legacy_v1`, label `City Tour`. Load and instantiate only the selected
  world. An idle hidden old city is still a live world and is not lazy selection.
- Preserve existing world query signatures. New worlds expose a level manifest
  and explicit activity layout; absent optional activities must not create old
  coordinate-based actors, routes or colliders.
- Root owns Main/HUD integration; the designer owns geometry/manifest. Agree
  identities, accepted goal event IDs, spawn/height behaviour and API before edits.

## Progress and settings

- Existing `user://career.json` version0/1 data belongs to City Tour. Preserve
  that source file and its backups when adopting a new versioned career book.
  A missing new book may migrate the validated old profile once. A damaged or
  newer new book must never silently fall back and overwrite newer progress.
- Separate each level's completed goals, best score and best combo. New default
  goal IDs are namespaced. Old completion IDs must not mark new goals complete.
- Settings, control bindings, cosmetics and earned special unlocks are global.
  Derive unlocks from genuine achievements across domains; do not insert fake
  completed City Tour goals to grant a reward earned in the new level.
- Reuse the existing settings validator and defensive atomic-save pattern where
  practical. Bound file size, reject nonfinite/fractional/out-of-range numbers,
  validate goal/event identities and required fields, and preserve unknown newer
  versions. Check primary, backup and temporary files before replacement. Never
  overwrite unreadable player data without explicit user-selected recovery.
- Scripted launches keep persistence disabled by default. Migration/load/save
  must not start Apple Music, read another person's account, or write profile
  data in tests outside isolated `user://` paths.

## Verification

Test real transitions: old profile migration without source changes, independent
level goals/records, global unlock and cosmetic retention, save/reload, invalid
and future-version refusal, primary/backup recovery and malformed event rejection.
Use temporary isolated profiles and actual native Godot. Do not create dozens of
assertions that merely mirror getters or turn source inspection into a native
acceptance claim. Preserve failed runs, exact source pins and actual stderr.

Ordinary title/pause selection needs keyboard/controller navigation, cancellation,
one selected live world, a reset score chain and no stale contacts/activities.
Root's combined gate owns those behaviours; pure persistence tests cannot pass
them. Full existing City Tour regressions stay explicitly scoped to that world;
the new default receives its own real-play checks rather than false old-map passes.

## Handoff

Provide exact changed files/preimages, public API, versioned schema, migration
policy, native results, failure cases and remaining integration/hardware gates.
Keep work on main under root's shared-file ownership and non-force Git policy.
