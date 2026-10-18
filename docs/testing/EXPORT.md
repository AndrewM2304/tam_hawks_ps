# Local native exports

**Latest checkpoint:** the performance/classic-mechanics game is packaged from clean `b97dac100f2993a26aaf50a05cb3b9676ea3d4e2` after **1,739/0** on **309 unchanged inputs**. Both archives/source/current captures audit and actual Linux headless/rendered startup pass; see [native-facade receipts](native-facade/README.md). The fitted facade stays disabled after its frame-spike gate failed, while its prepared resources are separately verified. The smaller source prototype is excluded. Mac execution remains untested. The native-performance checkpoint and earlier sections below are historical.

`tools/export.sh` prepares repeatable, unsigned local packages for Linux x86_64 and macOS universal (arm64 + x86_64). It uses free official Godot 4.6.3 templates and never signs, notarizes, uploads, publishes or calls a paid service. A successful cross-export does not establish that the game launches or performs acceptably on a Mac.

## Prepare and build

Prerequisites: the pinned Godot 4.6.3 editor, Bash, Python 3, Git, and approximately 3 GB of free workspace space. The first preparation downloads the official 1.17 GB non-Mono template archive; only the Linux/macOS templates are installed under the checkout's ignored `.local/data/godot/export_templates/4.6.3.stable`. No global installation is required. `tools/run.sh` supplies the matching XDG directories.

```bash
./tools/export.sh --prepare
# Once gameplay edits have stopped:
./tools/export.sh
# Or select one native target:
./tools/export.sh --target linux
./tools/export.sh --target macos
```

The normal command runs `tools/check.sh` before exporting. `--skip-check` is available only when the same unchanged gameplay checkpoint has already passed that command; its use is recorded in build metadata. Do not export while another agent is editing gameplay or package inputs. The script detects changed, added or removed package inputs during export and stops.

macOS cross-export requires both `rendering/textures/vram_compression/import_s3tc_bptc=true` and `rendering/textures/vram_compression/import_etc2_astc=true` in project settings before the import/check. The presets explicitly disable code signing and notarization. Apple Silicon launch and Gatekeeper behavior remain a real-Mac acceptance gate; this workflow does not disable OS security or purchase Apple enrollment.

## Verification and provenance

The template URL is `https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz`. The official `SHA512-SUMS.txt` supplies this pinned SHA-512:

```text
da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68
```

The script verifies the whole archive before extracting selected files and confirms `version.txt`. It checks cached files on reuse, keeps template hashes in `.local/downloads/export-template-verification.json`, and checks Godot's upstream `LICENSE.txt` and `COPYRIGHT.txt` against reviewed SHA-256 pins. A mismatch stops the build; never bypass verification.

Each platform ZIP contains a player guide, `BUILD-METADATA.json`, all reviewed `docs/licences/third-party/*.txt` notices, Godot's MIT licence, Godot's third-party copyright/licence text, and the project's provenance register. This includes the imported rail helper's MIT notice, the Flite CMU, KAL16 voice and Debian notices, the ZC texture CC0 licence, and the MakeHuman mesh CC0 licence/scope notices. `NOTICES/VOICE-PROVENANCE.json` records the three generated voice files and their source hashes; `NOTICES/TEXTURE-PROVENANCE.json` records the pinned source photographs, normal maps, licences and import settings. `NOTICES/HUMAN-MESH-PROVENANCE.json` records the pinned cropped head/scalp/hands, generator/output hashes and exact mesh licence scope. No MakeHuman program or full unclothed body is distributed. The upstream licences do not grant a public licence to the game's original content. Do not publish release assets until the separate release review is complete.

For each exported data pack, an isolated Godot invocation loads and instantiates the main scene's script dependencies, then loads all three imported WAV resources and checks their durations. It also loads all four imported brick/concrete textures, requires nonzero dimensions no larger than 1024 and verifies their mipmaps. It also loads the four imported anatomical meshes as ArrayMesh resources and requires nonzero surfaces and vertices. Its empty project directory prevents falling back to checkout files. `PACKAGED-RESOURCES.json` records this inspection and the data-pack digest. Full licence notices are supplied alongside the executable under `NOTICES/`; `docs/.gdignore` deliberately excludes documentation from the runtime pack. The script reopens each completed ZIP to verify the reviewed notices and provenance files byte-for-byte and confirm that it contains the same inspected pack. These checks establish packaged resources, not audible sound on target hardware.

