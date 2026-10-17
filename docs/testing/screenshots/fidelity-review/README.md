# Current board and rider inspection

17 October 2026, 21:35 UTC. `./tools/rider_capture.sh` completed exit 0 with `RIG ACTION CAPTURE errors=0 meshes=44 bones=10`, clean engine/script logs and 129 unchanged game/project/capture inputs. Godot 4.6.3 Compatibility rendered these actual 1280×800 frames on Linux/llvmpipe. The complete recipe exercises idle, push, brake, coast, grab, landing, flip, manual, revert and both specials. Six representative images and the log are retained here; [manifest.json](manifest.json) records input/artifact hashes and exact limits.

The original 5,696-triangle four-surface GLB board replaces 25 procedural mesh instances while preserving its local contact dimensions. [idle-feet.png](idle-feet.png) shows the shaped deck, trucks/wheels and current shoe contact; [grab-hand.png](grab-hand.png) checks the existing grab near the new deck. [flip-close.png](flip-close.png) exposes the underside. The ordinary chase view is also retained.

These are asset/pose inspections: close views use authored cameras, explicit render readbacks freeze between actions, and special poses use a full-meter fixture. They do not demonstrate human input comfort or frame rate. The garments, shoes, hand contact, textures and movement still need the realistic final-art pass in M05-001/M06-007; the board is one completed pipeline proof, not a final character acceptance.
