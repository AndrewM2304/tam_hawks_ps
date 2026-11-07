# Private source UV01 — native board finish

No actual asset/source promotion, native import, rendered appearance, contact or
M5 acceptance. This is a private offline derivative of the tracked original GLB.

`board_uv_finish.py.txt` reads actual float32 position/normal/UV/index buffers and
preserves every maple drawn triangle corner and all other primitive buffers. It
splits UV seams, maps sidewalls by finite perimeter distance and laminate height,
places seven restrained ply bands in an otherwise unused atlas area, and moves
upward-facing wood to a separate original maple patch. Downward river-art UVs and
left-half pixels, the complete grip quadrant, and protected hardware sampling
neighbourhoods remain unchanged. No external artwork is used.

The same-author separate verifier passes19controls, including the exact original
172/224side-face defect under RA's `abs(normal.y)<0.3`, doubled3Darea>1e−12 and
UVarea<1e−12 criterion. A broader0.5normal cutoff finds427collapsed UV faces among
600side/bevel triangles. All2600candidate wood triangles have nonzero UV area;
triangle geometry/winding and protected buffers remain exact. Tangent frames have
finite unit orthogonal axes and every corner agrees with its independent
Jacobian-derived bitangent (minimum normalized dot0.804868). Explicit collapsed
UV, bad tangent sign,100µm wheel displacement and reversed winding controls reject.
These are author controls, not an independent QE pass.

Private output:
`.local/board-fidelity/candidate-uv01/tam_skateboard.glb`, SHA-256
`6d1b5fd27af335650db36786fd72a46249d8a272594f8bc5adf35a95e806f0c0`.
The generator/PNG/source report hashes and declared budgets are retained in the
JSON records. It adds0triangles and30,800geometry-buffer bytes; encoded GLB grows
21,492bytes. Atlas dimensions and conservative unique RGBA allocation stay fixed.
Runtime component IDs/markers/resource allocation still need actual native proof.

The physical28mm thickness remains unresolved. The measured conflict with the
old underside marker and truck mount is documented in
[BOARD-CONSTRUCTION](../../../research/BOARD-CONSTRUCTION.md). A UV fix must not be
presented as successful physical construction. Next gates are independent source
review, source-frozen native component/UV/marker checks and close normal/shaded
frames, followed by actual action/contact/moving and integration gates.
