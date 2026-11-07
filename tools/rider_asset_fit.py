#!/usr/bin/env python3
"""Original offline CC0 proxy fitting to the eleven-bone native game rig.

No MakeHuman program code, rig or weights are imported. Body geometry and
targets remain ignored source inputs. Runtime export is selected by the pipeline.
"""
from pathlib import Path
import hashlib
import json
import math
import struct
import functools
from rider_asset_projection import propagate

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / '.local/downloads/mh_skin/production-study'
CACHE = ROOT / '.local/downloads/makehuman_hm08'
OUT = Path(__file__).resolve().parent
GARMENT_FIT = None
APPLIED_GARMENT_FIT = None


def parse_obj(path):
    vertices, uv, faces, groups = [], [], [], {}
    group = ''
    for line in path.read_text().splitlines():
        p = line.split()
        if not p:
            continue
        if p[0] == 'v':
            vertices.append(list(map(float, p[1:4])))
        elif p[0] == 'vt':
            uv.append(list(map(float, p[1:3])))
        elif p[0] == 'g':
            group = p[1]
        elif p[0] == 'f':
            face = [tuple(int(x) - 1 for x in item.split('/')[:2]) for item in p[1:]]
            groups.setdefault(group, set()).update(i for i, _ in face)
            faces.extend((face[0], face[j], face[j + 1]) for j in range(1, len(face) - 1))
    return np.array(vertices), np.array(uv), faces, groups


def adult():
    vertices, _, _, groups = parse_obj(CACHE / 'base.obj')
    for name in ('african-male-young.target', 'asian-male-young.target', 'caucasian-male-young.target'):
        path = CACHE / name
        for line in path.read_text().splitlines():
            row = line.split()
            if row and not row[0].startswith('#'):
                vertices[int(row[0])] += np.array(list(map(float, row[1:4]))) / 3
    joints = {}
    for name, indices in groups.items():
        if name.startswith('joint-'):
            points = vertices[list(indices)]
            joints[name[6:]] = (points.min(axis=0) + points.max(axis=0)) * .05 * [1, 1, -1]
    assert np.max(np.abs(joints['head'] - [0, .761995, -.0475916666666667])) < 1e-10
    return vertices, joints


def proxy(path, vertices):
    scales = np.ones(3)
    mappings = []
    active = False
    for line in path.read_text().splitlines():
        p = line.split()
        if not p or p[0] == '#':
            continue
        if p[0] in ['x_scale', 'y_scale', 'z_scale']:
            axis = 'xyz'.index(p[0][0])
            scales[axis] = abs(vertices[int(p[1]), axis] - vertices[int(p[2]), axis]) / float(p[3])
        elif p[0] == 'verts':
            active = True
        elif active:
            if len(p) == 9:
                mappings.append((list(map(int, p[:3])), list(map(float, p[3:6])), list(map(float, p[6:9]))))
            elif len(p) == 1 and p[0].isdigit():
                mappings.append(([int(p[0])], [1.0], [0, 0, 0]))
            elif p[0] in ['material', 'vertexboneweights_file']:
                continue
            else:
                break
    points = np.array([np.array(w) @ vertices[ids] + np.array(offset) * scales for ids, w, offset in mappings])
    return points * [.1, .1, -.1], mappings


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def basis(start, end):
    y = (end - start) / np.linalg.norm(end - start)
    z = np.array([0., 0., 1.]) - y * y[2]
    z /= np.linalg.norm(z)
    x = np.cross(y, z)
    z = np.cross(x, y)
    return np.stack([x, y, z], axis=1)


def matrix(origin, frame=None):
    result = np.eye(4)
    result[:3, :3] = np.eye(3) if frame is None else frame
    result[:3, 3] = origin
    return result


