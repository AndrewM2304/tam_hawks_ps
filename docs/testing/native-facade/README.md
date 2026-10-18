# Current native checkpoint — 18 October 2026

Both unsigned local packages export from clean **`b97dac100f2993a26aaf50a05cb3b9676ea3d4e2`**, with **171 package inputs unchanged**. Required `./tools/check.sh` passes **1,739/0** on **309 unchanged inputs** at `9549d5c`; all current game/test/tool/project inputs still match those hashes. [Archive/source audit](ARCHIVE-AUDIT.json), [build metadata](BUILD-METADATA.json), [combined receipt](RECEIPT.json) and [ordinary source receipt](../logs/facade-ordinary-source.json).

The auditor validates all source files against both committed Git objects and checkout, pinned official templates, ZIP CRC/path/mode safety, Linux ELF and Mac universal x86_64+arm64 slices, byte-identical cross-platform packs and all 13 notices/provenance records. It verifies **161 ordinary/package** and **160 normal-capture/package** overlaps and independently decodes/hashes all **19 normal-play images**. Source/Linux-pack/Mac-pack construction probes match: 48 routes, 351 bodies/1,863 shapes,64 m batching, displayed interpolation, graphics choices, classic tricks/pipes and original bin percussion. Normal Main constructs **zero fitted facade pilots** and the default is OFF; separate checks load held 18,392/3,544/648-triangle assets and four shared 1024px maps. `art_source` and the two-surface experiment are absent from both packs. Pack availability does not accept the rejected live candidate.

Actual standalone Linux main starts pass: **headless 120 frames exit 0** and **rendered 1920×1080 / 30 frames exit 0**, from an empty working directory and isolated XDG. No script override, fixed clock or synthetic input is used. [Startup receipt](SMOKE-RESULTS.json), [summary](smoke-summary.log), [headless](headless.log), [rendered](rendered.log) and the real [title frame](title-live.png) are retained. Root inspected the fully contained, readable menu/focus. The driver's unsupported V-Sync warning is retained; script/resource error scans are clean. This is startup evidence, not a gameplay or FPS result. **The unsigned Mac executable remains unlaunched**, and Apple M5/DualSense/audio/save/performance acceptance remains open.

Local ignored artifacts, not uploaded or published:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `TamHawksProSkater-linux.zip` |34,400,966|`5e2a8602fc583b7459f9fab615cf88350c079eb764baae8b06824085d0284984`|
| `TamHawksProSkater-macos.zip` |68,960,501|`74f62c384467d7670ff10d28cf6fa1f305d4db8e3ae4ef94f944229cab67c580`|

Build directory: `builds/tam-hawks-20261018T082004Z-b97dac100f29/`. No signing, notarization, upload, paid service or hosted CI.

## Repeat

After current source passes the required check, commit a clean checkpoint, then run:

```sh
./tools/export.sh --skip-check
python3 docs/testing/native-facade/audit.py <new-build-directory> --receipt-dir <new-receipt-directory>
python3 docs/testing/native-performance/smoke_capture.py <new-build-directory>
```

The reusable smoke recipe hash is in RECEIPT. Do not overwrite old evidence or reuse these packages to certify later runtime edits. `--skip-check` here reuses the just-passed unchanged source; it is not a replacement for required verification.

Independent review tightened source binding to exact membership and every hash of all ordinary-tested inputs before archive comparison. Two disposable altered-receipt cases (changed tested-tool hash, added untested inventory member) both reject with exit 1 before any engine launch. [Negative cases](source-binding-negative.json) and [expected rejection logs](rejected-source-evidence.log) retain that evidence; actual source was never mutated. An earlier source-probe call omitted its mandatory output path and was rejected; the saved probe now fails cleanly on that misuse. Rejected attempts are not acceptance.
