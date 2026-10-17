# Project Glasgow

Autonomous game development plan · Version 1.0 · 17 October 2026

**Project objective\:** Develop an original, arcade-style 3D skateboarding game set in a fictionalised Glasgow, capturing the responsive controls, addictive trick combinations, two-minute runs, memorable levels, secrets and irreverent humour of Tony Hawk's Pro Skater 3.

The development model will be **AI-agent-led**, with independent specialist agents coordinated through GitHub issues, pull requests, shared specifications and automated quality gates.

The goal is to minimise your involvement in day-to-day implementation. Agents should research, plan, implement, test, review and correct their own work. You should only need to play milestone builds, provide feedback on the skating experience and approve significant changes to scope or direction.

## 1\. Project definition

# Glasgow: Grind City

Working title · Original IP

(Pre-production)

PRIMARY PLATFORM

**macOS / Apple Silicon**

ENGINE

**Godot 4.x**

INPUT

**PS5 DualSense**

TARGET

**60 fps / 1080p**

GAMEPLAY

**Single-player arcade**

DEVELOPMENT

**Multi-agent / GitHub**

---

The experience we're building

A fast, funny, replayable skating game where a player can spend two minutes chaining ridiculous tricks across Glasgow, discover a hidden shortcut, knock the cone off Wellington's statue, beat their previous score and immediately restart for another attempt.

### Non-negotiable design principles

1. **Skating comes first.** Movement, trick responsiveness and combo flow matter more than graphics.
2. **Arcade physics, not simulation.** Exaggerated jumps, forgiving grinds and responsive aerial control.
3. **Dense levels.** Every street should offer something to jump, grind, discover or interact with.
4. **Immediate replayability.** Restarting a run must be fast and painless.
5. **Meaningful exploration.** Hidden gaps, shortcuts, secret areas and environmental interactions reward curiosity.
6. **Distinctly Glasgow.** Recognisable landmarks, local humour, architecture and atmosphere.
7. **Original content.** Inspired by classic arcade skating, without copying protected characters, level layouts, animations, audio or branding.
8. **Controller-first.** The game must feel natural using a DualSense.
9. **Agent-maintainable.** Game systems, missions, level geometry and content should be independently editable and testable.

## 2\. What the first game will contain

The initial release will focus on **one large, interconnected Glasgow level**, rather than multiple separate locations.



Visual inspiration: recognisable Glasgow locations, compressed into a single skateable environment.

The fictional geography will connect George Square, Royal Exchange Square, Glasgow Central and the Barras/Barrowlands into a cohesive arcade playground. These locations need not follow real-world distances or street layouts.

### Release 1 scope

| System | Included |
|--------|--------|
| Skating | Ollie, flip tricks, grabs, grinds, manuals, reverts, spins |
| Scoring | Combos, multipliers, named gaps, special tricks |
| Game modes | Two-minute career runs, free skate |
| Goals | 10 distinct objectives including three score tiers |
| Progression | Unlocks, records, goal completion, local saves |
| World | One Glasgow level with four distinct districts |
| NPCs | Ambient characters, short voiced reactions |
| Secrets | Hidden areas, secret tape equivalent, interactive events |
| Audio | Skating SFX, ambience, AI-generated voice clips |
| UI | Menus, HUD, trick feedback, goal list, results |
| Input | DualSense and keyboard fallback |
| Distribution | Standalone macOS application |

Online multiplayer, realistic physics, open-world missions, character creation, complex dialogue and additional cities are explicitly excluded from the first release.

---

## 3\. Agent organisation and responsibilities

I'd use **eight permanent specialist agents**, with the Orchestrator coordinating work and the QE agent providing independent validation.

**Orchestrator / Technical Lead**

Planning · Delegation · Architecture · Integration · Release decisions

These are logical roles, not necessarily eight continuously running models. The Orchestrator should activate specialists only when they have ready work, and use isolated Git worktrees to avoid conflicting changes.

### Agent contracts

**A01 — Orchestrator / Technical Lead**

Owns the project roadmap, architecture decisions, task dependencies, agent assignments, Git integration and release readiness.

**Authority\:** May approve ordinary technical decisions, reassign work, reject PRs and adjust implementation plans. Must escalate changes that materially alter the game vision, legal risk or hardware requirements.

**Outputs\:** Architecture decision records (ADRs), milestone plans, dependency graph, integrated builds and progress reports.

---

**A02 — Business Analyst / Product Owner Proxy**

Translates the game vision into functional requirements, user stories, acceptance criteria and testable definitions of success.

**Authority\:** May clarify requirements using the approved design principles, but cannot silently remove core mechanics or redefine the product.

**Outputs\:** Product requirements document, prioritised backlog, feature specifications and acceptance criteria.

---

**A03 — Researcher / Technical Investigator**

Investigates open-source skating controllers, Godot capabilities, animation workflows, Glasgow reference material, suitable assets and licences.

**Authority\:** Recommends technologies and assets, but cannot introduce dependencies without architecture and licence review.

**Outputs\:** Evidence-based research notes, comparison matrices, playable experiments and licence records.

---

**A04 — Gameplay / Physics Engineer**

Owns skating movement, trick execution, input handling, grind snapping, manuals, reverts, camera behaviour and scoring integration.

**Authority\:** May tune gameplay parameters within agreed design targets. Significant changes to control schemes or combo rules require an ADR.

