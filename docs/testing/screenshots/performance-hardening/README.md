# Graphics choices and Settings resize

18 October 2026 (Europe/London). Eight actual Godot4.6.3 Compatibility images from the production Main/chase, fixed clock and software renderer. `source.json` verifies284 recorded game/test/tool/project inputs stayed unchanged and match runtime `8a975b2c0e0bce5ffbc212c91368d659e6f8b30d`. Recipe and log report zero errors; each PNG passed CRC and full row decoding. These are presentation checks, not frame-time or Mac acceptance.

`settings-balanced` uses the actual pause→Settings GUI. Native clicks cycle High→Performance→Balanced. Native End input moves Interface size to1.4; Graphics is focused before both window/content size shrink to960×540. The final `settings-small-large-ui` shows its full focus border with3.36px clearance inside the scroll clip. The first headless-only fix left a0.00003px boundary overlap in real rendering; four logical pixels of reveal padding fixed the actual border instead of relaxing the assertion. No page rebuild or per-frame deferred work is introduced.

The six spawn/park views use declared supported initial fixtures and the production chase: High/Balanced/Performance at1280×800. All retain220m skyline range. Performance uses0.75 3D resolution, noMSAA and30m shadows; its softer scene is deliberate while UI stays native. Root inspected all six chase views plus both UI states. This does not prove every terrain view or human temporal comfort.

`rejected-short-range/` retains the150m candidate: its GUI/body assertions passed, but visual review caught CityHall's facade clipped away while its dome floated. That image is explicitly rejected, never final preset evidence. Source hashes/recipe and disposition retain the failure. Native occlusion's separate missing-wall rejection is in `../../performance-static-20261017/README.md`.

Reproduce with `./tools/performance_capture.sh` on a graphical desktop; Linux starts the existing local private display if needed. No purchases, installs, profile saves or runtime service.
