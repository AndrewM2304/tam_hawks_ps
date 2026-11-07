# Private forecast observer receipt alias — 7 November 2026

Owner LD; reported to Motion, root and QE. No actual production controller or
`tests/line_design_tests.gd` change. The original
[four-case native log](../motion-fidelity-2026-11-07/air-anticipation-finite-native/engine.log)
is retained unchanged; this note does not upgrade its endpoint positives to
visual, performance or integration acceptance.

An offline cold-read explains the inconsistent query attribution for gate 78.7,
physics frame 544. That row contains an independently checked positive forecast
receipt of 120 queries. On the same callback, its first synchronous foreign-owner
negative invokes the source helper, which clears the live forecast Dictionary.
The helper restores the source field to a saved duplicate before physics resumes,
but the observer's local `forecast` variable aliases the cleared original object.
The later cost recorder sees an empty local receipt and labels a genuine accepted
attempt as a refusal with its raw count of 85. This omits the receipt's 35 reserved
current-pose guard queries. The invocation stamp is correctly 544; this is not the
separately recorded frame 541 with no current forecast invocation.

That frame's accepted/refused classification and the derived gate-78.7 query
distribution are **rejected**. The earlier positive native future/current-pose
proof and strict model/shoe/capsule/camera checks run before the destructive fault;
their scoped observations remain in the original packet. The old packet must not
be rewritten or silently relabelled to repair the cost distribution.

The private-only observer now snapshots the receipt with `.duplicate()` before
running synchronous faults. Motion additionally requested a pure reserved-query
hard-cap negative: at `cap − 3 − actual_component_count`, a counted query must
refuse without incrementing or changing the invocation stamp, then restore the
entire saved state before physics. The combined observer SHA-256 is
`157556f2f733fe21e65ec286115101d2dfe45f5dddf0c90ca73b65636c59037f`, at
`.local/motion-sweep-source/tests/line_design_tests.gd`. It preserves the source
controller, actual native queries, restoration checks and all physical/clearance
thresholds. A new parse/native epoch is required to claim corrected attribution;
no new native execution result is claimed by this note. Motion's private source
cap reduction from 384 to 192 is a separate candidate change for the next epoch.
The observer additionally requires each receipt's cap to equal the declared
controller cap and be no greater than 192. This does not alter actual production
or retroactively accept old cost evidence.
