# Passive adult bystanders — supporting inspection

Three actual 1280×800 frames from production `Main`, rendered with Godot 4.6.3 Compatibility / Mesa llvmpipe. Profile writes were disabled. The inspection camera changes viewpoint; the adults keep their ordinary grounded scene poses.

| Frame | Preserved root | Coat |
| --- | --- | --- |
| [Civic adult](01-civic-adult.png) | `(-27, 6, -116)`, yaw `-0.6` | Brown `766354` |
| [Station adult](02-station-adult.png) | `(-120, 2, 28)`, yaw `1.2` | Plum `6b5866` |
| [Barras adult](03-barras-adult.png) | `(123, 0, 29)`, yaw `-0.3` | Olive `847c67` |

The capsule mannequins now use the existing cleared ActivityActor anatomy, native skinned garments and shaped footwear. Both soles meet independently probed district floors. Root coordinates, facing, all four existing NPC proximity anchors and coat variety are preserved. The three adults are noncolliding, explicitly pausable passive scenery with a deliberate relaxed static pose; no interaction, reward, voice or new asset was added. Existing activity hosts retain their animation behavior.

All three frames were inspected: full adult bodies and original coat differences are readable, soles sit on their actual floors, and nearby skate surfaces remain visible. The focused native suite passes **22 checks, 0 failures**, covering adult meshes, native sole contacts, original placement/color, finite limbs, static posture and Main pause/resume. See [native-tests.log](native-tests.log), [engine.log](engine.log) and the [capture recipe](capture-recipe.gd.txt).

The [scoped source record](supporting-source.json) explicitly records **`global_source_changed: true`**. The broad guard spans a failed restricted-socket display attempt and the later successful local-display capture; `game/player/skater.gd` changed in that interval. All recorded actor inputs remained identical before/after, and PNG CRCs/decoded rows were validated. These frames support the bounded bystander upgrade; they are **not a globally frozen runtime receipt**. The final production Main film and its source lock provide that wider evidence.

This supporting inspection does not certify final art, human preference, controller comfort or target-Mac performance.