def rig(joints):
    bones = ['hips', 'torso']
    source = [matrix(joints['pelvis']), matrix(joints['pelvis'])]
    target = [matrix([0, .94, 0]), matrix([0, .94, 0])]
    warps = [np.diag([.968, 1., 1., 1.]), np.diag([1.046, .932, 1., 1.])]
    for side, prefix in [(-1, 'r'), (1, 'l')]:
        name = 'left' if side < 0 else 'right'
        # Game names follow existing negative/positive-side API, while retained
        # MakeHuman subject-left is positiveX. Only source landmark labels differ.
        for part, a, b, origin, length in [
            ('thigh', 'upper-leg', 'knee', [side * .105, .965, 0], .43),
            ('calf', 'knee', 'ankle', [side * .105, .535, 0], .41),
            ('sleeve', 'shoulder', 'elbow', [side * .215, 1.365, 0], .30),
            ('forearm', 'elbow', 'hand', [side * .215, 1.065, 0], .29),
        ]:
            start, end = joints[f'{prefix}-{a}'], joints[f'{prefix}-{b}']
            bones.append(name + '_' + part)
            source.append(matrix(start, basis(start, end)))
            target.append(matrix(origin, np.diag([-1., -1., 1.])))
            warps.append(np.diag([1., length / np.linalg.norm(end - start), 1., 1.]))
    bones.append('neck')
    source.append(matrix(joints['head']))
    target.append(matrix([0, 1.58, -.026]))
    warps.append(np.eye(4))
    transforms = [t @ scale @ np.linalg.inv(s) for s, t, scale in zip(source, target, warps)]
    return bones, source, target, transforms


@functools.lru_cache(maxsize=1)
def source_neck_field():
    """One original source-body field shared by body and wardrobe proxy."""
    base, _, faces, groups = parse_obj(CACHE / 'base.obj')
    body_faces = [face for face in faces if all(v in groups['body'] for v, _ in face)]
    selected = sorted({v for face in body_faces if all(base[v, 1] >= 5.9 for v, _ in face) for v, _ in face})
    hp, _, hf, _ = parse_obj(ROOT / 'game/art/assets/makehuman_hm08/head.obj')
    edges = {}
    for face in hf:
        ids = [v for v, _ in face]
        for a, b in zip(ids, ids[1:] + ids[:1]):
            edge = tuple(sorted((a, b)))
            edges[edge] = edges.get(edge, 0) + 1
    rim = {selected[v] for edge, count in edges.items() if count == 1
           and all(abs(hp[i, 1] + .13) < 1e-7 for i in edge) for v in edge}
    assert len(rim) == 46
    adjacency = {v: set() for v in groups['body']}
    for face in body_faces:
        ids = [v for v, _ in face]
        for v in ids:
            adjacency[v].update(i for i in ids if i != v)
    distances = {v: 0 for v in rim}
    frontier = set(rim)
    for ring in range(1, 7):
        following = {j for i in frontier for j in adjacency[i] if j not in distances}
        for j in following:
            distances[j] = ring
        frontier = following
    field = np.zeros(len(base))
    for v, ring in distances.items():
        field[v] = 1 - smooth(0, 6, ring)
    morphed, _ = adult()
    source_points = morphed * [.1, .1, -.1]
    body_triangles = [[v for v, _ in face] for face in body_faces]
    helper_normals = np.zeros_like(source_points)
    for face in faces:
        if all(v in groups['body'] for v, _ in face):
            continue
        a, b, c = [v for v, _ in reversed(face)]
        normal = np.cross(source_points[b]-source_points[a], source_points[c]-source_points[a])
        helper_normals[[a,b,c]] += normal
    helper_normals /= np.maximum(np.linalg.norm(helper_normals,axis=1)[:,None],1e-20)
    records = propagate(source_points, body_triangles, groups['body'], field, helper_normals)
    _, proxy_mapping = proxy(SOURCE / 'male_casualsuit01.mhclo', morphed)
    used_helpers = {v for ids, _, _ in proxy_mapping for v in ids if v not in groups['body']}
    for record in records:
        helper = record['source_helper_vertex']
        record['used_by_selected_wardrobe_proxy'] = helper in used_helpers
        record['source_helper_groups'] = [name for name, ids in groups.items() if helper in ids]
    (OUT / 'source-neck-helper-map.json').write_text(json.dumps({
        'policy': 'One authentic BODY geodesic neck field; proxy fitting helpers inherit exact nearest real BODY triangle barycentric interpolation before the original mhclo transfer. No MakeHuman program code or authored rig/weights.',
        'global_body_triangle_centroid_radius_m': float(np.max(np.linalg.norm(source_points[np.asarray(body_triangles)] - source_points[np.asarray(body_triangles)].mean(axis=1)[:, None], axis=2))),
        'positive_helper_records': records}, indent=2) + '\n')
    return field


