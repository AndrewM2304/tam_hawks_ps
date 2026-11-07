# Original Tam skateboard UV derivative

The model, river graphic, grip and base atlas are project-authored original
content (ART-001). No external visual assets, photographs, logos or branding are
included. Existing ownership is unchanged; no public project licence grant has
been selected. The derivative uses deterministic original NumPy grain/ply
colours. Physical thickness and bolt arrangement are inherited and remain open.

The original base is byte-pinned in tools/art/source/tam_skateboard-base.glb.gz;
its original manifest and generator hash are preserved alongside it. The
original Blender generator remains tools/art/build_skateboard.py. The final
reproduction entry is tools/art/regenerate_skateboard_uv.py. It requires pinned
NumPy/SciPy/Pillow development dependencies, not game/runtime dependencies.

## Godot import algorithm attribution

The exact-position shadow-vertex deduplication/LOD remapping in
`tools/art/import_board_wood.gd::_source_shadow` is adapted from Godot Engine's
ImporterMesh shadow-mesh algorithm. Public source inspected: Godot 4.6.3 tag
35e80b3, scene/resources/3d/importer_mesh.cpp. This is corroborating algorithm
source, not a claim that the installed 7d41c59c4 binary was built from that tag.
The editor policy is a project-authored adaptation through public script APIs.

Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
