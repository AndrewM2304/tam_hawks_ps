# Current-source local packages

Unsigned packages export from clean main commit `08046020d80e84c458840a1117da4dd1c37e4382` after
the required **4,852/0** and four-phase cold-source pass. [Archive audit](ARCHIVE-AUDIT.json),
[build metadata](BUILD-METADATA.json), [source receipt](../validation/final/receipt.json)
and [checksums](SHA256SUMS.txt) bind the source and completed ZIPs.

All **572 required-tested inputs** remain identical. All **258 package inputs**
match both the checkout and that commit's Git objects; **248** overlap the required
suite's manifest. Both platforms have byte-identical data packs. CRC, executable
modes, Mac **arm64+x86_64** slices, thirteen notice/provenance records and imported
main/scripts, three voice streams, four textures and four human meshes pass.
Official Godot4.6.3 templates/notices retain the export script's pinned checksums.

| Archive | Bytes | SHA-256 |
| --- | ---: | --- |
| TamHawksProSkater-linux.zip | 36,327,950 | `611a24895f9a0b64e39a72da4774244217f4abea0edf41583129080cdf49b68e` |
| TamHawksProSkater-macos.zip | 70,887,485 | `b5e73be97cf5ed32bdcf7a1a8881c324aeedafbc9614c592e24bd85259876123` |

Local build directory: `builds/tam-hawks-20261025T131553Z-08046020d80e/`. ZIPs stay in ignored builds;
no release, upload, signing, notarization or hosted CI was performed.

The actual Linux executable boots headlessly and rendered from an empty working
directory with isolated profiles. [Native smoke](standalone/SMOKE-RESULTS.json)
and the [1920×1080 title image](standalone/title-live.png) confirm the normal
menu, with no injected input, script override or fixed clock. The explicit
[design-preview startup](standalone/PREVIEW-SMOKE.json) also exits zero with a
clean log. These are startup checks, not played gameplay or timing benchmarks.
The Mac resource pack was inspected by Linux Godot; **the Mac binary has not
been executed**. Physical DualSense, Mac save/audio/play, performance, moving
shadow and final art/fun acceptance remain open.

Repeat on a clean, required-tested source checkpoint:

```sh
./tools/export.sh --skip-check
python3 docs/testing/pt24-continuation-2026-10-25/packages/observers/archive_audit.py <build-directory>
python3 docs/testing/native-performance/smoke_capture.py <build-directory>
```

`--skip-check` reuses the just-passed, unchanged required source, whose hashes
are checked independently. It does not relabel the metadata's
`checks_run_by_export_script: false` as a test execution. The guide and complete
third-party notices are included in each ZIP. Source preview remains
`./tools/run.sh -- --pt24-design-preview`; default rendering admission is unchanged.
