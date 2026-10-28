"""Audit final fitted GLBs and independently compare their geometry to proof.

python3 art_source/glasgow_bay/fitted/audit.py
No Blender/Godot dependency or rendering. Fails nonzero on any mismatch.
"""
from collections import Counter
from pathlib import Path
import hashlib
import importlib.util
import json
import math
import struct
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
PROOF = ROOT.parent
REPO = PROOF.parents[1]
RUNTIME = REPO / "game/art/assets/glasgow_bay"
SLOTS = ["01_Original_sandstone", "02_Painted_forest_joinery",
         "03_Opaque_glazing", "04_Aged_dark_metal"]
TEXTURES = ["sandstone_basecolor.png", "sandstone_normal_opengl.png",
            "sandstone_orm.png", "opaque_glazing_basecolor.png"]
BOUNDS = ([-3.25, 0, -0.5], [3.25, 16, 0.36])
BUDGETS = {"near": (12000, 20000), "mid": (2000, 5000), "far": (300, 800)}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def helpers():
    spec = importlib.util.spec_from_file_location("proof_glb_reader", PROOF / "audit.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


H = helpers()


def triangle_records(doc, binary, uv_key="TEXCOORD_0"):
    result = Counter()
    for surface in doc["meshes"][0]["primitives"]:
        a = surface["attributes"]
        positions = H.accessor(doc, binary, a["POSITION"])
        uv = H.accessor(doc, binary, a[uv_key])
        indices = [i[0] for i in H.accessor(doc, binary, surface["indices"])]
        for start in range(0, len(indices), 3):
            # Micrometre rounding tolerates export float quantisation, but is
            # far tighter than any intended geometry/UV edit in this task.
            vertices = tuple(sorted(tuple(round(v, 5) for v in (*positions[i], *uv[i]))
                                    for i in indices[start:start + 3]))
            result[(surface["material"], vertices)] += 1
    return result


def compare_original(path, doc, binary, lod):
    old_doc, old_bin, _ = H.glb(PROOF / "generated" / path.name)
    before, after = triangle_records(old_doc, old_bin, "TEXCOORD_1"), triangle_records(doc, binary)
    removed, added = before - after, after - before
    shifted = Counter()
    low, high = [math.inf] * 3, [-math.inf] * 3
    for (material, vertices), count in removed.items():
        # Exact agreed envelope for the original complete entry assembly.
        # Everything outside it must remain untouched, including all windows,
        # facade body, cornice, pilasters, fascia and display joinery.
        for vertex in vertices:
            x, y, z = vertex[:3]
            assert 1.3999 <= x <= 2.6001 and -0.0001 <= y <= 2.7601 and -0.2251 <= z <= 0.2751
        translated = tuple(sorted((x, round(y + 0.33, 5), z, u, v) for x, y, z, u, v in vertices))
        shifted[(material, translated)] += count
        for vertex in translated:
            for axis in range(3):
                low[axis] = min(low[axis], vertex[axis])
                high[axis] = max(high[axis], vertex[axis])
    assert removed and shifted == added, "Only complete entry triangles may translate +0.33 m; preserve UVs"
    expected = {"near": 632, "mid": 440, "far": 48}
    # Counts are independently pinned to the actual original GLB, not inferred
    # from the fitted script's names or accepted merely because it ran.
    assert sum(removed.values()) == expected[lod], (lod, sum(removed.values()))
    assert abs(low[1] - 0.33) < 0.0001 and abs(high[1] - 3.09) < 0.0001
    stone_entry = [vertex for (mat, vertices) in added for vertex in vertices if mat == 0]
    assert stone_entry and abs(max(v[1] for v in stone_entry) - 0.53) < 0.0001
    assert abs(min(v[1] for v in stone_entry) - 0.33) < 0.0001
    return {"changed_triangles": sum(removed.values()), "translation_m": [0, 0.33, 0],
            "all_other_triangles_and_authored_uvs_unchanged": True,
            "uv_comparison": "original authored TEXCOORD_1 equals fitted TEXCOORD_0", "entry_bounds_min_m": low,
            "entry_bounds_max_m": high, "threshold_top_m": 0.53}


def inspect(lod):
    path = ROOT / "generated" / ("glasgow_bay_" + lod + ".glb")
    doc, binary, raw = H.glb(path)
    assert doc["asset"]["version"] == "2.0"
    assert len(doc["meshes"]) == len(doc["nodes"]) == len(doc["buffers"]) == 1
    assert not doc.get("images") and not doc.get("textures") and not doc.get("samplers")
    assert not doc.get("extensionsUsed") and not doc.get("extensionsRequired")
    assert "uri" not in doc["buffers"][0]
    assert doc["materials"] == [{"name": name, "alphaMode": "OPAQUE", "doubleSided": False} for name in SLOTS]
    node = doc["nodes"][0]
    assert node.get("translation", [0, 0, 0]) == [0, 0, 0]
    assert node.get("rotation", [0, 0, 0, 1]) == [0, 0, 0, 1]
    assert node.get("scale", [1, 1, 1]) == [1, 1, 1] and "matrix" not in node
    primitives = doc["meshes"][0]["primitives"]
    assert len(primitives) == 4 and [p["material"] for p in primitives] == [0, 1, 2, 3]
    low, high = [math.inf] * 3, [-math.inf] * 3
    triangles = vertices = 0
    surfaces = []
    for primitive in primitives:
        assert primitive.get("mode", 4) == 4
        attrib = primitive["attributes"]
        assert set(attrib) == {"POSITION", "NORMAL", "TEXCOORD_0", "TANGENT"}
        arrays = {name: H.accessor(doc, binary, idx) for name, idx in attrib.items()}
        pos, normals, uvs, tangents = [arrays[k] for k in ("POSITION", "NORMAL", "TEXCOORD_0", "TANGENT")]
        indices = [i[0] for i in H.accessor(doc, binary, primitive["indices"])]
        assert len(indices) % 3 == 0 and max(indices) < len(pos)
        assert len(pos) == len(normals) == len(uvs) == len(tangents)
        assert all(math.isfinite(v) for array in arrays.values() for row in array for v in row)
        assert all(abs(H.length(n) - 1) < 0.005 for n in normals)
        assert all(abs(H.length(t[:3]) - 1) < 0.005 and abs(abs(t[3]) - 1) < 0.001 for t in tangents)
        assert all(abs(sum(n[i] * t[i] for i in range(3))) < 0.005 for n, t in zip(normals, tangents))
        for p in pos:
            for axis in range(3):
                low[axis] = min(low[axis], p[axis])
                high[axis] = max(high[axis], p[axis])
        for start in range(0, len(indices), 3):
            a, b, c = indices[start:start + 3]
            assert H.length(H.cross(H.subtract(pos[b], pos[a]), H.subtract(pos[c], pos[a]))) > 1e-10
            d1, d2 = H.subtract(uvs[b], uvs[a]), H.subtract(uvs[c], uvs[a])
            assert abs(d1[0] * d2[1] - d1[1] * d2[0]) > 1e-12
        formats = {name: {"component_type": doc["accessors"][idx]["componentType"],
                          "type": doc["accessors"][idx]["type"],
                          "normalized": doc["accessors"][idx].get("normalized", False)}
                   for name, idx in attrib.items()}
        assert all(f["component_type"] == 5126 and not f["normalized"] for f in formats.values())
        formats["INDICES"] = {"component_type": doc["accessors"][primitive["indices"]]["componentType"],
                              "type": "SCALAR"}
        data = {name: arrays[name] for name in sorted(arrays)}
        data["indices"] = indices
        surfaces.append({"slot": primitive["material"], "name": SLOTS[primitive["material"]],
                         "triangles": len(indices) // 3, "vertices": len(pos), "formats": formats,
                         "decoded_data_sha256": H.sha(json.dumps(data, separators=(",", ":")).encode())})
        triangles += len(indices) // 3
        vertices += len(pos)
    assert BUDGETS[lod][0] <= triangles <= BUDGETS[lod][1]
    assert all(abs(a - b) < 0.0001 for a, b in zip(low + high, BOUNDS[0] + BOUNDS[1]))
    assert path.read_bytes() == (RUNTIME / path.name).read_bytes()
    return {"file": path.name, "bytes": len(raw), "sha256": H.sha(raw), "triangles": triangles,
            "exported_vertices": vertices, "opaque_named_slots": 4, "embedded_images": 0,
            "embedded_material_payloads": 0, "bounds_min_m": low, "bounds_max_m": high,
            "surface_data": surfaces, "entry_comparison": compare_original(path, doc, binary, lod)}


def main():
    assets = [inspect(lod) for lod in BUDGETS]
    assert sorted(p.name for p in (RUNTIME / "textures").glob("*.png")) == sorted(TEXTURES)
    textures = []
    for name in TEXTURES:
        original, runtime = PROOF / "textures" / name, RUNTIME / "textures" / name
        data = runtime.read_bytes()
        assert data == original.read_bytes() and data[:8] == b"\x89PNG\r\n\x1a\n"
        assert struct.unpack_from(">II", data, 16) == (1024, 1024)
        textures.append({"file": "textures/" + name, "bytes": len(data), "sha256": digest(runtime),
                         "dimensions_px": [1024, 1024], "original_unchanged": True})
    generation = json.loads((ROOT / "generation.json").read_text())
    for name, expected in generation["preserved_proof_sha256"].items():
        assert digest(PROOF / name) == expected, name
    report = {"schema": 1, "status": "Fitted asset structural audit passed; live acceptance pending",
              "source_sha256": {"fitted/generator.py": digest(ROOT / "generator.py"),
                                "fitted/audit.py": digest(Path(__file__)),
                                "original/generator.py": digest(PROOF / "generator.py"),
                                "original/audit.py": digest(PROOF / "audit.py")},
              "assets": assets, "shared_textures": textures,
              "original_proof_files_preserved": len(generation["preserved_proof_sha256"]),
              "not_tested": ["Godot import", "live visual integration", "route/camera clearance", "LOD switching", "Mac performance"]}
    (ROOT / "audit.json").write_text(json.dumps(report, indent=2) + "\n")
    (RUNTIME / "manifest.json").write_text(json.dumps(report, indent=2) + "\n")
    for asset in assets:
        print(asset["file"], asset["triangles"], "triangles;", asset["bytes"], "bytes; moved", asset["entry_comparison"]["changed_triangles"], "triangles")
    print("FITTED_GLASGOW_BAY_AUDIT PASSED")


if __name__ == "__main__":
    main()
