"""Independent stdlib audit of the exported GLBs, not Blender source counts.

  python3 art_source/glasgow_bay/audit.py
Fails nonzero for budget, geometry, UV, normal, material or embedding defects.
"""
from pathlib import Path
import hashlib
import json
import math
import struct

ROOT = Path(__file__).resolve().parent
BUDGETS = {"near": (12000, 20000), "mid": (2000, 5000), "far": (300, 800)}
COMPONENTS = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
              5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
LENGTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def glb(path):
    raw = path.read_bytes()
    magic, version, size = struct.unpack_from("<III", raw, 0)
    assert magic == 0x46546C67 and version == 2 and size == len(raw), "GLB header"
    cursor = 12
    chunks = {}
    while cursor < len(raw):
        length, kind = struct.unpack_from("<II", raw, cursor)
        cursor += 8
        chunks[kind] = raw[cursor:cursor + length]
        cursor += length
    return json.loads(chunks[0x4E4F534A]), chunks[0x004E4942], raw


def accessor(doc, binary, index):
    acc = doc["accessors"][index]
    assert "sparse" not in acc
    view = doc["bufferViews"][acc["bufferView"]]
    code, width = COMPONENTS[acc["componentType"]]
    count = LENGTHS[acc["type"]]
    stride = view.get("byteStride", count * width)
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    return [struct.unpack_from("<" + code * count, binary, offset + i * stride)
            for i in range(acc["count"])]


