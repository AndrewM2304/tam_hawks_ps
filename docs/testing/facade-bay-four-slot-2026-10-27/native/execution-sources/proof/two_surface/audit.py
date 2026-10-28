"""Independent decoded-GLB and decoded-PNG audit; no Blender/Godot required.

Run only after the root releases the exclusive timing window. Writes audit.json
even when the prospective colour-error gate fails, then exits nonzero. A pass
never certifies runtime, appearance, mip filtering on a GPU, or performance.
"""
from collections import Counter
from pathlib import Path
import hashlib
import importlib.util
import json
import math
import sys

import numpy as np
from PIL import Image

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
PROOF = ROOT.parent
SLOTS = ["01_Original_sandstone", "02_Original_accent_atlas"]
BOUNDS = ([-3.25, 0, -0.5], [3.25, 16, 0.36])
DOMAIN = (-1.75, -0.25, 1.75, 8.0)
RECTS = {1: (16, 432, 224, 496), 2: (16, 16, 496, 400), 3: (272, 432, 496, 496)}
COLOURS = {1: (0.028, 0.085, 0.067), 3: (0.105, 0.095, 0.069)}
ORM = {1: (1.0, 0.48, 0.0), 2: (1.0, 0.32, 0.0), 3: (1.0, 0.46, 0.65)}
NAMES = {1: "paint", 2: "glazing", 3: "metal"}
STONE = ("sandstone_basecolor.png", "sandstone_normal_opengl.png", "sandstone_orm.png")
spec = importlib.util.spec_from_file_location("preserved_glb_reader", PROOF / "audit.py")
H = importlib.util.module_from_spec(spec)
spec.loader.exec_module(H)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def decode(path, srgb):
    pixels = np.asarray(Image.open(path).convert("RGB"), dtype=np.float64) / 255
    if srgb:
        pixels = np.where(pixels <= 0.04045, pixels / 12.92, ((pixels + 0.055) / 1.055) ** 2.4)
    return pixels


def sample(pixels, uv, repeat=False):
    """Independent top-origin glTF lookup, linear filtering decoded PNGs."""
    uv = np.asarray(uv, dtype=np.float64).reshape((-1, 2))
    h, w = pixels.shape[:2]
    coords = uv * [w, h] - 0.5
    low = np.floor(coords).astype(np.int64)
    weight = coords - low
    x0, y0 = low[:, 0], low[:, 1]
    x1, y1 = x0 + 1, y0 + 1
    if repeat:
        x0, x1, y0, y1 = x0 % w, x1 % w, y0 % h, y1 % h
    else:
        x0, x1, y0, y1 = np.clip(x0, 0, w - 1), np.clip(x1, 0, w - 1), np.clip(y0, 0, h - 1), np.clip(y1, 0, h - 1)
    wx, wy = weight[:, 0:1], weight[:, 1:2]
    return ((1 - wy) * ((1 - wx) * pixels[y0, x0] + wx * pixels[y0, x1])
            + wy * ((1 - wx) * pixels[y1, x0] + wx * pixels[y1, x1]))


def rect(material, size):
    x0, y0, x1, y1 = RECTS[material]
    return ((x0 * size / 512 + 0.5) / size, (y0 * size / 512 + 0.5) / size,
            (x1 * size / 512 - 0.5) / size, (y1 * size / 512 - 0.5) / size)


def map_uv(original_gltf, material, size):
    original = np.asarray(original_gltf).copy()
    original[:, 1] = 1 - original[:, 1]
    a, b, c, d = DOMAIN
    x0, y0, x1, y1 = rect(material, size)
    mapped = (original - [a, b]) / [c - a, d - b] * [x1 - x0, y1 - y0] + [x0, y0]
    mapped[:, 1] = 1 - mapped[:, 1]
    return mapped


def triangle_key(material, vertices):
    return material, tuple(sorted(tuple(round(float(v), 5) for v in row) for row in vertices))


