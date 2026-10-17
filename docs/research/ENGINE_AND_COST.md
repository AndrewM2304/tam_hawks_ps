# Engine and zero-cost research record

Date: 17 October 2026. This records the current choices and remaining investigations, not an assertion that every target platform has been tested.

## Chosen foundation

The supplied plan selects Godot 4.x and Apple Silicon/macOS. The implementation pins Godot 4.6.3, GDScript and the Compatibility renderer. This reduces external dependency and graphics requirements for a first procedural prototype. The shared API and install scripts are the authoritative implementation details. This environment already supplies Godot 4.6.3; `tools/setup.sh` verifies it and runs checks. No engine dependency was downloaded in the initial session and no artifact checksum validation is claimed. The executable version and command results belong in `docs/STATUS.md`. If an engine is missing on a future machine, obtain the pinned free editor from the official archive and verify the official download normally.

Godot's engine is MIT licensed. Official reference entry points are [Godot documentation](https://docs.godotengine.org/), [download archive](https://godotengine.org/download/archive/) and [licence](https://godotengine.org/license/). These are research references; this document does not imply a fresh external page inspection or a successful platform test. Use authoritative release checksums and keep TLS/signature verification intact.

## Options assessed for the first session

| Option | Decision | Reason / next evidence |
|---|---|---|
| Native GDScript controller | Current playable reference | Uses Godot's engine facilities; compare reusable components before further infrastructure work |
| Existing skating implementations | Selective reuse adopted | [Research](SKATING_REUSE.md) inspected four projects. One MIT rail helper adapted and tested; broader controller/trick patterns inform M02. No entire external game imported. |
| Procedural primitive art | Use | Original, reproducible and sufficient to evaluate geometry/feel |
| Purchased/free-download asset packs | Defer | Purchases prohibited; free downloads still require asset-level provenance review |
| Local synthetic SFX | Implemented original deterministic PCM | Reproducible source, no paid API, no copied recordings |
| Cloud voice generation | Prohibited under current budget | Paid services and billing are not authorized |
| Local/open voice model | Implemented installed Flite KAL16 | Three original lines generated locally with inspected permissive notices; no runtime Flite dependency; human listening still required |
| Hosted GitHub CI | Deferred | Local checks provide current gates without risking billed runner use |
| Signed/notarized macOS distribution | Investigate in M07 | Do not purchase Apple enrollment; document unsigned local distribution limits if needed |

## Research tasks still open

The owner explicitly encouraged reuse after the initial prototype. [ADR-004](../architecture/decisions/ADR-004-selective-reuse.md) supersedes any assumption that movement infrastructure must be custom-built. Source/licence inspection and focused adaptation tests now precede substantial new skating systems.

M02 mechanics now have local regression evidence; physical feel still needs testing. M05 has a lawful zero-cost Flite voice source and original PCM sounds, pending listening acceptance. Official Godot 4.6.3 export templates and runtime notices were downloaded and checksum-verified; EXPORT.md records packaging results. M06 still needs a real target Mac and DualSense test record, including wired/Bluetooth behaviour, performance and first-run checks. Do not let research quietly substitute an easier product for the requested game.

## Budget guardrails

The user authorized development but explicitly prohibited anything costing money. There is no permission to buy tools/assets, consume billed APIs, enable hosting/billing, start a subscription, trigger remote build minutes, or continue model agents unattended. Existing assistant credits may still be consumed by an active conversation; durable task and handoff files make a later resume possible. No mechanism here replenishes credits or schedules automatic future work.
