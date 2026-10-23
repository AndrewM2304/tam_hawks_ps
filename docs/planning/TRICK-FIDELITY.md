# Trick fidelity implementation — 23 October 2026

Current owner priority: polished original trick sets, connected combinations and
classic arcade skating functionality on the existing Glasgow map. This continues
the skating-first roadmap without adding districts or paid dependencies.
[ADR-014](../architecture/decisions/ADR-014-trick-fidelity.md) is the runtime
contract; [TRICK-FIDELITY verification](../testing/TRICK-FIDELITY.md) holds evidence.

| Existing task | Owner | Priority / milestone | Dependencies | Acceptance / verification |
|---|---|---|---|---|
| M02-001 | Catalog/input + root | P0 / M02 | ADR-006, reuse review | Complete directional vocabulary and validated pose metadata; neutral defaults, diagonals, opposite-axis cancellation, bounded flick memory and remapping work. Pure and live-action checks. |
| M01-004, M02-001 | Root + independent QE | P0 / M02 | Existing launch/landing rules | Fresh repeat flips, catch cooldown, ordered flip/grab queue, held/released grabs, forgiving completed catches and incomplete-flip bails work in actual physics. Two flips must fit ordinary flat ollie airtime. |
| M02-002 | Root + articulation + QE | P0 / M02 | Existing rail geometry/clearance | Nine distinguishable grinds/slides retain signed motion, balance, collision, rail-ID challenge events and capped duration scoring. Visible deck/truck contact meets the rail. |
| M02-003/004 | Root + QE | P0 / M02 | Existing manual/revert/link rules | Nose/tail manual polarity, deliberate 0.18-second landing buffer and release cancellation; no stale held entry, deadline extension or overtime entry. Real linked lines retain exact scoring. |
| M02-005/006 | Score/HUD + root | P0 / M02 | Actual entry/link signals | Stable repeat identity, bounded hold additions, entry counts, bank/drop receipts and pause/reset/overtime guards. Names/stance cannot farm variety. Both original specials retain unlock/meter gates. |
| M05-002 | Articulation + root | P0 / M05 | Catalog pose metadata | Bilateral grab contacts, feet lift/flick/catch, smooth odd-yaw shove catches, planted feet through later grabs/manuals and real rail support; native geometry checks plus actual renders. |
| M06-003/007 | HUD + QE | P0 / M06 | Catalog + score receipts | Remapped Trick Guide shows all directional choices; readable active balance, stance, repeat/hold and banking feedback; inspect actual small/large UI and gameplay frames. |
| M04-007/009/010 | Encounter review + QE | P0 / M04 | Expanded catalog | Existing Mo/Rae/Mairi challenges recognize new families and retain actual capture/order/bank/visible-payoff rules. No extra goals or free challenge points. |
| M02-008, M01-007 | Owner + QE | P0 / M02 | Verified playable source | Human Mac keyboard/DualSense comfort and continuous animation/feel review remain open. Automated Linux results cannot close these acceptance gates. |

Engineering and local verification proceed without routine approval requests.
Completion records live in STATUS and BACKLOG; completed source and bounded
automated/rendered evidence do not imply commercial-game parity or final art.
Full transition/vert/lip support (M02-011), wallrides (M02-012), skitch/traffic
assessment (M02-013), the charge/release ollie follow-up under M01-003 and
additional map/encounter work retain their separate contracts.
