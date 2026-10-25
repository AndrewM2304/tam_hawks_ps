# Current-source local packages

Unsigned packages export from clean main source commit`d2b4ae28ac43aa56f03f0216fb40f245273d47fb` after the
required **5,037/0**, actual short-script Music guard2/0, four cold-source phases
and44 native frames. [Archive audit](ARCHIVE-AUDIT.json),
[build metadata](BUILD-METADATA.json), [required receipt](../validation/final/receipt.json)
and [checksums](SHA256SUMS.txt) bind the exact source and completed ZIPs.

All **597 required inputs** still match. All **260 package inputs** match the
checkout and commit objects;250 overlap the required suite, for607 unique
committed input blobs verified. Both platforms have byte-identical data packs.
ZIP CRC/safe paths, executable modes, Mac **arm64+x86_64** slices, all13 notices
and provenance records, Main/scripts,3 voice streams,4 textures and4 human meshes
pass. Official Godot4.6.3 templates/notices retain their pinned checksums.

| Archive | Bytes | SHA256 |
| --- | ---: | --- |
| TamHawksProSkater-linux.zip | 36,376,048 | `ba8910a90054d6ebd3391e7e0f8131551c0a40deceb3c0072d7ebaf5c9f43d1c` |
| TamHawksProSkater-macos.zip | 70,935,653 | `b6e8517dfdaec2376b912ea77ed15506b14556131c3df9ed2f75bc7b22997ba2` |

Local directory:`builds/tam-hawks-20261025T165900Z-d2b4ae28ac43/`. ZIPs stay in
ignored builds; no release/upload/hosting/signing/notarization was performed.
`--skip-check` reuses the just-passed unchanged source; metadata truthfully records
`checks_run_by_export_script:false`. The independent audit binds the prior
required receipt rather than claiming export reran it.

The actual Mac archive's Info.plist contains:
“Control Music to play your chosen soundtrack and show the current song.”
Source config enables the Apple Events entitlement declaration, with export
signing/notarization disabled. Embedded template signature structures contain no
XML entitlement; Linux has not verified cryptographic signature validity or an
effective Automation entitlement/TCC consent. This metadata is not Music playback
or Mac execution acceptance. No real account was connected by these checks.

The actual Linux executable boots headlessly and rendered from an empty working
directory with isolated XDG profiles. [Native receipt](standalone/SMOKE-RESULTS.json)
and the [1920×1080 title frame](standalone/title-live.png) show the real menu,
including Soundtrack. There is no script override, injected input or fixed clock.
The separate [preview argument launch](standalone/PREVIEW-SMOKE.json) exits0 with
a clean log from another empty directory/profile. These are bounded startup
checks, not played gameplay or timing measurements. The Mac pack was loaded by
Linux Godot; **the Mac executable has not run**.

Repeat on a clean, required-tested source checkpoint:

```sh
./tools/export.sh --skip-check
python3 docs/testing/pt24-next-2026-10-25/packages/observers/archive_audit.py \
  --build <build-directory> \
  --receipt docs/testing/pt24-next-2026-10-25/validation/final/receipt.json \
  --source-before docs/testing/pt24-next-2026-10-25/validation/final/source-before.json \
  --source-after docs/testing/pt24-next-2026-10-25/validation/final/source-after.json \
  --output docs/testing/pt24-next-2026-10-25/packages
python3 docs/testing/native-performance/smoke_capture.py <build-directory>
```

Actual Mac/DualSense/save/audio/Music playback/consent, target performance/moving
shadows and human art/fun remain open. Railway/train, pond, green and civic return
retain the explicit `--pt24-design-preview` rendering-admission gate.
