# Full-fidelity native motion evidence

Final source-bound capture is pending. The files in this directory must not be
treated as a completed render receipt until `manifest.json` and the exact clean
capture result are present. The independent [completeness matrix](COMPLETENESS.md)
tracks the full request, including open human and hardware acceptance.

Run `./tools/full_fidelity_capture.sh --private-display` with installed Godot
4.6.3, FFmpeg and a rendering display. This is bounded local work; it downloads
nothing, writes no player profile and uses no hosted service. The wrapper refuses
publication after a failed assertion, runtime error, missing catalog clip, changed
source input, corrupt PNG or video that fails full decoding.

The capture runs the same production Main integration tests as the ordinary
suite, with a read-only observer after every genuine physics/process step. The
timeline retains all 60 Hz native observations, actual held action strengths,
body/deck/limb markers, current identities, support state and earned score. The
movies sample each fourth step at 15 fps. Paused sequences intentionally retain
repeated frozen poses. Fixed logical time is simulation evidence, not a rendering
performance or target-machine benchmark. The capture uses the Dummy audio driver;
these movies are silent and do not certify sound or listening quality.

Each clip has a fully decoded MP4 and lossless first/middle/last review frames.
Setup clips also retain a contact frame near phase 0.65. Every original lossless
source PNG has a manifest hash; those raw PNGs remain in the ignored staging
directory printed by the wrapper. The distributed H.264 movies are lossy and
cannot reconstruct those PNGs byte for byte. The manifest records hashes of all
game/test/tool inputs and verifies them unchanged through capture and encoding.
Its base Git commit may precede an integrated source commit; the input hashes
identify the actual rendered source.

`all-phases.mp4` joins those same clips, without re-encoding, with a seekable
chapter for every phase. It is an inspection reel of declared separate fixtures
and routes; the chapter boundaries do not represent one unbroken skating run.
The complete reel is also decoded and checked against every source frame count.

Camera and fixture boundaries are deliberate:

- Six aerial views are authored district inspection cameras. Native ground,
  bowl/halfpipe/spine, wall, gate, cone, cart and park routes use the production
  chase camera. Contact/trick/recovery close views use a declared camera bounded
  around the actual head, board, feet and hands. Neither camera substitutes for
  player movement or scores.
- Boneless and No Comply begin from actual floor support and complete their real
  planted-foot preparation before launch. Grab selection clips use real ordinary
  ground Ollies. The unsupported-plant controls use an explicit narrow native
  platform above the existing floor and compare the resulting launch with an
  ordinary Ollie charged for exactly the same time.
- All 24 flip stages and six special command clips use explicitly declared
  elevated initial air fixtures. Special eligibility is explicitly seeded with
  existing unlock IDs and a full meter; real directional input, controller motion,
  animation, landing and bank follow. These clips do not prove earning a special
  meter; separate live-meter integration tests cover that behavior.
- Directional grind clips and the rail pivot declare their initial descending
  rail position/motion. Production collision admits the actual capture; held
  input, style, exit, native landing and once-only score are subsequently real.
- The bowl includes both an actual outside roll-in and a separately declared
  curved-contact/tangent initial fixture for the full lap. Halfpipe return and
  spine transfer use actual ground approaches and fresh input.
- Recovery follows actual unfinished landings or native obstructions. The high
  wall fall uses declared temporary native wall/obstruction geometry and an
  initial airborne pose. A separate native two-floor 20° valley fixture proves
  continuous local recovery with distinct support normals. Real paused standing-
  clearance probes add/remove native diagnostic sidewall and ceiling shapes. The results-fade case explicitly sets
  the run timer near expiry; it does not seed a bail or score.
- Gate opening, full-hull cone/ring/raft contact, moving-cart catch/tow/release,
  both park laps and district manual routes use genuine native input/movement
  after their documented restart placement. Park drivers steer and throttle
  through input; they do not assign heading, speed or position during a route.

Automated execution and selected-frame review do not certify physical DualSense,
macOS/Apple Silicon performance, listening, human difficulty/fun or final art
acceptance. Those remain specific acceptance tasks; they do not excuse missing
independent implementation, regression or render work.
