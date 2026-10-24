# Clyde bowl excavation

Owner request24October2026: replace the standalone raised bowl/access ramp with
a bowl sunk into the surrounding level and integrated surface treatment.

| ID | Owner | Priority | Milestone | Dependencies | Status |
|---|---|---|---|---|---|
| BOWL-01 | Codex | P1 owner playtest | M03/M05 | Existing ClydeEastBowl and quay | Implemented; focused/native verified; whole-game acceptance open |

Acceptance: rim at quay Y2; bottom Y−0.4; remove the external roll-in and top
landing; excavate both displayed paving and native collision without disturbing
the Z124 through lane; ground/support queries agree with actual curved collision;
retain bowl/coping IDs; match the surrounding paving using existing materials.
Preserve ordinary skating physics and the other reported playtest defects.

Test strategy: independent native ray coverage of the pit/rim/surroundings,
production outside approach and carve regression, exact collision inventory,
required `tools/check.sh`, actual matched native before/after frames.

Budget declared before implementation: no added bodies, draw surfaces, materials
or textures; remove two access bodies; at most1024 added paving triangles from
startup-only clipping; no mesh rebuilding per frame. Constant-time exact faceted
bowl support query replaces the old flat height only inside this pit. Static
native p50/p95/p99, >33ms frames, draws/primitives/texture/video memory recorded;
uncontended moving performance and owner feel remain separate open gates.

This overlay preserves all75 original backlog ticket bodies. Other video repair
work remains in [the owner recording list](OWNER-PLAYTEST-2026-10-24.md).

Evidence: [captured comparison, exact commands and retained failures](../testing/clyde-sunken-bowl-2026-10-24/README.md).
Focused50/0; final required4521/20 and unchanged baseline4517/20 have identical
20 failure labels. Actual pit/rim support and a production entry/lap pass. No
whole-game/owner/performance acceptance is inferred from those bounded checks.
