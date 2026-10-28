"""Original reduced-near-poly four-slot facade; OFFLINE source experiment.

blender -b --factory-startup -t 2 --python <this-file> -- --allow-generate
No rendering, image generation, downloads, runtime copies or game edits.
"""
from pathlib import Path
import argparse
import gzip
import hashlib
import importlib.util
import json
import struct
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
PROOF = ROOT.parent
SLOTS = ("01_Original_sandstone", "02_Painted_forest_joinery",
         "03_Opaque_glazing", "04_Aged_dark_metal")
ENTRY = {"Recessed door", "Door opaque glass", "Stone threshold", "Door handle",
         "Handle mount", "Door metal handle silhouette"}
EXPECTED = {"near": (9864, 246), "mid": (3544, 142), "far": (648, 54)}
TEXTURES = ("sandstone_basecolor.png", "sandstone_normal_opengl.png",
            "sandstone_orm.png", "opaque_glazing_basecolor.png")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def preserved_inputs():
    # Keep the complete preceding source proofs and receipts immutable. Exclude
    # our new experiment and generated local interpreter/import caches.
    return {str(path.relative_to(PROOF)): digest(path)
            for path in sorted(PROOF.rglob("*")) if path.is_file()
            and ROOT not in path.parents
            and not any(part in ("__pycache__", ".godot", ".local")
                        for part in path.relative_to(PROOF).parts)}


