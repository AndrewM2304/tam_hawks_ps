# Rider refinement evidence — 17 October 2026

The rider now uses original skinned jacket/trouser meshes with continuous knee and elbow surfaces, shaped clothing, a shaped face, and a narrower deck with street-scale wheels. Native Godot `Skeleton3D`/`Skin` drives the clothing; the collision body and skating rules are unchanged. No external character model or animation was imported.

The pose helper blends push, foot-drag brake, coast, launch/tuck, landing compression, grab, flip, manual, revert and special poses. Shoes follow the deck except during deliberate flip/board-spin separation. The grab hand reaches the deck edge. Revert turns the gaze toward travel. The manual raises the deck around its supporting rear wheels; the special tumble rotates around a body-centre pivot. Deep-tuck inspection found open sleeve attachments, which were closed before these final captures.

## Reproduce

- Run `./tools/rider_capture.sh` for actual-input action captures in `.local/rider-capture/`. It creates 23 images: normal chase and close inspection views of 11 states, plus a face view. Close cameras freeze an already reached physical state; they do not inject poses.
- Run `./tools/rider_motion.sh` for `.local/rider-cleanup-motion.mp4`, with cut metadata in `.local/rider-motion-sequence.json`. The free local `ffmpeg` executable is required to encode it. Generated PNG frames remain in ignored `.local/rider-motion-frames/`.
- The scripts create and stop only their own temporary Xorg display when needed on this Linux image, use the project's writable local directories, and never access a player profile or network service. They have a 600-second execution bound when the platform supplies `timeout`.

Both runners use real production input, physics and gameplay state at a fixed 60 Hz, with rendering requested explicitly. All movement speed comes from ordinary push input. The two special demonstrations start with an explicit full-meter fixture in free skate. Resets between motion segments are deliberate cuts, not one continuous combo or a human playtest.

## Timing and captured states

The motion clip contains 222 frames at 30 fps, 1280×800, for **7.4 seconds of simulated normal-speed playback**. Rendering on software OpenGL takes longer than playback; the encoded frame rate is not measured game performance. The clip has no recorded audio.

| Start | Segment |
|---:|---|
| 0.000 s | Push, foot-drag brake, coast |
| 2.167 s | Ollie, grab, landing recovery |
| 3.367 s | Manual, ollie, flip, landing, revert |
| 5.133 s | Clyde Carousel, full-meter fixture |
| 6.267 s | Tenement Tumble, full-meter fixture |

Selected final stills in this directory show the normal chase view and the closer geometry/contact inspections. Full sets and logs remain local. Static images and the replay support animation review; they do not establish physical controller feel, a target-Mac frame rate, or owner approval.

Start with the [normal manual view](manual-chase.png), [rear-wheel contact](manual-close.png), [grab](grab-close.png), [flip separation](flip-close.png), [braking foot](brake-close.png) and [closed sleeves during the tumble](special_two-close.png).

## Geometry and contact checks

The rider/board contains **63 mesh instances**, 25,648 triangles across those instances, and 10 clothing bones. The two skinned garment meshes have 2,398 vertices; packed skin weights sum to one within 0.000016. Mesh-instance count is not a measured scene draw-call count, because shadows and other passes can add work.

A real push-to-manual probe on a flat collision floor measured the lowest rear-wheel vertex at Y=0.000252 m after the visual contact correction; reset restores the board origin to Y=0.12 m. A separate close-pose grab inspection measured a 0.00836 m hand-target gap after 0.2 seconds of pose blending. Focused manual/revert/special checks passed 39/39 after the last contact change. The takeoff suite passed 21/21 earlier in this pass; no movement code was edited. Aggregate current results belong in the main QE report.

## Remaining art limits

The character remains a stylized original procedural model. The clothing uses overlapping sealed attachment surfaces rather than an artist-retopologized unified body. Hands have no articulated fingers, facial animation and cloth simulation are absent, and specialized grind/bail animation still needs further work. Human evaluation of transition timing, silhouette, contact and final realistic finish remains open. These captures do not close M05/M06 visual acceptance.
