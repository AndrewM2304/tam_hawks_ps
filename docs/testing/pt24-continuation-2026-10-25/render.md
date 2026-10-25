# Clyde display ownership and station plinth joins

25 October 2026. Owner-approved consolidated continuation on main; source
baseline `6b18f30`. This slice addresses proven duplicate faces. It does not
claim that all reported temporal shadow or material flicker has been solved.

## Declared cost and scope

No new collision bodies/shapes, visible surfaces, materials, textures, lights,
frame callbacks or per-frame allocations. Existing quays keep their native grids,
height queries, hazards, route and grind identities. Existing station north
fences keep all native convex panels, ironwork and masonry instance counts.
Submitted triangles must not increase across the two changed quay displays.
The dense flat north display can drop from 340 triangles to two; south clipping
retains the bowl/hip cuts and may introduce a few triangulation edges.

`PT24RenderRepairs.install(world)` runs once after the outdoor/fidelity geometry
and exploration boundaries, before art/static batching. Reinstallation is
idempotent. The internal `pt24_render_repairs_baseline` metadata flag is only a
matched diagnostic fixture; ordinary play applies the repair.

## Source-proven causes and repairs

`NorthEmbankment` is a native/visible box centred at `(0,-0.2,77.6)` with size
`(170,4.4,0.8)`. Its top is exactly Y2, coincident with the paved north-quay grid
over X−85…85/Z77.2…78: **136m²** of duplicate horizontal faces.

`SouthEmbankment` is centred at `(18.5,-0.2,116.4)` with size `(115,4.4,0.8)`.
Its Y2 top overlaps the south-quay paving over X−39…76/Z116…116.8:
another **92m²**. The existing stone coping owns both strips after the repair.
Native support stays unchanged beneath the display exclusion.

The north quay is a complete flat rectangle. Its visible top is rebuilt as one
exact two-triangle plane ending at Z77.2. An area/height assertion refuses an
unexpected source hole instead of filling it. The south display is clipped in
place, preserving its independent bowl/hip excavations and existing material.

The station-north fence's plinth consists of neighbouring half-metre-square
boxes. The earlier beam helper extended every piece by 4cm; adjacent flat top
and side skins therefore overlapped over a positive area. The repair reconstructs
the same number of visual transforms from the retained boundary points, using
the exact segment length. All pieces meet at their authored endpoints. The
native panels and ironwork are untouched. Construction transforms are retained
for deterministic verification because headless rendering cannot reliably read
MultiMesh GPU transforms back.

## Deterministic checks

`tests/pt24_render_repairs_tests.gd` independently checks the north visible area,
both fixed coping bands and their actual stone display, inland paving, original
native contacts at the recorded quay/landfall witnesses, existing south display
holes, shared materials, byte-identical native grids, resident child counts and
idempotency. A separate 36m fence fixture checks all 24 plinth pieces against
fixed endpoints, with no gap/overlap and unchanged native panel vertices.

Root integration owns the focused/required suite execution and receipts. No
engine or performance job was launched by the rendering specialist while other
agents were editing source.

The first integrated focused run exposed one incorrect expected sample in this
test: X−25/Z116.4 lies under the safe bridge's final Y3.4→2 grade, with highest
support Y2.461176m. The test now uses that independently declared deck height;
the actual reported landfall at X−25.4/Z122.315 remains beyond the deck and Y2.
No production geometry or assertion tolerance was changed for this correction.
Root retains the failed initial run and owns the final rerun receipt.

## Bounded rendered evidence

`tools/pt24_temporal_probe.gd` supports a matched diagnostic before/after mode:

```sh
./tools/run.sh --rendering-method gl_compatibility --windowed --resolution 1280x800 --audio-driver Dummy --disable-render-loop --fixed-fps 60 --script tools/pt24_temporal_probe.gd -- --witness=20,29,35 --samples=3 --output=res://.local/pt24-temporal/after
```

The runner needs an actual graphical display, as supplied by the existing capture
shell helpers. Add `--baseline` and a separate output directory for prior display
ownership. Each witness begins at the owner's exact recorded camera and advances
one metre over the declared samples, with paused simulation and unchanged
shadow/filter/MSAA settings. It saves completed native readbacks, source hashes
and draw/primitive/memory counters. This is world-only analytic camera evidence;
it does not establish normal-input route quality, frame-time performance or Mac
acceptance. Image readback timings must not be used as a performance benchmark.

### Completed matched-camera A/B

The root ran both modes at owner witnesses **20, 29 and 35**, three frames per
witness. Each mode completed **9 native PNG readbacks, zero failures**, against
**96 unchanged source hashes**. The two manifests have exactly the same source
hash map and camera positions/workload. All 18 recorded PNG hashes were checked
against the actual files. Both runs use Godot **4.6.3 Compatibility**, Linux
**llvmpipe (LLVM19.1.7, 256bits)**, 1280×800 and the same Balanced-equivalent
PCF/MSAA/far settings.

The baseline flag skips only this slice's coping/plinth display ownership. It
does not restore an older game revision or change lighting, support, movement,
camera settings or other repairs. Portable artifacts are [before](temporal/before/manifest.json) and
[after](temporal/after/manifest.json). The final refresh includes the completed approach shoulder and later
civic-preview closure in the bound source. The preview is absent in both
ordinary-world modes. Manifest SHA-256 values are:

```text
before de5360199c5946224a1f1325d4c902231e909473f05bf9c63271c89649bbb40b
after  bc46523d0ebbae05bb39632cc1342d4a183495e3bf1ed5260c5065b8529e0ea2
```

The captured construction report confirms **528→213 triangles** across the two
quay displays (−315), the north display's two triangles, **228m²** of removed
duplicate tops, and **54** repaired station plinth instances. The first frame of
each witness reports these native rendering counters:

| Owner witness | Draw calls before→after | Reported primitives before→after |
| --- | ---: | ---: |
| 20 · station fence base | 1,114→1,114 | 940,553→940,215 |
| 29 · north-quay edge | 209→209 | 93,830→93,200 |
| 35 · bridge landfall | 925→925 | 496,337→495,707 |

Every matched frame retains the same draw count. Texture memory is unchanged at
**40,613,556B**; reported video memory is **59,390,880→59,373,542B** (−17,338B).
These are backend counter snapshots, including its submitted rendering work;
they are not a timing benchmark or a claim of improved FPS.

The initial north-quay before/after frames and corrected station/landfall frames
were visually inspected: the stone edge, plinth, adjoining paving and bridge
remain present. This bounded review does not close temporal acceptance. There
are only three analytic camera samples per witness, no rider/HUD or mapped-input
run, and paused simulation does not freeze shader `TIME`; animated water can
differ between captures. No pixel-variance statistic or water/shadow difference
is being used as evidence that the owner's flicker is eliminated. Actual moving
target-Mac shadow/material acceptance remains open.

## Still open

PT24-01 civic moving-shadow diagnosis has no new proven root cause in this slice.
PT24-09 park tile temporal acceptance and PT24-10 Exchange masonry-base flicker
also remain open. Removing station plinth/coping duplicates is a concrete repair
under PT24-12/21, but moving native acceptance remains necessary; still images
alone cannot prove it. Global shadow bias, shadows/ranges and normal materials
were not weakened to hide the owner's reports.

The chase-camera specialist/root separately addresses repeated identical native
queries and first-play landmark construction. Root records their parity evidence
separately; target timing remains open and this geometry result makes no FPS claim.