def body_weights(vertices, joints, bones):
    p = vertices * [.1, .1, -.1]
    weights = np.zeros((len(vertices), len(bones)))
    torso = smooth(joints['pelvis'][1] + .025, joints['pelvis'][1] + .17, p[:, 1])
    weights[:, 0], weights[:, 1] = 1 - torso, torso
    for side, prefix, name in [(-1, 'r', 'left'), (1, 'l', 'right')]:
        # Original continuous part masks are evaluated on source body geometry,
        # then transferred through authenticated proxy barycentric mappings.
        shoulder, elbow, wrist = [joints[f'{prefix}-{part}'] for part in ['shoulder', 'elbow', 'hand']]
        arm_length = np.linalg.norm(elbow - shoulder) + np.linalg.norm(wrist - elbow)
        def chain_coordinate(start, end, offset):
            vector = end - start
            t = np.clip((p - start) @ vector / (vector @ vector), 0, 1)
            distance = np.linalg.norm(p - (start + t[:, None] * vector), axis=1)
            return offset + t * np.linalg.norm(vector), distance
        a, da = chain_coordinate(shoulder, elbow, 0)
        b, db = chain_coordinate(elbow, wrist, np.linalg.norm(elbow - shoulder))
        # A height-only arm mask incorrectly gives low cuff vertices to the
        # torso, stretching them into lateral flaps. Compare actual source
        # arm capsules with the torso's elliptical distance instead.
        body_distance = np.sqrt((p[:, 0] / .17) ** 2 + ((p[:, 2] - .005) / .13) ** 2)
        arm_distance = np.minimum(da, db) / .075
        arm = smooth(-.15, .55, body_distance - arm_distance)
        arm *= smooth(.08, .20, p[:, 1] + np.maximum(0, side * p[:, 0] - .24) * .9)
        coordinate = np.where(da < db, a, b)
        elbow_at = np.linalg.norm(elbow - shoulder)
        forearm = smooth(elbow_at - .060, elbow_at + .060, coordinate)
        weights *= (1 - arm[:, None])
        weights[:, bones.index(name + '_sleeve')] += arm * (1 - forearm)
        weights[:, bones.index(name + '_forearm')] += arm * forearm
    leg_amount = 1 - smooth(joints['pelvis'][1] - .02, joints['pelvis'][1] + .08, p[:, 1])
    seat = (1 - smooth(0, .10, np.abs(p[:, 0]))) * smooth(joints['pelvis'][1] - .30, joints['pelvis'][1] - .10, p[:, 1])
    leg_amount *= 1 - seat * .65
    weights *= 1 - leg_amount[:, None]
    for side, prefix, name in [(-1, 'r', 'left'), (1, 'l', 'right')]:
        leg = leg_amount * smooth(-.018, .018, side * p[:, 0])
        calf = 1 - smooth(joints[f'{prefix}-knee'][1] - .07, joints[f'{prefix}-knee'][1] + .07, p[:, 1])
        weights[:, bones.index(name + '_thigh')] += leg * (1 - calf)
        weights[:, bones.index(name + '_calf')] += leg * calf
    weights /= weights.sum(axis=1)[:, None]
    neck = source_neck_field()
    weights *= 1 - neck[:, None]
    weights[:, bones.index('neck')] += neck
    return weights


def apply_garment_fit(positions):
    """Apply source-authenticated offline wardrobe fit; never change skin weights."""
    global APPLIED_GARMENT_FIT
    if GARMENT_FIT is None:
        APPLIED_GARMENT_FIT = None
        return
    data = json.loads(Path(GARMENT_FIT).read_text())
    source_hash = hashlib.sha256((SOURCE / "male_casualsuit01.obj").read_bytes()).hexdigest()
    rest_hash = hashlib.sha256(positions.astype("<f4").tobytes()).hexdigest()
    if source_hash != data["source_obj_sha256"] or rest_hash != data["baseline_game_rest_positions_f32_sha256"]:
        raise RuntimeError("Garment fit refers to a different source or base retarget.")
    delta = np.zeros_like(positions)
    for source_id, offset in data["source_vertex_offsets_m"].items():
        source_id = int(source_id)
        if not 0 <= source_id < len(positions) or len(offset) != 3:
            raise RuntimeError("Invalid source garment vertex in fit adjustment.")
        delta[source_id] = offset
    if not np.isfinite(delta).all() or np.linalg.norm(delta, axis=1).max() > .008 + 1e-10:
        raise RuntimeError("Garment fit exceeds its bounded8mm displacement budget.")
    protected = data["protected_waist_source_vertex_ids"]
    if len(protected) != 100 or np.any(delta[protected] != 0):
        raise RuntimeError("Garment fit changes an authenticated waist source vertex.")
    positions += delta
    APPLIED_GARMENT_FIT = data