def original_module():
    spec = importlib.util.spec_from_file_location("preserved_original_facade", PROOF / "generator.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def strip_materials(path):
    raw, cursor, chunks = path.read_bytes(), 12, {}
    while cursor < len(raw):
        size, kind = struct.unpack_from("<II", raw, cursor)
        cursor += 8
        chunks[kind] = raw[cursor:cursor + size]
        cursor += size
    doc = json.loads(chunks[0x4E4F534A])
    assert not doc.get("images") and not doc.get("textures")
    assert [material["name"] for material in doc["materials"]] == list(SLOTS)
    # Only named opaque slots are exported. Native shared StandardMaterial3D
    # definitions remain the authority for scalar paint/metal and original maps.
    doc["materials"] = [{"name": name, "alphaMode": "OPAQUE", "doubleSided": False}
                        for name in SLOTS]
    for key in ("samplers", "extensionsUsed", "extensionsRequired"):
        doc.pop(key, None)
    doc["nodes"][0]["name"] += "_ReducedFourSlot"
    doc["nodes"][0]["extras"]["prototype_status"] = "OFFLINE reduced four-slot experiment; native visual/performance acceptance pending"
    doc["nodes"][0]["extras"]["entry_lift_m"] = 0.33
    encoded = json.dumps(doc, separators=(",", ":"), ensure_ascii=False).encode()
    encoded += b" " * (-len(encoded) % 4)
    binary = chunks[0x004E4942]
    path.write_bytes(struct.pack("<III", 0x46546C67, 2, 28 + len(encoded) + len(binary))
                     + struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
                     + struct.pack("<II", len(binary), 0x004E4942) + binary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--allow-generate", action="store_true")
    parser.add_argument("--output", type=Path, default=ROOT / "generated")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if not args.allow_generate:
        parser.error("Wait for the orchestrator's exclusive engine lease, then pass --allow-generate")
    import bpy
    from mathutils import Vector

    before = preserved_inputs()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    original = original_module()
    original.OUT = output
    original.MATERIALS.clear()
    for name in SLOTS:
        original.material(name, (0.5, 0.5, 0.5), 0.8)
    source_box = original.box
    parts, triangles = {}, {}

    def reduced_box(name, x, y, z, sx, sy, sz, mat=0, bevel=0.0, segments=None):
        # Change only near edge subdivision, preserving all 246 authored parts,
        # dimensions, radii, material classes and original metre-scaled phase.
        effective = 1 if original.LOD == "near" and bevel > 0 else segments
        obj = source_box(name, x, y, z, sx, sy, sz, mat, bevel, effective)
        mesh = obj.data
        for layer in list(mesh.uv_layers):
            if layer.name != "FacadeUV":
                mesh.uv_layers.remove(layer)
        assert len(mesh.uv_layers) == 1
        mesh.uv_layers.active_index = 0
        mesh.uv_layers[0].active_render = True
        if name in ENTRY:
            obj.location.z += 0.33  # Translate after UV creation, as fitted.
        bpy.context.view_layer.update()
        mesh.calc_loop_triangles()
        corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        bounds = [(p.x, p.z, -p.y) for p in corners]
        lod_parts = parts.setdefault(original.LOD, [])
        index = len(lod_parts)
        record = {"index": index, "part": name, "source_class": mat,
                  "dimensions_m": [sx, sy, sz],
                  "bounds_min_m": [min(p[axis] for p in bounds) for axis in range(3)],
                  "bounds_max_m": [max(p[axis] for p in bounds) for axis in range(3)],
                  "bevel_radius_m": min(bevel, min(sx, sy, sz) * 0.2),
                  "bevel_segments_override": effective,
                  "entry_lift_m": 0.33 if name in ENTRY else 0,
                  "triangles": len(mesh.loop_triangles)}
        lod_parts.append(record)
        # Retain the actual pre-join triangles, not only self-reported bounds.
        # An independent decoder can bind every part to the final GLB union and
        # compare its position/authored-UV triangles to the preserved proofs.
        actual = []
        for triangle in mesh.loop_triangles:
            vertices = []
            for vertex_index, loop_index in zip(triangle.vertices, triangle.loops):
                p = obj.matrix_world @ mesh.vertices[vertex_index].co
                uv = mesh.uv_layers[0].data[loop_index].uv
                vertices.append([p.x, p.z, -p.y, uv.x, 1.0 - uv.y])
            actual.append(vertices)
        triangles.setdefault(original.LOD, []).append({"part_index": index,
            "source_class": mat, "position_uv_triangles": actual})
        return obj

    original.box = reduced_box
    geometry = []
    for lod in ("near", "mid", "far"):
        result = original.build_lod(lod)
        assert (result["blender_triangles"], result["authored_parts"]) == EXPECTED[lod], result
        path = output / ("glasgow_bay_" + lod + ".glb")
        strip_materials(path)
        result.update(sha256=digest(path), bytes=path.stat().st_size)
        geometry.append(result)
    assert before == preserved_inputs(), "A preserved input changed"
    raw_parts = json.dumps({"schema": 1, "coordinates": "glTF X/Y/Z metres and UV0; pre-join actual loop triangles",
                           "parts": triangles}, separators=(",", ":")).encode()
    part_path = output / "part-triangles.json.gz"
    part_path.write_bytes(gzip.compress(raw_parts, mtime=0))
    report = {"schema": 1, "status": "OFFLINE experiment; independent audit/native visual/performance acceptance pending",
              "blender": bpy.app.version_string, "generator_sha256": digest(Path(__file__)),
              "material_slots": SLOTS, "geometry": geometry, "parts": parts,
              "part_triangle_file": {"file": part_path.name, "bytes": part_path.stat().st_size,
                                     "sha256": digest(part_path), "uncompressed_sha256": hashlib.sha256(raw_parts).hexdigest()},
              "uv_policy": "Sole original authored FacadeUV becomes TEXCOORD_0; no atlas/remapping; translate entry after UV creation",
              "original_shared_maps": {name: digest(PROOF / "textures" / name) for name in TEXTURES},
              "preserved_inputs_sha256": before, "embedded_images": 0,
              "embedded_pbr_materials": 0, "rendered": False, "godot_launched": False,
              "runtime_files_written": False, "downloaded_assets": []}
    (output / "generation.json").write_text(json.dumps(report, indent=2) + "\n")
    print("REDUCED_FOUR_SLOT_GLASGOW_BAY " + json.dumps(geometry))


if __name__ == "__main__":
    main()
