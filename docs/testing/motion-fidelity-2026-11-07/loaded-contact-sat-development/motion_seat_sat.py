import json
from pathlib import Path
import numpy as np
from scipy.spatial import ConvexHull

packet=json.loads(Path('.local/motion-seat-sat.json').read_text())
board=packet['board']
board_basis=np.array(board['basis'],dtype=np.float64).T
board_origin=np.array(board['origin'],dtype=np.float64)
for box_number,box in enumerate(packet['native_boxes']):
    body_basis=np.array(box['body']['basis'],dtype=np.float64).T
    child_basis=np.array(box['child']['basis'],dtype=np.float64).T
    box_basis=body_basis@child_basis
    box_origin=np.array(box['body']['origin'],dtype=np.float64)+body_basis@np.array(box['child']['origin'],dtype=np.float64)
    half=np.array(box['half'],dtype=np.float64)
    if np.linalg.norm(box_origin-board_origin)>4:
        continue
    print('NATIVE_BOX',box_number,'world_origin',box_origin.tolist(),'world_basis',box_basis.tolist(),'half',half.tolist())
    results=[]
    for number,raw in enumerate(packet['parts']):
        points=np.array(raw,dtype=np.float64)
        local=((board_origin-box_origin)+points@board_basis.T)@box_basis
        hull=ConvexHull(local)
        axes=[np.eye(3)[i] for i in range(3)]
        axes.extend(hull.equations[:,:3])
        edges=set()
        for a,b,c in hull.simplices:
            for x,y in ((a,b),(b,c),(c,a)):
                edges.add(tuple(sorted((int(x),int(y)))))
        for a,b in edges:
            edge=local[b]-local[a]
            for basis in np.eye(3):
                axis=np.cross(edge,basis)
                length=np.linalg.norm(axis)
                if length>1e-12:
                    axes.append(axis/length)
        best=(-float('inf'),None,None)
        for axis in axes:
            projection=local@axis
            extent=half@np.abs(axis)
            low=float(projection.min()-extent)
            high=float(-extent-projection.max())
            gap=max(low,high)
            if gap>best[0]:
                best=(gap,axis.tolist(),[float(projection.min()),float(projection.max()),float(extent)])
        item={'component':number,'point_count':len(points),'sat_gap_m':best[0],'axis_box_local':best[1],'interval':best[2]}
        results.append(item)
        if number in (3,15,28,31) or best[0]<0:
            print('COMPONENT',json.dumps(item))
    print('OVERLAP_CANDIDATES',json.dumps([r for r in results if r['sat_gap_m']<=0]))
    Path('.local/motion-seat-sat-result.json').write_text(json.dumps({'native_box':box,'component_sat':results},indent=2)+'\n')
