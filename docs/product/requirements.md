# Release 1 requirements and traceability

The supplied plan is the source of product requirements; [vision](vision.md) states the current scope and [game design](game-design.md) supplies proposed details. The user's later no-money instruction overrides any implication that CI, assets or generated voices may be purchased. The task backlog covers all release requirements, including those beyond the source document's truncated M03 roadmap.

**Status legend:** Prototype = partial implementation under current M01 verification; Planned = release work not yet implemented; Gate = evidence requires human/hardware or a release decision. Exact present results are in [STATUS](../STATUS.md); this table is not an automated completion report.

| ID | Requirement and acceptance intent | Implementing tickets | Acceptance evidence | State |
|---|---|---|---|---|
| R01 | Original single-player arcade 3D skating game; responsive and forgiving rather than simulation physics | M01-002–M01-007, M02-008 | Movement tests plus owner controller feel review | Prototype / Gate |
| R02 | Godot 4.x implementation, pinned repeatable toolchain and maintainable system boundaries | M00-002–M00-004, M02-009–M02-010 | Engine version, import/start/test command and interface review | Prototype |
| R03 | macOS standalone app with Apple Silicon as primary target | M06-005, M07-003 | Real exported app launch, offline play and save persistence on Mac | Planned / Gate |
| R04 | Target 60 fps at 1080p on a declared Apple Silicon baseline | M06-004, M06-006 | Representative ten-minute route, frame-time report and hardware details | Planned / Gate |
| R05 | DualSense-first controls and complete keyboard fallback | M01-001, M01-007, M06-001 | Action tests, physical wired/Bluetooth controller session, keyboard navigation | Prototype / Gate |
| R06 | Ollie, flip tricks and grabs | M01-003, M01-004, M02-001, M05-002 | Eligibility/edge tests, original visible animation, controller timing review | Prototype |
| R07 | Spins with consistent rotation awards | M01-004, M02-006 | Rotation threshold/direction tests and readable landing feedback | Prototype / Planned |
| R08 | Grinds, manuals and reverts with forgiving deliberate transitions | M02-002–M02-004, M02-010 | State/window/balance tests and continuous controller line | Planned |
| R09 | Combo scoring, multipliers, repeated-trick degradation and bail loss | M01-006, M02-005, M02-008 | Deterministic score sequences, exploit checks and owner combo flow review | Prototype / Planned |
| R10 | Special tricks and named gaps | M02-006, M02-007, M03-005 | Special-meter tests, gap traversal tests and authored world routes | Planned |
| R11 | Two-minute career runs and free skate | M01-006, M04-001 | Timer/pause/restart/timeout/mode integration tests and complete mode play | Prototype / Planned |
| R12 | Ten distinct objectives including three score tiers | M04-002, M04-003, M04-006 | All ten goals completed via actual play, negative cases and tuning evidence | Planned |
| R13 | Unlocks, personal records, goal completion and local saves | M04-004, M04-005 | Versioned persistence/recovery tests and relaunch on macOS | Planned |
| R14 | One connected Glasgow-inspired level with four distinct districts | M03-001–M03-005 | Whole-level circuit, district captures, collision and route review | Planned |
| R15 | Dense skateable routes, shortcuts, hidden areas and secrets | M03-005, M04-003 | Reference lines, secret access/exit and discoverability playtest | Planned |
| R16 | Secret recording collectible and interactive environmental events, including cone interaction | M03-001, M03-004, M04-003 | Actual event/collectible activation and eligible goal/save effects | Planned |
| R17 | Ambient characters with short voiced reactions | M05-004, M05-005 | NPC placement/trigger tests, captions, voice rights and listening review | Planned; free source unresolved |
| R18 | Skating SFX and district ambience | M05-003, M05-005 | Reproducible local sound source, event tests and listening pass | Planned |
| R19 | Menus, readable HUD, trick feedback, goal list and results | M01-006, M02-008, M06-002 | Captured frames, state transitions and controller/keyboard screen traversal | Prototype / Planned |
| R20 | Immediate replay with fast restart and safe pause | M01-006, M04-001, M06-002 | Repeat restart/pause boundary tests and player-observed flow | Prototype |
| R21 | Original assets, names, humour and audio; no copied franchise content | M00-005, M05-001–M05-005, M07-002 | Provenance register, package audit and title/licence decisions | Ongoing / Gate |
| R22 | Independently editable/testable game, world, missions and content | M00-003, M00-004, M04-002 | API/data validation and independent module/QE review | Prototype / Planned |
| R23 | Readable captions, audio controls, input options and camera comfort | M06-001, M06-003 | Settings tests and target-display/controller review | Planned |
| R24 | Full local tickets, durable decisions and continuation after credits end | M00-001, M00-006, M07-004 | Complete backlog fields, source preservation and actionable STATUS/resume record | In progress |
| R25 | Zero additional spend: no purchases, paid APIs, billing, hosted compute or unattended loops | M00-005; applies to every ticket | Tool/dependency/workflow review; no paid service provisioned | Required throughout |
| R26 | Independent QE and evidence-based milestone/release decisions | M01-007, M02-008, M03-005, M04-006, M06-006, M07-001, M07-005 | Recorded automated results, real screenshots and human/hardware gates | Required throughout |

The owner also explicitly authorizes free compatible reuse. Inspect existing implementations before writing substantial new generic systems; follow ADR-004 and the source/asset provenance register.

**Owner visual requirements:** the correct title is Tam Hawks Pro Skater. Final presentation must replace blockout with believable realistic-but-fun environments/characters and polished UI; recognise real Glasgow shops and street edges through verified references. M03-006/M03-007 implement reference/boundary work, M05-001/M05-002 and M06-002 deliver detailed art/UI, and required M06-007 signs off the final cleanup after core gameplay. These are release requirements, not optional polish.

## Explicit exclusions

Online multiplayer, realistic simulation physics, open-world mission structures, character creation, complex dialogue and additional cities are outside Release 1. A large connected arcade level does not imply a streaming open-world game. Neither online accounts nor a server backend are needed.

## Scope and completion rules

A prototype object, label or timer is not proof that its eventual release feature exists. A square with Glasgow signs does not satisfy R14; aerial landing scores do not satisfy all of R08–R10; a paused HUD does not establish complete menus/accessibility. The current status must state those distinctions.

The voice requirement is retained despite the ban on paid generation. Local synthetic skating sounds do not satisfy voiced NPC reactions. M05-004 must establish a lawful free source or record an owner-approved scope change. Hardware and subjective enjoyment gates cannot be marked passed by software tests. Any accepted release exception must link to the owner's decision and an ADR rather than disappearing from this table.
