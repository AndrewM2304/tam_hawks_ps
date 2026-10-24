# Trick-fidelity render receipt — 23 October 2026

The current capture contains **36 actual 1280 × 800 PNGs**, **63 checks / zero
failures**, and **190 unchanged source inputs**. It completed at
**22:58:26 UTC on 23 October 2026** using Godot **4.6.3**, the Compatibility
renderer, X11 and Mesa llvmpipe. Every image passed PNG signature, chunk CRC,
dimensions and decompressed-row validation. A separate post-capture comparison
also found every recorded input still matched the checkout.

Command:

```sh
./tools/trick_fidelity_capture.sh --private-display
```

The source-bound [manifest](manifest.json) has SHA-256
`d0e683b95d75de51b4ff79365c4d36376291b793f7d14804da10cd398b25361f`.
It records each image's hash, camera type, actual player state, score and board
rotation, plus the command and all source hashes. [engine.log](engine.log) and
[import.log](import.log) retain the engine/import evidence. The dummy display
reports an unsupported V-Sync-setting warning; rendering succeeds without
script, parse or engine errors. Profile writes are disabled.

## Actual actions and reviewed samples

Actions execute through the production Main scene, Input actions, controller and
Godot physics. Each independent action starts from a documented reset. Rail
captures start from an explicit descending fixture next to the real Exchange
rail, then use ordinary acquisition, balance and travel. Close views use an
authored inspection camera; the script freezes an executed action only while
rendering its screenshots. Chase views use the production camera and HUD.

| Sample | Observed result |
| --- | --- |
| [Kickflip](02-kickflip-close.png), [Heelflip](03-heelflip-close.png), [Pop Shove-it](04-pop-shove-it-close.png) | Different authored roll/yaw motion, visible board separation and intact clothing. |
| [Recovered shove-it](04b-pop-shove-it-catch-close.png) | Shoes remain planted after the deck's half-turn; its persistent orientation has settled before the next action. |
| [Natural double flip](05b-natural-double-flip-chase.png), [bank](05c-double-flip-banked-chase.png) | An actual flat-ground Ollie → Heelflip → Kickflip shows 700 × 3 pending, then banks **2,100** once. |
| [Melon](06-melon-close.png), [Indy](07-indy-close.png), [Nose](08-nose-grab-close.png), [Tail](09-tail-grab-close.png) | Different hand sides/end targets and crouched contact poses. Some contacts remain partly body-occluded from this inspection angle. |
| [Nose Manual](10-nose-manual-close.png) | Opposite board pitch and balance posture with supported shoe contact. |
| [Rail Grind](11-rail-grind-close.png), [Boardslide](12-directional-slide-close.png) | Distinct supported truck/deck contact, perpendicular slide deck and planted feet with rider counter-rotation. |
| [Queued flip](13-combo-flip-phase-chase.png), [grab](14-combo-grab-phase-chase.png), [landing manual](15-linked-combo-manual-chase.png), [bank](16-banked-combo-chase.png) | Ordered air actions continue into an actual buffered landing manual; releasing it banks **3,000**. |
| [Trick guide](17-trick-guide-chase.png), [scrolled directory](18-trick-directory-chase.png) | All rule paragraphs wrap without ellipses. The directory exposes all nine direction rows and the Back control remains accessible. |

The reviewed samples support this bounded presentation check. Static samples
and scripted input do not establish continuous human animation quality,
commercial-game parity, enjoyment, Mac output, physical-controller comfort or
target-hardware performance. Those acceptance gates remain open. The capture
uses fixed 60 Hz simulation; its timings are not performance measurements.

The script stages outputs and verifies source stability before replacing this
receipt set. Superseded development runs remain only in ignored `.local/`
folders and are not current evidence.
