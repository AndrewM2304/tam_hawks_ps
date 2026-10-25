# Personal Mac soundtrack — 25 October 2026

M05-008 / [ADR-014](../architecture/decisions/ADR-014-personal-mac-soundtrack.md). The implementation controls the installed Music app using its existing account. It does not use MusicKit credentials, bundle songs or change the user's Music volume. Original game audio and career persistence retain their existing behavior.

## Implemented behavior

- Explicit connection and a picker for personal and saved Apple Music subscription playlists, including a library containing only one playlist.
- Default [Tony Hawk Pro Skater by Alex Troyan](https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8), as explicitly chosen by the owner. Open the exact link in Music for one-time Add to Library, then resolve its unique saved-library title to a native playlist ID. Missing or duplicate names require setup/selection instead of playing another playlist.
- Separate remembered playlist and autoplay preferences. The owner-authorized default is enabled on a fresh normal Mac configuration; saved off/manual choices win. Actual gameplay entry starts the selected playlist; unrelated music does not suppress it. Restart and game pause preserve the current song/queue.
- Shuffle is enabled and checked before starting playlist playback. Music owns continuous playback, shuffle and repeat.
- Live Pause/results and Soundtrack cards show song, artist, album and available local artwork. Missing metadata does not disable skipping an actively playing stream. Unavailable artwork uses the original musical-note fallback.
- Off-thread Apple Events with two-second polling, a four-command queue, twelve-second Apple Event timeout and thirty-second hard process deadline. Metadata updates keep existing controls and focus.
- Denied Automation access, missing playlist/track data, stopped Music and unsupported platforms have readable states. Disconnect disables polling/autoplay and leaves Music playing.
- Script runners and non-persistent test games cannot launch/control Music or access saved soundtrack preferences.

## Merged-main evidence

Integration of `02065ae` with newer main `c046497` passes **4,910/0**, including58
soundtrack checks, with583 unchanged inputs and five refreshed merged-HUD fixtures.
[Current receipts/commands/source manifests](apple-music-main-merge/README.md)
preserve the exact result. Main/HUD caching, recorder, current gameplay and all newer
PT24 work are retained. Actual Mac Music playback remains unverified.

## Earlier feature-branch evidence (02065ae)

`GODOT_BIN="$PWD/.local/godot-fixed-60" ./tools/check.sh > .local/soundtrack-default-check.log 2>&1` exits **0** with **1,319 passed / 0 failed**, including **55** soundtrack assertions (29 backend, 21 UI, 5 Main integration). The local wrapper runs Godot with `--fixed-fps 60`, disabling wall-clock synchronization while retaining 1/60-second frames and time scale 1. [Full log](logs/soundtrack-check.log) and [tested-source receipt with exact wrapper contents](logs/soundtrack-source.json) retain commands/results/hashes. The earlier normal-clock **1,302/0** run predates the default-link addition and is [preserved separately](logs/soundtrack-generic-check.log). The focused tests exercise backend opt-in/queue/error/metadata/artwork handling, the real HUD/popup selection handler, and production Main signal forwarding/pause/restart using a player spy. All music data in those tests is synthetic; no account is accessed and no Music playback occurs.

`./tools/music_ui_capture.sh` renders five fixture images at 1920×1080 and 960×600 with 1.4× UI. The images show real UI output with explicitly fictional metadata and a generated artwork swatch. They establish layout, scrolling and focus, not actual Apple Music playback. [Capture files and source hashes](screenshots/apple-music/README.md).

The macOS export preset declares `NSAppleEventsUsageDescription` and Godot's Apple Events entitlement. XML/declaration validation is separate from an exported app launch. No native package or signed app was rebuilt during this slice.

## Target-Mac acceptance still open

1. Open **Soundtrack → Open default playlist in Music** and add the supplied **Tony Hawk Pro Skater by Alex Troyan** playlist once. Connect and grant Automation access. Verify its unique saved-library title is selected automatically; start skating to check default autoplay. Missing/duplicate names should request explicit setup/selection. Confirm personal and subscription playlists can also be selected manually, including the only playlist in a small library.
2. Select **Shuffle & play playlist**. Verify audible playback, shuffle/repeat in Music, current song/artist/album and available artwork after the next metadata poll. Add the songs to the Music library if streamed metadata is unavailable. Skip several tracks and leave playback running across a natural track boundary.
3. Pause skating and verify the song continues; use the menu's pause/resume and skip controls. Verify gameplay remains paused and controller focus remains on the active button during metadata changes. Restart the run and confirm the song does not restart.
4. Enable autoplay, close/reopen the game and enter a mode. Confirm playback starts the saved playlist. With unrelated music already playing, select a different playlist in the game and start skating; verify the selected playlist wins.
5. Deny Automation once, then allow it under **System Settings → Privacy & Security → Automation** for the host app and reconnect. Close Music while connected; verify the game remains responsive and reports the need to reconnect.
6. Disconnect, relaunch and start skating; verify no automatic Music control. Continue normal offline skating, game-audio mix and save/restart checks independently.

Linux cannot compile the Music application's AppleScript dictionary or establish macOS Automation/subscription/stream/artwork behavior. These are open Mac checks, not reported passes.
