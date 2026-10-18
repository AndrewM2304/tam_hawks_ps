# Compact Clyde admission

DENSITY-01 moves existing feature groups into one river pocket. The [placement contract](../../levels/COMPACT-CLYDE-CONTRACT.md) and [ADR-018](../../architecture/decisions/ADR-018-compact-clyde-pocket.md) define the geometry; [input trials](LINES.md) and [independent QE](QE-REVIEW.md) explain their bounded evidence. [Results and rejected attempts](RESULTS.md) distinguish final evidence from development. Current acceptance and remaining work belong in [STATUS](../../STATUS.md) and [the density task packet](../../planning/LEVEL-DENSITY-NEXT.md).

The baseline is the production game at `811b629` (identical game inputs to `321501d`). The recovery implementation checkpoint is `889350f`; subsequent source corrections and their exact input manifests are retained with this evidence. A commit name alone does not identify uncommitted executed inputs: compare the actual per-file SHA-256 inventories.

The capture uses ordinary Main, Balanced1280×800, a220m far plane, native Compatibility rendering and one isolated llvmpipe renderer. It records eleven settled production chase poses, a real route map and one explicitly authored overview. Forty frame intervals per chase pose exclude screenshot readback. These are stationary rendering diagnostics, not moving target-Mac or human-fun acceptance. The same observer is used for original/candidate/original controls. Native input traces use one initial fixture, followed by production actions and collision; they are separate from the stationary render workload.

Final logs, source guards, raw traces, images and matched performance results are retained here; [the final audit](audit.json) binds them to committed inputs. Rejected development attempts remain labelled rejected; earlier passing counts are not added to the final full-suite count. No new asset purchase, paid service, district, texture or shader is introduced.


## Repeating or continuing this work

Read the current [STATUS](../../STATUS.md), [results](RESULTS.md) and [ordered tasks](../../planning/LEVEL-DENSITY-NEXT.md) first. Required regression is `./tools/check.sh`; it imports with the installed Godot then runs `tests/run_tests.gd`. Optional `COMPACT_CLYDE_LINES_OUTPUT` retains the six native Clyde traces. Serialize engine/render/Blender work and freeze game/tests/tools/project inputs during a check.

The evidence directory retains the exact executed standalone diagnostic and observer text as `.txt`, before/after SHA256 inventories, receipts, console/raw capture JSON, lossless native trace gzip and original PNGs. Copy a preserved observer back into an ignored `.local/compact-clyde/` file only for an explicitly labelled reproduction; inspect its matching shell wrapper and environment assumptions first. A receipt describes its executed files, not every later checkout. Source/artifact auditing must disclose any subsequent diagnostic-only test migration rather than silently treating all historical inventories as identical.

`phase.py` only switches the six comparison files and verifies game hashes. The comparison shell caller installed an EXIT trap that invoked its `candidate` action; the helper does not install that trap itself. This was local measurement tooling, not normal gameplay. Its local snapshots can be reconstructed from the named Git revisions and inventories. Never switch source during a running engine/test process. Prefer the existing saved evidence when only documents or nonexecuted tests change; a new production change requires fresh affected checks and rendering/performance evidence.

The park document is a draft. Start its actual work with the shared port survey and placement contract, preserving complete backlog task bodies, no-spend rules, performance gates and all current mechanics/identities. Do not mistake static image review, conservative native keyboard feasibility or software-renderer timing for human/Mac acceptance.
