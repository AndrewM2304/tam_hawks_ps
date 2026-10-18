# Rejected audit-harness attempt

Both packages exported successfully. The reused base auditor passed archive, source, capture and three construction probes, but the current wrapper correctly refused overall acceptance because the pack-only art-source exclusion check had not executed. Godot consumes its engine-owned `--main-pack` option before the script's `get_cmdline_args()` query, so that conditional was false.

`audit.log` retains the complete failure. `partial-base-audit.json` is the base report only, **not a passing current package audit**. No game or package behavior changed. The corrected probe identifies the actual virtual `res://project.binary`, checks prototype-directory absence and emits a marker that the wrapper requires independently for both packs; source requires its actual `project.godot`. A fresh complete audit must pass before retention.
