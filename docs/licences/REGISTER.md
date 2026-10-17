# Dependency and asset provenance register

Update this before introducing any third-party material. “Free to download” alone is not redistribution permission. Keep licence text and attribution required by shipped dependencies alongside release packaging.

| ID | Material | Origin / author | Licence or permission | Distribution status / evidence |
|---|---|---|---|---|
| DEP-001 | Godot 4.6.3 engine/editor | Godot Engine contributors; official release | MIT; engine includes third-party notices | Development dependency. Preserve engine and third-party notices required by the exported runtime; M07 validates packaging. Installed-version evidence belongs in setup output and STATUS; verify official artifact checksums if a future download is needed. |
| SRC-001 | Original game scripts, tests, procedural world generation, trick catalog and ride-state integration, excluding DEP-002 | Original work produced for this repository | Project owner controls distribution; no public project licence selected | Do not infer an MIT game licence from the engine or an imported component. |
| DEP-002 | `game/tricks/grind_line.gd` | [TinyBitAdventures/not-pro-skater](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/skater/grind_line.gd), Austin Ginder, 2026 | MIT; [full retained notice](third-party/not-pro-skater-MIT.txt) | Adapted isolated source, no assets. Revision/file hashes, inspected scope and modification record in [reuse research](../research/SKATING_REUSE.md). Preserve notice in source and future native distributions; export/package audit must include it explicitly. |
| ART-001 | Primitive skater, board, buildings, ramps, statue/cone and signs | Original procedural geometry in repository | Project-owned original content | Temporary M01 blockout; no external textures, models or photos currently imported. Later art may use compatible free licensed assets with separate records. Confirm actual imports in review. |
| TXT-001 | Tam Hawks title, UI strings, fictional dialogue and goals | Original project text; user supplied concept | Project-owned text | Final title clearance remains M07; familiar architectural references are not copied branding. |
| DOC-001 | Original autonomous development plan | User-supplied pasted document, preserved verbatim | Provided by owner for this project | Internal project source record; do not represent its third-party franchise references as permission to reuse franchise content. |
| SFX-001 | Locally synthesised prototype sound effects | Project generator/code, when implemented | Project-owned generated waveforms | Record generator file and actual produced assets at M05 acceptance; current implementation status is in STATUS. |

## Geography reference material

`docs/research/GLASGOW_REFERENCES.md` records inspected historical address leads from a pinned community dataset. That dataset has no established redistribution licence and has not been imported or redistributed. Official/map/Street View pages were blocked and their contents remain uninspected. Individual factual observations can inform original facade designs once verified; source photographs, map tiles, panoramas and logos need separate permissions before inclusion as assets.

## Prohibited imports

No commercial game models, animation, level layouts, textures, logos, character names, UI copies or recordings. No licensed music without an explicit licence and approval. No performer voice cloning or imitation. No asset pack is approved merely by a URL or a marketplace “free” label.

## Per-asset record for future additions

Record stable source URL, exact version/download date, author, licence text path, attribution, allowed modification/redistribution, any model/output licence distinction, files included and the approving A01/A03 review. For procedural/generated content, record the source generator and inputs. Never store credentials in a manifest.

## Unresolved release items

- Select the project's public source/content licensing terms with the owner before publishing a licence grant.
- Check the Tam Hawks title and included real/fictional shop signs during release review; reference photographs/logos are not automatically production assets.
- Validate runtime notices in the macOS package.
- Resolve voiced NPC reactions with a lawful zero-cost source; there is no approved external voice dependency yet.
