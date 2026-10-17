# Tam Hawks Pro Skater — art and UI direction

**Owner direction recorded:** 17 October 2026. **Status:** production specification; a second architectural/material, skinned-rider and UI cleanup pass is implemented, with final realistic finish still open. The corrected title is **Tam Hawks Pro Skater**. The owner wants polished UI, realistic and fun graphics, and recognisable Glasgow shopfronts and street edges.

## Intended finish and delivery order

Aim for a polished independent skating game with believable human proportions, recognisable Glasgow architecture, textured surfaces, convincing light and expressive movement. Arcade physics, readable tricks and a lively visual identity support the fun. The target is a convincing, cohesive city at skating speed and in ordinary close views; photographic fidelity is not an established capability or acceptance claim.

The original cuboid blockout now has varied facade modules, verified CC0 brick/concrete materials and a native skinned clothing rig. Generated surfaces, stylized anatomy, static bystanders and unverified shop strips still need refinement. Blockout geometry is useful for agreeing lines and collision, but its appearance does not satisfy final presentation. Basic geometric meshes may remain as hidden collision or construction elements; visible production art needs deliberate silhouette, surface detail and finish.

1. **Now:** maintain the reference dossier, art direction, placeholder inventory and actionable tasks while core skating develops. Record real locations and reusable free assets before investing in final production art.
2. **Representative art pass:** continuous combos are implemented and locally tested. The owner authorizes proceeding while M02-008 physical/feel acceptance remains open. Establish a representative scene and HUD treatment, including a skater, a shopfront edge, a skateable approach and readable trick feedback. Capture the result and its frame cost; subsequent hardware/feel findings can still require revisions.
3. **M03 / M05:** retain approved skating layouts, then replace visible blockout throughout all four districts using the approved art treatment. Grey-box acceptance remains distinct from art acceptance.
4. **M06 and final cleanup (M06-007):** complete polished menus and accessibility, remove the remaining visible placeholders, compare matched before/after evidence, verify target performance and obtain the owner's visual signoff. This cleanup is a required release gate with tracked defects, not discretionary decoration.

Use the acceptance procedure in [VISUAL_ACCEPTANCE.md](../testing/VISUAL_ACCEPTANCE.md). Final presentation is still planned. No art acceptance, hardware performance pass or owner signoff has occurred.

## Glasgow as a place

Build district identity through real architectural proportions and researched street edges: masonry coursing, window rhythm, shop bay widths, entrances, upper-storey facades, cornices, rooflines, closes, awnings and changing ground materials. Repetition should follow a plausible building, with a few purposeful variants that break uniform rows.

| District | Art treatment to develop | Useful border composition |
|---|---|---|
| George Square | Broad civic space, substantial stone architecture, formal facade rhythm and generous sky | Researched civic/building silhouettes and street frontage frame long skating views |
| Royal Exchange Square | Gallery and columned architecture, dense stone paving, finer retail and hospitality frontages | Recognisable frontage proportions and arcade entrances surround the compact court |
| Central Station surroundings | Station massing, railway canopy details, layered urban facades and varied ground edges | Station approaches and researched Gordon Street / nearby street references suggest routes beyond the playable boundary |
| Barras / Barrowlands | Market textures, painted metal, warehouse fronts, stall variation and venue identity | Researched market/shop frontage sequences provide a distinct low-rise edge and strong destination silhouette |

These are art briefs, not claims that the current level reconstructs those streets. Preserve real adjacency where it helps recognition; record deliberate compression or relocation in the level plan. [The Glasgow reference dossier](../research/GLASGOW_REFERENCES.md) tracks dated sources and confidence; live storefront verification remains M03-006. Record whether a storefront is current, historical or an intentional composite. Do not invent a shop at a precise address and present it as verified. M03-007 owns translating the approved references into shopfront borders.

Real shop identities and characteristic facade arrangements may inform the selected borders. Produce original geometry and surface art from inspected references; record any imported asset and its permissions. Google Maps or Street View may be consulted through available free access as a visual reference. Their imagery and map tiles are not approved distributable textures or game assets. A source link and observation date are sufficient to preserve research; no paid Maps API is required.

Borders are primarily nonplayable facades with shallow doorway/window depth and convincing upper-storey silhouettes. Add interiors only where a separately tracked playable space needs them. Keep decorative furniture, signs and awnings clear of accepted landing zones and camera paths. Street closures, market stalls or architectural edges should make the level boundary visually understandable without cluttering the skating line.

## Environment production kit

- Create reusable facade modules with explicit dimensions: structural bays, recessed windows and doors, shopfront frames, cornices, roof/parapet pieces and district-specific details. Align shared edges; vary height, bay rhythm and surface treatment deliberately.
- Use compatible free licensed or original textures for sandstone, brick, slate, painted wood, metal, glass, asphalt and paving. Keep a consistent real-world texture scale. Roughness, restrained normal detail and selective staining should explain the material; uniform flat colours on all large surfaces are insufficient for the final finish.
- Give visible rails, coping, ledges and ramps credible edges, joints and wear. Cosmetic detail must retain the authored skating surface and collision profile. Use a consistent visual treatment to distinguish grindable surfaces without turning the city into glowing obstacle markers.
- Add a modest selection of local street details: drain covers, kerbs, bollards, bins, street signs, recessed shop entrances and window displays. Choose them for place recognition and composition rather than density alone.
- Validate seams, texture stretching, transparent-window sorting, floating props, intersecting trims, repetitive shop strips, shadow leaks and camera-distance aliasing along actual skating routes. Inspect a close approach to every facade kit, not only distant showcase shots.

