# Primary-source contract

Exact Godot4.6.3 source URLs and SHA256s are in sources.json. Full downloaded sources stay in the ignored research directory.

- `editor/import/resource_importer_texture.cpp:937–941`: high_quality selects COMPRESS_BPTC; false selects COMPRESS_S3TC. Forced normal-map source chooses USED_CHANNELS_RG.
- `modules/etcpak/image_compress_etcpak.cpp:59–74`: RGB→DXT1, RG→RGTC_RG, RGBA→DXT5.
- `drivers/gles3/storage/config.cpp:80,86–91`: BPTC requires its extension; desktopGL enables S3TC and RGTC, the latter core sinceOpenGL3.0. An OpenGL4.1 label alone does not establish BPTC extension support. The owner's warning establishes the missing support on their observed driver.
- `drivers/gles3/storage/texture_storage.cpp:650–713`: unsupported BPTC enters the decompression fallback; supported S3TC/RGTC upload compressed data.
- `scene/resources/material.cpp:968–969,1092`: albedo uses source_color; normal does not. Existing ARM channels remain linear roughness/AO inputs. `drivers/gles3/shaders/scene.glsl:2159–2164` reconstructs positive normal Z from RG and ignores stored blue, matching the CPU angular comparison.
- `editor/file_system/editor_file_system.cpp:553–586,670–676`: prior filesystem modification/import hashes can trigger reimport; missing named destination payloads trigger reimport even without a prior filesystem cache. Updated S3TC/ETC2 remaps therefore regenerate through the ordinary launcher; no manual cache deletion is needed.

The Godot4.6 image-import documentation says Compatibility always disables high-quality compression. That wording disagrees with the exact importer branch and observed actual owner log. This repair follows the versioned implementation and measured native formats. The sources.json top-level retrieval time covers the initial download group; later appended references were fetched during this task without separate per-file timestamps.