def old_triangles(lod):
    doc, binary, _ = H.glb(PROOF / "fitted/generated" / ("glasgow_bay_" + lod + ".glb"))
    records, positions = Counter(), []
    for p in doc["meshes"][0]["primitives"]:
        pos = H.accessor(doc, binary, p["attributes"]["POSITION"])
        uv = H.accessor(doc, binary, p["attributes"]["TEXCOORD_0"])
        ids = [row[0] for row in H.accessor(doc, binary, p["indices"])]
        positions.extend(pos)
        for start in range(0, len(ids), 3):
            records[triangle_key(p["material"], [(*pos[i], *uv[i]) for i in ids[start:start + 3]])] += 1
    return records, np.asarray(positions)


def inspect(lod, size):
    path = ROOT / "generated" / ("glasgow_bay_" + lod + ".glb")
    doc, binary, raw = H.glb(path)
    assert len(doc["nodes"]) == len(doc["meshes"]) == len(doc["buffers"]) == 1
    assert not any(doc.get(k) for k in ("images", "textures", "samplers", "extensionsUsed", "extensionsRequired"))
    assert doc["materials"] == [{"name": name, "alphaMode": "OPAQUE", "doubleSided": False} for name in SLOTS]
    node = doc["nodes"][0]
    assert node.get("translation", [0, 0, 0]) == [0, 0, 0]
    assert node.get("rotation", [0, 0, 0, 1]) == [0, 0, 0, 1]
    assert node.get("scale", [1, 1, 1]) == [1, 1, 1] and "matrix" not in node
    surfaces = doc["meshes"][0]["primitives"]
    assert len(surfaces) == 2 and [p["material"] for p in surfaces] == [0, 1]
    records, all_pos, samples, surface_data = Counter(), [], {k: [[], []] for k in NAMES}, []
    triangle_count = vertex_count = 0
    uv_error = 0.0
    for primitive in surfaces:
        attributes = primitive["attributes"]
        assert set(attributes) == {"POSITION", "NORMAL", "TANGENT", "TEXCOORD_0", "TEXCOORD_1"}
        values = {k: np.asarray(H.accessor(doc, binary, v)) for k, v in attributes.items()}
        pos, normals, tangent, uv, source = [values[k] for k in ("POSITION", "NORMAL", "TANGENT", "TEXCOORD_0", "TEXCOORD_1")]
        assert all(len(a) == len(pos) and np.isfinite(a).all() for a in values.values())
        assert np.max(abs(np.linalg.norm(normals, axis=1) - 1)) < 0.005
        assert np.max(abs(np.linalg.norm(tangent[:, :3], axis=1) - 1)) < 0.005
        assert np.max(abs(abs(tangent[:, 3]) - 1)) < 0.001
        assert np.max(abs(np.sum(normals * tangent[:, :3], axis=1))) < 0.005
        ids = np.asarray([row[0] for row in H.accessor(doc, binary, primitive["indices"])])
        assert len(ids) % 3 == 0 and min(ids) >= 0 and max(ids) < len(pos)
        classes = np.zeros(len(pos), dtype=np.int64)
        if primitive["material"] == 0:
            assert np.max(abs(uv - source)) < 1e-6, "Stone UV0 must exactly preserve authored UV"
        else:
            bottom = uv.copy()
            bottom[:, 1] = 1 - bottom[:, 1]
            for material in NAMES:
                x0, y0, x1, y1 = rect(material, size)
                selected = (bottom[:, 0] >= x0 - 1e-6) & (bottom[:, 0] <= x1 + 1e-6) & (bottom[:, 1] >= y0 - 1e-6) & (bottom[:, 1] <= y1 + 1e-6)
                assert not np.any(classes[selected])
                classes[selected] = material
                if np.any(selected):
                    error = float(np.max(abs(uv[selected] - map_uv(source[selected], material, size))))
                    uv_error = max(uv_error, error)
                    assert error < 2e-6, "Original UV phase/continuous atlas mapping changed"
            assert np.all(classes > 0), "An accent UV leaves its assigned rectangle"
        for tri in ids.reshape((-1, 3)):
            a, b, c = pos[tri]
            assert np.linalg.norm(np.cross(b - a, c - a)) > 1e-10
            d1, d2 = uv[tri[1]] - uv[tri[0]], uv[tri[2]] - uv[tri[0]]
            assert abs(d1[0] * d2[1] - d1[1] * d2[0]) > 1e-14
            material = int(classes[tri[0]])
            assert np.all(classes[tri] == material), "A triangle crosses material atlas regions"
            records[triangle_key(material, [(*pos[i], *source[i]) for i in tri])] += 1
            if material:
                # Centroid and three off-centre triangle interiors, including
                # thin bevel faces. These use decoded exported UV0 and UV1.
                weights = np.asarray(((1 / 3, 1 / 3, 1 / 3), (0.8, 0.1, 0.1), (0.1, 0.8, 0.1), (0.1, 0.1, 0.8)))
                samples[material][0].extend(weights @ source[tri])
                samples[material][1].extend(weights @ uv[tri])
        all_pos.extend(pos)
        formats = {k: {"component_type": doc["accessors"][v]["componentType"], "type": doc["accessors"][v]["type"]} for k, v in attributes.items()}
        assert all(v["component_type"] == 5126 for v in formats.values())
        formats["INDICES"] = {"component_type": doc["accessors"][primitive["indices"]]["componentType"]}
        surface_data.append({"slot": primitive["material"], "triangles": len(ids) // 3, "vertices": len(pos), "formats": formats,
            "decoded_data_sha256": hashlib.sha256(b"".join(values[k].tobytes() for k in sorted(values)) + ids.tobytes()).hexdigest()})
        triangle_count += len(ids) // 3
        vertex_count += len(pos)
    positions = np.asarray(all_pos)
    assert np.max(abs(positions.min(axis=0) - BOUNDS[0])) < 1e-4
    assert np.max(abs(positions.max(axis=0) - BOUNDS[1])) < 1e-4
    assert {"near": 1000, "mid": 2000, "far": 300}[lod] <= triangle_count <= {"near": 10000, "mid": 5000, "far": 800}[lod]
    old, old_pos = old_triangles(lod)
    comparison = {"fitted_triangles": sum(old.values()), "shared_exact_position_and_source_uv_triangles": sum((old & records).values())}
    if lod != "near":
        assert old == records, "Mid/far geometry and authored texture phase must remain exact"
        comparison["all_geometry_and_authored_uvs_identical"] = True
    else:
        # Convex support is a macro-bound check, not proof of every silhouette.
        directions = np.asarray([(math.cos(a) * math.cos(b), math.sin(b), math.sin(a) * math.cos(b))
            for a in np.linspace(0, 2 * math.pi, 24, endpoint=False) for b in (-0.7, 0, 0.7)])
        error = max(float(abs((positions @ d).max() - (old_pos @ d).max())) for d in directions)
        assert error <= 0.02
        comparison.update(macro_support_max_error_m=error, complete_silhouette_preservation="Not claimed: one-segment chamfers alter small rounded profiles; matched views pending")
    threshold = positions[(positions[:, 0] >= 1.3999) & (positions[:, 0] <= 2.6001) & (positions[:, 1] >= 0.3299) & (positions[:, 1] <= 0.5301)]
    assert len(threshold) and abs(threshold[:, 1].max() - 0.53) < 1e-4
    return {"file": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw),
            "triangles": triangle_count, "exported_vertices": vertex_count, "opaque_surfaces": 2,
            "bounds_min_m": positions.min(axis=0).tolist(), "bounds_max_m": positions.max(axis=0).tolist(),
            "threshold_top_m": float(threshold[:, 1].max()), "max_continuous_uv_mapping_error": uv_error,
            "fitted_comparison": comparison, "surfaces": surface_data}, samples