Outputs live under ignored `builds/tam-hawks-<UTC timestamp>-<Git short SHA>/`. The script writes `builds/.gdignore` before imports, keeping earlier apps, logs and screenshots out of the resource scan. `SHA256SUMS.txt` records distributable ZIP digests. Build metadata records the full Git commit, dirty-worktree status, runtime/package input hashes including `.import` configurations, engine version, verified template provenance and unsigned/unverified Mac status. Before export, the texture source, import configuration and licence hashes must match the reviewed manifest. A dirty build is identified by its file manifest rather than falsely attributed entirely to the preceding commit.

## Required validation

- Run the full import/gameplay suite on the source checkpoint. Review package logs for errors.
- Check both executable formats. The script checks the macOS Mach-O contains x86_64 and arm64 slices and that Linux has an executable plus data pack.
- Smoke-launch the Linux standalone with an isolated local save directory, then render and review a frame if graphics are available. Headless startup alone does not establish visible rendering or audio output.
- On a real Mac, verify extraction, launch, keyboard and wired/Bluetooth DualSense behavior, saves, sound and 1080p performance. Record exact hardware and OS; these cannot be certified from Linux.
- Keep these artifacts local until the owner is ready for distribution. No hosted build or release workflow is configured.

If a future download is blocked, preserve the precise failing URL/error and finish source validation. The free source-play route remains: open `project.godot` in Godot 4.6.3 and press F5. Do not substitute unverified third-party binaries or request paid signing.

## Current evidence

On 17 October 2026, `./tools/export.sh --prepare` completed successfully with the installed `4.6.3.stable.official.7d41c59c4` editor. The 1,255,918,323-byte official archive matched the SHA-512 above. Selected verified templates occupy about 258 MB in the ignored local template directory. The complete archive is retained for reproducible verification. Both Godot notice hashes matched their pins. Shell syntax and the embedded Python programs parsed successfully.

The first native export attempt from `fbdc6ad398410b588130275ef09aea47a1022a97` was rejected by packaging validation. Selecting only the main scene and WAV resources omitted GDScript preload dependencies; a normal Linux launch reproduced missing-script errors. In addition, `docs/.gdignore` correctly prevented the attempted runtime inclusion of documentation notices. The correction exports all game resources while excluding tests/tools, checks the packed main scene/scripts, and supplies the complete notices alongside the executable in each ZIP. No ZIP from that failed attempt was produced; its ignored diagnostic directory is `builds/tam-hawks-20261017T130216Z-fbdc6ad39841/`.

### Earlier native checkpoint — 13e76ac, 17 October 2026

`./tools/export.sh --skip-check` completed with exit 0 from clean commit `13e76aca241f5603c5ecbe52623f30d60e9ee842`. The orchestrator had already run the unchanged production suite: **717 passed, 0 failed**. Metadata truthfully records that the export invocation skipped repeating it. The runtime/package input fingerprint is `03257b10bd0e1fe1298567038b48051cb771054306961252e46d99ea7b58f9a8`.

Artifacts are local under `builds/tam-hawks-20261017T130506Z-13e76aca241f/`:

| Archive | Bytes | SHA-256 |
| --- | ---: | --- |
| `TamHawksProSkater-linux.zip` | 27,541,414 | `3e215cf25c5da4b1ea832e84cad42bde03bc271ab0035b76ff11c501710fa1b7` |
| `TamHawksProSkater-macos.zip` | 62,100,941 | `1ec905891b87aa1a727f98bc61d294fccf6362b75dcf11c26e8144f1efaebf44` |

Both ZIPs passed CRC inspection. Linux contains an ELF x86_64 executable; the macOS Mach-O contains x86_64 and arm64 slices. Both preserve executable permissions. All four reviewed third-party notices and both Godot notice files byte-match their source files. Each archive also includes the full project provenance and matching voice provenance manifest.

