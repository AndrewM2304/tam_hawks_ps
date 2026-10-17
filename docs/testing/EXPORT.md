# Local native exports

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

Current local artifacts: `builds/tam-hawks-20261017T141540Z-a99f9933091d/`.

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


### Current native checkpoint — a301279, 17 October 2026

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
