# ADR-001: Local development with no additional spend

Status: Accepted for the current user-authorized development session. Date: 17 October 2026. Owner: A01.

## Context

The supplied plan proposes GitHub issues/PRs, CI and voice generation. The owner explicitly requires that nothing cost money and that tasks survive an exhausted credit allowance. An empty repository offers no existing service budget or licence authorization.

## Decision

Use free local tooling, repository task documents, local checks, original procedural geometry and locally generated synthetic SFX. Do not trigger hosted CI, provision infrastructure, purchase assets, use paid APIs, enable billing or run unattended agents. Store comprehensive ticket and handoff records in Git. Local issue/PR templates support later publication but do not create remote records. Normal in-session assistant work is bounded by the user's available credits.

The environment is already isolated. Use the existing checkout and a feature branch; no extra Git worktrees unless the user explicitly requests them. Logical specialist roles can share disjoint files under an agreed interface.

## Alternatives

Hosted CI and paid voice/asset services could reduce some labour but conflict with the current budget constraint. Permanently removing voice reactions would change Release 1 scope, so voice implementation stays gated on a lawful free local source or a later owner decision.

## Consequences

Local validation must be reproducible and recorded. Physical controller/Mac certification still requires access to real hardware. Distribution signing or voice tools that would incur cost remain blocked rather than silently purchased. Every session ends with concrete resumption instructions; the project does not autonomously schedule future compute.