def errors(a, b):
    delta = np.abs(a - b)
    maximum_channel = delta.max(axis=1)
    return {"samples": len(delta), "mean_absolute_linear_rgb": float(delta.mean()),
            "p95_max_channel_linear": float(np.quantile(maximum_channel, 0.95)), "max_channel_linear": float(delta.max())}


def mip(pixels):
    h, w = pixels.shape[:2]
    return pixels[:h // 2 * 2, :w // 2 * 2].reshape((h // 2, 2, w // 2, 2, 3)).mean(axis=(1, 3))


def texture_audit(size, samples):
    expected = set(STONE) | {"accent_basecolor.png", "accent_orm.png"}
    assert {p.name for p in (ROOT / "textures").glob("*.png")} == expected
    for name in STONE:
        assert (ROOT / "textures" / name).read_bytes() == (PROOF / "textures" / name).read_bytes()
    colour = decode(ROOT / "textures/accent_basecolor.png", True)
    orm = decode(ROOT / "textures/accent_orm.png", False)
    original = decode(PROOF / "textures/opaque_glazing_basecolor.png", True)
    assert colour.shape == (size, size, 3) and orm.shape == (128, 128, 3)
    records = []
    failures = []
    for lod, lod_samples in samples.items():
        for material, (source_uv, actual_uv) in lod_samples.items():
            source_uv, actual_uv = np.asarray(source_uv), np.asarray(actual_uv)
            expected_colour = sample(original, source_uv, True) if material == 2 else np.broadcast_to(COLOURS[material], (len(actual_uv), 3))
            result = errors(expected_colour, sample(colour, actual_uv))
            # Prospective bounded error gates, declared before generation.
            # A max seam error is reported separately, not concealed by RMS.
            okay = result["mean_absolute_linear_rgb"] <= 0.003 and result["p95_max_channel_linear"] <= 0.01
            if not okay:
                failures.append(lod + ":" + NAMES[material] + " colour sampling gate")
            orm_error = float(np.max(abs(sample(orm, actual_uv) - ORM[material])))
            assert orm_error <= 1 / 255 + 1e-6
            records.append({"lod": lod, "class": NAMES[material], "base_level_error": result, "prospective_gate_passed": okay,
                            "orm_max_channel_error": orm_error})
    # Check both sides of every integer wrap crossed by the bounded field.
    # Do not wrap mesh vertices; seams occur inside the baked repeated field.
    seam_uv = []
    for axis, integers, other in ((0, (-1, 0, 1), np.linspace(-0.2, 7.9, 41)), (1, range(0, 8), np.linspace(-1.7, 1.7, 41))):
        for seam in integers:
            for epsilon in (-0.01, -0.001, -0.0001, 0, 0.0001, 0.001, 0.01):
                for value in other:
                    u, v = (seam + epsilon, value) if axis == 0 else (value, seam + epsilon)
                    seam_uv.append((u, 1 - v))
    seam_uv = np.asarray(seam_uv)
    mapped = map_uv(seam_uv, 2, size)
    seam_error = errors(sample(original, seam_uv, True), sample(colour, mapped))
    # Actual gutter pixels must be nearest-edge copies. The generated atlas
    # receipt is not trusted to assert its own extrusion.
    gutter_checks = 0
    for pixels in (colour, orm):
        n = len(pixels)
        bottom = pixels[::-1]
        pad = n // 32
        for coordinates in RECTS.values():
            x0, y0, x1, y1 = [int(c * n / 512) for c in coordinates]
            xx, yy = np.meshgrid(np.arange(x0 - pad, x1 + pad), np.arange(y0 - pad, y1 + pad))
            assert np.array_equal(bottom[yy, xx], bottom[np.clip(yy, y0, y1 - 1), np.clip(xx, x0, x1 - 1)])
            gutter_checks += int(xx.size)
    # This simulates box-filtered mips in linear colour space; it does not
    # substitute for the future renderer's compression/anisotropic filtering.
    mip_errors = []
    colour_mip, orm_mip = colour, orm
    for level in range(8):
        result = {"level": level, "colour_size": len(colour_mip), "orm_size": len(orm_mip),
                  "glazing_seam_reference_error": errors(sample(original, seam_uv, True), sample(colour_mip, mapped))}
        material_error = {}
        for material, (_, actual_uv) in samples["near"].items():
            material_error[NAMES[material]] = float(np.max(abs(sample(orm_mip, actual_uv) - ORM[material])))
        result["orm_class_max_errors"] = material_error
        mip_errors.append(result)
        if len(colour_mip) > 1:
            colour_mip = mip(colour_mip)
        if len(orm_mip) > 1:
            orm_mip = mip(orm_mip)
    return {"triangle_interior_samples": records, "integer_seam_samples": seam_error, "gutter_pixels_checked": gutter_checks,
            "simulated_linear_box_mips": mip_errors, "sampling_gate_failures": failures,
            "limits": "Deep mips can blend classes; max seam loss is reported. No exact shading, GPU mip, visual or timing pass is implied."}, failures


def main():
    generation = json.loads((ROOT / "generation.json").read_text())
    size = generation["atlas"]["colour_size"]
    assets, samples = [], {}
    for lod in ("near", "mid", "far"):
        asset, samples[lod] = inspect(lod, size)
        assets.append(asset)
    textures, failures = texture_audit(size, samples)
    for name, expected in generation["preserved_inputs_sha256"].items():
        assert digest(PROOF / name) == expected, "Preserved input changed: " + name
    maps = []
    for path in sorted((ROOT / "textures").glob("*.png")):
        maps.append({"file": path.name, "sha256": digest(path), "bytes": path.stat().st_size, "dimensions_px": list(Image.open(path).size)})
    # DXT-style example, not measured GPU residency: 8-bit/pixel three stone
    # maps + 4-bit/pixel opaque colour + 8-bit/pixel ORM, including 4/3 mips.
    estimated_bytes = (3 * 1024 * 1024 + size * size / 2 + 128 * 128) * 4 / 3
    # Most usefully, the three stone maps are identical and the default colour
    # map has the old glazing map's dimensions. The only texture-count delta
    # is the tiny ORM; exact resident bytes depend on the eventual importer.
    delta_bytes = ((size * size - 1024 * 1024) / 2 + 128 * 128) * 4 / 3
    first_bleed = next((row["level"] for row in textures["simulated_linear_box_mips"]
                        if max(row["orm_class_max_errors"].values()) > 0.01), None)
    report = {"schema": 1, "status": "EXPERIMENTAL; structural audit passed; " + ("sampling gate failed" if failures else "prospective base-level sampling gate passed"),
              "assets": assets, "texture_sampling": textures, "shared_maps": maps,
              "estimated_block_compressed_mip_bytes_not_gpu_measurement": estimated_bytes,
              "estimated_texture_byte_delta_vs_same_format_fitted_not_gpu_measurement": delta_bytes,
              "added_uv1_vertex_bytes_before_import": sum(asset["exported_vertices"] for asset in assets) * 8,
              "first_simulated_orm_mip_level_with_class_error_over_0_01": first_bleed,
              "preview_gate": "Open: inspect chamfer silhouette and glazing; verify actual mip selection/material bleed before integration",
              "inputs_preserved": len(generation["preserved_inputs_sha256"]),
              "source_sha256": {name: digest(ROOT / name) for name in ("generator.py", "atlas.py", "audit.py")},
              "not_tested": ["Blender render", "Godot import", "matched appearance", "runtime compression/mips", "LOD switching", "in-game performance", "Mac performance"]}
    (ROOT / "audit.json").write_text(json.dumps(report, indent=2) + "\n")
    for asset in assets:
        print(asset["file"], asset["triangles"], "triangles", asset["opaque_surfaces"], "surfaces", asset["bytes"], "bytes")
    print("TWO_SURFACE_STRUCTURAL_AUDIT PASSED; SAMPLING", "FAILED" if failures else "PASSED")
    if failures:
        raise SystemExit("; ".join(failures))


if __name__ == "__main__":
    main()
