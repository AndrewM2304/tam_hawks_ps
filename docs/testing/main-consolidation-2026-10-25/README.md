# Main consolidation —25 October 2026

Owner instruction: put everything on main and always work directly on main.
No new feature branch/worktree; no release, hosted CI or background session.
The existing combined tip5a2cba26558990bd13293ae8dfaa110a8b2e1195 fast-forwards
main7e4d263 and contains all other existing local branch tips. It includes the
38-capture planning packet and the separately committed recorder/world candidate.
The captured-candidate.patch is archival: its code is now applied in main.

## Required check — rejected, not all green

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 docs/testing/horizon-background/observers/run_checked.py .local/main-consolidation-20261025/full ./tools/check.sh
```

Actual native Mac headless Godot4.6.3 result: **4552 passed,8 failed**, exit1,
149.3395s,522 source inputs stable. Import clean; failed assertions make receipt
invalid. No production/test edits were made to hide these failures or merely to
change the old expected inventory. No native visual/performance acceptance claimed.

| Failure | Test source |
| --- | --- |
| Core/bench approved civic guard panel delta and compact totals | tests/clyde_surface_tests.gd:68 |
| Backdrop core/bench collision inventory | tests/city_backdrop_tests.gd:106 |
| Held-context per-chunk counts/park-contour triangles | tests/city_backdrop_tests.gd:151 |
| Four regional meshes combined triangle budget | tests/horizon_background_tests.gd:158 |
| River/water combined triangle ceiling | tests/horizon_background_tests.gd:466 |
| Exact557-body/1654-shape inventory | tests/horizon_background_tests.gd:569 |
| Reversible appearance restores physical inventory | tests/horizon_background_tests.gd:598 |
| Fixed32 foundation faces retain original building bases/roofs/footprints | tests/horizon_background_tests.gd:709 |

The candidate previously measured564 bodies/1674 shapes and910 combined horizon
triangles after guard/terrain changes. Extended foundations intentionally change
some original bases. These observations suggest fixture/contract reconciliation,
but do not prove that all failed assertions are stale: independently inspect
native geometry and preservation before changing expectations. The recorder test
module is committed but not registered in tests/run_tests.gd, so it is not covered
by this aggregate. Existing owner-visible defects and PT24-30 remain open.

[Complete console](console.log), [receipt](receipt.json),
[before hashes](source-before.json), [after hashes](source-after.json).
Manifest SHA256:591e2025c5f8a9b380ac82615988cdc024a762848ccc0cda14d52496ea33dba0.

Only documentation/instructions/evidence change after this frozen run. Verify
all522 hashes remain equal before the final push. Keep the failure record even
after later repairs. Full75-ticket backlog bodies/statuses remain unchanged.
