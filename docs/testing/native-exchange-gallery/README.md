# Exchange/gallery: native package receipts

These receipts cover clean runtime **`00da63a29990c0839cf15d4c9a34edc2fc167122`**, exported locally on 17 October 2026 after the gallery entrance and west seating pass. They verify archives, source identity, constructed resources and bounded Linux startup. The prior [Barras/Clyde receipts](../native-barras-clyde/README.md) remain historical.

## Audited build

Build: `builds/tam-hawks-20261017T185223Z-00da63a29990/`.

| Archive | Bytes | SHA-256 |
|---|---:|---|
| `TamHawksProSkater-linux.zip` | 32,105,526 | `900689e0aff5035288118255913b26ac3185f215293fdab6a7ae015694c78cd1` |
| `TamHawksProSkater-macos.zip` | 66,665,060 | `ac4ad7cb4f7b9a7c1e653a3783e7dfd93bb262285c1cf27a3ac535f9d1fd3d1a` |

[BUILD-METADATA.json](BUILD-METADATA.json) records a clean checkout and **121** package inputs. Every input matches the named Git object and current checkout, and remained unchanged during the audit. Runtime fingerprint: `26b9606113ff7fa97319ff5650f519664ab5db81b8a5fbc26d653165bda31cef`. Metadata SHA-256: `c1b0f49bf5cbd1698ea7d37ce9553628b5f4c227da5b64524aea2fa839d3094d`.

[ARCHIVE-AUDIT.json](ARCHIVE-AUDIT.json), SHA-256 `45e5fa7e05cf1ac7f4eb24d8a55920bfb497392f854996362fe1ab3bddbbddf8`, records complete ZIP CRC, unique/safe paths, member bytes, archive/unpacked mode parity, metadata, source and provenance checks. Linux has 18 files, macOS 22. Executables retain `0755` permissions; Linux is ELF64 x86_64, while macOS contains x86_64 and arm64 Mach-O slices. Their bytes match the previously verified official Godot 4.6.3 templates. All **13** notices/provenance records in each archive match their reviewed sources, including generated voice, texture and human-mesh outputs, import settings and licences.

Both archives contain the same inspected data pack, SHA-256 `6447f96516e715e1d4881e934175c137f28dcc7283895e611b1b51e4b38b76cc`. The retained [Linux](linux-resources.json) and [macOS](macos-resources.json) export-resource reports verify main scene/script loading, three voice WAVs, four 1024×1024 textures with ten mipmap levels and four anatomical meshes. Exact resource/export logs accompany them.

## Current additions actually constructed

The independent [pack probe](pack_probe.gd) adds the ordinary main scene to the tree, running its construction code. Source, Linux-PCK and macOS-PCK reports match exactly. The new `game/levels/art/exchange_gallery.gd` loads in each case, and the probe finds:

- `ExchangeGalleryArchitecture`, the gallery terrace, side/front banks and threshold, and the west shop terrace/bank/corner geometry.
- Eight `GalleryPorticoColumn` bodies at the shared authored positions, each with base, shaft and capital collision shapes; bases are at approximately Y2.65.
- **44** route definitions, including `gallery_entrance_bank_loop`, `gallery_entrance_front_return`, `gallery_entrance_bypass`, `exchange_west_bank_loop` and `exchange_west_bypass`.
- Both `Grind_Ledge_GalleryEntrance` and `Grind_Ledge_ExchangeShops`.

It also checks the retained Barrowland, Barras, Clyde, Mairi, gull, delivery counter and hidden torso-attached courier bag, the two market delivery choices and six checkpoints. These are construction checks; they do not independently replay the new physical lines or assess the art.

See [source-district-resources.json](source-district-resources.json), [linux-district-resources.json](linux-district-resources.json), [macos-district-resources.json](macos-district-resources.json) and their logs. All three probes exit 0 with clean engine/script/resource logs. Platform probes run from an empty project with `--main-pack`, preventing fallback to checkout assets. The Linux engine reads the macOS data pack; it does **not** launch the macOS executable.

The retained original eight-second bin percussion remains identical in all three probes: cached mono PCM16, 22,050 Hz, 352,800 bytes, forward loop 0–176,400; PCM SHA-256 `0965cbed26ca6c6ef81360c1567ecf2da0c2c20e4f57b69ba0fbbef49b66b7b9`. Dummy audio and sample checks do not establish audible playback.

## Current capture and test identity

The corrected [22-image capture manifest](../screenshots/exchange-gallery/manifest.json), SHA-256 `8c6122729aad2fda9c7c609fb6c53dda36accec62c41e3cef0571f7484b9e39e`, has **164** source/test/tool hashes. All **110** inputs shared with the package match exactly. Every image hash, PNG chunk CRC, 1280×800 header and decompressed scanline structure passes. The audit records each image hash/size. This binds the accepted pre-commit capture to the clean package; it does not replace the visual review or certify performance. The superseded first capture remains in its separate diagnostics folder.

The [ordinary-suite source receipt](../logs/exchange-gallery-source.json), SHA-256 `cb0dbf69a948805b3c336673d089c6056063e5be270abbebc7cb157efe36bb1b`, records **1,155 passed / 0 failed**, exit 0, 162 unchanged inputs and clean engine/script scans. All **110** package overlaps match. Its gameplay log SHA-256 is `0313be0238a3288f4f75ce4f94e3afb85020ec4d201051c817eb53552076399a`. The independent native auditor checked source identity; it did not repeat that suite.

## Normal Linux startup

The integration agent separately ran the actual exported executable through:

```bash
./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T185223Z-00da63a29990
```

Both the **120-frame headless** and **1920×1080 / 30-frame rendered** normal-main launches naturally exited 0, with isolated profile directories and no engine/script/resource errors. [headless.log](headless.log), [rendered.log](rendered.log) and [smoke-summary.log](smoke-summary.log) are exact copies. The Xorg configuration and logs are also retained. Mesa llvmpipe and Dummy audio were used; the sole graphical warning concerns unsupported V-Sync on the software display. The integration agent stopped and waited for owned game/display processes. The independent auditor did not repeat these native launches.

## Reproduce the independent audit

Use the exact build and matching source/evidence, Python 3, Git and installed Godot `4.6.3.stable.official.7d41c59c4`. No download, export, graphical display or paid service is required.

```bash
cd /workspace/tam_hawks_ps
python3 docs/testing/native-exchange-gallery/audit.py \
  builds/tam-hawks-20261017T185223Z-00da63a29990 \
  --receipt-dir /tmp/tam-hawks-exchange-gallery-audit \
  --evidence docs/testing/screenshots/exchange-gallery/manifest.json \
  --evidence docs/testing/logs/exchange-gallery-source.json
```

The [helper](audit.py) adapts the final Barras/Clyde audit, writes supplemental probes under the ignored build directory and receipts only to the requested output. [audit.log](audit.log) records its successful invocation. It uses writable isolated XDG directories, including for the engine-version query; no cache diagnostic or harness rerun occurred in this checkpoint. The audit records the helper/probe hashes.

Earlier video/profile receipts are historical and do not certify this changed scene. No Mac launch, signing/notarization, physical DualSense use, listening, moving-route frame rate, human discovery/fun or final realistic-art acceptance is claimed. No artifact was publicly released and no paid service was used.
