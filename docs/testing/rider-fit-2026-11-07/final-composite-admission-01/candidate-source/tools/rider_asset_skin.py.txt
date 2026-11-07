#!/usr/bin/env python3
"""Bake cropped CC0 skin and original anatomical roughness/fine normal maps.

Skin diffuse is a masked derivative of the explicitly licensed MakeHuman system
skin, retaining only the visible head/hands. Roughness and fine normals are
painted analytically in anatomical space. The fitted wardrobe/face pipeline is separate. Requires numpy and Pillow.
"""
from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game/art/rider"
SKIN_SOURCE = ROOT / ".local/downloads/mh_skin/young_lightskinned_male_diffuse.png"
SKIN_SHA256 = "862a26e335e958b70534cb5f0d7c47ef30ab148a56c42b3e9da969cf76f12963"


def save(name, data):
    path = OUT / name
    temporary = OUT / ("." + name + ".tmp")
    Image.fromarray(np.uint8(np.clip(data, 0, 1) * 255 + .5)).save(temporary, format="PNG")
    temporary.replace(path)


def resize_map(name, size):
    image = Image.open(OUT / name)
    temporary = OUT / ("." + name + ".tmp")
    image.resize((size, size), Image.Resampling.LANCZOS).save(temporary, format="PNG")
    temporary.replace(OUT / name)


