"""Original, offline, UNINTEGRATED Glasgow-inspired facade proof.

Run from any directory with Blender 4.3:
  blender -b --factory-startup -t 2 --python /absolute/path/generator.py
No renders, downloads, scene imports, collision or game edits occur.
"""
from pathlib import Path
import hashlib
import json
import math
import sys

import bpy
import numpy as np
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "generated"
TEX = ROOT / "textures"
WIDTH = 6.5
HEIGHT = 16.0
SEED = 2304
MATERIALS = []
PARTS = []
LOD = "near"


def png(name, rgb, noncolor=False):
    """Store original mathematical pixels, without a Blender render/bake."""
    h, w, _ = rgb.shape
    image = bpy.data.images.new(name, width=w, height=h, alpha=False)
    image.colorspace_settings.name = "Non-Color" if noncolor else "sRGB"
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[:, :, :3] = np.clip(rgb, 0, 1)
    image.pixels.foreach_set(rgba.ravel())
    image.filepath_raw = str(TEX / (name + ".png"))
    image.file_format = "PNG"
    image.save()
    return image


def make_textures():
    n = 1024
    rng = np.random.default_rng(SEED)
    v, u = np.mgrid[0:n, 0:n].astype(np.float32) / n
    # Periodic mineral grain: broad restrained beds, rather than masonry drawn
    # into the map. Two metres per repeat; actual stone joints are geometry.
    broad = (np.sin(2 * np.pi * (u * 3 + v)) * 0.010
             + np.sin(2 * np.pi * (v * 7 + u * 2)) * 0.008
             + np.sin(2 * np.pi * (v * 23 - u * 3)) * 0.004)
    grain = rng.normal(0, 0.006, (n, n)).astype(np.float32)
    color = np.array([0.60, 0.475, 0.345], dtype=np.float32)
    albedo = png("sandstone_basecolor", color + (broad + grain)[:, :, None])
    # OpenGL tangent-space +Y normal, deliberately subtle; finite periodic
    # differences eliminate a normal seam at the wrap boundary.
    height = broad * 0.16 + grain * 0.05
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 12.0
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 12.0
    normal = np.stack((-dx, -dy, np.ones_like(dx)), axis=2)
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    normal_image = png("sandstone_normal_opengl", normal * 0.5 + 0.5, True)
    orm = np.zeros((n, n, 3), dtype=np.float32)
    orm[:, :, 0] = 1.0  # No fabricated baked cavity/scene AO.
    orm[:, :, 1] = np.clip(0.81 + broad * 2 + grain, 0.74, 0.9)
    orm_image = png("sandstone_orm", orm, True)
    # Original opaque glazing card: soft sky falloff plus a quiet abstract
    # reflection. No photographed interiors, real business, or transparency.
    reflection = (np.sin(2 * np.pi * u * 3) * 0.5 + 0.5) ** 12 * 0.018
    glass = np.empty((n, n, 3), dtype=np.float32)
    for channel, base in enumerate([0.045, 0.072, 0.082]):
        glass[:, :, channel] = base + v * 0.045 + reflection
    glazing = png("opaque_glazing_basecolor", glass)
    return albedo, normal_image, orm_image, glazing