def fit_outfit(vertices, joints):
    obj, uv, faces, _ = parse_obj(SOURCE / 'male_casualsuit01.obj')
    fitted, mapping = proxy(SOURCE / 'male_casualsuit01.mhclo', vertices)
    assert len(obj) == len(fitted)
    bones, source, target, transforms = rig(joints)
    native_weights = body_weights(vertices, joints, bones)
    weights = np.array([np.array(w) @ native_weights[ids] for ids, w, _ in mapping])
    weights = np.clip(weights, 0, 1)
    order = np.argsort(weights, axis=1)[:, -4:][:, ::-1]
    kept = np.take_along_axis(weights, order, axis=1)
    kept /= kept.sum(axis=1)[:, None]
    full = np.zeros_like(weights)
    np.put_along_axis(full, order, kept, axis=1)
    points4 = np.concatenate([fitted, np.ones((len(fitted), 1))], axis=1)
    posed = sum((points4 @ transform.T)[:, :3] * full[:, index, None] for index, transform in enumerate(transforms))
    assert np.isfinite(posed).all() and np.max(np.abs(kept.sum(axis=1) - 1)) < 1e-12
    apply_garment_fit(posed)
    parents = list(range(len(posed)))
    def root(i):
        while parents[i] != i:
            parents[i] = parents[parents[i]]
            i = parents[i]
        return i
    for face in faces:
        a, b, c = [root(v[0]) for v in face]
        parents[b] = parents[c] = a
    components = {}
    for index in range(len(posed)):
        components.setdefault(root(index), []).append(index)
    part_for = {}
    for indices in components.values():
        part = 'FittedOutfit'
        for index in indices:
            part_for[index] = part
    np.savez(OUT / 'fitted-cloth.npz', positions=posed, source_positions=fitted, uv=uv,
             weights=kept, joints=order, target_bones=np.array(target), source_bones=np.array(source))
    metadata = {'purpose': 'Source-authenticated offline garment fit; native/Main/art admission is tracked separately.', 'bones': bones,
                'source_joint_markers_m': {k: v.tolist() for k, v in joints.items()},
                'source_vertices': len(posed), 'triangles': len(faces), 'components': [],
                'target_rest_bone_matrices': [t.tolist() for t in target],
                'bounds_min_m': posed.min(axis=0).tolist(), 'bounds_max_m': posed.max(axis=0).tolist()}
    for indices in sorted(components.values(), key=len, reverse=True):
        metadata['components'].append({'vertices': len(indices), 'part': part_for[indices[0]],
                                       'source_mean_m': fitted[indices].mean(axis=0).tolist()})
    (OUT / 'cloth-fit.json').write_text(json.dumps(metadata, indent=2) + '\n')
    # This source outfit is genuinely one welded surface across the belt.
    # Split native draws at an authenticated row of source triangles, keeping
    # shared source vertex IDs/weights/normals exactly equal on both sides.
    face_parts = ['SkinnedJacket' if np.mean(fitted[[v[0] for v in face], 1]) > joints['pelvis'][1] + .060
                  else 'SkinnedTrousers' for face in faces]
    return posed, uv, faces, order, kept, bones, target, face_parts


def write_obj(path, positions, uv, faces):
    triangles = [[v[0] for v in reversed(face)] for face in faces]
    normals = np.zeros_like(positions)
    for a, b, c in triangles:
        n = np.cross(positions[b] - positions[a], positions[c] - positions[a])
        normals[[a, b, c]] += n
    normals /= np.maximum(np.linalg.norm(normals, axis=1)[:, None], 1e-12)
    lines = ['# CC0 fitted derivative; ignored diagnostic prototype, not runtime approved.']
    lines += ['v ' + ' '.join(f'{x:.8f}' for x in point) for point in positions]
    lines += ['vt ' + ' '.join(f'{x:.8f}' for x in point) for point in uv]
    lines += ['vn ' + ' '.join(f'{x:.8f}' for x in point) for point in normals]
    lines += ['s 1']
    lines += ['f ' + ' '.join(f'{v + 1}/{t + 1}/{v + 1}' for v, t in reversed(face)) for face in faces]
    path.write_text('\n'.join(lines) + '\n')


