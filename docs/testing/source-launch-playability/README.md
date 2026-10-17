# Fresh-source launcher regression

17 October 2026, 19:22:10–19:22:33 UTC. `python3 tools/source_launch_smoke.py` completed exit 0. The helper copied exactly **174 game/test/project/launcher inputs** into an initially cache-free ignored project. No source or copied input changed.

The unchanged launcher command imports assets before ordinary Main starts. Cold and warm normal Main runs exit 0 with clean logs; the normal-scene wrapper starts through the actual paused title and passes **44/0**. A deliberate syntax failure is injected only into the disposable copy: the launcher exits **1** and refuses play before partially initialized actors can run. That negative phase intentionally contains parser errors, and the copied file is restored afterward.

[SOURCE-LAUNCH.json](SOURCE-LAUNCH.json) records command arrays, bounds, hashes, source inputs and all four phases. Receipt SHA-256: `acc6ca209b81e5c5485f8ea85a5277ebda49e2c8378eba8578818756f78da448`. The exact helper SHA is in that receipt. The [before reproduction](../logs/playability-cold-source-before.log) preserves the owner-matching missing class/OBJ/anatomy cascade from a cold source project launched without preparation.

These Linux headless/Dummy-audio checks prove the source-launch workflow and declared synthetic inputs. They do not prove a repaired Mac run, rendered framing, listening, performance or human skating feel. The normal-scene wrapper is separate from the unmodified Main cold/warm launches.
