# Local original audio — Tam Hawks Pro Skater

## Scope and integration

`game/audio/skate_audio.gd` synthesizes and caches original mono 22,050 Hz PCM for stone/asphalt/metal wheel contact, a continuous grind, ollie, landing, grind entry, bail, bank and UI feedback. Four quiet abstract city beds distinguish Exchange, George Square, Central Station and Barras. They are synthesized sound design, not field recordings or sampled people.

The node has the following integration contract:

| Method / signal | Contract |
|---|---|
| `set_mix(sfx, ambience)` | Independently clamp finite levels to 0–1; mute affects active players immediately |
| `set_motion(speed, grounded, grinding, district)` | Smooth wheel/grind gains, change pitch with speed, crossfade district ambience; use actual contact and grind state |
| `set_surface("stone" / "asphalt" / "metal")` | Production floor-contact selection; unknown values use stone |
| `play_event(id) -> bool` | `ollie`, `landing`, `grind`, `bail`, `bank`, `ui`; true means admitted, false means invalid, muted, paused, debounced or over the bounded pool |
| `set_paused(bool)` | Pause gameplay/ambient loops, discard current impacts; UI feedback remains usable |
| `play_bark(id) -> bool` | Original NPC lines `landing`, `cone`, `again`; one voice, shared and per-line cooldowns, no gameplay effect |
| `caption(text: String)` | Emit the exact spoken line when a bark is admitted, including when audio is muted |

Root owns connecting the actual movement/trick/score events. Emit bank only when points are committed, not every score preview; emit landing once on contact and grind only on rail acquisition. Supply stationary contact at rest and stop/pause audio at results. Root owns nearby-NPC triggers and visible captions. The audio component alone does not implement NPC proximity or prove captions are displayed.

Sound effects use three bounded one-shot players plus a separate UI player, contact loops and two ambience crossfade players. Same-event cooldowns suppress spam. Low waveform peaks and conservative channel gains provide mix headroom; this is not a perceptual loudness certification. Dummy audio runs retain PCM generation and event/mix state but skip inaudible mixer playback, avoiding unnecessary audio-server work in automated tests.

## Original procedural provenance

The PCM generator and event orchestration are original project code in `game/audio/skate_audio.gd`. Inputs are deterministic seeded noise, sine oscillators and envelopes; no third-party samples, recorded music or downloaded assets are used. Synthesis occurs once per process and cached resources are shared. No engine plug-in, runtime network or paid service is required. The code is the reproducible source; generated effect WAV files do not need to be committed.

## Free local speech provenance and production decision

Research on 17 October 2026 found no installed `espeak`, `espeak-ng`, `festival`, `flite`, `piper` or macOS `say` executable. The machine already provides Debian **libflite1 2.2-7**, including the built-in **cmu_us_kal16** diphone voice and the US English language/lexicon libraries. Generation calls those installed C libraries locally through Python `ctypes`; no library, voice model or binary is downloaded or installed.

