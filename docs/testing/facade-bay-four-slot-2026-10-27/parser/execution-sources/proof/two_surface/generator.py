"""EXPERIMENTAL source-only candidate; run only after profiling is released.

blender -b --factory-startup -t 2 --python <this-file> -- --allow-generate
Optional: --colour-size 512 (default 1024). No rendering or runtime copying.
"""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import struct
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
PROOF = ROOT.parent
sys.path.insert(0, str(ROOT))
from atlas import make_atlases, remap_uv

SLOTS = ("01_Original_sandstone", "02_Original_accent_atlas")
SOURCE_SLOTS = ("Source_stone", "Source_paint", "Source_glazing", "Source_metal")
ENTRY = {"Recessed door", "Door opaque glass", "Stone threshold", "Door handle", "Handle mount", "Door metal handle silhouette"}
BUDGETS = {"near": 10000, "mid": 5000, "far": 800}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def original_module():
    spec = importlib.util.spec_from_file_location("original_bay_geometry", PROOF / "generator.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def source_receipt():
    paths = [PROOF / "generator.py", PROOF / "audit.py", *sorted((PROOF / "textures").glob("*.png")),
             *sorted((PROOF / "fitted/generated").glob("*.glb"))]
    return {str(path.relative_to(PROOF)): digest(path) for path in paths}


def strip_materials(path):
    raw, cursor, chunks = path.read_bytes(), 12, {}
    while cursor < len(raw):
        length, kind = struct.unpack_from("<II", raw, cursor)
        cursor += 8
        chunks[kind] = raw[cursor:cursor + length]
        cursor += length
    doc = json.loads(chunks[0x4E4F534A])
    assert not doc.get("images") and not doc.get("textures")
    assert [material["name"] for material in doc["materials"]] == list(SLOTS)
    doc["materials"] = [{"name": name, "alphaMode": "OPAQUE", "doubleSided": False} for name in SLOTS]
    for key in ("samplers", "extensionsUsed", "extensionsRequired"):
        doc.pop(key, None)
    encoded = json.dumps(doc, separators=(",", ":"), ensure_ascii=False).encode()
    encoded += b" " * (-len(encoded) % 4)
    binary = chunks[0x004E4942]
    path.write_bytes(struct.pack("<III", 0x46546C67, 2, 28 + len(encoded) + len(binary))
                     + struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
                     + struct.pack("<II", len(binary), 0x004E4942) + binary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--allow-generate", action="store_true", help="Explicitly launch the offline export after the exclusive profile window")
    parser.add_argument("--colour-size", type=int, choices=(512, 1024), default=1024)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if not args.allow_generate:
        parser.error("Source-only candidate: wait for the root's export release, then pass --allow-generate")
    import bpy
    from mathutils import Vector

    preserved = source_receipt()
    atlas = make_atlases(args.colour_size)
    output = ROOT / "generated"
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    original = original_module()
    original.MATERIALS.clear()
    for name in SOURCE_SLOTS:
        original.material(name, (0.5, 0.5, 0.5), 0.8)
    export_materials = []
    for name in SLOTS:
        material = bpy.data.materials.new(name)
        material.use_nodes = True
        material.use_backface_culling = True
        export_materials.append(material)
    source_box = original.box
    parts = {}

    def fitted_box(name, x, y, z, sx, sy, sz, mat=0, bevel=0.0, segments=None):
        # Preserve all boxes, their dimensions, bevel radii and entry assembly.
        # A single chamfer replaces multi-segment rounding only at near LOD.
        # This changes tiny edge profiles, so matched appearance stays open.
        effective_segments = 1 if original.LOD == "near" and bevel > 0 else segments
        obj = source_box(name, x, y, z, sx, sy, sz, mat, bevel, effective_segments)
        mesh = obj.data
        source_uv = [tuple(item.uv) for item in mesh.uv_layers["FacadeUV"].data]
        for layer in list(mesh.uv_layers):
            mesh.uv_layers.remove(layer)
        mapped = mesh.uv_layers.new(name="SurfaceUV")
        authored = mesh.uv_layers.new(name="SourceUV")
        for index, uv in enumerate(source_uv):
            mapped.data[index].uv = uv if mat == 0 else remap_uv(uv, mat, args.colour_size)
            authored.data[index].uv = uv
        mesh.uv_layers.active_index = 0
        mapped.active_render = True
        if name in ENTRY:
            obj.location.z += 0.33  # Preserve authored texture phase.
        bpy.context.view_layer.update()
        coordinates = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        game_coordinates = [(p.x, p.z, -p.y) for p in coordinates]
        mesh.calc_loop_triangles()
        parts.setdefault(original.LOD, []).append({"part": name, "source_class": mat,
            "dimensions_m": [sx, sy, sz], "bounds_min_m": [min(p[i] for p in game_coordinates) for i in range(3)],
            "bounds_max_m": [max(p[i] for p in game_coordinates) for i in range(3)],
            "bevel_radius_m": min(bevel, min(sx, sy, sz) * 0.2), "bevel_segments_override": effective_segments,
            "entry_lift_m": 0.33 if name in ENTRY else 0, "triangles": len(mesh.loop_triangles)})
        return obj

    original.box = fitted_box
    records = []
    for lod in ("near", "mid", "far"):
        original.LOD = lod
        original.PARTS.clear()
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        original.box("Closed shallow backing", 0, 7.92, -0.45, original.WIDTH, 15.84, 0.10)
        original.upper_wall()
        original.shopfront()
        original.cornice()
        bpy.ops.object.select_all(action="DESELECT")
        for obj in original.PARTS:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = original.PARTS[0]
        bpy.ops.object.join()
        obj = bpy.context.object
        obj.name = "GlasgowBay_TwoSurface_" + lod.upper()
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        old = list(obj.data.materials)
        indices = [0 if original.MATERIALS.index(old[p.material_index]) == 0 else 1 for p in obj.data.polygons]
        obj.data.materials.clear()
        for material in export_materials:
            obj.data.materials.append(material)
        for polygon, index in zip(obj.data.polygons, indices):
            polygon.material_index = index
        obj.data.uv_layers.active_index = 0
        obj.data.uv_layers[0].active_render = True
        obj["prototype_status"] = "EXPERIMENTAL; unintegrated; visual/performance acceptance pending"
        obj["units"] = "metres; Y up and +Z front in glTF"
        obj["collision"] = "none; preserve independent gameplay geometry"
        obj["lod"] = lod
        obj["uv_policy"] = "UV0: unchanged stone / baked-field accent; UV1: preserved original authored coordinates"
        bpy.context.scene.unit_settings.system = "METRIC"
        bpy.context.scene.unit_settings.scale_length = 1.0
        obj.data.calc_loop_triangles()
        count = len(obj.data.loop_triangles)
        assert count <= BUDGETS[lod], (lod, count, "budget exceeded; do not silently loosen")
        path = output / ("glasgow_bay_" + lod + ".glb")
        bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
            export_texcoords=True, export_normals=True, export_tangents=True, export_materials="EXPORT",
            export_extras=True, export_yup=True, export_cameras=False, export_lights=False, export_animations=False)
        strip_materials(path)
        records.append({"lod": lod, "blender_triangles": count, "authored_parts": len(original.PARTS), "sha256": digest(path)})
    assert preserved == source_receipt(), "An input changed during generation"
    report = {"schema": 1, "status": "EXPERIMENTAL offline exports; independent audit and visual/performance acceptance pending",
              "blender": bpy.app.version_string, "material_slots": SLOTS, "geometry": records, "parts": parts,
              "atlas": atlas, "preserved_inputs_sha256": preserved,
              "source_sha256": {name: digest(ROOT / name) for name in ("generator.py", "atlas.py", "audit.py")},
              "rendered": False, "godot_launched": False, "runtime_files_written": False, "downloaded_assets": []}
    (ROOT / "generation.json").write_text(json.dumps(report, indent=2) + "\n")
    print("TWO_SURFACE_GLASGOW_BAY " + json.dumps(records))


if __name__ == "__main__":
    main()
