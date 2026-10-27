# Current unsigned connection trial builds — 27 October 2026

Exported from clean source **`ba187f32c2c5f2a802dc350f5df1b4b89d4d6b00`**
with Godot 4.6.3. Normal Main includes all merged features without a flag,
the corrected bank queries and the Kelvingrove practice identity. The player
guide describes the market, civic/park and facility connections.

Local directory: `builds/tam-hawks-20261027T144844Z-ba187f32c2c5/`.

| Artifact | Bytes | SHA256 |
| --- | ---: | --- |
| `TamHawksProSkater-linux.zip` | 36,380,040 | `dc13ce4c2285dd9f5d16c0ec18a96ae9172a6a943518a8db75eda8a3f0847558` |
| `TamHawksProSkater-macos.zip` | 70,939,644 | `e5323135605335f39046535aa106b3c41472b41fd948ed9ad704dbcc65b7dc40` |

Command: `./tools/export.sh --skip-check`. The immediately preceding required
suite passes **5,151/0 plus Music guard 2/0 on 617 stable inputs**. Export does not
repeat unchanged checks; [metadata](BUILD-METADATA.json) truthfully records
`checks_run_by_export_script:false`. Official 4.6.3 templates and notices remain
checksum pinned. Native pack inspection loads Main/scripts, three voices, four
textures and four anatomical meshes for both platforms.

[Archive audit](ARCHIVE-AUDIT.json) passes all 617 required and 260 package inputs,
250 overlapping, 627 unique committed blobs. Memberships and hashes match the
checkout and clean source commit. ZIP CRC, safe paths, executable modes, 13
notices, Linux x86_64 and Mac arm64+x86_64 pass. Platform data packs are identical,
SHA256 `00e4c50e9d9ec1c66471945e0ee075f1857a5201f0e14954d7d97778d94f1d83`.
Exact required receipts/maps/console are preserved alongside the metadata.

```sh
python3 docs/testing/pt24-next-2026-10-25/packages/observers/archive_audit.py --build builds/tam-hawks-20261027T144844Z-ba187f32c2c5 --receipt docs/testing/pt24-connections-2026-10-27/validation/combined/receipt.json --source-before docs/testing/pt24-connections-2026-10-27/validation/combined/source-before.json --source-after docs/testing/pt24-connections-2026-10-27/validation/combined/source-after.json --output docs/testing/pt24-connections-2026-10-27/packages
python3 docs/testing/native-performance/smoke_capture.py builds/tam-hawks-20261027T144844Z-ba187f32c2c5
```

[Standalone smoke](SMOKE-RESULTS.json) passes the actual unmodified Linux binary
headless and rendered from an empty working directory, with isolated profiles.
The [real 1920×1080 title](title-live.png) and OCR show the normal menu. No script,
scene override, injected input or fixed clock is used for this startup proof.
It is not a gameplay or target frame-time benchmark.

Signing/notarization are disabled. Mac Music usage/Apple Events configuration is
present, but effective Automation entitlement, TCC consent and personal playback
are not verified on Linux. Actual Mac execution, physical controls, Mac saves,
audio, target performance and human acceptance remain open. No release, asset
upload, hosted CI, signing, notarization or spending occurred. ZIPs remain local
ignored outputs. Fully quit/relaunch after pulling, or replace an older app;
Restart Run inside the old running app cannot load the new source.
