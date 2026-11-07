# Independent source-launch protocol review

The corrected launcher has no remaining shell or cold-copy review blocker. The [second independent audit](epoch-02/review.json) passes22 checks against its exact three source hashes. These are Linux synthetic subprocess and source-copy checks, not Godot gameplay, macOS launch or frame-rate acceptance. Root’s separate real four-phase cold-launch gate owns native startup verification.

The original [17-check epoch](epoch-01/review.json) found two concrete gaps: the source selector rejected existing ignored Python caches, and terminating only the importer PID left a forked worker alive. Its source, logs and failure finding remain intact. QA stopped that owned worker after recording the result.

The corrected source skips `.godot`, `.local` and `__pycache__` descendants while retaining source/symlink/hash/mode checks and the complete editor-only board import tools. The exact selector successfully inventories876 actual files in the reviewed checkout. Bash job control puts the importer in its own group; timeout and cancellation clean that group. All four independent cases—timeout, ordinary success with a residual worker, direct helper TERM and caller-group TERM—leave no live importer or worker. Killed workers recorded as zombies are distinguished from live processes.

The original protocol also verifies visible preparation/log output, one copy of a final unterminated log line, spaced paths, explicit Dummy import audio, refusal on zero-exit script errors, preservation of a native nonzero exit, validated base10 limits and script-mode bypass. Those17 checks retain their original source scope; they are not reassigned to the changed helper.

The shell uses portable Bash constructs without GNU timeout or a production Python dependency. Actual macOS behavior remains unmeasured. Cleanup covers owned workers retaining the isolated group, not an arbitrary daemon that escapes its group/session. The preserved `.py.txt` files are exact historical audit recipes; their absolute staging paths are recorded and should be restored into a new diagnostic destination before reuse.
