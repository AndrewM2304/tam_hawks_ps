# Current-main static baseline

Source: `0b620358767c9c647dde66945377d99702c85d0b`, isolated `git archive` of game/tests/tools/project. Capture UTC:6 November 2026 approximately 23:26:23–23:27:54, from observed inventory/receipt write times, not a performance measurement. This is clean-main BEFORE specialist candidates; the old alpha checkout is not its source.

Result: **17 original 1280×800PNGs,61 checks/0 failures,engine exit 0,source stable**. Independent Pillow RGBA8 decode hashes match all 17native buffers. [receipt](receipt.json), [snapshot](snapshot.json), [before](source-before.json), [after](source-after.json), [log](engine.log). Receipt SHA256: `0a417e39cb41d063c3d40f3c26f47c5e9644a4eb906556cdfad4923293056e0b`.

The exact [observer](capture-sources/snapshot.gd.txt) extends `tools/full_fidelity_capture.gd` with natural `frame_post_draw`, same logical-frame fence, native RGBA8 hashes and projected-marker/current-Canvas proofs. Exact [runner](capture-sources/capture.py.txt) creates private Xorg and rejects source/script failures. Restore these files to `.local/qa-fidelity/snapshot.gd` and `capture.py` in archived source, import once, then:

```sh
python3 .local/qa-fidelity/capture.py main-before gl_compatibility
```

Output is `.local/qa-fidelity/main-before`; existing output is refused. Disposable archived production remains ignored under `.local/qa-fidelity/baseline-source`, not duplicated here. Inventories establish exact executed inputs; Git discovery from the parent checkout makes the receipt HEAD contextual. Preserve this packet when capturing a candidate.

Godot 4.6.3; Compatibility/OpenGL 4.5; Mesa 25.0.7 llvmpipe LLVM 19.1.7; Linux; dummy audio; private 1280×800 Xorg; fixed 60 Hz; four software-render threads. One expected warning says V-Sync switching is unsupported; no engine/script errors. No real-time, M5, controller, natural-line, animation or AAA acceptance follows.

- `ordinary-spawn.png`: actual Main after 40 settle ticks, no pose/camera assignment.
- `overview_*.png`: 7 authored district/facility cameras, native movement frozen.
- `synchronization/*.png`: 3 diagnostic cameras/Canvas changes and actual head/board markers, not gameplay.
- `rider-front/side/rear.png`: authored 3.3 m camera, actual startup idle pose, movement frozen.
- Shopfront/quay frames: authored environment views, no movement/trick proof.

Normal trial content remains enabled; persistence and personal Music control disabled and checked. The independent [review/defects](../../FIDELITY-REVIEW.md) separates visible shortcomings from capture integrity. Candidate runner metadata has since improved; its archived baseline text remains exact.
