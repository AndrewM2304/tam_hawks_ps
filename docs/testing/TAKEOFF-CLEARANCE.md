# Takeoff clearance regression — 18 October 2026 (Europe/London)

The ordinary aggregate exposed an uphill takeoff assertion that treated `is_on_floor() == false` as proof that the whole rider was beyond collision recovery. Desired horizontal velocity stayed unchanged, while the first unsupported move included a small additional positional correction near the finite platform edge. This correction changes `get_real_velocity()`, which derives from displacement, without changing the carried velocity.

Three bounded ordinary-schedule diagnostic trials recorded actual physics frame IDs and the player's motion. The failing trial sampled exactly frames **188→189**, so skipped physics ticks did not explain it. Carried Z velocity stayed **−11.94728 m/s**; real displacement reported **−12.01816 m/s**, a **1.181 mm** horizontal difference for that tick. Its departing capsule was only **6.804 mm** from the rotated box, inside the player's **15 mm safe margin**. The two passing trials departed with **81.967 mm** clearance. These observations identify native near-edge contact/recovery behavior, rather than restored gameplay momentum. No production physics, forces, collision dimensions or rendering settings were changed for this correction.

The corrected fixture separates the claims:

- The original immediate carried-momentum threshold remains **0.05 m/s**.
- Near-edge positional correction must remain within the configured spatial safe margin, with 0.2 mm numerical allowance.
- A native full-capsule overlap query including that margin, plus independent capsule-to-oriented-box distance from the actual fixture shapes/transforms, must confirm clearance within eight observation samples. No pose or velocity is forced while waiting.
- From that cleared origin, both real velocity and independently measured displacement velocity must meet the original **0.05 m/s** threshold. Displacement uses the observed physics frame count, so a sampled interval cannot silently assume one tick.

In the validated candidate, the same near-edge case had **6.802 mm** initial clearance and a native margin overlap; after its first unsupported tick it had **121.934 mm** clearance. The following free-flight interval **189→190** reported carried Z **−11.94728 m/s**, with both real and independently measured Z velocity **−11.94729 m/s**. The original downhill, flat, airborne steering, rollback, collision and wall-removal cases remain.

Evidence:

- [Three-trial diagnostic](logs/performance-takeoff-diagnostic.log): original observations and per-tick contact/motion traces.
- [Ignored-candidate run](logs/performance-takeoff-candidate.log): **29 passed / 0 failed**, ordinary scheduling, exit 0.
- [Integrated focused run](logs/performance-takeoff-corrected.log): **29 passed / 0 failed**, ordinary scheduling, exit 0. The tracked module is byte-identical to the validated candidate.

Commands use the existing local free engine: `./tools/run.sh --headless --script .local/takeoff-clearance-candidate-run.gd` for the ignored candidate and `./tools/run.sh --headless --script .local/takeoff-clearance-tracked-run.gd` for the integrated focused run. The temporary runners invoke only this test module; their logs identify the cases and totals. The required final aggregate is recorded separately in STATUS/QE and is not inferred from these focused results. These checks establish collision/momentum contracts, not rendering, Mac performance or human feel.
