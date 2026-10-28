# Original offline experimental derivative

The geometry derives from the repository's original
[`../generator.py`](../generator.py), with the fitted complete entry translation
documented in [`../fitted/README.md`](../fitted/README.md). New changes are a
single-segment near bevel policy, two material slots, original mathematical
atlas pixels and coordinate/audit bookkeeping. No external geometry, franchise
content, real business identity, photographed reflection or web image is used.

Sandstone base colour, OpenGL normal and ORM maps are copied byte-for-byte from
the original proof. The new colour atlas samples its original
`opaque_glazing_basecolor.png`, using its existing painted-wood and aged-metal
linear colour constants. The ORM atlas uses the existing roughness and metallic
constants. Actual input/output hashes are retained in `generation.json`, `atlas.json`
and the independently decoded `audit.json`; reproducibility has its own receipt.
The original generator, audit helper, four source maps and three fitted GLBs
are checked byte-for-byte before/after generation and during the audit.

Rights remain with the repository owner's project licensing under the existing
[`../LICENSE-NOTICE.md`](../LICENSE-NOTICE.md); this experiment makes no new public
licence grant. Installed Blender, Python, NumPy and Pillow are tools, not bundled
assets or source. No tool source is copied. No download, installation, purchase,
API, native messaging, rendering or live runtime integration is required.
