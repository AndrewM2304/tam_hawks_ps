# Current performance/classic-mechanics native packages

18 October 2026. **Both local exports, the complete archive/source/capture audit and normal Linux startup pass.** Built from clean **`9930b304ecd7f9d0f5800a0380e84cfaf2c63a78`** after the unchanged production checkpoint passed **1,701/0**. Game code remains `8a975b2`; final ordinary source/tests/tools were `9e39316`. Later audit/handoff changes do not change any of the **151** package inputs.

Build: `builds/tam-hawks-20261018T000141Z-9930b304ecd7/`. Archives stay local/ignored; no release upload, signing, notarization or paid service.

| Archive | Bytes | SHA-256 |
| --- | ---: | --- |
| `TamHawksProSkater-linux.zip` | 32,813,204 | `a66a5b22a277c948b9a2d67735ada7bb4e4688c818bfa0475962ffa17484c8ec` |
| `TamHawksProSkater-macos.zip` | 67,372,739 | `76943cf5e8cc1586b20404e49272d2c9cee1c564b7cd8a87d3ea529cdee178a7` |

[BUILD-METADATA.json](BUILD-METADATA.json), SHA-256 `4378df5127ca9b0b7779b7c62145f06c78fe5a3b5ed6e9681d594ec63849221d`, records the clean build, all 151 unchanged package inputs and fingerprint **`7ae2f095cbb4d4616c23b7c0fd19733cb8342df46eaf68bd728003e8be1e156c`**. Export skipped repeating the already-passed ordinary suite; that choice is recorded. The cached free official Godot 4.6.3 templates and notices were reverified against their reviewed pins.

## Archive and actual resource checks

[ARCHIVE-AUDIT.json](ARCHIVE-AUDIT.json), SHA-256 `b72967958649903b27803d3d69450c2d93eff233420207ed562b5a7830905d2a`, verifies ZIP CRC, unique/safe paths, every member's bytes/modes, executable permissions and official binary pins. Linux is ELF64 x86_64; Mac is unsigned universal Mach-O x86_64 + arm64. Every source input matches its named Git object/current checkout, and all **13 notices/provenance records per archive** match. Both contain the same inspected PCK, SHA-256 **`a45d7105e5e873c4379e9146ce758c2ae634e58acd6a04d5281b1337b79dbd45`**. The isolated art prototype is explicitly absent from both packs.

The final ordinary receipt/logs are checked, and all **141** shared ordinary/package inputs match. All **140** shared current normal-play capture/package inputs match, with all **19 actual PNGs** independently hash/CRC/scanline decoded. Those images certify their source-bound fixtures, not native performance or human acceptance.

The export-resource probes load Main/scripts, all three voice WAVs, four 1024² textures with ten mip levels and four anatomical meshes. Supplemental source/Linux-PCK/Mac-PCK construction reports match exactly. They retain the gallery/market/percussion checks, **48 authored routes**, all three quarter/half-pipe faces, directional flip/grab/manual/lip IDs, **64 m batches / 234 fewer nodes**, **351 bodies / 1,863 shapes**, actual Balanced settings, **0.20 m near / 220 m far**, native interpolation and disabled occlusion. `instances_preserved: 17387` in this construction report counts the merged families; the separate rendered multiset audit proves all **17,742** registered pieces including untouched families. These construction probes do not independently replay skating routes or judge visual quality.

The Linux editor reads both packs from an empty project; **this does not launch a Mac executable**. Full source/three-probe/export/resource logs are retained. The first audit wrapper correctly rejected a missing exclusion-check execution: Godot consumed `--main-pack` before the argument query. [Rejected evidence](rejected-argument-detection/README.md) remains separate. The corrected probe checks actual virtual `project.binary` and emits an exclusion marker required independently for each pack. Only the complete corrected audit is accepted.

## Actual Linux main and title image

The actual exported executable, with no script override, runs from an **empty working directory** and isolated XDG/profile folders. Both headless **120-frame** and native-rendered **1920×1080 / 30-frame** normal-main launches naturally exit **0**, with no engine/script/resource errors. The sole graphical warning is the software driver's unsupported V-Sync-change warning. Logs, [SMOKE-RESULTS.json](SMOKE-RESULTS.json), private-display configuration and [CAPTURE-REVIEW.json](CAPTURE-REVIEW.json) are retained; no live Godot/game/display job remains. One unrelated exited zombie under PID 1 is recorded separately from running work.

[title-live.png](title-live.png) is the actual X11 frame, **398,895 bytes**, SHA-256 **`4a131799d36e6b1adacd1ef5decf675bf3fd308752a205e2ccb0932778452643`**. The first capture caught the loading splash and was rejected as title evidence; [that raw capture](rejected-splash-capture/README.md) remains separate. The corrected helper waits for actual screen terms using installed free Tesseract, then root visually inspected all four menu choices, complete focus border and unclipped text. The PNG passes full CRC/decompression/1920×1080 checks. OCR is only a readiness heuristic; agent visual review is separate from owner/final-art acceptance. No fixed clock, forced draws or injected input is used. Startup duration here is **not a performance benchmark**.

## Reproduce

`audit.py` reuses the strict earlier archive auditor rather than copying its archive checks. The schema adapter retains the complete accepted ordinary receipt and only adds the existing source-hash alias under ignored build output. Original receipt/helper/probe hashes remain explicit.

```sh
python3 docs/testing/native-performance/audit.py \
  builds/tam-hawks-20261018T000141Z-9930b304ecd7 \
  --receipt-dir /tmp/tam-hawks-current-native-audit
./tools/native_smoke.sh /absolute/path/to/builds/tam-hawks-20261018T000141Z-9930b304ecd7
# Optional X11 actual-title capture, with installed Pillow/Tesseract:
python3 docs/testing/native-performance/smoke_capture.py /absolute/path/to/a/fresh/build
```

The optional capture expects a fresh `standalone-smoke/` output path; preserve/move an earlier receipt folder before repeating so no stale display/log is mistaken for the new process. It is Linux-only and calls the existing bounded smoke runner. Its caption/word gate does not replace image review.

The initial `preflight-*` files describe syntax/source checks before the argument-query correction; the final complete audit attests the corrected helper/probe hashes. Physical Mac launch, keyboard/DualSense, saves/relaunch, listening, ten-minute 1080p moving frame times, human feel and final realistic art/UI remain open. No old video or software-rendered timing is relabelled as hardware acceptance.
