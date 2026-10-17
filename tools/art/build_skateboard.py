"""Build the original Tam skateboard with installed Blender, without downloads.

    blender --background --factory-startup --python tools/art/build_skateboard.py

All dimensions below are in metres in the game's board-local X/Y/Z frame.
Godot Y-up is converted to Blender Z-up before glTF's normal Y-up export.
No third-party images, geometry, materials, scripts or generated AI services are used.
The output is project-owned original content, under the same terms as ART-001.
"""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import struct
import sys

import bpy
import numpy as np
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "game/art/assets/tam_skateboard"
PARTS: list = []
MATERIALS: list = []


def point(value):
    x, y, z = value
    return (x, -z, y)


def uv_region(index, u, v):
    # One 1024px atlas. Each material selects a distinct, padded region.
    if index == 0:
        return (0.015 + 0.465 * u, 0.015 + 0.97 * v)
    if index == 1:
        return (0.52 + 0.46 * u, 0.52 + 0.46 * v)
    if index == 2:
        return (0.53 + 0.18 * u, 0.04 + 0.40 * v)
    return (0.78 + 0.18 * u, 0.04 + 0.40 * v)


def mesh(name, vertices, faces, material_index, uv=None, smooth=True):
    data = bpy.data.meshes.new(name)
    data.from_pydata([point(v) for v in vertices], [], faces)
    data.update()
    data.materials.append(MATERIALS[material_index])
    uv_layer = data.uv_layers.new(name="UVMap")
    for polygon in data.polygons:
        polygon.use_smooth = smooth
        for loop_index in polygon.loop_indices:
            i = data.loops[loop_index].vertex_index
            base = uv[i] if uv else (0.5, 0.5)
            uv_layer.data[loop_index].uv = uv_region(material_index, *base)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    PARTS.append(obj)
    return obj


