# Source-launch repair native gate

Exact pushed gameplay source `7e7a178` plus only the four launcher/protocol files listed in `launcher-pins.json` passed all four native phases. The cold phase starts with no imported cache; ordinary title-to-play reports **50 passed, zero failed**. Warm launch succeeds and a deliberate copied parse error refuses play. All copied source bytes/modes remain unchanged; injected source is restored. Native Linux Godot4.6.3 was exercised, not the owner's Mac.

The original pushed-source cold diagnostic took129.183s with only the preparing message visible; see the sibling `pushed-7e-cold` packet. The repair streams current import progress, gives30-second notices, bounds import to300s (configurable1–3600), and stops the importer process group on timeout/cancellation. Actual Mac-specific stall cause remains pending the owner's log; a Mac launch is not claimed.

Public launcher protocol tests pass8/8 using an explicitly fake editor; independent protocol22/0 additionally checks cancellation and worker cleanup. These verify shell behaviour, not skating or Godot rendering. The sibling independent packet preserves earlier findings and their corrected exact sources. Existing wider-game failures and fidelity work remain separate.

Raw native/import logs are losslessly compressed; SOURCE-LAUNCH.json retains exact phase counts, timestamps, hashes and all source inputs. The four before-bound launcher files are retained verbatim.