def subtract(a, b):
    return tuple(x - y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def length(a):
    return math.sqrt(sum(x * x for x in a))


def inspect(path, lod):
    doc, binary, raw = glb(path)
    assert doc["asset"]["version"] == "2.0"
    assert "KHR_draco_mesh_compression" not in doc.get("extensionsRequired", [])
    assert "KHR_draco_mesh_compression" not in doc.get("extensionsUsed", [])
    assert len(doc["buffers"]) == 1 and "uri" not in doc["buffers"][0]
    assert len(doc["meshes"]) == 1 and len(doc["nodes"]) == 1, "one merged mesh/object"
    node = doc["nodes"][0]
    assert node.get("scale", [1, 1, 1]) == [1, 1, 1]
    assert node.get("translation", [0, 0, 0]) == [0, 0, 0]
    assert node.get("rotation", [0, 0, 0, 1]) == [0, 0, 0, 1]
    assert "matrix" not in node, "export must contain applied transforms"
    assert len(doc["materials"]) == 4
    for sampler in doc.get("samplers", []):
        assert sampler.get("magFilter") == 9729  # LINEAR
        assert sampler.get("minFilter") == 9987  # LINEAR_MIPMAP_LINEAR
        assert sampler.get("wrapS", 10497) == sampler.get("wrapT", 10497) == 10497
    for mat in doc["materials"]:
        assert mat.get("alphaMode", "OPAQUE") == "OPAQUE"
        assert not mat.get("doubleSided", False), "solid geometry must cull backfaces"
        assert mat.get("pbrMetallicRoughness", {}).get("baseColorFactor", [1] * 4)[3] == 1
    stone = doc["materials"][0]
    assert "normalTexture" in stone and "baseColorTexture" in stone["pbrMetallicRoughness"]
    assert "metallicRoughnessTexture" in stone["pbrMetallicRoughness"]
    surfaces = doc["meshes"][0]["primitives"]
    assert len(surfaces) == 4 and sorted(p["material"] for p in surfaces) == [0, 1, 2, 3]
    mins, maxs = [math.inf] * 3, [-math.inf] * 3
    triangles, vertices, degenerate_uv, degenerate_geo = 0, 0, 0, 0
    normal_errors = []
    tangent_errors = []
    surface_report = []
    for primitive in surfaces:
        assert primitive.get("mode", 4) == 4
        attrib = primitive["attributes"]
        assert {"POSITION", "NORMAL", "TANGENT", "TEXCOORD_0"} <= attrib.keys()
        arrays = {key: accessor(doc, binary, idx) for key, idx in attrib.items()}
        pos, normals, uv, tangents = (arrays[key] for key in ("POSITION", "NORMAL", "TEXCOORD_0", "TANGENT"))
        indices = [i[0] for i in accessor(doc, binary, primitive["indices"])]
        assert len(indices) % 3 == 0 and max(indices) < len(pos)
        assert len(normals) == len(uv) == len(tangents) == len(pos)
        for values in arrays.values():
            assert all(math.isfinite(x) for row in values for x in row), "finite attributes"
        for p in pos:
            for i in range(3):
                mins[i] = min(mins[i], p[i])
                maxs[i] = max(maxs[i], p[i])
        normal_errors.extend(abs(length(n) - 1) for n in normals)
        tangent_errors.extend(abs(length(t[:3]) - 1) for t in tangents)
        assert all(abs(abs(t[3]) - 1) < 0.001 for t in tangents)
        assert all(abs(sum(n[i] * t[i] for i in range(3))) < 0.005 for n, t in zip(normals, tangents))
        for start in range(0, len(indices), 3):
            a, b, c = indices[start:start + 3]
            if length(cross(subtract(pos[b], pos[a]), subtract(pos[c], pos[a]))) < 1e-10:
                degenerate_geo += 1
            d1, d2 = subtract(uv[b], uv[a]), subtract(uv[c], uv[a])
            if abs(d1[0] * d2[1] - d1[1] * d2[0]) < 1e-12:
                degenerate_uv += 1
        data = {key: arrays[key] for key in sorted(arrays)}
        data["indices"] = indices
        surface_report.append({"material": doc["materials"][primitive["material"]]["name"],
                               "triangles": len(indices) // 3, "vertices": len(pos),
                               "decoded_geometry_sha256": sha(json.dumps(data, separators=(",", ":")).encode())})
        triangles += len(indices) // 3
        vertices += len(pos)
    assert BUDGETS[lod][0] <= triangles <= BUDGETS[lod][1], f"{lod} triangle budget: {triangles}"
    assert degenerate_geo == 0 and degenerate_uv == 0, (degenerate_geo, degenerate_uv)
    assert max(normal_errors) < 0.005 and max(tangent_errors) < 0.005
    assert all(abs(a - b) < 1e-4 for a, b in zip(mins, [-3.25, 0, -0.5])), mins
    assert all(abs(a - b) < 1e-4 for a, b in zip(maxs, [3.25, 16, 0.36])), maxs
    images = []
    for image in doc.get("images", []):
        assert "uri" not in image and image.get("mimeType") == "image/png"
        view = doc["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        content = binary[start:start + view["byteLength"]]
        assert content[:8] == b"\x89PNG\r\n\x1a\n"
        dimensions = struct.unpack_from(">II", content, 16)
        assert dimensions == (1024, 1024)
        images.append({"name": image.get("name"), "dimensions": dimensions,
                       "bytes": len(content), "sha256": sha(content)})
    assert len(images) == 4
    return {"file": str(path.relative_to(ROOT)), "sha256": sha(raw), "bytes": len(raw),
            "triangles": triangles, "exported_vertices": vertices,
            "opaque_surfaces": len(surfaces), "bounds_min_m": mins, "bounds_max_m": maxs,
            "degenerate_triangles": degenerate_geo, "degenerate_uv_triangles": degenerate_uv,
            "max_normal_length_error": max(normal_errors), "max_tangent_length_error": max(tangent_errors),
            "surface_data": surface_report, "embedded_images": images}


def main():
    records = [inspect(ROOT / "generated" / ("glasgow_bay_" + lod + ".glb"), lod) for lod in BUDGETS]
    source_hashes = {str(p.relative_to(ROOT)): sha(p.read_bytes()) for p in
                     [ROOT / "generator.py", ROOT / "audit.py", *sorted((ROOT / "textures").glob("*.png"))]}
    report = {"schema": 1, "status": "UNINTEGRATED PROTOTYPE; structural audit passed",
              "coordinate_system": "metres; Y up; +Z front; pivot at ground centre of wall plane",
              "tested": ["actual GLB budgets", "one mesh/four opaque single-sided primitives", "applied transforms",
                         "finite positions/normals/UVs/tangents", "unit orthogonal normals/tangents",
                         "nondegenerate geometry/UV triangles", "same measured LOD bounds",
                         "self-contained original embedded images", "linear/mipmap/repeat samplers",
                         "no optional Draco compression dependency", "decoded surface data hashes"],
              "not_tested": ["rendered appearance", "Godot import", "in-game comparison", "LOD switching",
                             "collision/route integration", "Mac performance", "human visual acceptance"],
              "source_sha256": source_hashes, "assets": records}
    (ROOT / "audit.json").write_text(json.dumps(report, indent=2) + "\n")
    for record in records:
        print(f"{record['file']}: {record['triangles']} triangles, {record['opaque_surfaces']} opaque surfaces, {record['bytes']} bytes")
    print("GLASGOW_BAY_AUDIT PASSED")


if __name__ == "__main__":
    main()
