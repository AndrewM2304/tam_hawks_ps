#!/usr/bin/env python3
"""Original NPC wardrobe fit, derived from the actual pinned shirt surface.

Vest pieces retain authenticated triangle/barycentric correspondence and native
weights. Apron cloth is original; its drape clears the real shirt/trousers. No
source character mesh, clothing weight, gameplay pose or contact marker changes.
"""
from pathlib import Path
import hashlib
import json
import struct

import numpy as np
from PIL import Image, ImageFilter
from rider_asset_fit import Gltf


def read_glb(path):
    data = path.read_bytes()
    count = struct.unpack_from('<I', data, 12)[0]
    document = json.loads(data[20:20 + count])
    binary = data[28 + count:]
    kinds = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
    types = {5126: '<f4', 5123: '<u2', 5125: '<u4'}

    def access(index):
        item = document['accessors'][index]
        view = document['bufferViews'][item['bufferView']]
        offset = view.get('byteOffset', 0) + item.get('byteOffset', 0)
        return np.frombuffer(binary, dtype=types[item['componentType']],
            count=item['count'] * kinds[item['type']], offset=offset).reshape(item['count'], -1).copy()

    meshes = {}
    for mesh in document['meshes']:
        primitive = mesh['primitives'][0]
        attrs = {key: access(value) for key, value in primitive['attributes'].items()}
        attrs['triangles'] = access(primitive['indices']).reshape(-1, 3)
        meshes[mesh['name']] = attrs
    return document, access, meshes


def polygon_planes(points):
    points = np.array(points, dtype=float)
    # Convex input may be clockwise or anticlockwise.
    area = np.cross(points, np.roll(points, -1, axis=0)).sum()
    if area < 0:
        points = points[::-1]
    planes = []
    for a, b in zip(points, np.roll(points, -1, axis=0)):
        edge = b - a
        normal = np.array([-edge[1], edge[0], 0.])
        planes.append((normal, float(normal[:2] @ a)))
    return planes


def clip(poly, planes):
    """Clip complete linear attributes; the final three entries are source bary."""
    for normal, threshold in planes:
        output = []
        for a, b in zip(poly, poly[1:] + poly[:1]):
            da, db = a[:3] @ normal - threshold, b[:3] @ normal - threshold
            if da >= -1e-11:
                output.append(a)
            if (da < -1e-11) != (db < -1e-11):
                output.append(a + (b - a) * da / (da - db))
        poly = output
        if len(poly) < 3:
            return []
    return poly


def weights_full(mesh, count):
    result = np.zeros((len(mesh['POSITION']), count))
    for column in range(4):
        result[np.arange(len(result)), mesh['JOINTS_0'][:, column]] += mesh['WEIGHTS_0'][:, column]
    return result


def surface(mesh, count, regions, offset, source_ids):
    full_weights = weights_full(mesh, count)
    records, triangles, ancestry = [], [], []
    for face, vertex_ids in enumerate(mesh['triangles']):
        original = [np.r_[mesh['POSITION'][v], mesh['NORMAL'][v], mesh['TEXCOORD_0'][v],
            full_weights[v], np.eye(3)[corner]] for corner, v in enumerate(vertex_ids)]
        for region in regions:
            selected = clip(original, region)
            if len(selected) < 3:
                continue
            start = len(records)
            for vertex in selected:
                normal = vertex[3:6] / max(np.linalg.norm(vertex[3:6]), 1e-12)
                vertex = vertex.copy()
                vertex[:3] += normal * offset
                vertex[3:6] = normal
                records.append(vertex)
                ancestry.append({'native_shirt_triangle': face,
                    'original_outfit_triangle': int(source_ids[face]),
                    'source_barycentric': vertex[-3:].tolist()})
            for corner in range(1, len(selected) - 1):
                ids = [start, start + corner, start + corner + 1]
                p = np.array([records[i][:3] for i in ids])
                if np.linalg.norm(np.cross(p[1] - p[0], p[2] - p[0])) > 1e-11:
                    triangles.append(ids)
    return np.array(records), np.array(triangles, dtype='<u4'), ancestry