def normal_map(height, strength):
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * strength
    dy = (np.roll(height, 1, 0) - np.roll(height, -1, 0)) * strength
    n = np.stack((-dx, -dy, np.ones_like(dx)), -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * .5 + .5


def noise(x, y, z=0):
    return np.sin(x * 127.1 + y * 311.7 + z * 74.7) * np.cos(x * 269.5 - y * 183.3 + z * 246.1)


def paint_skin(p, hand=False):
    x, y, z = p[..., 0], p[..., 1], p[..., 2]
    grain = noise(x * 330, y * 330, z * 330)
    mottling = noise(x * 14, y * 14, z * 14) * .018 + noise(x * 42, y * 42, z * 42) * .008
    rgb = np.empty((*x.shape, 3), np.float32)
    rgb[:] = [.77, .565, .465]
    rgb += mottling[..., None] * [1, .56, .37]
    rgb += grain[..., None] * .004
    roughness = np.full(x.shape, .64, np.float32)
    if not hand:
        front = np.clip((-z - .015) / .045, 0, 1)
        # Broad anatomical pigment and unshaven follicle tone. Nothing is baked
        # as a directional light: the game lights retain responsibility for form.
        cheeks = np.exp(-((np.abs(x) - .047) / .024) ** 2 - ((y + .007) / .030) ** 2) * front
        rgb += cheeks[..., None] * [.025, -.026, -.022]
        mouth = np.exp(-(x / .027) ** 6 - ((y + .046) / .007) ** 2) * front
        rgb = rgb * (1 - mouth[..., None] * .77) + np.array([.58, .32, .30]) * mouth[..., None] * .77
        chin = np.exp(-(x / .052) ** 4 - ((y + .080) / .035) ** 2) * front
        sideburns = np.exp(-((np.abs(x) - .064) / .016) ** 4 - ((y + .018) / .057) ** 4) * front
        stubble = np.clip(chin * .24 + sideburns * .35, 0, .45)
        follicles = np.clip((noise(x * 530, y * 530, z * 530) - .40) * 3, 0, 1)
        rgb *= 1 - (stubble * (.12 + follicles * .24))[..., None]
        brow_curve = .059 + .004 * np.sin(np.clip((np.abs(x) - .012) / .05, 0, 1) * np.pi)
        eyebrow = np.exp(-((np.abs(x) - .035) / .024) ** 6 - ((y - brow_curve) / .0043) ** 4) * front
        fibers = .55 + .45 * np.sin((x * 1.4 + y) * 6800 + np.sin(x * 530) * 1.2) ** 2
        brow = eyebrow * fibers * .80
        rgb = rgb * (1 - brow[..., None]) + np.array([.19, .13, .105]) * brow[..., None]
        eye_socket = np.exp(-((np.abs(x) - .030) / .019) ** 4 - ((y - .035) / .013) ** 2) * front
        rgb *= 1 - eye_socket[..., None] * [.065, .095, .082]
        nose = np.exp(-(x / .018) ** 2 - ((y + .006) / .030) ** 2) * front
        roughness -= nose * .18 + mouth * .1
    else:
        # Fingers/knuckles retain the anatomical mesh rather than drawn outlines.
        knuckles = np.exp(-((y + .10) / .025) ** 2)
        rgb += knuckles[..., None] * [.025, -.014, -.015]
    return rgb, roughness, grain


def bake_skin(name, size=2048):
    vertices, uvs, faces = [], [], []
    source = ROOT / "game/art/assets/makehuman_hm08" / f"{name}.obj"
    for line in source.read_text().splitlines():
        values = line.split()
        if not values:
            continue
        if values[0] == "v":
            vertices.append(list(map(float, values[1:4])))
        elif values[0] == "vt":
            uvs.append(list(map(float, values[1:3])))
        elif values[0] == "f":
            face = [tuple(int(i) - 1 for i in v.split("/")[:2]) for v in values[1:]]
            for i in range(1, len(face) - 1):
                faces.append([face[0], face[i], face[i + 1]])
    positions = np.array(vertices)
    texcoords = np.array(uvs)
    if not SKIN_SOURCE.exists() or hashlib.sha256(SKIN_SOURCE.read_bytes()).hexdigest() != SKIN_SHA256:
        raise RuntimeError("Run python3 tools/rider_asset_acquire.py to obtain the verified CC0 source skin.")
    licensed_diffuse = np.asarray(Image.open(SKIN_SOURCE).convert("RGB").resize((size, size), Image.Resampling.LANCZOS), dtype=np.float32) / 255.0
    canvas = np.zeros((size, size, 3), np.float32)
    rough = np.zeros((size, size), np.float32)
    pores = np.zeros((size, size), np.float32)
    mask = np.zeros((size, size), bool)
    for face in faces:
        vi, ti = np.array(face).T
        uv = texcoords[ti] * [size - 1, -(size - 1)] + [0, size - 1]
        x0, y0 = np.floor(uv.min(0)).astype(int).clip(0, size - 1)
        x1, y1 = np.ceil(uv.max(0)).astype(int).clip(0, size - 1)
        yy, xx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        a, b, c = uv
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-8:
            continue
        w0 = ((b[1] - c[1]) * (xx - c[0]) + (c[0] - b[0]) * (yy - c[1])) / den
        w1 = ((c[1] - a[1]) * (xx - c[0]) + (a[0] - c[0]) * (yy - c[1])) / den
        w2 = 1 - w0 - w1
        inside = (w0 >= -.001) & (w1 >= -.001) & (w2 >= -.001)
        p = w0[..., None] * positions[vi[0]] + w1[..., None] * positions[vi[1]] + w2[..., None] * positions[vi[2]]
        rgb, r, h = paint_skin(p, name != "head")
        canvas[y0:y1 + 1, x0:x1 + 1][inside] = licensed_diffuse[y0:y1 + 1, x0:x1 + 1][inside]
        rough[y0:y1 + 1, x0:x1 + 1][inside] = r[inside]
        pores[y0:y1 + 1, x0:x1 + 1][inside] = h[inside]
        mask[y0:y1 + 1, x0:x1 + 1] |= inside
    # Dilate islands to avoid dark mip seams; no exterior background enters skin.
    for _ in range(12):
        for axis in [0, 1]:
            for direction in [-1, 1]:
                neighbor = np.roll(mask, direction, axis)
                add = ~mask & neighbor
                canvas[add] = np.roll(canvas, direction, axis)[add]
                rough[add] = np.roll(rough, direction, axis)[add]
                pores[add] = np.roll(pores, direction, axis)[add]
                mask |= add
    canvas[~mask] = [.77, .565, .465]
    rough[~mask] = .64
    save(f"{name}_albedo.png", canvas)
    save(f"{name}_roughness.png", rough)
    save(f"{name}_normal.png", normal_map(pores, .035))
    resize_map(f"{name}_roughness.png", 512)
    resize_map(f"{name}_normal.png", 1024 if name == "head" else 512)



def bake_all(root, output):
    """Write only the nine cropped anatomical maps; the full fitter completes head/eyes/chest."""
    global ROOT, OUT, SKIN_SOURCE
    ROOT, OUT = Path(root), Path(output)
    OUT.mkdir(parents=True, exist_ok=True)
    SKIN_SOURCE = ROOT / ".local/downloads/mh_skin/young_lightskinned_male_diffuse.png"
    layouts = {}
    for name in ["head", "left_hand", "right_hand"]:
        bake_skin(name, 2048 if name == "head" else 1024)
        if name != "head":
            layouts[name] = pack_hand_islands(name)
    (OUT / 'hand-atlas-layout.json').write_text(json.dumps({
        'schema': 1, 'size': 512,
        'policy': 'Original native hand mesh XYZ/UV/normal/index streams unchanged. Positive uniform per-material UV1 scale/offset with repeat places two authenticated UV islands in distinct512 rectangles. Albedo samples exact2K licensed source; auxiliary maps resample the original512 derivatives in the same physical UV field. No full body atlas exported.',
        'hands': layouts}, indent=2) + '\n')


def pack_hand_islands(name):
    """Pack palm+nail islands using one positive uniform *material* transform.

    Repeat is intentional: the two source islands are far apart in V, but a
    source-derived3.45 scale places their repeated rectangles without overlap.
    No original anatomy file or native vertex attribute is changed.
    """
    source = ROOT / 'game/art/assets/makehuman_hm08' / (name + '.obj')
    uvs, faces = [], []
    for line in source.read_text().splitlines():
        parts = line.split()
        if parts and parts[0] == 'vt':
            uvs.append(list(map(float, parts[1:3])))
        elif parts and parts[0] == 'f':
            ids = [int(vertex.split('/')[1]) - 1 for vertex in parts[1:]]
            for corner in range(1, len(ids) - 1):
                faces.append([ids[0], ids[corner], ids[corner + 1]])
    uvs = np.array(uvs)
    faces = np.array(faces)
    parents = list(range(len(uvs)))

    def root(index):
        while parents[index] != index:
            parents[index] = parents[parents[index]]
            index = parents[index]
        return index

    for face in faces:
        anchor = root(int(face[0]))
        for index in face[1:]:
            parents[root(int(index))] = anchor
    charts = {}
    for face_id, face in enumerate(faces):
        charts.setdefault(root(int(face[0])), {'uvs': set(), 'faces': []})
        charts[root(int(face[0]))]['uvs'].update(map(int, face))
        charts[root(int(face[0]))]['faces'].append(face_id)
    charts = sorted(charts.values(), key=lambda chart: len(chart['uvs']), reverse=True)
    if [len(chart['uvs']) for chart in charts] != [1817, 84]:
        raise RuntimeError('Pinned hand UV chart topology changed; inspect before repacking.')
    native_uv = uvs * [1, -1] + [0, 1]
    scale, size, padding = 3.45, 512, 12
    primary = native_uv[sorted(charts[0]['uvs'])]
    offset = np.array([.025, .025]) - primary.min(0) * scale
    transformed = native_uv * scale + offset
    target_uv = np.mod(transformed, 1.)
    records, boxes = [], []
    for chart in charts:
        ids = sorted(chart['uvs'])
        tiles = np.floor(transformed[ids] + 1e-10).astype(int)
        if not np.all(tiles == tiles[0]):
            raise RuntimeError('An actual source UV chart crosses a repeat boundary.')
        lower, upper = target_uv[ids].min(0), target_uv[ids].max(0)
        padded = [lower - padding / size, upper + padding / size]
        if (padded[0] <= 0).any() or (padded[1] >= 1).any():
            raise RuntimeError('Packed chart has insufficient native mip padding.')
        boxes.append(padded)
        records.append({'source_uv_ids': ids, 'source_triangle_ids': chart['faces'],
            'source_obj_uv_bounds': [uvs[ids].min(0).tolist(), uvs[ids].max(0).tolist()],
            'native_repeat_tile_xy': tiles[0].tolist(),
            'packed_native_uv_bounds': [lower.tolist(), upper.tolist()],
            'effective_pixel_extent': ((upper - lower) * size).tolist()})
    overlap = np.minimum(boxes[0][1], boxes[1][1]) - np.maximum(boxes[0][0], boxes[1][0])
    if np.all(overlap >= 0):
        raise RuntimeError('Padded real palm and nail islands overlap.')
    originals = {
        'albedo': np.asarray(Image.open(SKIN_SOURCE).convert('RGB'), dtype=np.float32) / 255,
        'normal': np.asarray(Image.open(OUT / (name + '_normal.png')).convert('RGB'), dtype=np.float32) / 255,
        'roughness': np.asarray(Image.open(OUT / (name + '_roughness.png')).convert('L'), dtype=np.float32) / 255,
    }
    packed = {'albedo': np.full((size, size, 3), [.77, .565, .465], dtype=np.float32),
        'normal': np.full((size, size, 3), [.5, .5, 1.], dtype=np.float32),
        'roughness': np.full((size, size), .64, dtype=np.float32)}
    mask = np.zeros((size, size), dtype=bool)

    def sample(image, uv):
        height, width = image.shape[:2]
        xy = uv * [width, height] - .5
        xy = np.clip(xy, 0, [width - 1, height - 1])
        lower = np.floor(xy).astype(int)
        upper = np.minimum(lower + 1, [width - 1, height - 1])
        blend = xy - lower
        x, y = blend[:, 0], blend[:, 1]
        if image.ndim == 3:
            x, y = x[:, None], y[:, None]
        a = image[lower[:, 1], lower[:, 0]] * (1 - x) + image[lower[:, 1], upper[:, 0]] * x
        b = image[upper[:, 1], lower[:, 0]] * (1 - x) + image[upper[:, 1], upper[:, 0]] * x
        return a * (1 - y) + b * y

    for face in faces:
        pixels = target_uv[face] * size - .5
        lower = np.maximum(np.floor(pixels.min(0)).astype(int), 0)
        upper = np.minimum(np.ceil(pixels.max(0)).astype(int), size - 1)
        yy, xx = np.mgrid[lower[1]:upper[1] + 1, lower[0]:upper[0] + 1]
        point = np.stack([xx.ravel(), yy.ravel()], axis=1)
        a, b, c = pixels
        determinant = np.cross(b - a, c - a)
        if abs(determinant) < 1e-12:
            continue
        relative = point - a
        u = np.cross(relative, c - a) / determinant
        v = np.cross(b - a, relative) / determinant
        inside = (u >= -1e-7) & (v >= -1e-7) & (u + v <= 1 + 1e-7)
        if not inside.any():
            continue
        bary = np.stack([1 - u[inside] - v[inside], u[inside], v[inside]], axis=1)
        original_uv = bary @ native_uv[face]
        x, y = point[inside].T
        for key, image in originals.items():
            packed[key][y, x] = sample(image, original_uv)
        mask[y, x] = True
    interior_pixels = int(mask.sum())
    for _ in range(padding):
        previous = mask.copy()
        for axis in (0, 1):
            for direction in (-1, 1):
                neighbor = np.roll(previous, direction, axis)
                added = ~mask & neighbor
                for image in packed.values():
                    image[added] = np.roll(image, direction, axis)[added]
                mask |= added
    for key, image in packed.items():
        save(name + '_' + key + '.png', image)
    return {'source_hand_mesh_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'native_uv_orientation': 'OBJ U unchanged; native V=1-OBJ V',
        'material_uv1_scale': [scale, scale, 1.],
        'material_uv1_offset': [*offset.tolist(), 0.], 'material_texture_repeat': True,
        'original_native_vertex_attributes_unchanged': True,
        'padding_pixels': padding, 'interior_pixels': interior_pixels,
        'source_skin_sha256': SKIN_SHA256, 'source_skin_size': [2048, 2048],
        'effective_texels_per_original_uv_unit': size * scale,
        'prior_full_atlas_albedo_texels_per_uv_unit': 1024,
        'charts': records}
