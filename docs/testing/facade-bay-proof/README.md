# Isolated Glasgow bay proof

18 October 2026 (Europe/London). Original [editable source and audit](../../../art_source/glasgow_bay/README.md), three GLBs and local PBR images. The prototype stays outside the live map behind `.gdignore`; no collision, rail, footprint, save or gameplay changes.

The actual GLB audit passes 18,392 / 3,544 / 648 triangles, one mesh/four opaque surfaces each, identical metre bounds, finite nondegenerate geometry/UVs, unit orthogonal normals/tangents and embedded original textures. Two factory-startup Blender exports match all seven GLB/PNG hashes. These are alternatives, not three simultaneous models; later production work should share textures rather than duplicate embedded maps.

Six real Godot 4.6.3 Compatibility images show each alternative from the same front/detail camera. Copied GLB hashes match those recorded during rendering; the executed fixture/project match retained source. All six PNGs passed CRC and row decoding. Root inspected near front/detail and far front: recessed windows, shaped sills, cornice and shop joinery remain visible; the far alternative removes fine detail. This is an isolated asset inspection, not a matched improvement against the live facade.

The fixture uses production ambient/light colour, light angle/energy and ACES values, with a neutral background and ground, 45 m shadows, and no production sky reflection or scene fog. Opaque glazing is very dark in this setup; material readability under the actual world sky remains open. A fixed clock/forced draw supplies presentation evidence only. The first fixture failed GDScript type inference and is rejected; the corrected explicit type exits 0 with six image records. No timing result is claimed.

Run `./art_source/glasgow_bay/preview/run.sh` using installed Godot 4.6.3. It creates a disposable project and unique local output, imports copied assets and uses the native desktop or existing free Linux private-display setup. No downloads, player profile writes or live imports. The source generator/audit remain the editable asset workflow.

Next: choose one existing frontage, compare its actual close/chase views under the world sky, preserve structural collision/thresholds/rail and camera clearances, share materials, author explicit replacement ranges with hysteresis, and measure both directions before rollout. The prototype does not close final realism, current-shop accuracy, material polish, live LOD switching, Mac or frame-time acceptance.
