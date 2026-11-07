# Independent Main/HUD world lifecycle review

2026-11-07, independent topology/BA reviewer. Cold-read the exact held combined02
Main/HUD and13 associated state/actor sources, pinned/copied in
`source-bindings.json`. All15 match the subsequent immutable native timing01
pre-execution snapshot. No author edits or new lifecycle engine were performed.
The durable Main lifecycle packet's independent offline verifier was rerun:
**4452/0**, retaining its original native20/0 and cache/input/art/hardware limits.
Root's later parsed GUI31/0 is a separately reported epoch, not recertified here.

No additional blocking lifecycle, progress namespace or account-control issue was
found in this composition. That conclusion is a bounded source review alongside
the existing native lifecycle evidence, not a universal safety claim.

The replacement inventory is complete for current level-owned actors: world,
Skater, objectives, Glasgow encounters, cat, market encounter and FeatureHub are
freed. Their Main fields are cleared before any new constructors can look up the
rider. Old-node signal connections die with those nodes; the new Skater connects
once to Main and the retained current Score. Only the selected world is loaded
from Catalog's fixed IDs/paths. Invalid level IDs refuse before saving or loading.
No old world stays live to contribute geometry, routes or activity actors.

Native gap authority is invalidated before replacement and reconfigured with the
new rider/actual world. Old weak registrations and pending proof are cleared.
Fresh grind/transition/goal/encounter/activity registries come from the new world.
Restart resets Score, SpecialMeter, gap state, career run collections, all activity
runs, elapsed/overtime, counters, caption time, surface state, rider controls and
physics. HUD route data is deep-copied from the new registry; career-source cache
is invalidated and Book's generation changes on selection. Persistent HUD label
caches retain catalogue labels, not old actor references.

Main saves the old level before Book selects the next, then begins a fresh run.
Book stashes/restores only the selected level's goals/bests and clears transient
collections for both its own and delegated legacy runs. Settings remain shared;
unlocks derive from records across fixed level namespaces. Legacy Base and new
Book are distinct intended files. Loading happens once into a selected namespace;
level changes neither migrate again nor touch legacy files. Book rejects unsafe
primary/backup/temp/newer-version families, protects legacy paths, verifies loaded
signatures before replacing existing data and guards the candidate/backup family
before each rename. Main's save calls retain those guards after a load warning.
This review does not replace the separate fault-injection profile tests.

Music and audio remain the same objects. World selection does not call Music
configure, authenticate, connect or begin_session; the existing start-mode action
begins a session. Shared settings are applied to fresh actors without invoking
account controls. Main's one-time controller callback, HUD callbacks and recorder
owner reference do not multiply during selection. HUD waits for consumed menu
releases and a paused physics/idle boundary before emitting a transition; page,
revision, serial, weak owner and current pause/finished guards cancel stale work.
The actual keyboard/controller release behaviour belongs to the separate parsed
GUI cohort, not this cold-read.

One nonblocking diagnostic follow-up remains: persistent PlaytestRecorder reads
the current Main.world/Skater dynamically, but snapshots omit explicit level ID
and its static source manifest omits Merchant world/layout/Catalog/Book. A single
debug session spanning two levels can therefore contain ambiguous coordinates
and incomplete new-world provenance. Add a per-snapshot namespace and current
level source hashes after integration; this does not affect gameplay, account
state or progress persistence. No source change is included here.

Human/mapped GUI selection, future actors, full-map gameplay, art, native complete
model contact, corrupted/contended filesystem behaviour beyond existing fault
fixtures and Mac hardware/performance remain separate acceptance gates.
