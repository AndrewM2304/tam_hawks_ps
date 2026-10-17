# Ordinary-play and presentation capture

Captured 17 October 2026 at 20:42 UTC from the real `game/main.tscn` title branch in Godot 4.6.3 using the Compatibility renderer (`llvmpipe`, 1280×800). The capture drives the production game with mapped input; profile writes were disabled. Its source-stable manifest records 19 rendered frames, zero capture failures, 300 natural push/turn samples, successful chase-camera framing, four repaired street closes, the park taper, Barrowland market and Clyde bridge. No source files changed during the capture.

The images are useful for reviewing the rider framing, current grass/water materials, compact HUD feedback, supported routes and landmark readability. They are software-rendered Linux evidence, not Mac/Apple GPU certification or final art acceptance. The owner should still replay the same source on Mac and judge actual skating feel and UI behavior.

Reproduce after preparing local imports with:

```sh
./tools/playability_capture.sh --private-display
```

The complete source-bound record is in [manifest.json](manifest.json). Manifest SHA-256: `f63cd1c720f9db9138314106fa9d0ed22532be6da04d92c535f4d6886e357238`.
