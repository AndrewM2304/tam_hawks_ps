# Fitted bay provenance — 18 October 2026

This is a derivative of the repository's original `art_source/glasgow_bay` proof, created for Tam Hawks Pro Skater using installed Blender 4.3.2 and local Python. It uses no external model, image, font, business logo, downloaded code or paid service. The architectural composite is not a surveyed or verified present-day shop.

The original source generator, GLBs, textures, audits and preview files are preserved byte-for-byte; `generation.json` records their hashes and the new audit rechecks them. The only geometry modification is the complete entry's +0.33 m vertical translation. The fitted generator additionally fixes UV selection: original authored `FacadeUV` becomes the sole primary glTF UV set and tangents are regenerated. No other geometry or authored UV coordinates change, as verified by comparing the original and fitted exported triangle/UV data.

The four runtime PNGs are exact copies of the original mathematically generated 1024² images. Their original hashes and source/fitted generator hashes appear in `audit.json` and runtime `manifest.json`. Blender is used solely as an offline modelling/export tool; no Blender source or binary is redistributed, and the tool's GPL does not become the licence of these original exported assets.

Rights remain subject to the repository owner's chosen project licensing, as stated in the unchanged [original licence notice](../LICENSE-NOTICE.md). This preparation makes no independent public-licence grant. No third-party asset licence is needed because no third-party asset content is included. The runtime directory carries the same notice and a source pointer.

Actual live Godot import/render/material/LOD/performance acceptance belongs to the separate integration task. Nothing in this asset audit certifies those unperformed checks.
