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

For each exported data pack, an isolated Godot invocation loads all three imported WAV resources and checks their durations plus the embedded third-party notices. Its empty project directory prevents falling back to checkout files. `PACKAGED-RESOURCES.json` records this inspection and the data-pack digest. The script reopens each completed ZIP to verify the reviewed notices byte-for-byte and confirm that it contains the same inspected pack. These checks establish packaged resources, not audible sound on target hardware.

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

Preparing templates does not itself produce a standalone build. Final artifact paths/digests and launch evidence will be added after the orchestrator identifies a stable checkpoint.