def bevel_box(name, center, dimensions, material_index, bevel=0.002):
    bpy.ops.mesh.primitive_cube_add(size=1, location=point(center))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (dimensions[0], dimensions[2], dimensions[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(MATERIALS[material_index])
    bevel_modifier = obj.modifiers.new("MachinedEdge", "BEVEL")
    bevel_modifier.width = bevel
    bevel_modifier.segments = 2
    bpy.ops.object.modifier_apply(modifier=bevel_modifier.name)
    uv = obj.data.uv_layers.active or obj.data.uv_layers.new()
    for loop in uv.data:
        loop.uv = uv_region(material_index, 0.5, 0.5)
    PARTS.append(obj)
    return obj


def tube(name, start, end, radius, material_index, sides=12, end_radius=None):
    axis = Vector(end) - Vector(start)
    direction = axis.normalized()
    tangent = direction.cross(Vector((0, 1, 0)))
    if tangent.length < 0.01:
        tangent = direction.cross(Vector((1, 0, 0)))
    tangent.normalize()
    bitangent = direction.cross(tangent).normalized()
    vertices = []
    for center, r in [(start, radius), (end, end_radius or radius)]:
        for i in range(sides):
            angle = math.tau * i / sides
            p = Vector(center) + tangent * (math.cos(angle) * r) + bitangent * (math.sin(angle) * r)
            vertices.append(tuple(p))
    faces = []
    for i in range(sides):
        j = (i + 1) % sides
        faces.append((i, j, j + sides, i + sides))
    faces += [tuple(reversed(range(sides))), tuple(range(sides, sides * 2))]
    obj = mesh(name, vertices, faces, material_index)
    obj.data.polygons[-1].use_smooth = False
    obj.data.polygons[-2].use_smooth = False
    return obj


def atlas():
    size = 1024
    rng = np.random.default_rng(241017)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    pixels = np.ones((size, size, 4), dtype=np.float32)
    # Restrained maple grain, orange underside ink, an original river/bridge motif.
    grain = np.sin(xx * 0.24 + np.sin(yy * 0.012) * 3.0) * 0.025
    grain += np.sin(xx * 0.81 + yy * 0.007) * 0.008
    wood = np.array([0.66, 0.39, 0.17], dtype=np.float32)
    pixels[:, :512, :3] = np.clip(wood[None, None, :] + grain[:, :512, None], 0, 1)
    ink = (xx > 37) & (xx < 475) & (yy > 93) & (yy < 930)
    pixels[ink, :3] = np.array([0.55, 0.19, 0.075])
    river_x = 245 + 86 * np.sin(yy * 0.007 + 0.5) + 30 * np.sin(yy * 0.016)
    river = ink & (np.abs(xx - river_x) < 20)
    pixels[river, :3] = [0.055, 0.23, 0.25]
    banks = ink & (np.abs(np.abs(xx - river_x) - 26) < 2.3)
    pixels[banks, :3] = [0.88, 0.71, 0.38]
    for bridge_y in (238, 485, 742):
        bridge = ink & (np.abs(yy - bridge_y) < 4) & (np.abs(xx - river_x) < 58)
        pixels[bridge, :3] = [0.89, 0.77, 0.47]
    # Eight original bridge-star marks; no copied branding or typeface dependency.
    for star_y in (145, 337, 645, 856):
        for star_x in (86, 421):
            star = (np.abs(xx - star_x) + np.abs(yy - star_y) < 11)
            pixels[star, :3] = [0.89, 0.72, 0.37]
    # Grip grain has finite pixel detail and gets ordinary mipmaps in Godot.
    grip = (xx >= 512) & (yy >= 512)
    fine = np.clip(rng.normal(0.0, 0.014, (size, size)), -0.035, 0.035)
    pixels[grip, :3] = np.clip(np.array([0.075, 0.085, 0.089]) + fine[grip, None], 0, 1)
    pixels[:512, 512:768, :3] = [0.47, 0.51, 0.53]
    pixels[:512, 768:, :3] = [0.75, 0.68, 0.51]
    # Subtle cast machining and wheel sidewall bands, without extra material surfaces.
    pixels[:512, 512:768, :3] += (np.sin(xx[:512, 512:768] * 0.16) * 0.012)[:, :, None]
    image = bpy.data.images.new("TamBoardAtlas", width=size, height=size, alpha=False)
    image.pixels.foreach_set(pixels.ravel())
    image.filepath_raw = str(OUTPUT / "board_albedo.png")
    image.file_format = "PNG"
    image.save()
    return image


def materials(image):
    for name, roughness, metallic in [
        ("MapleAndRiverInk", 0.64, 0.0), ("Griptape", 0.96, 0.0),
        ("CastAluminium", 0.34, 0.72), ("Urethane", 0.70, 0.0),
    ]:
        material = bpy.data.materials.new(name)
        material.use_nodes = True
        material.use_backface_culling = True
        bsdf = material.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        tex = material.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = image
        material.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        MATERIALS.append(material)


def deck():
    # Preserve the existing silhouette and contact datums. The old fan deck has
    # long triangles; this grid resolves nose/tail kicks and a shallow concavity.
    rows, columns = 41, 11
    vertices, uvs = [], []
    zs = np.linspace(-0.4175, 0.4175, rows)
    for layer in range(2):
        for z in zs:
            cap = max(0.0, (abs(float(z)) - 0.30) / 0.118)
            half_width = 0.118 * math.sqrt(max(0.0, 1.0 - cap * cap))
            for col in range(columns):
                u = 2.0 * col / (columns - 1) - 1.0
                x = half_width * u
                kick = 0.65 * max(0.0, abs(float(z)) - 0.28) ** 1.5
                y = (-0.014 if layer == 0 else 0.014) + kick + x * x * 0.14
                vertices.append((x, y, float(z)))
                uvs.append((0.5 + x / 0.236, 0.5 + float(z) / 0.836))
    count = rows * columns
    faces = []
    for layer in range(2):
        for row in range(rows - 1):
            for col in range(columns - 1):
                a = layer * count + row * columns + col
                face = (a, a + columns, a + columns + 1, a + 1)
                faces.append(face if layer == 1 else tuple(reversed(face)))
    for row in range(rows - 1):
        a, b = row * columns, (row + 1) * columns
        faces += [(a, b, b + count, a + count),
                  (a + columns - 1, a + columns - 1 + count, b + columns - 1 + count, b + columns - 1)]
    for row in (0, rows - 1):
        for col in range(columns - 1):
            a = row * columns + col
            face = (a, a + 1, a + 1 + count, a + count)
            faces.append(tuple(reversed(face)) if row == 0 else face)
    maple = mesh("PressedMapleDeck", vertices, faces, 0, uvs)
    bpy.context.view_layer.objects.active = maple
    maple.select_set(True)
    edge = maple.modifiers.new("RoundedLaminatedRim", "BEVEL")
    edge.limit_method = "ANGLE"
    edge.angle_limit = math.radians(35)
    edge.width = 0.0015
    edge.segments = 2
    bpy.ops.object.modifier_apply(modifier=edge.name)
    maple.select_set(False)
    # Inset grip leaves a visible laminated maple perimeter, same shoe-contact Y.
    grip_vertices, grip_uvs = [], []
    for z in zs:
        z = float(z) * 0.94
        cap = max(0.0, (abs(z) - 0.282) / 0.111)
        half_width = 0.111 * math.sqrt(max(0.0, 1.0 - cap * cap))
        for col in range(columns):
            x = half_width * (2.0 * col / (columns - 1) - 1.0)
            y = 0.017 + 0.65 * max(0.0, abs(z) - 0.28) ** 1.5 + x * x * 0.14
            grip_vertices.append((x, y, z))
            grip_uvs.append((0.5 + x / 0.236, 0.5 + z / 0.836))
    grip_faces = []
    for row in range(rows - 1):
        for col in range(columns - 1):
            a = row * columns + col
            grip_faces.append((a, a + columns, a + columns + 1, a + 1))
    mesh("InsetGriptape", grip_vertices, grip_faces, 1, grip_uvs)


def wheel(side, z):
    # Lathed profile gives rounded shoulders and recessed bearing, same 32mm radius.
    center_x = side * 0.115
    profile = [(-0.016, 0.021), (-0.014, 0.029), (-0.009, 0.032),
               (0.009, 0.032), (0.014, 0.029), (0.016, 0.021),
               (0.016, 0.012), (-0.016, 0.012)]
    sides = 20
    vertices = []
    for axial, radius in profile:
        for i in range(sides):
            angle = math.tau * i / sides
            vertices.append((center_x + axial, -0.088 + math.cos(angle) * radius, z + math.sin(angle) * radius))
    faces = []
    for row in range(len(profile)):
        next_row = (row + 1) % len(profile)
        for col in range(sides):
            nxt = (col + 1) % sides
            faces.append((row * sides + col, row * sides + nxt, next_row * sides + nxt, next_row * sides + col))
    mesh("RoundedUrethaneWheel", vertices, faces, 3)
    tube("Bearing", (center_x - 0.0165, -0.088, z), (center_x + 0.0165, -0.088, z), 0.012, 2, 12)
    tube("AxleNut", (side * 0.131, -0.088, z), (side * 0.137, -0.088, z), 0.0065, 2, 6)


def hardware():
    for end in (-1.0, 1.0):
        z = end * 0.255
        bevel_box("TruckBaseplate", (0, -0.025, z), (0.075, 0.014, 0.094), 2, 0.003)
        # Hanger tapers toward the axle while the kingpin/bushing remains visible.
        tube("Hanger", (-0.095, -0.083, z), (0.095, -0.083, z), 0.020, 2, 12)
        tube("Axle", (-0.14, -0.088, z), (0.14, -0.088, z), 0.0045, 2, 10)
        tube("Kingpin", (0, -0.033, z - end * 0.021), (0, -0.082, z), 0.011, 2, 10)
        tube("Bushing", (0, -0.044, z - end * 0.017), (0, -0.063, z - end * 0.009), 0.018, 3, 12)
        for side in (-1.0, 1.0):
            wheel(side, z)
            for dz in (-0.035, 0.035):
                tube("FlushDeckBolt", (side * 0.045, 0.0175, z + dz),
                     (side * 0.045, 0.020, z + dz), 0.004, 2, 8)


def read_glb(path):
    data = path.read_bytes()
    length, kind = struct.unpack_from("<II", data, 12)
    assert kind == 0x4E4F534A
    return json.loads(data[20:20 + length])


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    materials(atlas())
    deck()
    hardware()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = "TamSkateboard"
    # Ensure independent author's coordinates and exporter have no hidden scale.
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.data.calc_loop_triangles()
    # Inverse Blender->Godot is (x,z,-y).
    bounds = [(v.co.x, v.co.z, -v.co.y) for v in obj.data.vertices]
    path = OUTPUT / "tam_skateboard.glb"
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                              export_animations=False, export_yup=True,
                              export_apply=True, export_cameras=False, export_lights=False)
    gltf = read_glb(path)
    primitives = gltf["meshes"][0]["primitives"]
    triangles = sum(gltf["accessors"][p["indices"]]["count"] // 3 for p in primitives)
    manifest = {
        "schema": 1, "asset": "Original Tam skateboard", "author": "Original project-authored geometry and texture",
        "licence": "Project-owned original content; no public project licence grant selected (ART-001)",
        "external_assets": [], "network_required": False, "blender_version": bpy.app.version_string,
        "generator": "tools/art/build_skateboard.py",
        "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "regenerate": "blender --background --factory-startup --python tools/art/build_skateboard.py",
        "coordinates": "Godot board-local metres: X right, Y up, Z along deck. No runtime offset or scale.",
        "contract": {"axle_z_m": [-0.255, 0.255], "wheel_center_y_m": -0.088,
                     "wheel_radius_m": 0.032, "deck_grip_center_y_m": 0.017,
                     "shoe_contact_at_z_m": [-0.255, 0.255], "collision": "None; visual replacement only"},
        "bounds_min_m": [round(min(p[i] for p in bounds), 7) for i in range(3)],
        "bounds_max_m": [round(max(p[i] for p in bounds), 7) for i in range(3)],
        "meshes": len(gltf["meshes"]), "surfaces": len(primitives), "triangles": triangles,
        "materials": [m["name"] for m in gltf["materials"]],
        "texture": {"dimensions": [1024, 1024], "purpose": "Shared basecolor atlas; grip/maple/river ink/metal/urethane",
                    "sources": "Deterministic original NumPy shapes and noise, seed 241017; no external imagery"},
        "outputs": {}
    }
    assert len(primitives) == 4, "Expected four material surfaces"
    assert triangles <= 6500, "Budget exceeded"
    for output in [path, OUTPUT / "board_albedo.png"]:
        data = output.read_bytes()
        manifest["outputs"][output.name] = {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("TAM_BOARD_BUILD_OK " + json.dumps({k: manifest[k] for k in ("meshes", "surfaces", "triangles", "bounds_min_m", "bounds_max_m")}))


if __name__ == "__main__":
    main()
