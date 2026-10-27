# Current unsigned trial packages — 27 October 2026

Exported from clean source commit **`2f2e22c1a0e321244e0f700e708b547af853be84`**
with Godot 4.6.3. Normal Main includes the station/train, pond, green and civic
return without flags, plus the current wall fit and downhill guide.

Local build directory:
`builds/tam-hawks-20261027T091718Z-2f2e22c1a0e3/`.

| Artifact | Bytes | SHA256 |
| --- | ---: | --- |
| `TamHawksProSkater-linux.zip` | 36,379,474 | `3ad5d0f8e56a6a60b1b394233118f9d22a3c203d0df81aa0a4f06cb004dfd47c` |
| `TamHawksProSkater-macos.zip` | 70,939,078 | `4cc0afd8e65f14d716ddade3d43641e1fc0246f968df6cb5503f4f0be4d85414` |

Command: `./tools/export.sh --skip-check`. The immediately preceding required
check passes 5,100/0 plus Music guard 2/0 on 609 stable inputs; this avoids repeating
unchanged checks. [Build metadata](BUILD-METADATA.json) truthfully records
`checks_run_by_export_script:false`. Official templates/notices are checksum
pinned. Both packs load Main/scripts, three voices, four material textures and
four anatomical meshes through the native resource inspector.

[Archive audit](ARCHIVE-AUDIT.json) passes all 609 required-suite and 260 package
inputs, 250 overlapping, 619 unique committed blobs. Every membership/hash agrees
with the checkout and source commit. ZIP CRC/paths/executable modes, 13 notices,
Linux x86_64 and Mac arm64+x86_64 pass. Both platform data packs are byte-identical,
SHA256 `ca8c718c7341a8d2517fe733c72a73620f9a66bdf20c0bbd9d8b1df039406c63`.
The exact required receipt/maps/console are preserved alongside the metadata.

```sh
python3 docs/testing/pt24-next-2026-10-25/packages/observers/archive_audit.py --build builds/tam-hawks-20261027T091718Z-2f2e22c1a0e3 --receipt docs/testing/pt24-park-2026-10-27/validation/combined/receipt.json --source-before docs/testing/pt24-park-2026-10-27/validation/combined/source-before.json --source-after docs/testing/pt24-park-2026-10-27/validation/combined/source-after.json --output docs/testing/pt24-park-2026-10-27/packages
python3 docs/testing/native-performance/smoke_capture.py builds/tam-hawks-20261027T091718Z-2f2e22c1a0e3
```

[Standalone smoke](SMOKE-RESULTS.json) passes the actual unmodified Linux binary
headless and rendered, from an empty working directory with isolated profiles.
The real 1920×1080 [title readback](title-live.png) and OCR show the normal menu.
No scene/script override, injected input or fixed clock is used in this startup
check. Its screenshot is startup evidence, not a gameplay/performance run.

Mac signing/notarization remain disabled. The package declares Music usage and
Apple Events configuration; effective Automation entitlement, consent and Music
playback are not verified on Linux. Actual Mac binary execution, physical
controls, saves/audio, target performance and human acceptance remain open.
No hosted CI, release, asset upload, signing, notarization or spending occurred.
ZIPs remain ignored local outputs. Pull/relaunch current main or replace the old
app; restarting a run inside an older running app cannot load the new source.
