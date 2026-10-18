# Independent QE review

18 October 2026. A09 (`clyde_qe`), read-only review of pushed core source db2b28e and native-05 before ordinary-02 completed. No engines, file edits or Git mutations by this reviewer.

The reviewer independently verified all four strict p95/p99 calculations, 480 intervals, 26 PNG hashes, 34 world checks, 375 before/after hashes, and agreement between current non-.local source and the capture inventory. Supported poses, FOV/far and actual manual/menu images agree with the stated behavior. No confirmed new blocker or material README overstatement was found.

River-west p95 has only about 1.37 ms headroom. The per-view software-renderer wording is required; these results do not establish general FPS improvement. Completion still needs the clean required ordinary-02 receipt and final source/artifact audit. The rejected first full run remains 2,182/1, and overlapping focused counts must not be summed.

The reviewer confirmed the single manual-bail input correction preserves the prior outward correction from positive balance, 65 ticks, exact one-bail/previous-bank/no-combo assertion, action cleanup and next fixture reset. No production change or assertion tolerance was needed.

Unverified pre-existing follow-up: release of held Ollie during pause may leave `_ollie_held` stale because release is polled during physics. This was not reproduced and is not a confirmed defect or blocker. Investigate with real pause/input events under PLAY-07 before changing behavior; the current manual-specific pause regression does not certify every held action. Physical controller, Mac performance, continuous flicker, future ramp/grind review and full horizon admission remain open.
