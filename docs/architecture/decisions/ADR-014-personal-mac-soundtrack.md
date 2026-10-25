# ADR-014 — Personal Apple Music soundtrack on macOS

Date: 25 October 2026. Status: accepted for implementation; Mac playback acceptance pending.

The owner requests a personal Mac soundtrack: choose a skate-punk playlist, play shuffled songs while skating, show artist/song/album/artwork in Pause, and skip songs. This extends the audio/UI scope without changing the skating roadmap or adding spending.

The owner subsequently supplies the exact default: [Tony Hawk Pro Skater by Alex Troyan](https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8), verified on the public Apple Music page on 25 October 2026 (60 songs). This instruction authorizes automatic playback of that default on gameplay entry. A fresh normal Mac configuration enables it; existing explicit off/selection preferences remain authoritative. The setup page opens this exact link for one-time Add to Library. Resolve its unique saved-library name to a local persistent ID; if missing or ambiguous, explain the required setup/selection rather than choosing another playlist. The public `pl.u-...` token is not a local Music persistent ID. Opening the web link alone does not establish a playback queue.

Use the installed Music app and its existing signed-in account through `/usr/bin/osascript`. The game offers an explicit connection, a library-playlist selector and remembered opt-in to playback when starting a session. Music keeps playing through the game pause and run restarts. Music owns the queue, playback and volume; its controls affect the user's Music session. A working Apple Music subscription is required for subscription tracks. Local playable library files can also be used.

This avoids native MusicKit/developer-token setup and extra dependencies. It does not embed a browser login, store Apple credentials, copy songs into the project or change Music's volume. Optional playback does not affect offline skating, career saves or original game effects/ambience. Game sound sliders continue to control the game's own audio; soundtrack volume is adjusted in Music.

Run Apple Events on a worker with a bounded command queue and periodic metadata polling. Gate external calls on macOS and explicit connection or authorized autoplay at gameplay start. The owner's exact default-playlist instruction supplies the first-run autoplay authorization; persisted choices still win. Scripted tests must not read/write real preferences or launch/control Music. Use separate argv fields for untrusted playlist identifiers; never interpolate them into shell or script source. Persist only soundtrack preferences in `user://soundtrack.cfg`.

Display metadata and artwork from the current Music track. Clear stale metadata and use an original fallback if it is unavailable. Some macOS versions cannot expose streamed tracks that are outside the library; add the chosen playlist's songs to the Music library for best results. Verify that Music accepts shuffle before claiming shuffled playback. An unavailable library, denied consent, missing playlist or failed playback must leave the game usable with a readable status.

The unsigned macOS export includes `NSAppleEventsUsageDescription`. The export preset also records Godot's Apple Events entitlement for any future signing configuration; no paid signing or notarization is enabled. The developer/editor host may be named in macOS's Automation prompt during source play. Automation access is managed under System Settings → Privacy & Security → Automation.

Linux tests cover the bridge's data handling, safe opt-in behavior and live menu controls using fixtures. They cannot establish AppleScript execution, subscription playback, shuffle behavior, artwork availability, macOS consent or controller comfort. Those remain explicit target-Mac acceptance steps in M05-008.

References inspected 25 October 2026:

- [Apple: Automation permissions](https://support.apple.com/guide/mac-help/mchl108e1718/mac).
- [Apple: NSAppleEventsUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription).
- [Apple DTS: Music scripting and non-library streaming tracks](https://developer.apple.com/forums/thread/798267).
- [Godot 4.6: macOS Apple Events entitlement](https://docs.godotengine.org/en/4.6/classes/class_editorexportplatformmacos.html#class-editorexportplatformmacos-property-codesign-entitlements-apple-events).
- [Godot 4.6: additional Info.plist content](https://docs.godotengine.org/en/4.6/classes/class_editorexportplatformmacos.html#class-editorexportplatformmacos-property-application-additional-plist-content).