The isolated probes loaded and instantiated each packed main scene and loaded all three imported voice streams: `landing` 0.9495 seconds, `cone` 1.2485 seconds, and `again` 1.137875 seconds. Each ZIP contains exactly the pack inspected by its probe. The Linux pack SHA-256 is `eff2813034b62f152e3c8fa40b1fd643e645ef643ea55a16c8f2f24d387cd355`; the macOS pack SHA-256 is `73061f2e31434dc56e7e51496cdb992bd7208f092b2e0c0c96b6da4fc301d8df`. Inspect `linux-resources.log`, `macos-resources.log`, their JSON reports, and each archive's `PACKAGED-RESOURCES.json` for the evidence. Both export logs were free of script/resource errors.

The exported Linux executable then booted its normal main scene, with no `--script` replacement, under isolated XDG data/config/cache directories in `standalone-smoke/`. Both bounded launches exited 0:

```bash
TamHawksProSkater.x86_64 --headless --audio-driver Dummy --quit-after 120
# Temporary Xorg display at 1920×1080, with LIBGL_ALWAYS_SOFTWARE=1:
TamHawksProSkater.x86_64 --audio-driver Dummy --resolution 1920x1080 --position 0,0 --quit-after 180
```

`standalone-smoke/headless.log` and `rendered.log` contain no script/resource errors. The sole rendered warning reports that the dummy graphics driver cannot change V-Sync mode. That checkpoint's title was captured after startup and reviewed at 1920×1080: title, four navigation choices and focus indicator were readable without clipping. Its retained `standalone-smoke/title-live.png` has SHA-256 `d8ea58c4751bff20bbd9ee77107cb998eba42c3536193a990a5935724dfe4870`. The ignored earlier build also retains its launch script, Xorg configuration/logs and `SMOKE-RESULTS.json`. The game exited normally and its temporary display process was stopped and waited. The screenshot in the tracked screenshots directory follows the newer checkpoint below.

This is a normal Linux startup/resource/visual smoke using software rendering and the Dummy audio driver. Audible output, physical controllers, real Mac launch/Gatekeeper behavior and target-hardware performance remain unverified. The macOS archive is unsigned and unnotarized. No artifacts were published and no paid service was used.

### Historical native checkpoint — a99f993, 17 October 2026

The updated visual pass was packaged with `./tools/export.sh --skip-check`, exit **0**, from clean commit **`a99f9933091d8931853ef375a2c029cccb6875f2`**. The unchanged runtime had passed the orchestrator's final `./tools/check.sh`: **778 passed, 0 failed**, exit 0 with clean engine logs. Export metadata records the skipped repeat honestly and includes all material import settings. The runtime/package input fingerprint is `1ce6dff6927dd7b5fdb8c5845a0061ebea422f6159719d4e891adaabde38eb97`.

Historical local artifacts: `builds/tam-hawks-20261017T141540Z-a99f9933091d/`.

| Archive | Bytes | SHA-256 |
| --- | ---: | --- |
| `TamHawksProSkater-linux.zip` | 31,518,442 | `cac607b28acfa68bb623d7379a2ab4754f0d1134f266484ea7e076d7e0ffb81f` |
| `TamHawksProSkater-macos.zip` | 66,077,978 | `2b5ca131c4b110305c9e25729eae100bc09a2644790b1292aaab915fd182b9b9` |

Both archives passed an independent CRC check. Linux is ELF x86_64; macOS is Mach-O with x86_64 and arm64 slices; executable permissions are retained. All ten `NOTICES/` files are present. The five reviewed third-party licences, two Godot notices and three project/voice/texture provenance files byte-match their source files. `ARCHIVE-AUDIT.json` records this audit. No runtime or fingerprinted packaging input changed during export.

Both isolated data-pack probes loaded and instantiated the main scene and its scripts, then loaded the three imported voices with their expected durations (`landing` 0.9495 s, `cone` 1.2485 s, `again` 1.137875 s). Both also loaded brick and concrete albedo/OpenGL normal maps: **four textures, each 1024×1024 with ten mipmap levels**. Both packaged data packs have SHA-256 `73abedf552e7ebd1c42efda3c6a8f4162d7dd4a29a5e77887abac509e9ec4127`; each ZIP contains the exact inspected pack. See the platform `*-resources.json`/`.log` and archive `PACKAGED-RESOURCES.json`. Export and resource logs contain no scanned script/resource errors.

