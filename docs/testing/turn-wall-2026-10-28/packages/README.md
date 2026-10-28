# Local package handoff — steering and wallride repair, 28 October 2026

Fresh Linux and universal-Mac archives were exported from clean main commit
`33bd26d78e4314c8b3bfd082a17491bfb48ef640`. Its gameplay source is the admitted
repair `40a6615d0c1837594a7e65fa73876d2ced08db11`; the intervening commit records
verification evidence. The explicit local build directory is
`builds/tam-hawks-20261028T184439Z-33bd26d78e43`. These files are local unsigned
outputs; they have not been uploaded or published as a release. Older exported
applications retain their previous source and need replacing or rebuilding to
trial this repair.

The [archive audit](ARCHIVE-AUDIT.json) passes. It independently compares the
complete required-suite and package input memberships with the checkout and
**687 committed Git blobs**: 677 required inputs, 274 package inputs and 264
shared inputs. [Build metadata](BUILD-METADATA.json) records a clean export tree.
The runtime-source fingerprint is
`a7ab3c87d774f9a7972aa8a5975a0f8dd2bff6617c08dc025203242c62b58195`.

| Archive | Architecture | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `TamHawksProSkater-linux.zip` | x86_64 | 36,741,852 | `eb3f5ea36d2c7042af57cb986062b3ee917a3f53f2e8b07ef7a361cc10d0860c` |
| `TamHawksProSkater-macos.zip` | arm64 + x86_64 | 71,301,457 | `a10bc75185189fcad6988651011d91d98e489c56747548cbe4bd59feb687d562` |

Both ZIPs pass CRC, member-path, executable-mode and all thirteen notice/provenance
checks. The actual Linux-loaded native resource reports verify Main, voice,
texture and anatomical mesh resources in each pack. Their PCK bytes are identical,
SHA-256 `6873169f488a8ca1a8451c78720cd1a4c076d03981c4685d11e32e749ac3150a`.
The [checksum manifest](SHA256SUMS.txt), export logs, native pack reports and
[exact audit observer](observers/turn_wall_archive_audit.py) are retained here.

`tools/export.sh --skip-check` reused the already admitted [complete required
suite](../required-01/receipt.json), **5,888/0** in 638.089 s with 677 unchanged
inputs. The actual short-script Music/profile isolation guard separately passes
**2/0** in the same console log. The audit checks both counts and their actual
engine arguments. The required receipt identifies gameplay commit `40a6615`;
the archive audit verifies all tested blobs against that commit and all combined
source blobs against the later clean export commit.

The [cold observer](../cold-01/receipt.json) passes with the same 677-input
fingerprint. Its [four-phase source launch record](../cold-source/SOURCE-LAUNCH.json)
retains cache-free import/launch, normal title-to-play **50/0**, warm launch and
correct refusal of deliberately invalid copied source. The separate [eight
rendered steering/wallride frames](../captures/README.md) document native gameplay
and connected rider presentation; they are distinct from exported-app startup.

The ordinary exported Linux application passes [standalone smoke](SMOKE-RESULTS.json)
in **57.995 s**, exit0, from an empty working directory with an isolated profile.
Both headless and rendered startup succeed. Root inspected the original
[1920×1080 title image](title-live.png), showing the expected native Main menu;
its SHA-256 is
`7912df27208ddb5f2c2a89615f3d254a6f8b73ad73825818c3b9fd4365c49a92`.
The [headless log](headless.log), [rendered log](rendered.log) and
[smoke summary](smoke-summary.log) are retained. No script/scene override, fixed
clock or performance measurement is used. This certifies ordinary exported-app
startup, not gameplay feel or target frame rate.

Mac signing and notarisation are disabled. Mac archive structure, arm64/x86_64
slices and resources were checked on Linux; the Mac executable was not launched.
Embedded template signature observations are structural, without cryptographic
verification. The archived Music Automation usage description and configured
Apple Events entitlement do not establish effective signing, TCC consent or
playback. Physical controllers, Mac execution, saves/audio, target performance,
final art and human skating feel remain open acceptance work. Ordinary merged
station, train, pond and route content stays enabled.
