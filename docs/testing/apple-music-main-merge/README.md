# Soundtrack merge onto main — 25 October 2026

Integrates soundtrack commit `02065ae` with main `c046497`, retaining all newer PT24, skating, graphics/HUD, recorder, source and acceptance work. Production integration is additive: 28 lines in Main, 193 in HUD and six runner lines against that main baseline. No skating/world code or graphics setting was removed or retuned.

**Combined full check: 4,910 passed / 0 failed**, exit0, clean log, **583 unchanged inputs**, 546.339 seconds. Includes 58 soundtrack assertions: 29 backend,22 UI,7 Main integration. Command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/soundtrack-main-merge ./tools/check.sh
```

[Receipt](validation/receipt.json), [full log](validation/console.log), [before](validation/source-before.json) and [after](validation/source-after.json) bind the exact merged input. Manifest SHA256 `a86b0151434b4f69992ef6758adf0416180709350840c29f8b39b0ef11ca4538`. The observer records parent `c046497` as HEAD because validation preceded the merge commit; its source hashes identify the merged working tree.

**Merged HUD: five real rendered fixture frames / zero failures**, both1920×1080 and960×600 at1.4× UI, same583 unchanged inputs/manifest. Command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/soundtrack-main-ui ./tools/music_ui_capture.sh
```

[UI receipt](ui/receipt.json), [log](ui/console.log), [before](ui/source-before.json), [after](ui/source-after.json) and [images/manifest](../screenshots/apple-music/README.md). Linux Compatibility/llvmpipe output shows the real merged menu with fictional track/artwork; no Apple account, actual playback, Mac GPU or frame-time claim.

Main caches the soundtrack snapshot on Music change events or player replacement. HUD retains unchanged nested data and updates music controls only on changed metadata/page construction. Tests cover no repeated playlist snapshot copy across unchanged paused frames and immediate changed-event presentation. Menu widgets are constructed on page opening; artwork is bounded to512px, one worker/four pending commands/two-second polls remain bounded. No extra 3D geometry, physics body, shader or skating-time artwork draw is introduced. Existing stutter/target-hardware acceptance remains open.

Actual Mac Music/Automation/shuffle/stream metadata/artwork/controller acceptance remains pending. Existing native packages predate this merged soundtrack and were not rebuilt. Continue on main; no hosted CI, release, paid service or unattended continuation was used.
