# Apple Music menu layout fixtures — 25 October 2026

`python3 docs/testing/horizon-background/observers/run_checked.py .local/soundtrack-main-ui ./tools/music_ui_capture.sh` exits **0** and produces **five actual rendered frames / zero failures**. Captures use the merged current-main HUD at 1.4× interface size, with 1920×1080 and 960×600 pause/setup layouts plus a small unsupported-platform layout.

The setup page identifies the real owner-chosen default, **Tony Hawk Pro Skater by Alex Troyan**, with a button for the exact supplied URL. The playing song, artist, album and artwork swatch are explicitly synthetic fixtures. No Apple Music account was connected, no music played and no profile was written. The setup page identifies this fixture; the pause card names fictional metadata. These PNGs prove UI layout, scrolling and settled focus, not AppleScript execution, subscription playback or Mac permissions.

- [Small pause card](pause-960-large-fixture.png)
- [Small setup page](setup-960-large-fixture.png)
- [Large pause card](pause-1080-large-fixture.png)
- [Large setup page](setup-1080-large-fixture.png)
- [Unsupported platform](unsupported-960-large-fixture.png)

[manifest.json](manifest.json) binds the production HUD, route-map dependency, capture script/wrapper and project settings to the generated images. Renderer: Linux Compatibility / Mesa llvmpipe; not a Mac GPU, listening or frame-rate result. [Feature evidence and remaining Mac checks](../../APPLE-MUSIC.md).

[Current merged-main UI receipt/log and all583 input hashes](../../apple-music-main-merge/README.md) certify these refreshed images. The original branch captures/logs are historical.
