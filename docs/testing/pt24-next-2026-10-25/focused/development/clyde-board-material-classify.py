"""Classify observed convex marker vertices against the unchanged source GLB."""
import hashlib
import json
import math
import re
import struct
from pathlib import Path
asset = Path('game/art/assets/tam_skateboard/tam_skateboard.glb')
raw = asset.read_bytes()
offset = 12
while offset < len(raw):
    size, kind = struct.unpack_from('<II', raw, offset)
    offset += 8
    chunk = raw[offset:offset + size]
    offset += size
    if kind == 0x4E4F534A:
        document = json.loads(chunk)
    elif kind == 0x004E4942:
        binary = chunk
result = {'asset': str(asset), 'sha256': hashlib.sha256(raw).hexdigest(), 'witnesses': []}
for line in Path('.local/clyde-bowl-contact-trace.log').read_text().splitlines():
    if not line.startswith('CLYDE_BOWL_CONTACT_CLASSIFICATION '):
        continue
    witness = json.loads(line.partition(' ')[2])
    local = tuple(map(float, re.findall(r'-?\d+(?:\.\d+)?(?:e[+-]?\d+)?', witness['chosen']['local'])))
    matches = []
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            accessor = document['accessors'][primitive['attributes']['POSITION']]
            view = document['bufferViews'][accessor['bufferView']]
            assert accessor['componentType'] == 5126 and accessor['type'] == 'VEC3'
            start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
            stride = view.get('byteStride', 12)
            distance, nearest = min((math.dist(local, vertex), vertex)
                for vertex in (struct.unpack_from('<3f', binary, start + i * stride)
                               for i in range(accessor['count'])))
            matches.append({'material': document['materials'][primitive['material']]['name'],
                            'vertex_distance_m': distance, 'source_vertex': nearest})
    result['witnesses'].append({'witness': witness['witness'], 'observed_local_vertex': local,
                               'nearest_materials': sorted(matches, key=lambda row: row['vertex_distance_m'])})
print(json.dumps(result, indent=2))