## Light, colour and weather

Start with a coherent Glasgow daylight treatment: soft sky illumination, readable stone colour, controlled shadows and a clear exposure range. Warm sandstone, cooler paving and restrained shop colours should support the skater and obstacles. Avoid blown-out pale facades, crushed landing-zone shadows and excessive saturation.

The representative scene must include both bright and shaded approaches. Use shading and contact shadows to ground wheels, feet, rails and facade details without hiding trick silhouettes. Match material response under the same lighting before judging texture quality.

A subtle damp-surface treatment is optional if it improves the mood within the measured budget. Dynamic rain, a day/night cycle, puddle simulation and a weather system are outside this cleanup requirement. Prefer one well-finished lighting condition. Bloom, blur, shake and colour grading must retain readability and respect reduced-motion settings.

## Skater, skateboard and animation

Replace the visible primitive rider with a rigged skater with believable anatomy, clothing volume and joint deformation. Use an original design or a compatible free licensed model, adapted to the game's identity. The board needs a plausible deck profile, grip surface, trucks and wheels. Verify scale against pavement, rails and shop doorways.

The action set must clearly communicate idle/coast, push, brake, crouch, ollie, airborne spin, flip, grab, grind, manual, revert, special, landing and bail/recovery. Poses can exaggerate anticipation, balance and landing compression for legibility and personality. Preserve credible feet/board contact and hand placement during ordinary playback; define deliberate separation for flips and bails.

Evaluate transitions and silhouettes at the normal chase-camera distance, then in a close slow-motion inspection. Look for foot sliding, hands missing the board, clipping, detached wheels, stiff landings and abrupt pose pops. The board and body must visually agree about rotation and trick state. Animation follows eligible gameplay input and must not introduce a waiting period before a trick executes. Adapt lawful existing rigs/clips when suitable and keep their attribution.

## UI identity and interaction

Use a coherent original identity for **Tam Hawks Pro Skater** across title, HUD, goals, pause, settings and results. An initial palette of charcoal, warm off-white, deep green and one warm accent can complement the city; settle the final palette in the representative scene. Typography, icons, borders and motion should share one visual system.

- Establish reusable theme tokens for font sizes/weights, colours, spacing, corner treatment, focus, disabled states and animation durations. Use one readable type family with a distinct display treatment, or a carefully matched pair; record font licences.
- Design around 1920×1080 with proper anchors and scaling. Default body and control labels should generally be 22–24 px at that resolution; supporting labels should remain at least 18 px. Score, timer and active-combo values need a stronger hierarchy. Check the result on the target display rather than treating pixel sizes as proof of readability.
- Keep the central skating line, landing area and trick silhouette clear. Group persistent run information, transient combo history and control prompts deliberately. Long trick names, large scores, multiple goals and captions must fit without overlap or unreadable shrinking.
- Give selected controller items an unmistakable focus treatment using shape/border and contrast as well as colour. Maintain predictable directional navigation, return focus after closing a panel and show prompts that match the active device/remapping. All required actions must work with keyboard and controller.
- Target text contrast of at least 4.5:1, or 3:1 for large text, against the actual panel/background. Use panels or outlines when the moving world would invalidate those values. Never communicate bail, success, focus, balance risk or a record using colour alone.
- Use short, purposeful motion for combo banking, records, focus and screen transitions. Transitions must not delay restart or accepted input. Reduced motion removes nonessential movement and shake. Effects should remain comfortable during repeated runs.
- Finish empty, loading/saving, disabled, disconnected-controller and error states where those systems exist. Clearly distinguish saved progress, the current run and free-skate status. Placeholder/debug text is not player-facing production UI.

The work is a full UI finish pass; a title rename or colour swap alone does not satisfy it. Use original composition and assets rather than copying another skating game's branded interface.

## Performance and production constraints

Keep Godot 4.6.3 and use the current Compatibility renderer as the starting point. Art improvement does not require an engine migration. Any later renderer change needs a documented visual benefit and measured compatibility/performance evidence.

Target **1080p / 60 fps on a declared Apple Silicon baseline**. Profile the representative scene before expanding it and the full level after integration. Reuse material/texture sets and facade modules; consider mesh batching, sensible texture sizes, baked detail, distance LOD and culling when measurements justify them. Keep invisible collision simple and independent of decorative mesh detail. Agree texture, geometry and draw-call budgets from measured captures rather than inventing platform limits.

All assets and tools must remain within zero additional spend. Check existing libraries and free compatible sources before creating substantial new art tooling. Record source URL, author, version/date, licence, modification/redistribution terms, attribution and included files in [the provenance register](../licences/REGISTER.md). A free download or public image is not by itself an asset licence. No purchased packs, paid generation/API calls, hosted jobs or subscriptions are part of this work.

## Completion authority

A05 owns environment/skater production, A08 owns UI, A03 verifies asset provenance and A09 independently checks evidence and gameplay regressions. A01 tracks incomplete work and defects in the backlog and handoff. The owner reviews the playable finished scene and final level after core gameplay acceptance; automated tests and screenshots cannot supply that creative signoff. Target-Mac performance remains a separate measured gate.