Normal Linux startup used the actual exported executable with isolated XDG profile/config/cache directories, without replacing the main script. These final bounded commands both exited **0**:

```bash
TamHawksProSkater.x86_64 --headless --audio-driver Dummy --quit-after 120
# Temporary Xorg display; LIBGL_ALWAYS_SOFTWARE=1:
TamHawksProSkater.x86_64 --audio-driver Dummy --resolution 1920x1080 --position 0,0 --quit-after 30
```

The same binary's title was actually rendered and reviewed at 1920×1080. The title, four navigation choices and focused career button are legible without clipping. The updated [standalone-title-1080.png](screenshots/standalone-title-1080.png) is 361,499 bytes, SHA-256 `787a535cca11f060b19487c0e093fe10a799163b830478712573fc9ee386e6fa`. Its original is retained in `standalone-smoke-first-180frames/title.png`. The final natural-exit run retains `standalone-smoke/headless.log`, `rendered.log`, Xorg logs/configuration, `launch-smoke.sh` and `SMOKE-RESULTS.json`. Both final logs contain no engine/script/resource errors; the only game warning is the dummy graphics driver's unsupported V-Sync mode. The game exited normally and all temporary game/display processes were stopped and waited; the final process check found none remaining.

Smoke-harness diagnostics are retained transparently: the initial 180-frame graphical attempt rendered the reviewed title but reached its 90-second timeout (exit 124). A shorter attempt required the final window title too early while the window was still named `Godot`, despite its correct application class; a later screenshot raced the short-lived window. Those diagnostics are in `standalone-smoke-second-windowmatch/` and `standalone-smoke-third-capture-race/`. The final harness separates the retained visual evidence from the 30-frame natural-exit check. These harness corrections changed no runtime or package files. No target-performance conclusion is drawn from software rendering or the timeout.

This checkpoint's Mac app remains **unsigned, unnotarized and not launch-tested on a real Mac**. Actual Apple Silicon frame times, physical DualSense behavior, audible playback and final owner visual acceptance remain open. No build was published, and no paid service was used.


### Historical native checkpoint — a301279, 17 October 2026

`./tools/export.sh --prepare` and `./tools/export.sh --skip-check` completed exit **0** from clean runtime **`a30127940eacd4d2fe56d07a34ee1af4bacf95e5`**. Its unchanged gameplay had passed **955/0**, with clean import/engine/script scans. Metadata records that the export skipped repeating that already-completed suite. All 105 package inputs remained unchanged during export; fingerprint **`5c763454af485ccdabade16e5b0ed3aa4aa664a8e6e1b724aa238c1f3c442602`**. Exact input hashes are retained in the [build metadata](native-redesign/BUILD-METADATA.json).

Build directory: `builds/tam-hawks-20261017T155310Z-a30127940eac/`. Convenience files in `/workspace` are byte-identical copies:

| Archive | Bytes | SHA-256 |
|---|---:|---|
| `TamHawksProSkater-linux.zip` | 32,015,059 | `8e13443bde9d70a897c1814940fa7ed5713011b1496a9415ab7a893af01c1dea` |
| `TamHawksProSkater-macos.zip` | 66,574,593 | `44e780c9d271ea8f21ca127d8009a97767be8f4d2ee7d80bd4e11cfcbba5a81b` |

Both ZIPs pass a complete CRC check, executable-format/permissions checks and byte comparisons of all **13** notice/provenance files (seven third-party notices, two Godot notices and four project/asset provenance records). Linux is ELF x86_64; macOS contains both x86_64 and arm64 Mach-O slices. Both preserve executable permissions and include exactly the inspected data pack. Pack SHA-256: **`d5c0ae6d23787ed5faa42a13673659b679d38cfbac746067390f150e6238c049`**.

Both isolated pack probes instantiate the main scene and its script dependencies, load the three expected voice streams, all four 1024×1024 textures with ten mipmap levels, and the anatomical meshes: scalp425, head4,470, left hand1,901 and right hand1,901 imported vertices, one surface each. Probe directories contain no checkout resources to fall back to. The exported source hashes match all overlapping inputs in the final 98-file world capture and 97-file motion capture. The captures truthfully retain their earlier dirty-base identity; exact hashes bind them to this final runtime.