**Outputs\:** Reusable skating controller, state machines, trick definitions, physics test scenes and gameplay telemetry.

---

**A05 — World Designer / Technical Artist**

Owns Glasgow's level layout, modular geometry, visual style, landmark construction, collision surfaces, lighting and environmental effects.

**Authority\:** May rearrange fictional geography to improve gameplay. Cannot change skating physics to compensate for poor geometry without agreement.

**Outputs\:** Level scenes, modular asset library, environmental design documents, collision metadata and optimised models.

---

**A06 — Mission / Reward Designer**

Owns goals, score thresholds, collectibles, named gaps, progression, unlocks and replayability.

**Authority\:** May tune goals and rewards based on test evidence. Cannot alter core trick-scoring algorithms independently.

**Outputs\:** Data-driven mission definitions, progression tables, balance reports and mission validation tests.

---

**A07 — Audio / Narrative Designer**

Owns short NPC scripts, environmental humour, AI voice generation, skating sounds, ambient audio and audio implementation.

**Authority\:** May create original dialogue and select appropriately licensed voices. Cannot introduce unlicensed music, recordings or imitations of identifiable performers.

**Outputs\:** Dialogue catalogue, audio files, voice-generation manifests, SFX assets and event-to-audio mappings.

---

**A08 — UI / UX Engineer**

Owns controller navigation, menus, HUD, trick notifications, combo feedback, pause flow, results screens and accessibility.

**Authority\:** May iterate interface presentation, provided input mappings and game-state contracts remain stable.

**Outputs\:** UI scenes, reusable components, navigation tests and accessibility checks.

---

**A09 — Quality Engineer / Test Automation**

Independently verifies gameplay mechanics, mission completion, regressions, performance, controller behaviour and macOS builds.

**Authority\:** May block a release or PR for failed mandatory acceptance criteria. Cannot silently change production behaviour to make a test pass.

**Outputs\:** Automated tests, gameplay simulations, defect reports, performance results and release certification.

The QE agent should be involved from the first prototype, not introduced after gameplay implementation.

## 4\. How the agents coordinate

A shared repository is the source of truth. Agents must not rely on remembering conversations or informal agreements.

### Proposed repository structure

```
grind-city/
├── AGENTS.md
├── README.md
├── project.godot
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── workflows/
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   ├── product/
│   │   ├── vision.md
│   │   ├── requirements.md
│   │   └── game-design.md
│   ├── architecture/
│   │   ├── interfaces.md
│   │   └── decisions/
│   ├── research/
│   ├── levels/
│   │   └── glasgow.md
│   ├── testing/
│   └── licences/
├── game/
│   ├── core/
│   ├── player/
│   ├── tricks/
│   ├── scoring/
│   ├── missions/
│   ├── progression/
│   ├── levels/
│   ├── ui/
│   └── audio/
├── assets/
│   ├── characters/
│   ├── environment/
│   ├── animations/
│   └── audio/
├── tools/
│   ├── blender/
│   ├── voice_generation/
│   └── gameplay_testing/
└── tests/
    ├── unit/
    ├── integration/
    ├── simulation/
    └── performance/
```



### GitHub workflow

(Backlog)  (Ready)  (In Progress)

(Done)  (QE Review)  (PR Review)

Blocked is a separate status. Every blocked ticket must identify the dependency and responsible agent.

Each issue must have a unique ID, owner, priority, milestone, dependencies, explicit acceptance criteria and test strategy.

Agents must not work directly on `main`\. Each ticket uses its own branch or worktree.

**Required PR checks\:**

- Godot project imports successfully.
- GDScript parses and static checks pass.
- Relevant automated tests pass.
- No missing resources or broken scene references.
- New assets have documented provenance and licences.
- QE approves gameplay-sensitive changes.
- The Orchestrator verifies architectural compatibility.

For graphical changes, agents must also attach before/after screenshots or short gameplay recordings.

### Decision-making rules

| Decision | Responsible |
|--------|--------|
| Technical implementation | Specialist agent |
| Shared interfaces | Orchestrator |
| Gameplay acceptance criteria | BA + Gameplay + QE |
| Physics parameter tuning | Gameplay, verified by QE |
| Level geometry changes | Artist, verified by Gameplay |
| Mission balancing | Mission Designer + QE |
| Licensing decisions | Researcher, approved by Orchestrator |
| Scope changes | Orchestrator within approved vision |
| Major creative direction changes | You |
| Release readiness | QE recommendation + Orchestrator |

Every significant decision should produce an ADR recording the problem, alternatives, evidence, decision and consequences.

---

## 5\. Detailed delivery roadmap

I'd divide the project into eight milestones. These are **dependency-based delivery stages, not fixed calendar sprints**\. Agents can execute independent tickets concurrently, but must not bypass a milestone's exit criteria.

## 00

**Project foundation**

Repository, agent instructions, specifications, CI, test harness, licensing and engine research.

(Exit: reproducible empty game build)

---

## 01

**Skating proof of concept**

Controller, movement, ollies, ramps, aerial tricks, landing and basic camera.

(Exit: fun grey-box skating loop)

---

## 02

**Complete trick and combo system**

Grinds, manuals, reverts, multipliers, specials, named gaps, bails and trick feedback.

(Exit: satisfying continuous combos)

---

## 03

**Glasgow grey-box**

Full interconnected level, landmark silhouettes, skating lines, shortcuts, gaps and secret areas.

(Exit: traversable and enjoyable level)

---