Before generating speech, the installed package copyright and upstream source/licence were inspected. Upstream reference: [festvox/flite v2.2](https://github.com/festvox/flite/tree/e9e2e37c329dbe98bfeb27a1828ef9a71fa84f88), commit `e9e2e37c329dbe98bfeb27a1828ef9a71fa84f88`. `COPYING` grants unrestricted use/modification/redistribution subject to retaining notices, marking modifications and avoiding endorsement. It applies to distributed files except listed alternatives; the bundled `lang/cmu_us_kal16` voice is included under this grant, and its registration source carries the CMU notice explicitly. The inspected voice/data terms impose no separate restriction on generated speech. This is a reviewed licensed built-in synthetic voice, with no attempt to imitate a named person or a Glasgow accent.

Full upstream and installed-package notices are retained in `docs/licences/third-party/flite-COPYING.txt` and `flite-debian-copyright.txt`, plus the original voice notice in `flite-kal16-LICENSE.txt`. Licence text whitespace is normalized only. Retain those notices with distributed generated barks. No Flite runtime code/library is bundled in the game; the output is ordinary WAV audio. The project-authored modifications are the original text, peak normalization and short endpoint fades, recorded by the generation script.

| Bark ID | Original text | Intended trigger |
|---|---|---|
| `landing` | Some landing. | Successful landing near an ambient observer |
| `cone` | Mind the cone. | Approach to the cone monument |
| `again` | One more run. | A nearby observer's occasional encouragement |

These lines deliberately avoid third-party dialogue and impersonation. Initial pronunciation, timing, tone and suitability require a human listening review; their synthetic timbre is not a claim of finished voice acting.

`python3 tools/generate_voice.py` verifies the pinned local library hashes, creates three bounded clips under `game/audio/generated/`, and writes `manifest.json` with transcripts, source/library/output hashes and processing details. The script uses no network. A different installed library fails the pin check and requires a new source/licence/provenance review; never silently change the expected hashes. Playback on macOS uses the committed WAV files and requires neither Python nor Flite.

## Validation and remaining gates

`tests/audio_tests.gd` attaches real Godot audio nodes and audits generated PCM, finite levels, silence at rest/airborne, speed/pitch changes, surface selection, grind transitions, event debouncing, bounded players, pause/menu behavior, crossfades and immediate muting. Dummy output verifies those data/state contracts without claiming audible playback. Root includes this suite in `tools/check.sh`.

Focused check: Godot 4.6.3, `--headless --audio-driver Dummy`, **75 assertions passed, 0 failed**, exit 0 (61 procedural/state checks plus 14 speech/caption checks). Three generated barks total 3.34 seconds of mono 16 kHz audio, each peak-normalized below 0.55 full scale; exact output hashes and durations are in `game/audio/generated/manifest.json`. No human listening or target-Mac audio test has run. The complete integrated game suite is recorded in STATUS when root integration is validated.

Required listening route: from rest push across stone, asphalt and metal, ollie/land, enter/leave a long grind, deliberately bail, bank a combo, pause/restart repeatedly, then traverse all four districts. Listen for clicks, excessive repetition, clipping, harsh grind/roll fatigue, audible district transitions, correct mute controls and speech intelligibility under skating SFX. Check speakers and headphones at a sensible device volume. Confirm each admitted NPC bark has a matching visible caption, remains understandable with audio muted, and cannot overlap or spam. Record hardware, build, levels, defects and actual listener feedback before closing M05 audio/voice acceptance.

## Contact and completion integration

Main now selects wheel surfaces from actual upward collision contacts: connector asphalt, painted-metal ramps and stone fallback. Grinds retain their separate loop. Restart resets the surface, and a completed run near an NPC can play the cooldown-protected “again” reaction. `tests/presentation_integration_tests.gd` verifies real square, street and ramp contact and player-facing feedback; the audio suite retains waveform/state checks. These automated checks do not replace listening.


## Bin-drum busking correction — 17 October 2026

`game/characters/bin_percussion.gd` generates a separate original eight-second, 120 BPM mono 22,050 Hz/16-bit PCM loop. Sine sweeps, inharmonic container resonances and deterministic filtered noise supply kick, tub, snare and hat sounds. No article/video soundtrack, melody, sample or recording is imported. The source generator is the reproducible asset.

`main.apply_settings` forwards master and ambience volumes to `cat_encounter.set_mix`; the actor owns one bounded spatial player. Pause freezes its animation/playback, run end disables it, settings changes cannot re-enable a finished run, and run reset restores eligibility. Reduced motion holds the drummer and fabric-cat poses still. Independent cat tests inspect PCM format, duration, peak/energy/seam, finite mix clamping, mute, settings forwarding and lifecycle state; the Dummy driver does not provide audible playback evidence. Current counts and rendered evidence belong in STATUS/QE after the final source pass. Human listening, instrument mix, local tone and target-device audio remain open.