Normal Linux startup was checked with:

```bash
./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T155310Z-a30127940eac
```

The actual exported binary runs its normal main scene, using isolated XDG profile directories. Headless 120 frames and rendered 1920×1080 30 frames both exit **0** within their bounded timeouts, with clean script/resource/error scans. The graphical run uses Compatibility/Mesa llvmpipe; its sole warning is that the dummy display cannot change V-Sync. All owned game/display processes are stopped and waited by the wrapper. This run verifies normal rendered startup; it does not add a new native screenshot or establish frame rate/audible output. The 21 current source-rendered world/NPC frames are separate evidence, and the older title PNG above remains explicitly historical.

Durable [native-redesign receipts](native-redesign/README.md) include exact metadata, pack resource reports, independent archive audit and startup logs. The final source archive includes subsequent handoff-only commits; package-input identity remains the clean runtime above. `/workspace/TamHawks-downloads-SHA256SUMS.txt` records the two native ZIPs, final source ZIP and refreshed 7.4-second motion preview. Ignored binary/cached artifacts can be regenerated with these scripts after environment replacement.

The Mac app remains unsigned, unnotarized and not launch-tested on a real Mac. Actual DualSense use, offline Mac save relaunch, Apple Silicon frame times, listening, human route discovery/fun and final realistic art remain open. M06-007 and the explicit later mechanics/encounter tasks remain tracked. No build was published and no paid service was used.


### Historical mechanical-cat native checkpoint — ae481e6, 17 October 2026

`./tools/export.sh --skip-check` completed exit **0** from clean runtime **`ae481e684a0e7c897a4f0ff5b2492e7ceb4390d1`**. The unchanged production source had already passed **1,025/0**,34 accepted source-stable images, an audited six-view rendered diagnostic and decoded rider motion. Metadata records the skipped repeat. All **109** package inputs remained unchanged; fingerprint **`9bf76faacdefb8497cf1552363fb3eac93cf0ca46e874acba06012ddceb6f11c`**. Later handoff-only commits do not change this runtime or packaged player/provenance documents.

Build: `builds/tam-hawks-20261017T163413Z-ae481e684a0e/`. Convenience copies in `/workspace`:

| Archive | Bytes | SHA-256 |
|---|---:|---|
| `TamHawksProSkater-linux.zip` | 32,040,167 | `ffb8c980be0d587b8bd1e89da263634260cb4f8e22e153f2beba4f3faab8af59` |
| `TamHawksProSkater-macos.zip` | 66,599,701 | `447e92a171a953ca0a39bcbd2dbdfca34db458f39eec373f6b1364ebfd5ee8cd` |

Both isolated probes instantiate/load the packed main scene/scripts and load three voice streams, four 1024×1024/ten-mipmap textures and four anatomical meshes (head 4,470/scalp 425/hands 1,901 each, one surface each). Both archives contain the exact inspected pack, SHA-256 **`045b5e92afdb146392fee63660f80082d5c6fe218c759815dad51097d5a35933`**. Full ZIP CRC, executable architecture/permission and all 13 notice/provenance byte checks pass; Linux is ELF x86_64 and the Mac app contains arm64+x86_64 slices. No runtime/package input changed while exporting.

Normal Linux startup uses the actual exported executable/main scene, isolated XDG save directories and the bounded helper:

```bash
./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T163413Z-ae481e684a0e
```

Headless120 frames and rendered 1920×1080/30 frames both exit **0**, clean engine/script/resource logs. The graphical run uses Compatibility/Mesa llvmpipe and Dummy audio; its V-Sync warning belongs to the software display. Owned game/display processes stop and are waited. This is normal rendered startup evidence; current34 source frames are separate from native startup and no new native screenshot or frame-rate/audio acceptance is invented.

Durable [native-court-cat receipts](native-court-cat/README.md) preserve clean metadata, isolated pack reports, independent archive audit and startup logs. Exact runtime inputs bind the pre-commit dirty-base world/profile/motion evidence to this clean runtime. The final source ZIP contains subsequent handoff-only commits; external `TamHawks-downloads-SHA256SUMS.txt` records native/source/video digests.

