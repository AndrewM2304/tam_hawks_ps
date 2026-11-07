"""Restore only the inherited collar displacement in the pinned CC0 head."""
import hashlib, json
from pathlib import Path
import numpy as np

def restore(f, output):
    output = Path(output)
    adult,j=f.adult();base,_,body_faces,groups=f.parse_obj(f.CACHE/'base.obj')
    body_faces=[face for face in body_faces if all(v in groups['body'] for v,_ in face)]
    selected=sorted({v for face in body_faces if all(base[v,1]>=5.9 for v,_ in face) for v,_ in face})
    original=f.ROOT/'game/art/assets/makehuman_hm08/head.obj'
    p,uv,faces,_=f.parse_obj(original)
    manifest=json.loads((original.parent/'manifest.json').read_text())
    assert hashlib.sha256(json.dumps(selected,separators=(',',':')).encode()).hexdigest()==manifest['outputs']['head.obj']['selected_vertex_indices_sha256']
    assert len(selected)==len(p)
    natural=adult[selected]*[.1,.1,-.1]-j['head']
    changed=np.where(np.linalg.norm(natural-p,axis=1)>1e-7)[0]
    assert len(changed)==130
    normal=np.array([list(map(float,l.split()[1:4])) for l in original.read_text().splitlines() if l.startswith('vn ')])
    # Source body's actual smooth area normals include the adjacent real chest,
    # avoiding a flat cap normal at the open seam. Face/lip triangulation and all
    # other original head normals remain untouched.
    body_points=adult*[.1,.1,-.1];source_normals=np.zeros_like(body_points)
    for face in body_faces:
     a,b,c=[v for v,_ in reversed(face)]
     n=np.cross(body_points[b]-body_points[a],body_points[c]-body_points[a])
     source_normals[[a,b,c]]+=n
    source_normals/=np.maximum(np.linalg.norm(source_normals,axis=1)[:,None],1e-12)
    changed_set=set(map(int,changed));affected=set(changed_set)
    for face in faces:
     ids=[v for v,_ in face]
     if changed_set.intersection(ids):affected.update(ids)
    for i in affected:normal[i]=source_normals[selected[i]]
    # Only the 130 positions touched by the prior collar fit change, preserving
    # native face/eyes coordinates and the existing valid lip diagonals exactly.
    restored=p.copy();restored[changed]=natural[changed]
    lines=['# CC0 hm08 adult head derivative; authentic lower-neck geometry restored.', '# Existing face triangles/UVs and face/eye positions retained; no flattened collar rim.']
    lines+=['v '+' '.join(f'{v:.8f}' for v in point) for point in restored]
    lines+=['vt '+' '.join(f'{v:.8f}' for v in point) for point in uv]
    lines+=['vn '+' '.join(f'{v:.8f}' for v in point) for point in normal]
    lines+=['s 1']
    lines+=['f '+' '.join(f'{v+1}/{t+1}/{v+1}' for v,t in face) for face in faces]
    (output/'fitted-head-natural.obj').write_text('\n'.join(lines)+'\n')
    (output/'head-neck-restoration.json').write_text(json.dumps({'source_head_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),'source_head_selection_sha256':manifest['outputs']['head.obj']['selected_vertex_indices_sha256'],'policy':'Restore only130 source lower-neck/under-jaw vertices displaced by the prior hidden-collar ellipse adjustment. All other original head positions, source vertex identities, UVs and native triangle indices remain unchanged. Smooth source-body normals replace the affected neck neighbourhood.','restored_head_vertex_ids':changed.tolist(),'restored_source_body_vertex_ids':[selected[i] for i in changed],'updated_normal_head_vertex_ids':sorted(affected),'max_restoration_m':float(np.linalg.norm(restored-p,axis=1).max())},indent=2)+'\n')
