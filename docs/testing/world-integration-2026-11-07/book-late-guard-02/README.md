# Career book late-file preservation correction

Independent QE found a genuine hole in the previous56-check epoch: after writing
its verified temporary candidate, saving re-read all four slots but compared only
primary/backup signatures. A newly observed future/corrupt `.bak.tmp` could be
replaced by backup copying; another valid `.tmp` could become the primary.
The original56 source/evidence remains unchanged and is not admitted for this case.

The corrected PRIVATE source compares the exact expected hashes of all four slots
before backup copying, backup rename and primary rename. Its own candidate must
match the exact serialized intended book. A copied backup must match the original
primary hash. Newly observed future data blocks saving; other foreign changes
return busy, preserving all observed bytes. `_write_verified` is now an instance
method so an isolated test subclass can deterministically inject a late file after
`super` succeeds; production adds no callback, state or world/audio/filesystem init.
This is optimistic conflict detection, not interprocess locking or full race freedom.

Final native cohort: positive65/0, clean parsers/logs; same65checks against the
original56 save guard with ONLY the static-to-instance testing seam produce exactly
six expected failures. Each of three late-file faults starts with valid primary AND
backup: future backup-temp, malformed backup-temp, and valid foreign candidate with
other genuine Merchant completion/score. Corrected saving refuses all three and
preserves primary, backup, foreign file and recovery candidate. The old guard
replaces them, providing a failing control. Native calls128828/128841/128854/128867
ran11:58:28.319–11:58:31.140UTC (2.83s<15s bound); nine inputs in each private
project remained unchanged. The fixture uses separate XDG/user paths and never
constructs Main/world/Music or reads ordinary player profiles. Actual full04 was
the explicitly permitted other headless worker; no performance claim is made.

The earlier corrected65/0 at11:44:59 is retained at its narrower fixture scope
(no pre-existing backup and foreign settings variation). The final strengthened
cohort replaces that limited coverage; both preserve original56 provenance.

Runtime candidates remain `.local/world-integration/proposal-late-guard`; root
owns integration only after independent review. The runner's paths assume it is
restored under `.local/world-integration/` beside both private project snapshots;
do not execute its archived `.py.txt` in this deep evidence directory. Source
copies/diff and exact manifests allow independent inspection without execution.

Provenance correction from independent QE: source-before/after maps each contain
nine inputs (not the fourteen previously reported in agent messages). The outer
Python launcher is outside those maps; its archived copy was preserved after the
run and has no independent before-run hash binding. Do not infer that stronger
launcher identity from the native source inventories. Original maps/logs remain
unchanged. This correction does not change the65/0 or six expected native failures.