The Mac app remains unsigned, unnotarized and not launch-tested on Mac. Physical DualSense, offline Mac save relaunch, Apple Silicon moving-route frame times, human listening/fun and final realistic-art acceptance remain open. No artifact was publicly released and no paid service was used.


### Historical native checkpoint — corrected bin drums and dancing cats

`./tools/export.sh --skip-check` exits 0 from clean runtime **`100dde5f8d7aef5b1547890dc65ef188da66d697`**. Export and the final **1,039/0** ordinary suite use the same frozen inputs; the export script skips repeating that suite. The final suite receipt verifies 148 unchanged source/test files. Focused 52/0 and 104-input/34-image/100-frame capture evidence are separate, not added to the aggregate.

Build: `builds/tam-hawks-20261017T171619Z-100dde5f8d7a/`. Metadata records a clean checkout, 111 package inputs and fingerprint `e3b365e78d248125fe36cd360a475e8945117048ed48f905d75d8f39ae8e5182`; metadata SHA-256 `871d4d8bcaebdf371284e90f060436c5d70dec219d340428c580181e71090f5d`. Both native packs share SHA-256 `e103f0a47092f752ca2c81801ce5e85c74f518890c4b55693d0c42666e31f85d`.

| Convenience archive | Bytes | SHA-256 |
|---|---:|---|
| `/workspace/TamHawksProSkater-linux.zip` | 32,051,394 | `182147536cdec951bddead4ef94939df36addb34c28bf3c168d39dc8e5d0ee67` |
| `/workspace/TamHawksProSkater-macos.zip` | 66,610,929 | `0a84b144d6ea719913dc4f21da73d4bc327fffa97d4a33c9958babc4d2e00133` |

Independent ZIP CRC/unique safe paths, package equality, executable 755/ELF/universal Mach-O, all 13 notices/provenance and 111-source-input checks pass. All 100 capture/package overlaps match. Empty-project source/Linux/Mac probes load the new bin-percussion module and generate identical cached 8s/22,050Hz mono16 PCM, alongside existing scene/voice/texture/anatomy pack checks. The audit helper, reports, metadata and startup logs are retained in [native-bin-cats](native-bin-cats/README.md).

```sh
./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T171619Z-100dde5f8d7a
```

Normal Linux main startup passes headless 120 and rendered 1920×1080/30 frames, exit0, isolated XDG and no engine/script/resource errors. The private software driver’s unsupported V-Sync warning is environmental. This is startup evidence, not performance or audible-output acceptance. The Mac app is unsigned, unnotarized and not real-Mac launch-tested.

The final source ZIP is generated from the later committed documentation handoff; its ZIP comment identifies that commit. Native runtime/package inputs remain the clean 100dde5 commit above. The new silent 100-frame bin-cat preview and external download checksums are recorded in STATUS;previous profile/rider-motion footage remains historical. No paid signing, hosted CI or public release was triggered.

### Historical native checkpoint — Barrowland, Barras delivery and Clyde

`./tools/export.sh --skip-check` completes exit **0** from clean runtime **`2a7d20c51559907b0ca30a995d842dcc683ff320`**. The ordinary **1,106/0** suite validates the same unchanged source; export skips repeating it. Build: `builds/tam-hawks-20261017T180149Z-2a7d20c51559/`. **119 package inputs**, fingerprint `037f91d3a3b98991ed8f3668588927c8702f9049b44a5bd3e4cb5f5456568c3b`; metadata SHA-256 `7d297e87ab373e110bcc3da91f6cb7d40c5c0e632f1b846e4865af0ec44afd8c`.

Independent ZIP CRC/path/mode/architecture, official-template, licence/provenance and source audits pass. Both packs share SHA-256 `a4f5dacae4dd597ec0d384073e488e22269e3e088761023c9354bfd40177bf08`. Empty-project source/Linux-PCK/Mac-PCK probes construct the Barrowland/market/Clyde nodes, Mairi/gull/counter and hidden torso-attached bag, and preserve the identical original percussion data. All **108 capture/build overlap hashes** match; the aggregate receipt's 108 overlaps match too. The 24 PNGs also pass byte/CRC/scanline checks. [Durable receipts](native-barras-clyde/README.md) and [EXPORT](EXPORT.md) preserve exact commands and results.