class Gltf:
    def __init__(self):
        self.binary = bytearray()
        self.views = []
        self.accessors = []

    def accessor(self, data, kind, target=None):
        data = np.ascontiguousarray(data)
        while len(self.binary) % 4:
            self.binary.append(0)
        offset = len(self.binary)
        self.binary.extend(data.tobytes())
        view = {'buffer': 0, 'byteOffset': offset, 'byteLength': data.nbytes}
        if target:
            view['target'] = target
        view_id = len(self.views)
        self.views.append(view)
        component = {'f': 5126, 'H': 5123, 'I': 5125}[data.dtype.char]
        record = {'bufferView': view_id, 'componentType': component, 'count': len(data), 'type': kind}
        if kind == 'VEC3':
            record['min'] = data.min(axis=0).astype(float).tolist()
            record['max'] = data.max(axis=0).astype(float).tolist()
        index = len(self.accessors)
        self.accessors.append(record)
        return index

    def save(self, path, document):
        document.update({'asset': {'version': '2.0', 'generator': 'Original Tam Hawks CC0 data-only fitter prototype'},
                         'bufferViews': self.views, 'accessors': self.accessors})
        while len(self.binary) % 4:
            self.binary.append(0)
        document['buffers'] = [{'byteLength': len(self.binary)}]
        encoded = json.dumps(document, separators=(',', ':')).encode()
        encoded += b' ' * (-len(encoded) % 4)
        length = 12 + 8 + len(encoded) + 8 + len(self.binary)
        result = struct.pack('<4sII', b'glTF', 2, length)
        result += struct.pack('<I4s', len(encoded), b'JSON') + encoded
        result += struct.pack('<I4s', len(self.binary), b'BIN\0') + self.binary
        path.write_bytes(result)


