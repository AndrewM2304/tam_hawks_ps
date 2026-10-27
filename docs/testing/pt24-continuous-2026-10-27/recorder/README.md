# PT24-29 displayed recorder alignment

**35 passed / 0 failed**, actual native displayed witness, exit 0 and clean log
with 655 unchanged inputs in 36.711 seconds. This result owns its exact retained
source epoch over pushed `cd661ca`; root owns later combined batch admission.
[Native receipt](executions/native/receipt.json) binds source manifest
`1095227221af343f1753ecc4c54d30e183720edfa727fb87a04e7585964880cc`.
[Parser-only receipt](executions/parser/receipt.json) is clean, exit 0 on 654
stable inputs in 1.057 seconds; it contains zero native assertions.

The ignored observer uses ordinary Main, default enabled content and the normal
chase camera/HUD. Persistence is disabled before tree entry; personal Music
control, persistence and worker remain disabled. Six genuine Push updates precede
the production recorder's normal `1` key capture. One capture starts from live
play, the other from the ordinary pause menu. No actor pose, velocity, trick,
camera override or manual renderer draw substitutes for ordinary play.

An independent completed-draw callback connects before the production recorder
waits for its capture draw. While the recorder is busy it reads that actual
viewport image and constructs the current interpolated player/visual/rider/
board/head/feet/hands/camera transforms directly. Drawn/process/physics frame IDs,
raw frozen actor state, timestamps, pause/overlay state and canonical RGBA pixel
hash bind the production PNG/JSON to the same completed draw. The original
recorder outputs and two independent same-draw PNGs are retained. Normal note
save, state restore, completed manifest and independently readable ZIP complete
the bounded witness. Existing synthetic retry/input tests remain distinct;
this does not certify physical DualSense editing, Mac execution or target timing.

Both production PNGs exactly match their independently read completed-draw
pixels. Exact JSON presentation transforms match the independent same-draw
player, visual, rider, board, head, both feet, both hands and camera. Both raw
physical snapshots match the frozen actor; note/pause overlays are absent in
the actual PNGs. Visual inspection confirms normal chase framing, a complete
rider, unchanged gameplay HUD and the separate upper-right recorder badge.

| Capture | Original state | Raw physics / last player tick | Requested / completed process | Completed draw | Request / sample / PNG-read ms |
| --- | --- | --- | --- | --- | --- |
| [Issue1 PNG](session/issue-0001.png) / [JSON](session/issue-0001.json) | Live | 22 / 22 | 21 / 21 | 21 | 32119 / 32673 / 32679 |
| [Issue2 PNG](session/issue-0002.png) / [JSON](session/issue-0002.json) | Paused | 24 / 22 | 23 / 23 | 23 | 34158 / 34772 / 34777 |

The engine's global physics counter advances while gameplay is paused; the last
player update remains tick22. The report preserves both rather than forcing
them equal. Requested/completed process IDs may agree because the deferred
capture begins before that process signal; completed native draw and ordered
readback timestamps independently establish image alignment. No artificial
minimum frame increment is imposed.

The [completed session ZIP](session.zip) contains eight files, passes an
independent Python ZIP CRC check and preserves both final notes and PNG/JSON
pairs. The [raw native manifest](manifest.json) retains independent pixel hashes,
draw metadata and exact original local paths. The [artifact manifest](MANIFEST.json)
binds raw outputs and execution records. Each execution's `SNAPSHOTS.json`
resolves all inputs: parser643 immutable parent files plus11 exact snapshots;
native643 plus12. The wrapper is the extra native input. No production recorder
code changed and no earlier failed renderer attempt was substituted.

Reproduction, only after root freezes source and grants the engine lease:

```sh
python3 docs/testing/pt24-continuous-2026-10-27/recorder/observers/prepare.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/recorder-display-parser timeout 15s ./tools/run.sh --headless --audio-driver Dummy --check-only --script .local/recorder_display_witness.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/recorder-display-native bash .local/recorder_display_witness.sh .local/recorder_display_witness.gd
```

The second ignored-script argument binds both native producer inputs into the
outer source map. The native wrapper grants at most 100 seconds and uses the
existing local Xorg dummy display with software rendering. This environment
requires execution network permission for Xorg's local display socket; no
external service is contacted.