def material(name, color, roughness, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.use_backface_culling = True
    mat.diffuse_color = (*color, 1)
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    MATERIALS.append(mat)
    return mat


def image_node(mat, image):
    node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = image
    node.interpolation = "Linear"
    node.extension = "REPEAT"
    return node


def make_materials():
    albedo, normal, orm, glazing = make_textures()
    stone = material("01_Original_sandstone", (0.60, 0.475, 0.345), 0.81)
    tree = stone.node_tree
    shader = tree.nodes.get("Principled BSDF")
    tree.links.new(image_node(stone, albedo).outputs["Color"], shader.inputs["Base Color"])
    normal_map = tree.nodes.new("ShaderNodeNormalMap")
    tree.links.new(image_node(stone, normal).outputs["Color"], normal_map.inputs["Color"])
    tree.links.new(normal_map.outputs["Normal"], shader.inputs["Normal"])
    separate = tree.nodes.new("ShaderNodeSeparateColor")
    tree.links.new(image_node(stone, orm).outputs["Color"], separate.inputs["Color"])
    tree.links.new(separate.outputs["Green"], shader.inputs["Roughness"])
    # Stone is non-metallic. Leave Metallic at literal zero instead of also
    # tracing B from this image: Blender 4.3's exporter warns whenever two
    # sockets trace image nodes, even when they trace this same packed image.
    material("02_Painted_forest_joinery", (0.028, 0.085, 0.067), 0.48)
    glass = material("03_Opaque_glazing", (0.06, 0.1, 0.12), 0.32)
    glass.node_tree.links.new(image_node(glass, glazing).outputs["Color"],
                              glass.node_tree.nodes.get("Principled BSDF").inputs["Base Color"])
    material("04_Aged_dark_metal", (0.105, 0.095, 0.069), 0.46, 0.65)


def project_uv(obj, glazing=False):
    mesh = obj.data
    uv = mesh.uv_layers.new(name="FacadeUV")
    for face in mesh.polygons:
        axis = max(range(3), key=lambda i: abs(face.normal[i]))
        axes = ((1, 2), (0, 2), (0, 1))[axis]
        for li in face.loop_indices:
            p = obj.matrix_world @ mesh.vertices[mesh.loops[li].vertex_index].co
            uv.data[li].uv = (p[axes[0]] / 2.0, p[axes[1]] / 2.0)


def box(name, x, y, z, sx, sy, sz, mat=0, bevel=0.0, segments=None):
    """Arguments are game X/upY/frontZ metres; Blender uses X/-Y/upZ."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -z, y))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (sx, sz, sy)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(MATERIALS[mat])
    if bevel > 0 and LOD != "far":
        modifier = obj.modifiers.new("Authored edge radius", "BEVEL")
        modifier.width = min(bevel, min(sx, sy, sz) * 0.2)
        modifier.segments = segments or (2 if LOD == "near" else 1)
        modifier.affect = "EDGES"
        modifier.harden_normals = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        for face in obj.data.polygons:
            face.use_smooth = True
        weighted = obj.modifiers.new("Area weighted corner normals", "WEIGHTED_NORMAL")
        weighted.keep_sharp = True
        weighted.weight = 50
        bpy.ops.object.modifier_apply(modifier=weighted.name)
    project_uv(obj, mat == 2)
    PARTS.append(obj)
    return obj


def wall_rect(name, x0, x1, y0, y1):
    if x1 - x0 > 0.001 and y1 - y0 > 0.001:
        box(name, (x0 + x1) / 2, (y0 + y1) / 2, -0.20,
            x1 - x0, y1 - y0, 0.40)


def window(x, y, height):
    width = 1.45
    b = 0.018 if LOD == "near" else 0.0
    # Glass remains behind the wall face. All trim is solidly embedded in
    # the jamb; the shallow backing closes the module at the building mass.
    box("Recessed opaque pane", x, y, -0.19, width, height, 0.045, 2)
    if LOD == "far":
        box("Sill silhouette", x, y - height / 2 - 0.11, 0.10, 1.88, 0.16, 0.40)
        return
    for side in (-1, 1):
        box("Stone jamb", x + side * 0.86, y, -0.005, 0.22, height + 0.34, 0.40, 0, 0.022)
        box("Recessed sash side", x + side * 0.69, y, -0.105, 0.075, height, 0.12, 1, b, 1)
    box("Stone lintel", x, y + height / 2 + 0.14, 0.005, 1.93, 0.22, 0.42, 0, 0.025)
    box("Sill bed", x, y - height / 2 - 0.12, 0.04, 1.97, 0.18, 0.46, 0, 0.018)
    box("Weathered sill nose", x, y - height / 2 - 0.055, 0.13, 2.04, 0.085, 0.44, 0, 0.015)
    for yy in (-height / 2 + 0.04, 0.04, height / 2 - 0.04):
        box("Sash rail", x, y + yy, -0.07, width, 0.075, 0.13, 1, b, 1)
    box("Sash centre", x, y, -0.07, 0.06, height, 0.13, 1, b, 1)
    if LOD == "near":
        box("Lintel upper fillet", x, y + height / 2 + 0.28, 0.02, 2.01, 0.075, 0.44, 0, 0.012, 2)
        box("Sill underside drip", x, y - height / 2 - 0.2, 0.20, 1.83, 0.035, 0.09, 0, 0.006, 2)
        for side in (-1, 1):
            box("Sill corbel", x + side * 0.62, y - height / 2 - 0.29, 0.02, 0.18, 0.21, 0.31, 0, 0.02, 2)


def upper_wall():
    window_rows = [(5.25, 2.1), (8.45, 2.1), (11.65, 2.1), (14.65, 1.4)]
    last = 3.85
    # Wall boxes stop at actual openings instead of a flat wall behind panes.
    for row, (y, h) in enumerate(window_rows):
        bottom, top = y - h / 2, y + h / 2
        wall_rect("Solid stone spandrel", -3.25, 3.25, last, bottom)
        ends = [-3.25, -2.35, -0.90, 0.90, 2.35, 3.25]
        for a, b in ((ends[0], ends[1]), (ends[2], ends[3]), (ends[4], ends[5])):
            wall_rect("Stone pier", a, b, bottom, top)
        for x in (-1.625, 1.625):
            window(x, y, h)
        last = top
    wall_rect("Cornice wall", -3.25, 3.25, last, 15.83)
    if LOD == "near":
        # Shallow individual quoin courses carry the foreground edge detail.
        # Selected courses, not a tessellated flat facade, receive geometry.
        for course in range(18):
            y = 4.18 + course * 0.62
            width = 0.36 if course % 2 else 0.48
            for side in (-1, 1):
                box("Alternating ashlar quoin", side * (3.25 - width / 2), y, 0.026,
                    width, 0.595, 0.12, 0, 0.014, 1)
    for y in (3.85, 7.02, 10.22, 13.42):
        box("Continuous stone stringcourse", 0, y, 0.045, WIDTH, 0.11, 0.29, 0,
            0.015 if LOD == "near" else 0.0, 2)


def shopfront():
    # 3.2 m display opening plus 1.05 m entry; all visual, no doorway collider.
    b = 0.015 if LOD == "near" else 0.0
    wall_rect("Shop left pier", -3.25, -2.9, 0, 3.85)
    wall_rect("Shop right pier", 2.9, 3.25, 0, 3.85)
    box("Shop display opaque glass", -0.72, 1.95, -0.14, 3.95, 1.93, 0.05, 2)
    box("Recessed door", 2.0, 1.46, -0.12, 1.08, 2.6, 0.16, 1, b, 2)
    box("Door opaque glass", 2.0, 1.88, -0.025, 0.83, 1.35, 0.025, 2)
    box("Stone threshold", 2.0, 0.10, 0.025, 1.2, 0.20, 0.50, 0, b, 2)
    box("Display stallriser", -0.72, 0.54, 0.02, 4.17, 0.86, 0.34, 1, b, 2)
    box("Stone shop plinth", -0.72, 0.10, 0.01, 4.23, 0.20, 0.48, 0, b, 2)
    for x in (-2.88, 1.42, 2.84):
        box("Painted shop pilaster", x, 1.65, 0.04, 0.22, 3.1, 0.40, 1, b, 2)
    box("Blank original shop fascia", 0, 3.27, 0.055, 6.13, 0.62, 0.38, 1, b, 2)
    box("Fascia stone hood", 0, 3.65, 0.10, 6.42, 0.15, 0.52, 0, b, 2)
    if LOD == "far":
        box("Door metal handle silhouette", 2.35, 1.35, 0.04, 0.035, 0.3, 0.065, 3)
        return
    for y in (1.0, 2.87):
        box("Display rail", -0.72, y, -0.025, 4.12, 0.085, 0.16, 1, b, 2)
    for x in (-1.45, -0.05):
        box("Display mullion", x, 1.95, -0.025, 0.065, 1.92, 0.16, 1, b, 2)
    box("Fascia upper metal fillet", 0, 3.50, 0.255, 5.94, 0.025, 0.03, 3, 0.004, 2)
    box("Fascia lower moulding", 0, 2.95, 0.09, 6.23, 0.07, 0.48, 1, b, 2)
    box("Door handle", 2.35, 1.35, 0.01, 0.035, 0.31, 0.06, 3, 0.009, 3)
    for y in (1.22, 1.48):
        box("Handle mount", 2.35, y, -0.02, 0.08, 0.06, 0.045, 3, 0.008, 2)
    if LOD == "near":
        for x in (-2.0, -0.72, 0.56):
            for side in (-1, 1):
                box("Stallriser panel stile", x + side * 0.49, 0.57, 0.205, 0.05, 0.58, 0.05, 1, 0.008, 2)
            for y in (0.29, 0.85):
                box("Stallriser panel rail", x, y, 0.205, 1.03, 0.05, 0.05, 1, 0.008, 2)
        for x in (-2.88, 1.42, 2.84):
            box("Pilaster capital", x, 2.81, 0.065, 0.32, 0.12, 0.45, 1, 0.012, 2)
            box("Pilaster foot", x, 0.28, 0.065, 0.30, 0.26, 0.45, 1, 0.012, 2)


def cornice():
    # Stepped outward profile stays inside the same 6.5 m width at all LODs.
    box("Roof cornice lower bed", 0, 15.77, 0.02, WIDTH, 0.12, 0.46, 0,
        0.018 if LOD == "near" else 0.0, 2)
    box("Roof cornice weather cap", 0, 15.93, 0.045, WIDTH, 0.14, 0.55, 0,
        0.025 if LOD != "far" else 0.0, 2)
    if LOD == "near":
        box("Cornice recessed fillet", 0, 15.84, -0.005, WIDTH, 0.045, 0.41, 0, 0.006, 2)
        for i in range(17):
            box("Cornice dentil", -3.03 + i * 0.379, 15.64, 0.07, 0.16, 0.18, 0.28, 0, 0.016, 2)


def build_lod(lod):
    global LOD
    LOD = lod
    PARTS.clear()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # Closed structural back and actual recess depth. No Godot collision tags.
    box("Closed shallow backing", 0, 7.92, -0.45, WIDTH, 15.84, 0.10)
    upper_wall()
    shopfront()
    cornice()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = "GlasgowBay_" + lod.upper()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # Join can leave duplicate slots: remap to the four original materials.
    old = list(obj.data.materials)
    indices = [MATERIALS.index(old[p.material_index]) for p in obj.data.polygons]
    obj.data.materials.clear()
    for mat in MATERIALS:
        obj.data.materials.append(mat)
    for polygon, index in zip(obj.data.polygons, indices):
        polygon.material_index = index
    obj["prototype_status"] = "UNINTEGRATED; visual and Mac performance acceptance pending"
    obj["units"] = "metres; Y up and +Z front in glTF"
    obj["lod"] = lod
    obj["collision"] = "none; preserve existing independent gameplay geometry"
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    bpy.ops.export_scene.gltf(filepath=str(OUT / ("glasgow_bay_" + lod + ".glb")),
                              export_format="GLB", use_selection=True,
                              export_texcoords=True, export_normals=True,
                              export_tangents=True, export_materials="EXPORT",
                              export_extras=True, export_yup=True,
                              export_cameras=False, export_lights=False,
                              export_animations=False, export_image_format="AUTO")
    obj.data.calc_loop_triangles()
    return {"lod": lod, "blender_triangles": len(obj.data.loop_triangles),
            "authored_parts": len(PARTS)}


def main():
    OUT.mkdir(exist_ok=True)
    TEX.mkdir(exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    make_materials()
    results = [build_lod(lod) for lod in ("near", "mid", "far")]
    # No .blend necessary: exact generator is the original editable source.
    report = {"schema": 1, "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "blender": bpy.app.version_string, "seed": SEED,
              "status": "UNINTEGRATED PROTOTYPE", "geometry": results,
              "rendered": False, "downloaded_assets": [], "game_integrated": False}
    (ROOT / "generation.json").write_text(json.dumps(report, indent=2) + "\n")
    print("GLASGOW_BAY_GEOMETRY " + json.dumps(results))


if __name__ == "__main__":
    main()