def write_outfit_glb(positions, uv, faces, joints, weights, bones, target, face_parts):
    gltf = Gltf()
    normals = np.zeros_like(positions)
    for face in faces:
        a, b, c = [v[0] for v in reversed(face)]
        normals[[a, b, c]] += np.cross(positions[b] - positions[a], positions[c] - positions[a])
    normals /= np.maximum(np.linalg.norm(normals, axis=1)[:, None], 1e-12)
    meshes = []
    landmarks = {}
    for part in ['SkinnedJacket', 'SkinnedTrousers']:
        lookup, mesh_vertices, source_ids, triangles, triangle_sources = {}, [], [], [], []
        for index, face in enumerate(faces):
            if face_parts[index] != part:
                continue
            triangle = []
            for v, t in reversed(face):
                key = (v, t)
                if key not in lookup:
                    lookup[key] = len(mesh_vertices)
                    mesh_vertices.append(key)
                    source_ids.append(v)
                triangle.append(lookup[key])
            triangles.append(triangle)
            triangle_sources.append(index)
        vi, ti = np.array(mesh_vertices).T
        attributes = {
            'POSITION': gltf.accessor(positions[vi].astype('<f4'), 'VEC3', 34962),
            'NORMAL': gltf.accessor(normals[vi].astype('<f4'), 'VEC3', 34962),
            'TEXCOORD_0': gltf.accessor((uv[ti] * [1, -1] + [0, 1]).astype('<f4'), 'VEC2', 34962),
            'JOINTS_0': gltf.accessor(joints[vi].astype('<u2'), 'VEC4', 34962),
            'WEIGHTS_0': gltf.accessor(weights[vi].astype('<f4'), 'VEC4', 34962)}
        indices = gltf.accessor(np.array(triangles, dtype='<u4').reshape(-1), 'SCALAR', 34963)
        meshes.append({'name': part, 'primitives': [{'attributes': attributes, 'indices': indices, 'material': 0}]})
        edge_counts = {}
        for triangle in triangles:
            for a, b in zip(triangle, triangle[1:] + triangle[:1]):
                edge = tuple(sorted((source_ids[a], source_ids[b])))
                edge_counts[edge] = edge_counts.get(edge, 0) + 1
        boundary = [edge for edge, count in edge_counts.items() if count == 1]
        # Keep authenticated source IDs and exact local triangles. QE chooses
        # semantic seam sets from these physical edges; no artificial witness
        # vertices are introduced to satisfy the old procedural-height checks.
        landmarks[part] = {'mesh_vertex_to_source_obj_vertex': source_ids,
                           'mesh_triangle_to_source_obj_triangle': triangle_sources,
                           'mesh_vertex_game_rest_positions_m': positions[vi].tolist(),
                           'mesh_vertex_source_uv': uv[ti].tolist(),
                           'mesh_vertex_game_rest_normals': normals[vi].tolist(),
                           'mesh_vertex_game_joint_indices': joints[vi].tolist(),
                           'mesh_vertex_game_joint_weights': weights[vi].tolist(),
                           'boundary_source_vertex_edges': boundary}
    shared_edges = sorted(set(map(tuple, landmarks['SkinnedJacket']['boundary_source_vertex_edges']))
                          & set(map(tuple, landmarks['SkinnedTrousers']['boundary_source_vertex_edges'])))
    landmarks['waist_seam_correspondence'] = {'source_vertex_edges': shared_edges,
        'meaning': 'Actual identical source boundary edges shared between native shirt/pants draws; no procedural witness geometry.',
        'game_rest_endpoint_positions_m': [[positions[a].tolist(), positions[b].tolist()] for a, b in shared_edges]}
    # Continue the authenticated source body topology below the exact retained
    # head crop. No synthetic zipper, planar insert or witness surface is used.
    base, body_uv, body_faces, body_groups = parse_obj(CACHE / 'base.obj')
    adult_body, body_joints = adult()
    body_p = adult_body * [.1, .1, -.1]
    body_ids = body_groups['body']
    body_faces = [face for face in body_faces if all(v in body_ids for v, _ in face)]
    selected_head = [face for face in body_faces if all(base[v, 1] >= 5.9 for v, _ in face)]
    selected_ids = sorted({v for face in selected_head for v, _ in face})
    head_manifest = json.loads((ROOT / 'game/art/assets/makehuman_hm08/manifest.json').read_text())
    selection_hash = hashlib.sha256(json.dumps(selected_ids, separators=(',', ':')).encode()).hexdigest()
    assert selection_hash == head_manifest['outputs']['head.obj']['selected_vertex_indices_sha256']
    head_source = ROOT / 'game/art/assets/makehuman_hm08/head.obj'
    original_head_p, _, _, _ = parse_obj(head_source)
    natural_head = OUT / 'fitted-head-natural.obj'
    head_p, head_uv, head_faces, _ = parse_obj(natural_head)
    assert len(selected_ids) == len(head_p)
    head_normal = np.array([list(map(float, line.split()[1:4])) for line in
                           natural_head.read_text().splitlines() if line.startswith('vn ')])
    edge_counts = {}
    for face in head_faces:
        ids = [v for v, _ in face]
        for a, b in zip(ids, ids[1:] + ids[:1]):
            edge = tuple(sorted((a, b)))
            edge_counts[edge] = edge_counts.get(edge, 0) + 1
    rim_head = sorted({v for edge, count in edge_counts.items() if count == 1
                       and all(abs(original_head_p[i, 1] + .13) < 1e-7 for i in edge) for v in edge})
    assert len(rim_head) == 46
    rim_source = {selected_ids[i]: i for i in rim_head}
    actual_head_triangles = {frozenset(selected_ids[v] for v, _ in face) for face in head_faces}
    body_native_weights = body_weights(adult_body, body_joints, bones)
    body_transforms = rig(body_joints)[3]
    source4 = np.concatenate([body_p, np.ones((len(body_p), 1))], axis=1)
    game_body = sum((source4 @ transform.T)[:, :3] * body_native_weights[:, index, None]
                    for index, transform in enumerate(body_transforms))
    h0 = target[bones.index('neck')]
    desired = {v: h0[:3, :3] @ head_p[i] + h0[:3, 3] for v, i in rim_source.items()}
    # The exact same source BODY field already drives proxy cloth rest and
    # skin weights. Use the authentic neck source transform, not a separate
    # averaged displacement applied only to the visible body patch.
    neck_weight = body_native_weights[:, bones.index('neck')]
    for v in rim_source:
        assert np.linalg.norm(game_body[v] - desired[v]) < 1e-8
        game_body[v] = desired[v]  # Retain native OBJ's eight-decimal rounding.
    # Use the source garment's authored wardrobe occlusion mask. Retain only
    # the genuine body component connected to the authentic head cut. Covered
    # shoulders/body are omitted exactly as authored, never by a guessed plane.
    source_proxy = SOURCE / 'male_casualsuit01.mhclo'
    delete_tokens = source_proxy.read_text().split('delete_verts', 1)[1].split()
    covered_body = set()
    cursor = 0
    while cursor < len(delete_tokens):
        start = int(delete_tokens[cursor])
        if cursor + 2 < len(delete_tokens) and delete_tokens[cursor + 1] == '-':
            end = int(delete_tokens[cursor + 2])
            assert start <= end
            covered_body.update(range(start, end + 1))
            cursor += 3
        else:
            covered_body.add(start)
            cursor += 1
    assert len(covered_body) == 8430 and not covered_body.intersection(rim_source)
    # The authored mask hides an original source polygon only when ALL its
    # corners are deleted. Keep both native triangles of a partly visible quad.
    body_polygons, polygon_kept, triangle_parent_polygon = [], [], []
    group = ''
    for line in (CACHE / 'base.obj').read_text().splitlines():
        fields = line.split()
        if not fields:
            continue
        if fields[0] == 'g':
            group = fields[1]
        elif fields[0] == 'f' and group == 'body':
            polygon = [tuple(int(i) - 1 for i in item.split('/')[:2]) for item in fields[1:]]
            kept = not all(v in covered_body for v, _ in polygon)
            body_polygons.append(polygon)
            polygon_kept.append(kept)
            for j in range(1, len(polygon) - 1):
                index = len(triangle_parent_polygon)
                assert body_faces[index] == (polygon[0], polygon[j], polygon[j + 1])
                triangle_parent_polygon.append(len(body_polygons) - 1)
    assert len(triangle_parent_polygon) == len(body_faces)
    candidates = [(i, face) for i, face in enumerate(body_faces)
                  if frozenset(v for v, _ in face) not in actual_head_triangles
                  and polygon_kept[triangle_parent_polygon[i]]]
    exposed_adjacency = {}
    for _, face in candidates:
        ids = [v for v, _ in face]
        for v in ids:
            exposed_adjacency.setdefault(v, set()).update(ids)
    exposed = set(rim_source)
    frontier = list(exposed)
    while frontier:
        v = frontier.pop()
        for neighbor in exposed_adjacency.get(v, []):
            if neighbor not in exposed:
                exposed.add(neighbor)
                frontier.append(neighbor)
    chosen = [(i, face) for i, face in candidates if all(v in exposed for v, _ in face)]
    assert len(chosen) == 520
    lookup, entries, tri_under, source_tri_ids = {}, [], [], []
    for source_face_id, face in chosen:
        triangle = []
        for v, t in reversed(face):
            if (v, t) not in lookup:
                lookup[v, t] = len(entries)
                entries.append((v, t))
            triangle.append(lookup[v, t])
        tri_under.append(triangle)
        source_tri_ids.append(source_face_id)
    vi, ti = np.array(entries).T
    p, chest_uv = game_body[vi], body_uv[ti]
    n = np.zeros_like(p)
    for a, b, c in tri_under:
        n[[a, b, c]] += np.cross(p[b] - p[a], p[c] - p[a])
    # UV seam duplicates share the original source-vertex normal.
    per_source = {}
    for v, normal in zip(vi, n):
        per_source[v] = per_source.get(v, np.zeros(3)) + normal
    n = np.array([per_source[v] for v in vi])
    n /= np.maximum(np.linalg.norm(n, axis=1)[:, None], 1e-12)
    for i, v in enumerate(vi):
        if v in rim_source:
            n[i] = head_normal[rim_source[v]]
    chest_weights = body_native_weights[vi].copy()
    js = np.argsort(chest_weights, axis=1)[:, -4:][:, ::-1].astype('<u2')
    ws = np.take_along_axis(chest_weights, js, axis=1)
    ws = (ws / ws.sum(axis=1)[:, None]).astype('<f4')
    attrs = {'POSITION': gltf.accessor(p.astype('<f4'), 'VEC3', 34962),
             'NORMAL': gltf.accessor(n.astype('<f4'), 'VEC3', 34962),
             'TEXCOORD_0': gltf.accessor((chest_uv * [1, -1] + [0, 1]).astype('<f4'), 'VEC2', 34962),
             'JOINTS_0': gltf.accessor(js, 'VEC4', 34962), 'WEIGHTS_0': gltf.accessor(ws, 'VEC4', 34962)}
    meshes.append({'name': 'UpperChest', 'primitives': [{'attributes': attrs,
                   'indices': gltf.accessor(np.array(tri_under, dtype='<u4').reshape(-1), 'SCALAR', 34963), 'material': 1}]})
    np.savez(OUT / 'chest-crop.npz', positions=p, uv=chest_uv, triangles=np.array(tri_under))
    rim_correspondence = [{'chest_mesh_vertex': i, 'source_body_vertex': int(v),
                           'head_obj_vertex': rim_source[v], 'game_rest_position_m': p[i].tolist(),
                           'uv': chest_uv[i].tolist()} for i, v in enumerate(vi) if v in rim_source]
    assert set(v['source_body_vertex'] for v in rim_correspondence) == set(rim_source)
    nodes = [{'name': 'FittedOutfit', 'children': [1]},
             {'name': 'ClothingSkeleton', 'children': list(range(2, 2 + len(bones)))}]
    for name, rest in zip(bones, target):
        nodes.append({'name': name, 'matrix': rest.T.reshape(-1).tolist()})
    for index, mesh in enumerate(meshes):
        nodes[0]['children'].append(len(nodes))
        nodes.append({'name': mesh['name'], 'mesh': index, 'skin': 0})
    inverse_bind = np.array([np.linalg.inv(t).T.reshape(-1) for t in target], dtype='<f4')
    skin = {'name': 'FittedNativeSkin', 'joints': list(range(2, 2 + len(bones))), 'skeleton': 1,
            'inverseBindMatrices': gltf.accessor(inverse_bind, 'MAT4')}
    gltf.save(OUT / 'fitted-casual01.glb', {'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': nodes,
              'meshes': meshes, 'skins': [skin], 'materials': [
                  {'name': 'FittedCloth', 'pbrMetallicRoughness': {'baseColorFactor': [.35, .42, .5, 1], 'metallicFactor': 0, 'roughnessFactor': .85}},
                  {'name': 'DarkUnderlayer', 'pbrMetallicRoughness': {'baseColorFactor': [.025, .030, .04, 1], 'metallicFactor': 0, 'roughnessFactor': .90}}]})
    landmarks['UpperChest'] = {'authorship': 'Authenticated source body complement of exact retained head crop; source casualsuit01 authored8430vertex wardrobe mask; exposed body component connected to authentic46headrim; no spatial crop; ONE shared46rim/six-source-adjacency-ring neck field and actual source neck transform retarget both BODY and proxy wardrobe; original UVs/topology retained.',
        'mesh_vertex_to_source_body_vertex': vi.tolist(),
        'mesh_triangle_to_source_body_triangle': source_tri_ids,
        'mesh_triangle_to_source_body_polygon': [triangle_parent_polygon[i] for i in source_tri_ids],
        'source_body_polygon_vertex_ids': {str(triangle_parent_polygon[i]): [v for v, _ in body_polygons[triangle_parent_polygon[i]]] for i in source_tri_ids},
        'mesh_vertex_game_rest_positions_m': p.tolist(),
        'mesh_vertex_source_uv': chest_uv.tolist(),
        'mesh_vertex_game_rest_normals': n.tolist(),
        'mesh_vertex_game_joint_indices': js.tolist(),
        'mesh_vertex_game_joint_weights': ws.tolist(),
        'head_boundary_correspondence': rim_correspondence,
        'head_source_selection_sha256': selection_hash,
        'neck_rest_matrix_rows': h0.tolist(),
        'authored_occlusion_mask': {'member': 'clothes/male_casualsuit01/male_casualsuit01.mhclo', 'sha256': hashlib.sha256(source_proxy.read_bytes()).hexdigest(), 'source_deleted_body_vertex_ids': sorted(covered_body), 'face_policy': 'omit an original source BODY polygon only when ALL its corners are deleted; preserve both triangles of a partly visible quad', 'component_policy': 'keep only exposed body component connected to all46 authentic head-rim source IDs'},
        'bounds_m': [p.min(axis=0).tolist(), p.max(axis=0).tolist()]}
    if APPLIED_GARMENT_FIT is not None:
        landmarks['garment_layer_fit'] = APPLIED_GARMENT_FIT
    (OUT / 'cloth-landmarks.json').write_text(json.dumps(landmarks, separators=(',', ':')) + '\n')


def main():
    vertices, joints = adult()
    _, uv, faces, _ = parse_obj(SOURCE / 'short02.obj')
    positions, _ = proxy(SOURCE / 'short02.mhclo', vertices)
    positions -= joints['head']
    write_obj(OUT / 'fitted-short02.obj', positions, uv, faces)
    print('Hair fit', len(positions), 'vertices', len(faces), 'triangles', flush=True)
    if (SOURCE / 'male_casualsuit01.obj').exists():
        fitted = fit_outfit(vertices, joints)
        p, uv, faces, *_ = fitted
        write_obj(OUT / 'fitted-casual01.obj', p, uv, faces)
        write_outfit_glb(*fitted)
        print('Cloth fit', len(p), 'vertices', len(faces), 'triangles', flush=True)



def configure(root, source, cache, output, garment_fit=None):
    global ROOT, SOURCE, CACHE, OUT, GARMENT_FIT, APPLIED_GARMENT_FIT
    GARMENT_FIT = garment_fit
    APPLIED_GARMENT_FIT = None
    ROOT, SOURCE, CACHE, OUT = map(Path, (root, source, cache, output))
    OUT.mkdir(parents=True, exist_ok=True)
    source_neck_field.cache_clear()
