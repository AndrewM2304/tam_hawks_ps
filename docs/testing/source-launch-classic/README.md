# Cold copied-source launch — classic controls

`python3 tools/source_launch_smoke.py` completed **exit 0** on 17 October 2026, **22:13:42–22:14:22 UTC**, against the corrected classic-tricks/HUD source. [SOURCE-LAUNCH.json](SOURCE-LAUNCH.json) records **208 unchanged inputs**, matching before/after fingerprints and all four accepted phases.

Cold and warm normal Main launches build cleanly. The actual title-branch wrapper passes **44/0**, including the ordinary controls/camera/support contracts. A deliberately invalid script in the disposable copy is refused with **exit 1**; that expected negative phase is accepted, and the copied Main file is restored. Every phase log and launcher import log is retained here; the invalid-source errors are intentional, not normal game errors.

Receipt SHA-256: `3bf0eda4de0c2305758f72ee82c1fd18e777369db8f4a58a9046430343aa9d18`.

This verifies cold-source import/launch behavior on Linux Godot 4.6.3. It does not certify a macOS export, physical DualSense, human skating feel or hardware frame times. Historical receipts in other folders apply to their own recorded sources.
