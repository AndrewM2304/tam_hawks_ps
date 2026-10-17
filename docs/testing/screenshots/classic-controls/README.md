# Actual Controls menu capture

17 October 2026, Godot 4.6.3 Compatibility/llvmpipe, Linux. `./tools/classic_controls_capture.sh` completed with **three rendered views / zero errors**, using the real Main free-skate → pause → focused Controls button and actual mouse click. No profile writes.

[Normal top](controls-1280-top.png) is 1280×800 at 1.0×. [Small top](controls-960-large-top.png) and [scrolled bottom](controls-960-large-bottom.png) are 960×540 at 1.4×. Native wheel events reach Restore defaults, and Back accepts native GUI focus. All 19 actual binding buttons exist; the bottom screenshot is a scrolled list rather than a compressed substitute layout.

The first inspection found real truncation: help reported five wrapped lines but only one visible, with an ellipsis. The production help now uses `OVERRUN_NO_TRIMMING`. This accepted rerun checks all five visible lines, dialog bounds, separation from binding rows, Restore visibility and a reachable fixed Back button. Root inspected the corrected small-screen image; the default and bottom images use the same checked contract.

[recipe.json](recipe.json) contains geometry, full help text, native UI state and four recorded input hashes, which match the committed checkout. [manifest.json](manifest.json) contains artifact hashes. These are fixed-clock GUI/capture checks, not target-Mac frame times or physical controller navigation acceptance.
