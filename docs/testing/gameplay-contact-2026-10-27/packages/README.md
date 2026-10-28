# Gameplay contact trial packages — 28 October 2026

Both local exports completed from clean main commit `471cd3c325dd729f52775ebd67dc77fddca81bdf`.
The gameplay inputs match the preceding verified source at `497781f350ddc15899fc73c69f5e993be20b6bd7`.
Later documentation and macOS evidence-filename repairs do not change these runtime inputs.

Build directory: `builds/tam-hawks-20261028T065221Z-471cd3c325dd`.
Archives remain local ignored build artifacts; no release or upload was created.

| Archive | Bytes | SHA-256 |
| --- | ---: | --- |
| `TamHawksProSkater-linux.zip` | 36,738,882 | `4493a57f593e603523cc03c12189c59dac95adfd586e4832d74fd11b4e195371` |
| `TamHawksProSkater-macos.zip` | 71,298,486 | `4c582949683a99e665d287f0fbaf9b19e635cc62d94e43048982fdf118cf61e7` |

The [archive audit](ARCHIVE-AUDIT.json) passes: 683 unique committed source blobs,
ZIP integrity and paths, executable modes, 13 notice/provenance records per archive,
and native resource loading. Linux x86_64 and Mac arm64/x86_64 contain the identical
game pack, SHA-256 `407d49cdb22af7b08cda09d7e61a2d3ad3376dc53affd83a8354c770f5cbcdc0`.
The retained [observer](observers/gameplay_archive_audit.py), source maps and logs
bind these observations to these exact archives.

The export command `./tools/export.sh --skip-check` reused the immediately preceding
[required check](../required-final/receipt.json): **5,746 passed, zero failed**, plus
the actual Music script CLI guard **2 passed, zero failed**. All 673 observed inputs
were unchanged. The export script did not run that suite again.
The [cold-source check](../cold-source/SOURCE-LAUNCH.json) separately passed cold,
normal title-to-play (50/0), warm and expected invalid-source refusal phases.

The ordinary exported Linux application passed [standalone smoke](SMOKE-RESULTS.json)
in 58.528 seconds from an empty working directory with an isolated profile. Both
headless and rendered startup succeeded. The original [1920×1080 title capture](title-live.png)
shows the native Main menu; root inspected it. Its SHA-256 is
`955fea879bfa9858e452b949f29f97385d94f96caeb6d49fcfeb130c139f1e0d`.
No scene/script override or fixed clock was used. This is startup evidence, not a
gameplay performance measurement.

Mac signing and notarisation are disabled. Mac archive structure and resources
were checked on Linux; the Mac executable was not launched. Embedded template
signature observations are structural, without cryptographic verification.
Music's configured Automation entitlement and usage description do not establish
effective signing, TCC consent or playback. Physical controllers, target-Mac
performance, audio and human skating feel remain open acceptance work.

This is a pushed handoff checkpoint. The accepted C07/C10 reduced-facade material
attribution task continues separately; the failed-cost facade diagnostic remains
disabled while ordinary merged station, train, pond and route content stays on.
