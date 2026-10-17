# Bin drums and soft cats: native receipts

These receipts cover clean runtime **`100dde5f8d7aef5b1547890dc65ef188da66d697`**, built locally on 17 October 2026 after the busker correction to bin percussion and two dancing soft toy cats. Binary downloads remain outside Git. This audit checks package integrity, source identity and resource availability; the ordinary gameplay suite has its separate receipt.

- [BUILD-METADATA.json](BUILD-METADATA.json) records **111** exact package input hashes, the clean commit, Godot 4.6.3 and verified official templates. Runtime input fingerprint: `e3b365e78d248125fe36cd360a475e8945117048ed48f905d75d8f39ae8e5182`. Metadata SHA-256: `871d4d8bcaebdf371284e90f060436c5d70dec219d340428c580181e71090f5d`.
- [ARCHIVE-AUDIT.json](ARCHIVE-AUDIT.json) records the independent complete ZIP CRC, safe/unique path, executable mode/architecture, member byte, metadata and notice checks. All 111 source inputs match both the checkout and the named Git objects. All **13** notices/provenance records in each archive match their reviewed sources, including voice, texture and human mesh provenance. The executable bytes match the verified official release templates.
- [linux-resources.json](linux-resources.json) and [macos-resources.json](macos-resources.json) record isolated pack loads of the main scene/scripts, three voice WAVs, four 1024×1024 textures with ten mipmap levels and four anatomical meshes. Both ZIPs contain the exact inspected PCK: SHA-256 `e103f0a47092f752ca2c81801ce5e85c74f518890c4b55693d0c42666e31f85d`.
- The `source-`, `linux-` and `macos-bin-percussion.json`/`.log` files record a second independent probe: packed main scene/script load and deterministic original `bin_percussion.gd` output. The platform probes use an empty project with `--main-pack`, so they cannot fall back to the checkout. All three produce identical cached mono PCM16 audio, 22,050 Hz, eight seconds, 352,800 bytes, forward loop 0–176,400. PCM SHA-256: `0965cbed26ca6c6ef81360c1567ecf2da0c2c20e4f57b69ba0fbbef49b66b7b9`.
- The accepted [bin-cats capture manifest](../screenshots/bin-cats/manifest.json) has **104** stable inputs; all **100** inputs shared with the package match exactly. Manifest SHA-256: `f172612c2194f223c37a62d47ec6d93fec3446add119afb3485fad1f9d43cf87`. Its source images are separate from native startup evidence.

The audited build directory is `builds/tam-hawks-20261017T171619Z-100dde5f8d7a/`:

| Archive | Bytes | SHA-256 |
|---|---:|---|
| `TamHawksProSkater-linux.zip` | 32,051,394 | `182147536cdec951bddead4ef94939df36addb34c28bf3c168d39dc8e5d0ee67` |
| `TamHawksProSkater-macos.zip` | 66,610,929 | `0a84b144d6ea719913dc4f21da73d4bc327fffa97d4a33c9958babc4d2e00133` |

Linux is ELF64 x86_64; macOS is universal Mach-O x86_64 + arm64. Both archive and unpacked executable modes are `0755`.

## Reproduce the independent audit

Use the exact clean runtime/package inputs above, the original build directory, the retained capture manifest and preview, Python 3, Git, Godot `4.6.3.stable.official.7d41c59c4`, ffprobe and ffmpeg. No network access, purchases or export is required. The helper writes supplemental probes under the ignored build directory and receipts only to the chosen output directory; it does not edit production source.

```bash
cd /workspace/tam_hawks_ps
python3 docs/testing/native-bin-cats/audit.py \
  builds/tam-hawks-20261017T171619Z-100dde5f8d7a \
  --receipt-dir /tmp/tam-hawks-bin-cats-audit \
  --evidence docs/testing/screenshots/bin-cats/manifest.json \
  --preview /workspace/TamHawks-bin-cats-preview.mp4 \
  --preview-sha256 00a929553cb13ee7f7b6b10e96d07a2e29ced73c87fb25b0128da38aa7ec26fb
```

The complete run passed. [preview-ffprobe.json](preview-ffprobe.json) and full ffmpeg decoding verify the **100-frame, 30 fps, 3.333-second silent H.264 preview**, SHA-256 `00a929553cb13ee7f7b6b10e96d07a2e29ced73c87fb25b0128da38aa7ec26fb`. This declared short scene fixture does not establish a moving-route frame rate. The earlier court-cat profiling and rider-motion receipts remain historical and do not certify this correction.

## Normal native startup

The integration agent separately ran the actual exported Linux executable and its normal main scene:

```bash
./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T171619Z-100dde5f8d7a
```

The bounded **120-frame headless** and **1920×1080 / 30-frame rendered** launches both exited **0**, with isolated local save/config/cache directories and clean engine/script/resource error scans. [headless.log](headless.log), [rendered.log](rendered.log) and [smoke-summary.log](smoke-summary.log) retain the actual results. The graphical run used Mesa llvmpipe and Dummy audio; its sole warning reports unsupported V-Sync in the software display. The integration agent stopped and waited for all owned game/display processes. This independently retained startup evidence is separate from the PCK probes above; the native auditor did not repeat the launch.

No Mac launch, signing/notarization, physical controller, audible listening, target hardware performance, human fun or final realistic-art acceptance is claimed. No artifact was publicly released and no paid service was used. See [EXPORT](../EXPORT.md) and [STATUS](../../STATUS.md) for the current project handoff.
