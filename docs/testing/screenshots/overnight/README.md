# Overnight implementation evidence

Reproduce with `tools/overnight_capture.sh --private-display`. The bounded tool runs the production Main scene with profile writes disabled, captures 28 real 1280×800 frames, checks gameplay state before each action capture, validates PNG checksums and complete pixel rows, and refuses publication if any game, test, or capture-tool source changes during the run. The exact engine, checks, source hashes, image hashes, camera positions, and gameplay observations are recorded in [manifest.json](manifest.json).

Fixture boundaries are explicit:

- The six district views use authored inspection cameras. They are aerial level reviews, not reachable player camera positions.
- Action pairs include the production chase camera and a separate close inspection camera. Physics freezes only after the action has produced the recorded state.
- The rail sequence starts from a documented descending position and velocity beside an existing authored rail; capture and style changes then use genuine input and native collision.
- The special sequence seeds the career unlock and full meter as fixture setup, then uses the mapped U input during an actual ollie. It does not claim that the fixture earned that unlock or charge.
- Crouch, charged pop, double flip, manual pivot, powerslide, wallride, curved riding, vert launch, and lip stall use real controls and production physics after a restart at their initial approach positions.

Review [Clyde practice](05-clyde-pocket.png), [park promenade](06-park-promenade.png), [wallride](14-wallride-chase.png), [curved contact](15-quarterpipe-close.png), [vert air](16-vert-air-close.png), and [lip stall](17-lip-stall-close.png). The two practice views show the supported deck/roll-in, concrete surfaces, neighboring features, flatbar feet, and boundary foundations.

These are Linux/Godot 4.6.3 captures using Mesa software OpenGL. Automated physics and rendered evidence remain distinct from human playtesting and target hardware acceptance; the procedural city and rider are not claimed as final release art.
