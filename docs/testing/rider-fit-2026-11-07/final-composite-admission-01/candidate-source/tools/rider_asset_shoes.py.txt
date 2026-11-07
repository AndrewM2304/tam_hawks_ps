"""Fit the actual selected CC0 shoe geometry to native sole/toe contacts."""
from pathlib import Path
import json
import numpy as np

def bake(fit, output):
    output = Path(output)
    vertices,joints=fit.adult();obj,uv,faces,groups=fit.parse_obj(fit.SOURCE/'shoes02.obj'); points,mapping=fit.proxy(fit.SOURCE/'shoes02.mhclo',vertices)
    assert len(points)==len(obj)
    # Authored UV charts separate the knitted socks from the actual shoe.
    # A height cut removed valid sloping tongue faces and left upper holes.
    adjacency = {i: set() for i in range(len(uv))}
    for face in faces:
        ids = [t for _, t in face]
        for i in ids: adjacency[i].update(ids)
    visited, sock_triangles, charts = set(), set(), []
    for first in range(len(uv)):
        if first in visited: continue
        chart, pending = {first}, [first]
        while pending:
            i = pending.pop()
            for j in adjacency[i]:
                if j not in chart: chart.add(j); pending.append(j)
        visited.update(chart)
        members = [i for i, face in enumerate(faces) if face[0][1] in chart]
        if not members: continue
        low, high = uv[list(chart)].min(0), uv[list(chart)].max(0)
        sock = low[0] > .75 and high[1] < .15
        if sock:
            assert len(members) == 252 and len(chart) == 154
            sock_triangles.update(members)
        charts.append({'uv_vertex_ids': sorted(chart), 'source_triangle_ids': members,
                       'uv_bounds': [low.tolist(), high.tolist()], 'is_sock': bool(sock)})
    assert len(sock_triangles) == 504 and len(charts) == 8
    metadata={'authored_source_uv_charts':charts,
              'sock_removal_policy':'Remove only the two actual connected UV charts mapped to the original lower-right knitted sock rectangle; retain the entire real upper, sole and detail charts. No height or spatial shoe crop.'}
    for side,prefix,label in [(-1,'r','left'),(1,'l','right')]:
        ankle=joints[f'{prefix}-ankle'];forward=joints[f'{prefix}-foot-2']-ankle;forward[1]=0;forward/=np.linalg.norm(forward)
        z=-forward;x=np.cross([0,1,0],z); frame=np.stack([x,[0,1,0],z],axis=1)
        local=(points-ankle)@frame
        selected=[(index,f) for index,f in enumerate(faces) if all(side*points[v,0]>0 for v,t in f)]
        used=sorted({v for _,f in selected for v,t in f}); bottom=float(local[used,1].min());local[:,1]+=-.0605-bottom
        # Remove only the actual authored sock UV islands. The real sloping
        # vamp and tongue remain intact, including faces above35mm localY.
        selected=[(i,f) for i,f in selected if i not in sock_triangles]
        used=sorted({v for _,f in selected for v,t in f})
        # The body proxy introduces sub-mm outsole tilt. Flatten only the actual
        # lowest 6mm of visible rubber to the existing skating contact plane.
        flat=[v for v in used if local[v,1]<-.0545];adjust=float(np.max(np.abs(local[flat,1]+.0605)));local[flat,1]=-.0605
        # Find an actual vamp triangle intersection x0,y.001. Translate longitudinally
        # so the existing ToeMarker remains ON the visible imported shoe surface.
        hits=[]
        for i,f in selected:
            ids=[v for v,t in f]; p=local[ids]
            mat=np.array([[p[0,0],p[1,0],p[2,0]],[p[0,1],p[1,1],p[2,1]],[1,1,1]])
            if abs(np.linalg.det(mat))<1e-12:continue
            bary=np.linalg.solve(mat,[0,.001,1])
            if np.min(bary)>=-1e-7 and np.max(bary)<=1+1e-7:
                point=bary@p
                if point[2]<-.075:hits.append((point[2],i,bary.tolist(),ids))
        assert hits,(label,'no physical upper target')
        z_hit,tri,bary,ids=min(hits)
        shift=-.115-z_hit;local[:,2]+=shift
        source_faces=[f for i,f in selected]
        # Physical source faces only: every bottom sample used by native support
        # comes from the visible moulded rubber, no added collision/proxy witness.
        sole=[f for f in source_faces if max(local[v,1] for v,t in f)<=-.035]
        upper=[f for f in source_faces if f not in sole]
        fit.write_obj(output/f'fitted-shoe-{label}-sole.obj',local,uv,sole)
        fit.write_obj(output/f'fitted-shoe-{label}-upper.obj',local,uv,upper)
        # Verify central sole target lies on a real horizontal visible outsole face.
        sole_hits=[]
        for f in sole:
            p=local[[v for v,t in f]]
            if np.max(np.abs(p[:,1]+.0605))>1e-8:continue
            m=np.array([[p[0,0],p[1,0],p[2,0]],[p[0,2],p[1,2],p[2,2]],[1,1,1]])
            if abs(np.linalg.det(m))<1e-12:continue
            b=np.linalg.solve(m,[0,0,1])
            if np.min(b)>=-1e-7:sole_hits.append([list(f),b.tolist()])
        assert sole_hits,(label,'sole target is outside actual outsole')
        metadata[label]={'upper_source_triangle_ids':[i for i,face in selected if face not in sole],'sole_source_triangle_ids':[i for i,face in selected if face in sole],'visible_triangles':len(source_faces),'sole_triangles':len(sole),'upper_triangles':len(upper),'bounds_m':[local[used].min(0).tolist(),local[used].max(0).tolist()], 'flattened_actual_outsole_vertices':flat,'max_outsole_flatten_m':adjust,'longitudinal_translation_m':shift,'toe_source_triangle_id':tri,'toe_source_vertex_ids':ids,'toe_barycentric':bary,'sole_source_face_proofs':sole_hits}
        print(label,metadata[label]['bounds_m'],'tri',len(source_faces),'sole',len(sole),'flatten',adjust,'zshift',shift,flush=True)
    (output/'shoe-fit.json').write_text(json.dumps(metadata,indent=2)+'\n')
