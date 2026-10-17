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

Each platform ZIP contains a player guide, `BUILD-METADATA.json`, all reviewed `docs/licences/third-party/*.txt` notices, Godot's MIT licence, Godot's third-party copyright/licence text, and the project's provenance register. This includes the imported rail helper's MIT notice and the Flite CMU, KAL16 voice and Debian notices. `NOTICES/VOICE-PROVENANCE.json` records the three generated voice files and their source hashes. The upstream code licence does not grant a public licence to the game's original content. Do not publish release assets until the separate release review is complete.

For each exported data pack, an isolated Godot invocation loads and instantiates the main scene's script dependencies, then loads all three imported WAV resources and checks their durations. Its empty project directory prevents falling back to checkout files. `PACKAGED-RESOURCES.json` records this inspection and the data-pack digest. Full licence notices are supplied alongside the executable under `NOTICES/`; `docs/.gdignore` deliberately excludes documentation from the runtime pack. The script reopens each completed ZIP to verify the reviewed notices byte-for-byte and confirm that it contains the same inspected pack. These checks establish packaged resources, not audible sound on target hardware.

Outputs live under ignored `builds/tam-hawks-<UTC timestamp>-<Git short SHA>/`. `SHA256SUMS.txt` records distributable ZIP digests. Build metadata records the full Git commit, dirty-worktree status, runtime/package input hashes, engine version, verified template provenance and unsigned/unverified Mac status. A dirty build is identified by its file manifest rather than falsely attributed entirely to the preceding commit.

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

### Verified native checkpoint, 17 October 2026

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

`standalone-smoke/headless.log` and `rendered.log` contain no script/resource errors. The sole rendered warning reports that the dummy graphics driver cannot change V-Sync mode. The game title was captured after startup and reviewed at 1920×1080: title, four navigation choices and focus indicator are readable without clipping. The committed image is [standalone-title-1080.png](screenshots/standalone-title-1080.png), SHA-256 `d8ea58c4751bff20bbd9ee77107cb998eba42c3536193a990a5935724dfe4870`. The ignored build retains `standalone-smoke/title-live.png`, launch script, Xorg configuration/logs and `SMOKE-RESULTS.json`. The game exited normally and its temporary display process was stopped and waited; no smoke processes remain.

This is a normal Linux startup/resource/visual smoke using software rendering and the Dummy audio driver. Audible output, physical controllers, real Mac launch/Gatekeeper behavior and target-hardware performance remain unverified. The macOS archive is unsigned and unnotarized. No artifacts were published and no paid service was used.
