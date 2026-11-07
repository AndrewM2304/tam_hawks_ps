#!/usr/bin/env python3
"""Reproduce fitted rig test reference from pinned public asset files only.

No Godot, NumPy, private source download, network, cache or runtime asset writes.
The source manifest is a reviewed provenance pin, not a signature/trust service.
"""
from pathlib import Path
import argparse, hashlib, json, math, struct
BONES = ['hips', 'torso', 'left_thigh', 'left_calf', 'left_sleeve', 'left_forearm', 'right_thigh', 'right_calf', 'right_sleeve', 'right_forearm', 'neck']

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def require(ok, message):
    if not ok:
        raise ValueError(message)

def glb(path):
    raw = path.read_bytes()
    require(struct.unpack_from('<III', raw) == (1179937895, 2, len(raw)), 'Invalid GLB header')
    offset = 12
    doc = None
    binary = None
    while offset < len(raw):
        size, kind = struct.unpack_from('<II', raw, offset)
        block = raw[offset + 8:offset + 8 + size]
        require(len(block) == size, 'Truncated GLB chunk')
        if kind == 1313821514:
            doc = json.loads(block)
        elif kind == 5130562:
            binary = block
        offset += 8 + size
    require(offset == len(raw) and doc is not None and (binary is not None), 'Missing GLB chunks')
    return (doc, binary)

def accessor(doc, blob, index):
    a = doc['accessors'][index]
    require('sparse' not in a, 'Sparse accessor requires separate admission')
    v = doc['bufferViews'][a['bufferView']]
    require(v.get('buffer', 0) == 0, 'External buffer unsupported')
    c = a['componentType']
    code, width = {5121: ('B', 1), 5123: ('H', 2), 5125: ('I', 4), 5126: ('f', 4)}[c]
    n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
    stride = v.get('byteStride', width * n)
    base = v.get('byteOffset', 0) + a.get('byteOffset', 0)
    require(stride >= width * n and base + (a['count'] - 1) * stride + width * n <= len(blob), 'Invalid accessor layout')
    rows = [list(struct.unpack_from('<' + code * n, blob, base + i * stride)) for i in range(a['count'])]
    if a.get('normalized'):
        require(c in [5121, 5123], 'Unexpected normalized accessor')
        divisor = 255 if c == 5121 else 65535
        rows = [[x / divisor for x in r] for r in rows]
    require(all((math.isfinite(x) for row in rows for x in row)), 'Nonfinite source attributes')
    return rows

def inverse(rows):
    a = [list(map(float, row)) + [float(i == j) for j in range(4)] for i, row in enumerate(rows)]
    for c in range(4):
        pivot = max(range(c, 4), key=lambda r: abs(a[r][c]))
        require(abs(a[pivot][c]) > 1e-12, 'Singular neck rest')
        a[c], a[pivot] = (a[pivot], a[c])
        scale = a[c][c]
        a[c] = [x / scale for x in a[c]]
        for r in range(4):
            if r != c:
                factor = a[r][c]
                a[r] = [x - factor * y for x, y in zip(a[r], a[c])]
    return [r[4:] for r in a]

def obj(path):
    points = []
    uv = []
    faces = []
    for line in path.read_text().splitlines():
        a = line.split()
        if not a:
            continue
        if a[0] == 'v':
            points.append(list(map(float, a[1:4])))
        elif a[0] == 'vt':
            uv.append(list(map(float, a[1:3])))
        elif a[0] == 'f':
            f = [tuple((int(n) - 1 for n in token.split('/')[:2])) for token in a[1:]]
            require(all((v >= 0 and u >= 0 for v, u in f)), 'Negative OBJ indices unsupported')
            faces.append(f)
    require(all((math.isfinite(x) for row in points + uv for x in row)), 'Nonfinite source OBJ')
    return (points, uv, faces)

