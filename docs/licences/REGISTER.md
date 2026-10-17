# Dependency and asset provenance register

Update this before introducing any third-party material. “Free to download” alone is not redistribution permission. Keep licence text and attribution required by shipped dependencies alongside release packaging.

| ID | Material | Origin / author | Licence or permission | Distribution status / evidence |
|---|---|---|---|---|
| DEP-001 | Godot 4.6.3 engine/editor | Godot Engine contributors; official release | MIT; engine includes third-party notices | Development dependency. Preserve engine and third-party notices required by the exported runtime; M07 validates packaging. Installed-version evidence belongs in setup output and STATUS; verify official artifact checksums if a future download is needed. |
| SRC-001 | Original game scripts, tests, procedural world generation, trick catalog and ride-state integration, excluding DEP-002 | Original work produced for this repository | Project owner controls distribution; no public project licence selected | Do not infer an MIT game licence from the engine or an imported component. |
| DEP-002 | `game/tricks/grind_line.gd` | [TinyBitAdventures/not-pro-skater](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/skater/grind_line.gd), Austin Ginder, 2026 | MIT; [full retained notice](third-party/not-pro-skater-MIT.txt) | Adapted isolated source, no assets. Revision/file hashes, inspected scope and modification record in [reuse research](../research/SKATING_REUSE.md). Preserve notice in source and future native distributions; export/package audit must include it explicitly. |
| ART-001 | Articulated rider/board, buildings, ramps, statue/cone, signs, NPCs and icon | Original procedural geometry and native skinned garments in `game/player/skater_visual.gd`, `game/player/skater_garments.gd`, `game/levels/city_art.gd`, `game/levels/art/`, `game/levels/glasgow_square.gd`; original `game/icon.svg` | Project-owned original content | Original mesh generation and generated material tiles. Imported photographic textures are separately recorded as ART-002; no external character model is bundled. Further art cleanup and final realistic visual acceptance remain open. |
| ART-002 | Weathered red brick and mineral concrete albedo/OpenGL normal textures | ZC / DaZCDude, [ZC's Spectacular Textures](https://github.com/DaZCDude/ZCs-Spectacular-Textures/tree/a866769b0ccb5e041f8855a52223d7d1a1166125), inspected 17 October 2026 | CC0 1.0; [complete retained text](third-party/zc-spectacular-textures-CC0.txt); author states all source photos were taken and edited by them | Four unchanged JPEGs total 4,057,737 bytes, stored in `game/art/assets/zc_textures/`. Pinned source, per-file hashes, physical-scale assumptions and 1024px/mipmap import settings in `manifest.json`. Roughness is an authored scalar because no source roughness maps were supplied. See [asset research](../research/VISUAL_ASSETS.md). Notices and texture provenance accompany native packages. |
| TXT-001 | Tam Hawks title, UI strings, fictional dialogue and goals | Original project text; user supplied concept | Project-owned text | Final title clearance remains M07; familiar architectural references are not copied branding. |
| DOC-001 | Original autonomous development plan | User-supplied pasted document, preserved verbatim | Provided by owner for this project | Internal project source record; do not represent its third-party franchise references as permission to reuse franchise content. |
| SFX-001 | Locally synthesised skating effects and four abstract district ambience beds | Original deterministic PCM generators in `game/audio/skate_audio.gd` | Project-owned generated waveforms | Runtime-generated and cached locally; no samples, music or field recordings. Automated signal/trigger checks are recorded in `docs/testing/AUDIO.md`; human listening remains open. |
| VOX-001 | Three synthetic NPC lines: “Some landing.”, “Mind the cone.”, “One more run.” | Original project text; generated locally by installed Flite 2.2-7 with CMU KAL16 via `tools/generate_voice.py` | Permissive CMU Flite and voice database licences; no prohibition on redistributing generated speech found in inspected notices | Shipped WAVs in `game/audio/generated/`; pinned upstream `e9e2e37c329dbe98bfeb27a1828ef9a71fa84f88`. Preserve [Flite COPYING](third-party/flite-COPYING.txt), [KAL16 licence](third-party/flite-kal16-LICENSE.txt) and [Debian copyright](third-party/flite-debian-copyright.txt). No runtime Flite dependency, paid service, performer imitation or claimed Glasgow accent. Generator, hashes and inspection evidence in `docs/testing/AUDIO.md`. |

## Geography reference material

`docs/research/GLASGOW_REFERENCES.md` records inspected historical address leads from a pinned community dataset. That dataset has no established redistribution licence and has not been imported or redistributed. Official/map/Street View pages were blocked and their contents remain uninspected. Individual factual observations can inform original facade designs once verified; source photographs, map tiles, panoramas and logos need separate permissions before inclusion as assets.

## Prohibited imports

No commercial game models, animation, level layouts, textures, logos, character names, UI copies or recordings. No licensed music without an explicit licence and approval. No performer voice cloning or imitation. No asset pack is approved merely by a URL or a marketplace “free” label.

## Per-asset record for future additions

Record stable source URL, exact version/download date, author, licence text path, attribution, allowed modification/redistribution, any model/output licence distinction, files included and the approving A01/A03 review. For procedural/generated content, record the source generator and inputs. Never store credentials in a manifest.

## Unresolved release items

- Select the project's public source/content licensing terms with the owner before publishing a licence grant.
- Check the Tam Hawks title and included real/fictional shop signs during release review; reference photographs/logos are not automatically production assets.
- Validate runtime notices in each exported package; `tools/export.sh` includes engine notices and the reviewed third-party notice files.
- Review synthetic NPC voice clarity and tone by listening on target hardware; the lawful local source is implemented, while audio acceptance remains open.