def source_surface(mesh, count, regions, offset, source_ids, arm_indices=None, arm_limit=.15):
    """Preserve source vertices/weights exactly; authored boundaries use UV alpha.

    Interpolating weights at a geometric clip point does not reproduce the
    source triangle's deformed surface. Keep its actual vertices instead.
    """
    full = weights_full(mesh, count)
    selected = []
    for face, ids in enumerate(mesh['triangles']):
        if arm_indices is not None and full[ids][:, arm_indices].sum(1).min() > arm_limit:
            continue
        original = [np.r_[mesh['POSITION'][v], np.eye(3)[corner]] for corner, v in enumerate(ids)]
        if any(clip(original, region) for region in regions):
            selected.append(face)
    vertex_map, records, triangles, ancestry = {}, [], [], []
    for face in selected:
        triangle = []
        for corner, v in enumerate(mesh['triangles'][face]):
            if int(v) not in vertex_map:
                vertex_map[int(v)] = len(records)
                normal = mesh['NORMAL'][v]
                records.append(np.r_[mesh['POSITION'][v] + normal * offset, normal,
                    mesh['TEXCOORD_0'][v], full[v], np.eye(3)[corner]])
                ancestry.append({'native_shirt_vertex': int(v), 'native_shirt_triangle': face,
                    'original_outfit_triangle': int(source_ids[face]),
                    'source_barycentric': np.eye(3)[corner].tolist()})
            triangle.append(vertex_map[int(v)])
        triangles.append(triangle)
    return np.array(records), np.array(triangles, dtype='<u4'), ancestry


def coverage_map(mesh, regions, path, colour_source=None, arm_indices=None, arm_limit=.15):
    # Evaluate the original authored shape in source triangle barycentrics.
    # Two-times sampling keeps clean cloth edges without geometric reweighting.
    size = 1024
    mask = np.zeros((size, size), dtype='uint8')
    arm_field = None
    if arm_indices is not None:
        arm_field = weights_full(mesh, 11)[:, arm_indices].sum(1)
    for ids in mesh['triangles']:
        uv = mesh['TEXCOORD_0'][ids] * size
        lower = np.maximum(np.floor(uv.min(0)).astype(int), 0)
        upper = np.minimum(np.ceil(uv.max(0)).astype(int), size - 1)
        if (upper < lower).any():
            continue
        xx, yy = np.meshgrid(np.arange(lower[0], upper[0] + 1), np.arange(lower[1], upper[1] + 1))
        pixels = np.stack([xx.ravel() + .5, yy.ravel() + .5], axis=1)
        a, b, c = uv
        determinant = np.cross(b - a, c - a)
        if abs(determinant) < 1e-9:
            continue
        delta = pixels - a
        u = np.cross(delta, c - a) / determinant
        v = np.cross(b - a, delta) / determinant
        inside = (u >= 0) & (v >= 0) & (u + v <= 1)
        points = mesh['POSITION'][ids[0]] * (1 - u - v)[:, None]
        points += mesh['POSITION'][ids[1]] * u[:, None] + mesh['POSITION'][ids[2]] * v[:, None]
        covered = np.zeros(len(points), dtype=bool)
        for region in regions:
            part = np.ones(len(points), dtype=bool)
            for normal, threshold in region:
                part &= points @ normal >= threshold - 1e-11
            covered |= part
        if arm_field is not None:
            arm = arm_field[ids[0]] * (1 - u - v) + arm_field[ids[1]] * u + arm_field[ids[2]] * v
            # Rest XY alone includes source sleeves folded beside the torso.
            # The authenticated native arm field distinguishes the garment body.
            covered &= arm <= arm_limit
        target = mask[yy.ravel(), xx.ravel()]
        mask[yy.ravel(), xx.ravel()] = np.maximum(target, (inside & covered).astype('uint8') * 255)
    # One source texel of coverage padding prevents UV-split seam pinholes;
    # it is explicitly garment-edge padding, never a source BODY occlusion mask.
    alpha = Image.fromarray(mask).filter(ImageFilter.MaxFilter(3)).resize((512, 512), Image.Resampling.LANCZOS)
    if colour_source is None:
        rgba = Image.new('RGBA', (512, 512), (255, 255, 255, 255))
    else:
        rgba = Image.open(colour_source).convert('RGBA').resize((512, 512), Image.Resampling.LANCZOS)
    rgba.putalpha(alpha)
    rgba.save(path)


