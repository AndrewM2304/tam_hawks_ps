# Independently reproduced original push defects

Production source: immutable clean main `0b620358767c9c647dde66945377d99702c85d0b`. A frozen copy of the new author's [native regression tests](motion_tests.gd.txt), driven by this independent [Main observer](observer.gd.txt), runs against original production. Both overlays live under `.local`; original production/test files remain unchanged. [Receipt](receipt.json) records hashes, scope and the post-run comparison against original source inventory. This negative diagnostic deliberately exits nonzero: **26 checks, six failures, exit 1**, no script errors. [Exact log](engine.log).

| Real Main case | Loaded rear-sole peak / cumulative slip | Torso / front-shoe dot actual travel |
| --- | --- | --- |
| Regular, disclosed initial +6 m/s moving start | 212.532 mm/tick / 2.00405 m over ten loaded samples | 0.3011 / 0.0663 |
| Fakie, disclosed initial −6 m/s and reversed heading | 212.521 mm/tick / 2.00380 m over ten loaded samples | −0.3973 / −0.0699 |
| From actual rest, ordinary pushing acceleration | 161.161 mm/tick / 3.16653 m over 26 loaded samples | 0.2984 / 0.0663 |

This independently confirms **FID-D007** planted sliding and **FID-D008** side-on push under the new owner requirement. The two 6 m/s cases explicitly set initial heading/speed/velocity once; subsequent acceleration and contacts use real Input actions, not trajectory corrections. The rest case has no velocity injection. The orientation result measures actual world axes, not a static catalog declaration; it does not replace visual cycle review.

Narrower existing behavior passes: supporting front sole stays within 0.854 mm of actual grip triangles; retained GLB wheels have 8 mm native flat-support gaps in all 48 samples per case; lifted rear return exceeds 0.1 m; release returns to grip. Actual braking produces 13 loaded drag samples with maximum gap 0.931 mm and stops. Six-/18-tick push-to-pop interruptions produce one clean native landing and recover both soles. The inspected apparent wheel float is therefore not demonstrated to violate existing support bounds.

Godot 4.6.3, Linux headless, dummy audio, fixed 60 Hz, ordinary default-enabled Main, persistence disabled. This is native contact/orientation evidence, not rendered motion, owner approval, physical-controller feel or Mac performance. Candidate retest must retain source freeze, contact bounds and normal-speed front/side/chase review; uphill/downhill/carving behavior remains additional evidence.

Restore both text files to their recorded `.local/qa-fidelity/` paths in the baseline archive, then run:

```sh
./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/qa-fidelity/motion_review.gd
```
