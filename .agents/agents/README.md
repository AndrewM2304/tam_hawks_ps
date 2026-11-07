# Persistent specialist roster

These repository-backed role briefs and skills survive future sessions. They are explicit instructions for the orchestrator to load when delegating; they do not create continuously running agents or claim registration in an undocumented Codex runtime configuration.

Start with [the studio guide](../../docs/planning/STUDIO.md), [the fidelity tickets](../../docs/planning/FIDELITY_TICKETS.md), and [the benchmark](../../docs/product/AAA_BENCHMARK.md). Read `AGENTS.md`, current STATUS and runtime interfaces before implementation. Work directly on `main` under the latest owner instruction; the orchestrator owns Git operations and final verification. Keep current default-enabled content and personal Music isolation intact. Audit existing implementation/evidence before creating replacements.

| Role brief | Use case | Skill |
| --- | --- | --- |
| [Studio director](studio-director.md) | Ticket selection, file ownership, integration, main handoff | [Studio production](../skills/studio-production/SKILL.md) |
| [Rider artist](rider-artist.md) | Believable anatomy, clothing, board, rig deformation | [Rider fidelity](../skills/rider-fidelity/SKILL.md) |
| [Rigging engineer](rigging-engineer.md) | Source-authenticated fitted seams, multi-bone deformation and head/neck continuity | [Rigging validation](../skills/rigging-validation/SKILL.md) |
| [Contact rigging engineer](contact-rigging-engineer.md) | Conservative actual skinned-surface contact envelopes with bounded native queries and CPU cost | [Deformed contact](../skills/deformed-contact/SKILL.md) |
| [Environment artist](environment-artist.md) | Materials, architecture, lighting and scene composition | [Environment fidelity](../skills/environment-fidelity/SKILL.md) |
| [Environment architect](environment-architect.md) | Recessed openings, credible joinery, shop interiors and route-facing building profiles | [Architectural fidelity](../skills/architectural-fidelity/SKILL.md) |
| [Motion engineer](motion-engineer.md) | Physics contacts, animation state delivery and camera stability | [Skating motion](../skills/skating-motion/SKILL.md) |
| [Level designer](level-designer.md) | Dense original trick lines, gaps, returns and collision | [Skate level design](../skills/skate-level-design/SKILL.md) |
| [Rendering engineer](rendering-engineer.md) | Engine/renderer choice, Metal portability, measured workload and resource admission | [Renderer evaluation](../skills/renderer-evaluation/SKILL.md) |
| [Combo engineer](combo-engineer.md) | Fresh landing links, stance-correct fore/aft balance and honest meter controls | [Combo usability](../skills/combo-usability/SKILL.md) |
| [Technical QE](technical-qe.md) | Independent reproduction, regression and source-bound capture | [Quality verification](../skills/quality-verification/SKILL.md) |
| [BA verifier](ba-verifier.md) | Independent requirements-to-outcome audit and acceptance gaps | [Quality verification](../skills/quality-verification/SKILL.md) |

There are twelve logical roles, not a requirement to run twelve workers simultaneously. With a root plus six available slots, root can direct production/rendering and BA can run after implementation owners finish. Independence means the person/agent verifying a ticket did not implement its production change. Do not ask an implementation owner to mark their own work accepted.

The supporting [native gameplay QA skill](../skills/gameplay-qa/SKILL.md) is available for technical QE alongside the verification skill. The current library contains twelve skills; future additions belong in this roster and the relevant ticket.