def draped_apron(meshes, count):
    cloth_triangles = np.concatenate([mesh['POSITION'][mesh['triangles']]
        for name, mesh in meshes.items() if name in ('SkinnedJacket', 'SkinnedTrousers')])
    rows, columns = 32, 12
    heights = np.linspace(1.36, .755, rows)
    records, triangles, measurements = [], [], []
    for row, y in enumerate(heights):
        blend = (1.36 - y) / (1.36 - .755)
        width = .105 + .058 * blend
        a = cloth_triangles[:, 0, :2]
        edge = cloth_triangles[:, 1, :2] - a
        other = cloth_triangles[:, 2, :2] - a
        determinant = edge[:, 0] * other[:, 1] - edge[:, 1] * other[:, 0]
        safe = np.where(abs(determinant) > 1e-12, determinant, 1.)
        hits = []
        for x in np.linspace(-width, width, columns):
            relative = np.array([x, y]) - a
            u = (relative[:, 0] * other[:, 1] - relative[:, 1] * other[:, 0]) / safe
            v = (edge[:, 0] * relative[:, 1] - edge[:, 1] * relative[:, 0]) / safe
            valid = (abs(determinant) > 1e-12) & (u >= 0) & (v >= 0) & (u + v <= 1)
            z = cloth_triangles[:, 0, 2] * (1 - u - v) + cloth_triangles[:, 1, 2] * u + cloth_triangles[:, 2, 2] * v
            if valid.any():
                hits.append(float(z[valid].min()))
        if not hits:
            raise RuntimeError(f'No actual garment beneath apron row {row}')
        front = min(hits)
        measurements.append({'rest_y_m': float(y), 'actual_garment_front_z_m': front,
            'nominal_clearance_m': .012})
        for column, x in enumerate(np.linspace(-width, width, columns)):
            # Original shallow drape and millimetre folds, away from the clothing.
            z = front - .012 - .004 * (1 - (x / width) ** 2)
            z += .0012 * np.sin(x * 110 + blend * 2) * np.sin(blend * np.pi)
            weights = np.zeros(count)
            weights[1] = 1.  # Source rig's torso bone; free lower apron stays with chest.
            records.append(np.r_[[x, y, z], [0, 0, -1], [column / (columns - 1), blend], weights, [0, 0, 0]])
            if row and column:
                current = row * columns + column
                triangles += [[current - columns - 1, current - 1, current],
                              [current - columns - 1, current, current - columns]]
    records = np.array(records)
    triangles = np.array(triangles, dtype='<u4')
    normals = np.zeros((len(records), 3))
    points = records[triangles, :3]
    face_normals = np.cross(points[:, 1] - points[:, 0], points[:, 2] - points[:, 0])
    # These original triangles face the native outward front direction.
    if face_normals[:, 2].mean() > 0:
        triangles = triangles[:, ::-1]
        face_normals *= -1
    for column in range(3):
        np.add.at(normals, triangles[:, column], face_normals)
    records[:, 3:6] = normals / np.maximum(np.linalg.norm(normals, axis=1)[:, None], 1e-12)
    return records, triangles, measurements