Normal Linux headless 120 and rendered 1920×1080/30-frame main startup exit **0**, with isolated XDG profiles and no engine/script/resource errors. The software driver's unsupported V-Sync warning is environmental. All owned game/display processes stopped. This is startup evidence, not a frame-rate or listening test. The Mac app is unsigned, unnotarized and unlaunched on real Mac hardware.

| Download | Bytes | SHA-256 |
|---|---:|---|
| `/workspace/TamHawksProSkater-linux.zip` | 32,099,727 | `500aa3642251d14ea6027f94c401396f2bc02613e107e034c4338788dd0b5348` |
| `/workspace/TamHawksProSkater-macos.zip` | 66,659,261 | `46b28b9381df63ff8c2b372cf7fbc7a45fb43cc6185ec84d3210d4c07f3d7fd4` |

`/workspace/tam-hawks-prototype-source.zip` is generated from the final committed documentation handoff; its ZIP comment identifies that commit. `/workspace/TamHawks-downloads-SHA256SUMS.txt` records current native/source hashes. Both older video previews are explicitly historical; no current-market motion or performance result is inferred from them. Ignored artifacts may disappear after environment replacement and can be regenerated.

```sh
./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T180149Z-2a7d20c51559
```

All three new district/encounter scripts and the Clyde helper are present in both packages. Cross-loading the Mac PCK under Linux verifies packaged resources; it does not launch the Mac executable. The short independent audit helper initially emitted a Fontconfig cache diagnostic during its bare version query; isolated writable cache paths corrected that audit harness only. Runtime/package inputs stayed unchanged. No paid service, signing, hosted CI or public release was used.

### Current native checkpoint — Exchange/gallery entrance and west seating

`./tools/export.sh --skip-check` completed exit **0** from clean runtime **`00da63a29990c0839cf15d4c9a34edc2fc167122`**. The unchanged source had already passed the ordinary **1,155 passed / 0 failed** suite, exit 0, with 162 unchanged inputs and clean error scans; export records the skipped repeat. Build: `builds/tam-hawks-20261017T185223Z-00da63a29990/`.

[Build metadata](native-exchange-gallery/BUILD-METADATA.json) records a clean checkout and **121 package inputs**, fingerprint `26b9606113ff7fa97319ff5650f519664ab5db81b8a5fbc26d653165bda31cef`; metadata SHA-256 `c1b0f49bf5cbd1698ea7d37ce9553628b5f4c227da5b64524aea2fa839d3094d`. Both inspected data packs share SHA-256 `6447f96516e715e1d4881e934175c137f28dcc7283895e611b1b51e4b38b76cc`.

| Build archive | Bytes | SHA-256 |
|---|---:|---|
| `TamHawksProSkater-linux.zip` | 32,105,526 | `900689e0aff5035288118255913b26ac3185f215293fdab6a7ae015694c78cd1` |
| `TamHawksProSkater-macos.zip` | 66,665,060 | `ac4ad7cb4f7b9a7c1e653a3783e7dfd93bb262285c1cf27a3ac535f9d1fd3d1a` |

The independent archive audit passed on its first invocation with clean logs. Full ZIP CRC, unique safe paths, member bytes/modes, executable permissions, official-template identity and all **13 notices/provenance records** match. Linux is ELF64 x86_64; the unsigned Mac executable contains x86_64 and arm64 Mach-O slices. All package inputs match their named Git objects and current source. [ARCHIVE-AUDIT.json](native-exchange-gallery/ARCHIVE-AUDIT.json) has SHA-256 `45e5fa7e05cf1ac7f4eb24d8a55920bfb497392f854996362fe1ab3bddbbddf8`.

Source, Linux-PCK and Mac-PCK construction probes load the new `exchange_gallery.gd` helper and find the terraces, banks, threshold, eight portico columns with three collision shapes each, **44 routes**, all five new route IDs and both new ledges. They retain the Barras/Clyde/market modules, six checkpoints, actors, attached bag and identical original percussion data. Export-resource probes also verify the three voices, four 1024×1024 textures and four anatomical meshes. Reading the Mac PCK with Linux Godot verifies packaged resources; it does not launch the Mac binary or replay physical routes.