def build(assets):
    names = ['fitted_outfit.glb', 'fitted_landmarks.json', 'fitted_head.obj']
    manifest = json.loads((assets / 'fitted-manifest.json').read_text())
    for name in names:
        require(sha(assets / name) == manifest['outputs'][name]['sha256'], 'Source pin mismatch: ' + name)
    doc, blob = glb(assets / names[0])
    meta = json.loads((assets / names[1]).read_text())
    skin = doc['skins'][0]
    bones = [doc['nodes'][i]['name'] for i in skin['joints']]
    require(bones == BONES, 'This admitted profile requires original11bone order')
    binds = accessor(doc, blob, skin['inverseBindMatrices'])
    binds = [[[row[c * 4 + r] for c in range(4)] for r in range(4)] for row in binds]
    result = {'asset_sha256': sha(assets / names[0]), 'metadata_sha256': sha(assets / names[1]), 'parts': {}, 'bone_names': bones, 'binds': binds, 'waist_edges': meta['waist_seam_correspondence']['source_vertex_edges'], 'waist_positions': meta['waist_seam_correspondence']['game_rest_endpoint_positions_m'], 'head_rim': []}
    require(len(result['waist_edges']) == 100, 'Missing100edge source waist contract')
    for mesh in doc['meshes']:
        name = mesh['name']
        require(name in ['SkinnedJacket', 'SkinnedTrousers', 'UpperChest'] and len(mesh['primitives']) == 1, 'Unexpected source mesh profile')
        p = mesh['primitives'][0]
        require(p.get('mode', 4) == 4, 'Expected indexed triangle primitive')
        attrs = {key: accessor(doc, blob, value) for key, value in p['attributes'].items()}
        ids = meta[name]['mesh_vertex_to_source_body_vertex' if name == 'UpperChest' else 'mesh_vertex_to_source_obj_vertex']
        indices = [r[0] for r in accessor(doc, blob, p['indices'])]
        require(len(indices) % 3 == 0 and all((0 <= i < len(ids) for i in indices)), 'Invalid source topology')
        triangles = [indices[i:i + 3] for i in range(0, len(indices), 3)]
        require(len(attrs['POSITION']) == len(ids), 'Missing source vertex identity')
        require(all((math.dist(a, b) < 1e-06 for a, b in zip(attrs['POSITION'], meta[name]['mesh_vertex_game_rest_positions_m']))), 'Source rest metadata mismatch')
        result['parts'][name] = {'attributes': attrs, 'source_ids': ids, 'triangles': triangles, 'source_triangles': [[ids[i] for i in t] for t in triangles]}
    points, uv, faces = obj(assets / names[2])
    used = {}
    counts = {}
    for face in faces:
        for v, u in face:
            used.setdefault(v, set()).add(u)
        ids = [c[0] for c in face]
        for a, b in zip(ids, ids[1:] + ids[:1]):
            e = tuple(sorted((a, b)))
            counts[e] = counts.get(e, 0) + 1
    inv = inverse(meta['UpperChest']['neck_rest_matrix_rows'])
    mapped = {}
    for item in meta['UpperChest']['head_boundary_correspondence']:
        chest = result['parts']['UpperChest']
        chest_index = item['chest_mesh_vertex']
        require(chest['source_ids'][chest_index] == item['source_body_vertex'], 'Wrong source Head/chest identity')
        require(math.dist(chest['attributes']['POSITION'][chest_index], item['game_rest_position_m']) < 1e-06, 'Head correspondence departs from actual source chest point')
        game = list(item['game_rest_position_m']) + [1.0]
        local = [sum((a * b for a, b in zip(row, game))) for row in inv[:3]]
        matches = [i for i, p in enumerate(points) if i in used and math.dist(p, local) < 1e-06 and any((math.dist(uv[u], item['uv']) < 1e-06 for u in used[i]))]
        require(len(matches) == 1, 'Ambiguous/missing source Head correspondence')
        index = matches[0]
        source = item['source_body_vertex']
        require(index not in mapped or mapped[index] == source, 'Conflicting source Head identity')
        mapped[index] = source
        result['head_rim'].append({'source_id': source, 'local': points[index], 'uv': item['uv']})
    require(len(mapped) == 46 and len(result['head_rim']) == 47, 'Incomplete source46/47neck contract')
    edges = [e for e, count in counts.items() if count == 1 and e[0] in mapped and (e[1] in mapped)]
    require(len(edges) == 46, 'Head source edge topology changed')
    result['head_edges'] = [[mapped[a], mapped[b]] for a, b in edges]
    result['head_asset_sha256'] = sha(assets / names[2])
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assets', type=Path, default=Path('game/art/rider'))
    parser.add_argument('--output', type=Path, default=Path('tests/fitted-reference.json'))
    args = parser.parse_args()
    result = build(args.assets)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, separators=(',', ':'), allow_nan=False))
    print(json.dumps({'output': str(args.output), 'sha256': sha(args.output), 'bone_count': len(result['bone_names']), 'waist_edges': len(result['waist_edges']), 'head_edges': len(result['head_edges'])}))
if __name__ == '__main__':
    main()