def bake(fit, work, exported):
    source = work / 'fitted-casual01.glb'
    document, access, meshes = read_glb(source)
    skin = document['skins'][0]
    count = len(skin['joints'])
    assert count == 11
    names = [document['nodes'][index]['name'] for index in skin['joints']]
    arm_indices = [index for index, name in enumerate(names) if name.endswith(('_sleeve', '_forearm'))]
    assert arm_indices == [4, 5, 8, 9]
    landmarks = json.loads((work / 'cloth-landmarks.json').read_text())
    shirt = meshes['SkinnedJacket']
    ids = landmarks['SkinnedJacket']['mesh_triangle_to_source_obj_triangle']
    # Fit lower vest coverage to actual sleeve-free source cloth folds. The
    # earlier authored161mm hem clipped real torso side folds at178mm, exposing
    # small shirt islands despite a geometrically continuous4mm overlay.
    arm_field = weights_full(shirt, count)[:, arm_indices].sum(1)
    torso_ids = np.where((arm_field <= .15) & (shirt['POSITION'][:, 1] >= .978)
        & (shirt['POSITION'][:, 1] <= 1.23))[0]
    lower_max_x = float(np.abs(shirt['POSITION'][torso_ids, 0]).max())
    lower_width = lower_max_x + .002
    front = [(0.014, .978), (lower_width, .978), (lower_width, 1.23), (.148, 1.373), (.072, 1.373), (.014, 1.265)]
    back = [(-lower_width, .978), (lower_width, .978), (lower_width, 1.23), (.148, 1.373), (-.148, 1.373), (-lower_width, 1.23)]
    regions = [polygon_planes(front) + [(np.array([0, 0, -1.]), -.018)],
        polygon_planes([(-x, y) for x, y in front]) + [(np.array([0, 0, -1.]), -.018)],
        polygon_planes(back) + [(np.array([0, 0, 1.]), .018)]]
    vest, vest_tri, correspondence = source_surface(shirt, count, regions, .004, ids, arm_indices)
    bands = []
    for lower, upper in [(1.015, 1.043), (1.187, 1.215)]:
        bands.append(polygon_planes([(-.3, lower), (.3, lower), (.3, upper), (-.3, upper)]))
    for side in (-1, 1):
        bands.append(polygon_planes([(side * .089, 1.215), (side * .117, 1.215),
            (side * .117, 1.38), (side * .089, 1.38)]))
    tape_regions = [vest_region + band for vest_region in regions for band in bands]
    tape, tape_tri, _ = source_surface(shirt, count, tape_regions, .0052, ids, arm_indices)
    coverage_map(shirt, regions, exported / 'fitted_vest_albedo.png', exported / 'fitted_cloth_albedo.png', arm_indices)
    coverage_map(shirt, tape_regions, exported / 'fitted_reflector_albedo.png', None, arm_indices)
    apron, apron_tri, apron_rows = draped_apron(meshes, count)
    apron_mesh = {'POSITION': apron[:, :3], 'NORMAL': apron[:, 3:6], 'TEXCOORD_0': apron[:, 6:8],
        'JOINTS_0': np.tile([1, 0, 0, 0], (len(apron), 1)),
        'WEIGHTS_0': np.tile([1., 0, 0, 0], (len(apron), 1)), 'triangles': apron_tri}
    pocket, pocket_tri, _ = surface(apron_mesh, count,
        [polygon_planes([(-.10, .84), (.10, .84), (.10, .98), (-.10, .98)])], .0025, np.arange(len(apron_tri)))
    geometry = [('FittedVest', vest, vest_tri), ('FittedReflectors', tape, tape_tri),
        ('FittedApron', apron, apron_tri), ('FittedApronPocket', pocket, pocket_tri)]
    gltf = Gltf()
    native_meshes = []
    maximum_dropped = 0.
    for name, records, triangles in geometry:
        weights = records[:, 8:8 + count]
        joints = np.argsort(weights, axis=1)[:, -4:][:, ::-1].astype('<u2')
        selected = np.take_along_axis(weights, joints, axis=1)
        maximum_dropped = max(maximum_dropped, float((weights.sum(axis=1) - selected.sum(axis=1)).max()))
        # The native shader consumes the authored float32 sums as written.
        # Renormalising even tiny source rounding changes its actual LBS field.
        if np.max(abs(selected.sum(axis=1) - 1)) > 2e-6:
            raise RuntimeError('Invalid fitted accessory weight sum.')
        attrs = {'POSITION': gltf.accessor(records[:, :3].astype('<f4'), 'VEC3', 34962),
            'NORMAL': gltf.accessor(records[:, 3:6].astype('<f4'), 'VEC3', 34962),
            'TEXCOORD_0': gltf.accessor(records[:, 6:8].astype('<f4'), 'VEC2', 34962),
            'JOINTS_0': gltf.accessor(joints, 'VEC4', 34962),
            'WEIGHTS_0': gltf.accessor(selected.astype('<f4'), 'VEC4', 34962)}
        native_meshes.append({'name': name, 'primitives': [{'attributes': attrs,
            'indices': gltf.accessor(triangles.reshape(-1), 'SCALAR', 34963)}]})
    if maximum_dropped > 1e-5:
        raise RuntimeError(f'Clipped accessory has more than four meaningful influences: {maximum_dropped}')
    bone_nodes = [document['nodes'][i] for i in skin['joints']]
    nodes = [{'name': 'FittedAccessories', 'children': [1]},
        {'name': 'ClothingSkeleton', 'children': list(range(2, 2 + count))}] + bone_nodes
    for index, mesh in enumerate(native_meshes):
        nodes[0]['children'].append(len(nodes))
        nodes.append({'name': mesh['name'], 'mesh': index, 'skin': 0})
    native_skin = {'name': 'AccessoryNativeSkin', 'joints': list(range(2, 2 + count)), 'skeleton': 1,
        'inverseBindMatrices': gltf.accessor(access(skin['inverseBindMatrices']).astype('<f4'), 'MAT4')}
    gltf.save(exported / 'fitted_accessories.glb', {'scene': 0, 'scenes': [{'nodes': [0]}],
        'nodes': nodes, 'meshes': native_meshes, 'skins': [native_skin]})
    metadata = {'schema': 1, 'authorship': 'Original shirt-conforming NPC overlays and draped apron; official CC0 source shirt triangles and unchanged native skin data.',
        'source_outfit_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'unchanged_main_outfit': True, 'vest_normal_clearance_m': .004, 'reflector_clearance_m': .0012,
        'edge_policy': 'Unchanged source vertex/weight identities; original convex cloth edge coverage baked in source UVs at2x then resized512. No geometrically clipped mixed-weight vest vertices.',
        'sleeve_exclusion': {'native_arm_bones': [names[index] for index in arm_indices],
            'maximum_fragment_arm_weight_before_padding': .15,
            'coverage_padding_source1024_texels': 1,
            'policy': 'Accessory coverage only; original shirt, BODY, source weights and all gameplay geometry remain unchanged.'},
        'vest_vertex_source_correspondence': correspondence, 'apron_row_garment_front_measurements': apron_rows,
        'lower_torso_coverage_fit': {'actual_source_native_vertices': torso_ids.tolist(),
            'source_y_band_m': [.978, 1.23], 'maximum_arm_weight': .15,
            'measured_max_absolute_x_m': lower_max_x, 'authored_margin_m': .002,
            'fitted_lower_coverage_halfwidth_m': lower_width,
            'original_lower_coverage_halfwidth_m': .161,
            'policy': 'Accessory UV coverage/selectedsourcefaces only; no source wardrobe/BODY or gameplay geometry modifications.'},
        'maximum_dropped_weight': maximum_dropped,
        'geometry': {name: {'vertices': len(records), 'triangles': len(triangles)} for name, records, triangles in geometry},
        'scope': 'Offline fitted candidate. Native role poses, moving clearance and final visual acceptance remain required.'}
    (exported / 'accessory-fit.json').write_text(json.dumps(metadata, separators=(',', ':')) + '\n')
    return metadata