The corrected [22-image capture manifest](screenshots/exchange-gallery/manifest.json), SHA-256 `8c6122729aad2fda9c7c609fb6c53dda36accec62c41e3cef0571f7484b9e39e`, records 164 unchanged inputs. Every PNG passes its hash, CRC, 1280×800 header and scanline checks. All **110 capture/package overlaps** match. The [ordinary-suite receipt](logs/exchange-gallery-source.json), SHA-256 `cb0dbf69a948805b3c336673d089c6056063e5be270abbebc7cb157efe36bb1b`, also matches all 110 shared package inputs. Exact evidence and audit commands are retained in [native-exchange-gallery](native-exchange-gallery/README.md).

```sh
./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T185223Z-00da63a29990
```

The actual exported Linux main scene naturally exits **0** after both headless 120-frame and rendered 1920×1080/30-frame startup, using isolated profiles. Exact [headless](native-exchange-gallery/headless.log), [rendered](native-exchange-gallery/rendered.log) and [wrapper](native-exchange-gallery/smoke-summary.log) logs are retained with the private-display configuration. No engine/script/resource errors occurred; Mesa llvmpipe's unsupported V-Sync warning is the sole graphical warning. Owned game/display processes stopped and were waited. These are bounded startup checks; earlier profile and video evidence remains historical.

The Mac app remains unsigned, unnotarized and not launched on a real Mac. Physical DualSense use, Mac save relaunch, listening, moving-route performance, human discovery/fun and final realistic-art acceptance remain open. No artifact was publicly released and no paid service was used.


## Current performance/classic-mechanics checkpoint — 18 October 2026

`./tools/export.sh --skip-check` completes **exit 0** from clean **`9930b304ecd7f9d0f5800a0380e84cfaf2c63a78`**. The unchanged gameplay/tests/tools already passed the actual required ordinary suite **1,701/0**, with 284 stable inputs and clean scans. Build: `builds/tam-hawks-20261018T000141Z-9930b304ecd7/`. Export verifies **151 unchanged package inputs**, fingerprint **`7ae2f095cbb4d4616c23b7c0fd19733cb8342df46eaf68bd728003e8be1e156c`**. Later docs/audit edits do not change those package inputs.

| Archive | Bytes | SHA-256 |
| --- | ---: | --- |
| `TamHawksProSkater-linux.zip` | 32,813,204 | `a66a5b22a277c948b9a2d67735ada7bb4e4688c818bfa0475962ffa17484c8ec` |
| `TamHawksProSkater-macos.zip` | 67,372,739 | `76943cf5e8cc1586b20404e49272d2c9cee1c564b7cd8a87d3ea529cdee178a7` |

[Complete native receipts](native-performance/README.md) retain metadata, corrected audit, source/Linux-PCK/Mac-PCK construction reports, export/resource logs, exact checksums and an actual exported [1080p title image](native-performance/title-live.png). ZIP/member/source/notice/binary checks pass; Linux is ELF64 x86_64 and Mac is unsigned universal x86_64+arm64. All 141 ordinary/package and 140 normal-capture/package overlaps match, and all 19 capture PNGs decode. Both packs construct current graphics/interpolation/batches, 48 routes, three quarter/half-pipe faces and directional trick catalogue, while excluding the isolated unused art prototype. The old gallery probe's current schema/route/performance extensions live in native-performance; its first consumed-engine-argument wrapper failure is retained as rejected evidence, not a pass.

The actual exported Linux main exits **0** after headless 120-frame and rendered 1920×1080/30-frame startup, from an empty working directory and isolated profiles. Only the software driver's expected V-Sync warning appears. The first screen capture was a loading splash and is rejected as title evidence; the corrected native title is fully decoded and reviewed with all four menu choices/focus border visible. No script override, fixed clock or forced draws; this is bounded startup, not FPS or native gameplay acceptance. The helper stops/waits its game/display; no live job remains.

Local ZIPs are not uploaded or published. Mac executable launch, Gatekeeper, physical keyboard/DualSense, save relaunch, listening, moving 1080p target frame times, human feel and final art/UI remain open. The Linux engine reading a Mac PCK is resource evidence only. No paid service, signing or notarization is used.
