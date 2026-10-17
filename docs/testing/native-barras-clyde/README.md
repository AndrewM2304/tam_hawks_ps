# Barras market and Clyde: native package receipts

These receipts cover clean runtime **`2a7d20c51559907b0ca30a995d842dcc683ff320`**, exported locally on 17 October 2026. They verify package integrity, source identity, resource construction and bounded Linux startup. They do not establish Mac launch, target hardware performance or human acceptance.

## Audited build

Build directory: `builds/tam-hawks-20261017T180149Z-2a7d20c51559/`.

| Archive | Bytes | SHA-256 |
|---|---:|---|
| `TamHawksProSkater-linux.zip` | 32,099,727 | `500aa3642251d14ea6027f94c401396f2bc02613e107e034c4338788dd0b5348` |
| `TamHawksProSkater-macos.zip` | 66,659,261 | `46b28b9381df63ff8c2b372cf7fbc7a45fb43cc6185ec84d3210d4c07f3d7fd4` |

[BUILD-METADATA.json](BUILD-METADATA.json) records a clean tree and **119** package inputs. Every input matches both the named Git object and the checkout; all inputs remained unchanged during the independent audit. Runtime fingerprint: `037f91d3a3b98991ed8f3668588927c8702f9049b44a5bd3e4cb5f5456568c3b`. Metadata SHA-256: `7d297e87ab373e110bcc3da91f6cb7d40c5c0e632f1b846e4865af0ec44afd8c`.

[ARCHIVE-AUDIT.json](ARCHIVE-AUDIT.json), SHA-256 `ae297799a5024d074d6acaaa4e0d57faaa0f03d244d54613749bf1fe4d8745a0`, records complete ZIP CRC, unique/safe paths, member byte equality, archive/unpacked mode parity, embedded metadata and notices. Linux contains 18 files and macOS 22. Executables have mode `0755`; Linux is ELF64 x86_64 and macOS is universal Mach-O x86_64 + arm64. Binary bytes match the previously verified official Godot 4.6.3 release templates. All **13** notice/provenance records in each archive match their sources, including human meshes, textures, generated voice and Godot notices. Source licence/output/import hashes were checked.

Both archives contain the same inspected PCK, SHA-256 `a4f5dacae4dd597ec0d384073e488e22269e3e088761023c9354bfd40177bf08`. [linux-resources.json](linux-resources.json) and [macos-resources.json](macos-resources.json), with their retained logs, verify main scene/script loading, three voice streams, four 1024×1024 textures with ten mipmap levels and four anatomical meshes. The export logs are retained separately.

## New district content actually constructed

The independent [pack probe](pack_probe.gd) loads and adds the ordinary main scene to the tree, so its `_ready()` constructs the world and actors. It checks these four new script resources:

- `game/characters/market_encounter.gd`
- `game/characters/market_actor.gd`
- `game/levels/art/barras_market.gd`
- `game/levels/art/clyde_landmarks.gd`

The source, Linux-PCK and macOS-PCK reports are identical. Each contains the constructed `BarrasCoveredMarket`, `BarrowlandLandmark`, `ClydeLandmarks`, `MarketStallholder`, `DeliveryCounter`, `MarketGull` and `CourierBag` with actual geometry descendants. It verifies the idle Gull-Proof Delivery encounter, required `market_hop` gap, `covered`/`west` route choices, six checkpoints and a hidden bag attached under the rider's `TorsoRig`. The retained original eight-second mono PCM16 bin percussion also matches in all three probes: 22,050 Hz, 352,800 bytes, cached stream identity and forward loop 0–176,400; PCM SHA-256 `0965cbed26ca6c6ef81360c1567ecf2da0c2c20e4f57b69ba0fbbef49b66b7b9`.

See [source-district-resources.json](source-district-resources.json), [linux-district-resources.json](linux-district-resources.json) and [macos-district-resources.json](macos-district-resources.json), with corresponding `.log` files. All probes exit 0 with clean engine/script/resource logs and isolated local data/config/cache directories. Platform probes run from an empty project using `--main-pack`, preventing fallback to checkout assets. The Linux Godot engine reads both data packs; this does **not** launch the macOS executable. Construction is not another physical challenge playthrough.

## Exact current evidence overlap

The [24-frame Barras/Clyde capture manifest](../screenshots/barras-clyde/manifest.json) has **160** source hashes, including all four new modules. Every one of its **108** inputs shared with the package matches exactly. Manifest SHA-256: `cea83820c9b58e2ba361709a1a4997f824755ce62a846e93cc64a8fe6a81a68a`. All 24 PNG hashes match; every PNG chunk CRC, 1280×800 header and decompressed scanline structure passed. The audit records each image hash/size. This is integrity verification of the accepted capture set, not independent subjective art acceptance or a performance measurement. The capture came from a dirty pre-commit checkout whose exact overlapping bytes match this clean build.

The separate [aggregate source receipt](../logs/barras-clyde-source.json), SHA-256 `7fa91706d7a19e913e4de8cdd8d8d45ba9524cc49bcddff36ff426e76c74292c`, records **1,106 passed / 0 failed**, exit 0, 158 stable inputs and no engine/script errors. All **108** package-overlapping hashes match. The native auditor checked that overlap; it did not rerun the aggregate suite.

## Normal Linux executable startup

The integration agent separately ran:

```bash
./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T180149Z-2a7d20c51559
```

Both the actual exported executable's **120-frame headless** launch and **1920×1080 / 30-frame rendered** launch naturally exited 0. [headless.log](headless.log), [rendered.log](rendered.log) and [smoke-summary.log](smoke-summary.log) are exact copies of the integration run's output. It used isolated profile directories, Mesa llvmpipe and Dummy audio. The only graphical warning reports unsupported V-Sync on that software display. Owned game/display processes were stopped and waited for by the integration agent. The independent package auditor did not repeat these native launches.

## Reproduce the independent audit

Use Python 3, Git, installed Godot `4.6.3.stable.official.7d41c59c4`, the exact build and matching retained source/capture evidence. No export, downloads, graphical display, audio device or paid service is required.

```bash
cd /workspace/tam_hawks_ps
python3 docs/testing/native-barras-clyde/audit.py \
  builds/tam-hawks-20261017T180149Z-2a7d20c51559 \
  --receipt-dir /tmp/tam-hawks-barras-clyde-audit \
  --evidence docs/testing/screenshots/barras-clyde/manifest.json \
  --evidence docs/testing/logs/barras-clyde-source.json
```

The [helper](audit.py) adapts the previous [native-bin-cats audit](../native-bin-cats/audit.py). It writes isolated supplemental probes beneath the ignored build directory and receipts to the selected output directory. [audit.log](audit.log) records the completed invocation. The first successful invocation printed `Fontconfig error: No writable cache directories` from its bare engine-version query; all three construction logs were clean. The helper then gave that query explicit writable local XDG directories. A brief repeat completed cleanly with identical package/source/capture results; no runtime input changed. The audit records its final helper and probe hashes.

Earlier bin-cat video, rider-motion and six-area profile receipts remain **historical**; they do not certify this changed scene. No Mac launch, signing/notarization, physical DualSense, audible listening, moving-route frame-rate result, human fun or final realistic-art acceptance is claimed. No artifact was publicly published and no paid service was used.
