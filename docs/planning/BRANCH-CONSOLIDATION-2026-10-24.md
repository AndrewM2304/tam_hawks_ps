# REPO-01: one clear default branch

Owner: Codex. Priority:P0. Milestone:M00. Status:Done.
Request:24October2026, consolidate existing work and make main the default.
Dependencies: tested combined source e62c32b; prior work/default ancestry.

Acceptance: GitHub default and remote HEAD are main; main contains all three
pre-migration heads, including the latest playtest fixes; preserve history and
retain review/work refs. Local main tracks origin/main. No force push, game
change, release, hosted CI or background continuation.

The old default26cf62c and work b001fd3 were ancestors of review e62c32b.
Fast-forwarded bootstrap/m00-m01 from26cf62c to e62c32b with git push, then used
GitHub's branch rename endpoint to rename that default to main. API and remote
HEAD readback both confirm main/e62c32b. GitHub reports zero Actions workflows.
The branch rename preserves history; work and review remain available.

Validation: all515 current project/game/test/tool inputs match the frozen
4555/0 full-check source from the prior repair. No gameplay changed and no
unchanged engine checks were repeated. Documentation-only handoff updates are
committed on review and fast-forwarded to main with skip-ci commit metadata.
Final git/API checks verify equal local/remote main and review heads, old heads'
ancestry, main tracking, remote HEAD and a clean working tree.

Commands: git fetch origin; git push origin HEAD:refs/heads/bootstrap/m00-m01;
POST /repos/AndrewM2304/tam_hawks_ps/branches/bootstrap%2Fm00-m01/rename
with new_name main; GET repository/branches readback; non-force atomic push of
main/review documentation; local branch rename, fetch/prune, upstream/remote HEAD
updates and fast-forward checkout. Credentials are supplied only in memory by
the existing Git credential helper; none are recorded in source or logs.

Resume from main for playtesting, using feature branches for implementation.
Older bootstrap instructions in dated records are historical. Human/controller,
visual, export and full-map performance acceptance remain open.
