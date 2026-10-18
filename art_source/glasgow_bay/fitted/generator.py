"""Fit the preserved original proof for one live Exchange frontage.

Blender 4.3.2, offline geometry export only:
  blender -b --factory-startup -t 2 --python art_source/glasgow_bay/fitted/generator.py
No rendering, Godot launch, network request or runtime-code edit.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import shutil
import struct
import sys

import bpy

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
PROOF = ROOT.parent
REPO = PROOF.parents[1]
RUNTIME = REPO / "game/art/assets/glasgow_bay"
OUT = ROOT / "generated"
SLOTS = ["01_Original_sandstone", "02_Painted_forest_joinery",
         "03_Opaque_glazing", "04_Aged_dark_metal"]
ENTRY_PARTS = {"Recessed door", "Door opaque glass", "Stone threshold",
               "Door handle", "Handle mount", "Door metal handle silhouette"}
TEXTURES = ["sandstone_basecolor.png", "sandstone_normal_opengl.png",
            "sandstone_orm.png", "opaque_glazing_basecolor.png"]
ENTRY_LIFT = 0.33


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def preserve_proof():
    # Include every existing file outside our new fitted directory, including
    # the owner's previous preview source. This function never rewrites them.
    return {str(p.relative_to(PROOF)): digest(p) for p in sorted(PROOF.rglob("*"))
            if p.is_file() and ROOT not in p.parents}


def import_original():
    spec = importlib.util.spec_from_file_location("original_glasgow_bay", PROOF / "generator.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def strip_material_payload(path):
    raw = path.read_bytes()
    cursor = 12
    chunks = {}
    while cursor < len(raw):
        size, kind = struct.unpack_from("<II", raw, cursor)
        cursor += 8
        chunks[kind] = raw[cursor:cursor + size]
        cursor += size
    document = json.loads(chunks[0x4E4F534A])
    assert not document.get("images") and not document.get("textures")
    assert [m["name"] for m in document["materials"]] == SLOTS
    # These are glTF's necessary surface-slot names, not embedded copies of
    # runtime material definitions. Root assigns four shared Godot materials.
    document["materials"] = [{"name": name, "alphaMode": "OPAQUE", "doubleSided": False}
                             for name in SLOTS]
    document.pop("samplers", None)
    document.pop("extensionsUsed", None)
    document.pop("extensionsRequired", None)
    document["nodes"][0]["name"] += "_Fitted"
    document["nodes"][0]["extras"]["prototype_status"] = "FITTED ASSET; live integration/visual/performance acceptance pending"
    document["nodes"][0]["extras"]["entry_lift_m"] = ENTRY_LIFT
    encoded = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode()
    encoded += b" " * (-len(encoded) % 4)
    binary = chunks[0x004E4942]
    result = (struct.pack("<III", 0x46546C67, 2, 28 + len(encoded) + len(binary))
              + struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
              + struct.pack("<II", len(binary), 0x004E4942) + binary)
    path.write_bytes(result)


def main():
    before = preserve_proof()
    OUT.mkdir(parents=True, exist_ok=True)
    (RUNTIME / "textures").mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    original = import_original()
    original.OUT = OUT
    original.MATERIALS.clear()
    for name in SLOTS:
        # No image nodes: the mesh export cannot accidentally pack textures.
        original.material(name, (0.5, 0.5, 0.5), 0.8)
    source_box = original.box
    moved = {}

    def fitted_box(name, *args, **kwargs):
        obj = source_box(name, *args, **kwargs)
        # The preserved proof has Blender's default cube UV set plus the
        # authored metre-scaled layer. Keep only the authored layer so runtime
        # material UV1/TEXCOORD_0 and rebuilt tangents use the intended mapping.
        for uv_layer in list(obj.data.uv_layers):
            if uv_layer.name != "FacadeUV":
                obj.data.uv_layers.remove(uv_layer)
        assert len(obj.data.uv_layers) == 1
        obj.data.uv_layers.active_index = 0
        obj.data.uv_layers[0].active_render = True
        if name in ENTRY_PARTS:
            # Translate after UV creation so the part's shape, UVs, normals
            # and tangent orientation are preserved; Blender uses +Z up.
            obj.location.z += ENTRY_LIFT
            obj.data.calc_loop_triangles()
            moved.setdefault(original.LOD, []).append({"part": name,
                "triangles": len(obj.data.loop_triangles), "translation_m": [0, ENTRY_LIFT, 0]})
        return obj

    original.box = fitted_box
    geometry = []
    for lod in ("near", "mid", "far"):
        geometry.append(original.build_lod(lod))
        path = OUT / ("glasgow_bay_" + lod + ".glb")
        strip_material_payload(path)
        shutil.copyfile(path, RUNTIME / path.name)
    for name in TEXTURES:
        shutil.copyfile(PROOF / "textures" / name, RUNTIME / "textures" / name)
    after = preserve_proof()
    assert before == after, "The preserved original proof changed"
    report = {"schema": 1, "status": "FITTED ASSET; live acceptance pending", "blender": bpy.app.version_string,
              "generator_sha256": digest(Path(__file__)), "original_generator_sha256": digest(PROOF / "generator.py"),
              "entry_translation_m": [0, ENTRY_LIFT, 0], "entry_parts": moved, "geometry": geometry,
              "material_slots": SLOTS, "embedded_images": 0, "embedded_pbr_materials": 0,
              "uv_policy": "Original authored FacadeUV becomes sole TEXCOORD_0; discard default cube UV; rebuild tangents",
              "rendered": False, "godot_launched": False, "downloaded_assets": [],
              "preserved_proof_sha256": before}
    (ROOT / "generation.json").write_text(json.dumps(report, indent=2) + "\n")
    print("FITTED_GLASGOW_BAY " + json.dumps(geometry))


if __name__ == "__main__":
    main()
