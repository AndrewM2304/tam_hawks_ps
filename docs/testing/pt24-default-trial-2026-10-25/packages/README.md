# Normal-play trial packages

Both unsigned packages export from clean source commit`330ed86b168faf37d820ee028cb9943b85e860f2`.
Station/train, pond/ducks, central green and civic return are **enabled by default**;
launch normally without flags. Replace any older exported app. Source users can
pull main and fully quit/relaunch with F5 or `./tools/run.sh`.

Required **5,038/0**, actual Music guard **2/0**, normal no-script title-to-play
**50/0**, four cold phases and eight ordinary-default native frames pass.
[Archive audit](ARCHIVE-AUDIT.json), [metadata](BUILD-METADATA.json),
[checksums](SHA256SUMS.txt) and [required receipt](../validation/receipt.json)
bind the source. All597 tested inputs and260 package inputs match the checkout
and source commit:250 overlap,607 unique Git blobs verified. Both platforms
have identical data packs. ZIP CRC/paths, executable modes, Mac arm64+x86_64,
all13 notices, Main/scripts and imported voice/texture/anatomical resources pass.

| Package | Bytes | SHA256 |
| --- | ---: | --- |
| TamHawksProSkater-linux.zip | 36,376,442 | `8d9e8a0e3e3c1a7f72a4acc196eed2d8f6478c02a28768d40823888e1020024c` |
| TamHawksProSkater-macos.zip | 70,936,047 | `d6d9ac1c0af3492a444d8fd19c18f245ce409a8ea26684faac34ca88f104e846` |

Local files:`builds/tam-hawks-20261025T181741Z-330ed86b168f/`.
No release/upload/signing/notarization was performed. `--skip-check` reuses the
unchanged just-tested source; metadata accurately records that export itself
did not rerun the required suite. The actual Mac plist retains Music usage text;
configured Apple Events entitlement is not verified consent/effective signing.

The actual unmodified Linux executable passes isolated headless and rendered
startup from an empty directory, without script override/input injection/fixed
clock. [Receipt](standalone/SMOKE-RESULTS.json), [title](standalone/title-live.png).
The Mac pack loads under Linux Godot; the Mac executable has not been run here.
Mac performance/Music/controllers/visual/human evidence remains open for trial
and does not switch these features off.

Commands from the repository root:

```sh
./tools/export.sh --skip-check
python3 docs/testing/pt24-next-2026-10-25/packages/observers/archive_audit.py \
  --build <build-directory> \
  --receipt docs/testing/pt24-default-trial-2026-10-25/validation/receipt.json \
  --source-before docs/testing/pt24-default-trial-2026-10-25/validation/source-before.json \
  --source-after docs/testing/pt24-default-trial-2026-10-25/validation/source-after.json \
  --output docs/testing/pt24-default-trial-2026-10-25/packages
python3 docs/testing/native-performance/smoke_capture.py <build-directory>
```
