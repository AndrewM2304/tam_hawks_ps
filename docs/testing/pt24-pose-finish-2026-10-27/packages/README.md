# Current unsigned rider/menu trial builds — 27 October 2026

Exported from clean source **`8d16c39a3850f22b281531d1a732bb5baa8fa54f`**
using Godot4.6.3. Normal Main includes all merged trial content and these Pogo,
wall-to-Ollie, controller-menu and fountain fixes. No launch flag is required.

Local directory: `builds/tam-hawks-20261027T161529Z-8d16c39a3850/`.

| Artifact | Bytes | SHA256 |
| --- | ---: | --- |
| `TamHawksProSkater-linux.zip` |36,383,356 |`0bb468b1454e38a17930921296093345a6994c9c2cfe50da02da43bd00ce3ed2` |
| `TamHawksProSkater-macos.zip` |70,942,960 |`1458bfd3200fb5e24bf7ea94fe66b941cf98453bb94205b8ae5a5e32f3b1ca73` |

Command: `./tools/export.sh --skip-check`. The immediately preceding required
suite passes **5,220/0 plus Music guard2/0**, clean/stable627 inputs. Export reuses
that admitted source; [metadata](BUILD-METADATA.json) correctly records
`checks_run_by_export_script:false`. Official4.6.3 templates and notices are
checksum pinned. Native pack inspection loads Main/scripts,3voices,4textures
and4anatomical meshes for both platform resource packs.

[Archive audit](ARCHIVE-AUDIT.json) verifies627required and260package inputs,
250overlapping, **637 unique committed blobs**. Memberships and hashes match the
checkout and clean source commit. ZIP CRC, paths, executable modes,13notices,
Linuxx86_64 and Macarm64+x86_64 pass. Both platform packs are byte-identical,
SHA256`826436393929d8c5e5c78c66a72c64d673467d422fb65ce9bb40b30527009d32`.
Raw required receipts/maps/logs, metadata, export/resource logs and sums remain
alongside this record.

```sh
python3 docs/testing/pt24-next-2026-10-25/packages/observers/archive_audit.py --build builds/tam-hawks-20261027T161529Z-8d16c39a3850 --receipt docs/testing/pt24-pose-finish-2026-10-27/validation/combined/receipt.json --source-before docs/testing/pt24-pose-finish-2026-10-27/validation/combined/source-before.json --source-after docs/testing/pt24-pose-finish-2026-10-27/validation/combined/source-after.json --output docs/testing/pt24-pose-finish-2026-10-27/packages
python3 docs/testing/native-performance/smoke_capture.py builds/tam-hawks-20261027T161529Z-8d16c39a3850
```

[Standalone smoke](SMOKE-RESULTS.json) passes the unmodified Linux binary both
headless and rendered from an empty working directory with isolated profiles.
The actual[1920×1080 title](title-live.png), OCR and logs show normal startup;
there is no script/scene override, injected input or fixed clock. This55.503s
startup check is not gameplay or performance acceptance.

Signing and notarization are disabled. Mac Automation usage configuration is
present, but effective entitlement, cryptographic template signatures, TCC,
actual playback and Mac execution are not verified by these Linux checks.
Physical controls, Mac saves/audio/performance and human acceptance remain open.
No release, upload, hosted CI, signing, notarization or spending occurred; ZIPs
remain local ignored outputs. Fully quit/relaunch source play, or replace the
older app completely. Restart Run inside an older running app cannot load new code.
