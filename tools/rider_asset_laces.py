"""Original flat cotton laces fitted offline to the actual selected shoe vamp.

No lace geometry or pattern is imported. The real fitted upper supplies surface
heights; all new geometry stays above it and clear of the authoritative toe and
outsole contact regions. Runtime only instantiates the two cached mesh assets.
"""
from pathlib import Path
import json
import numpy as np


def bake(fit, work, output):
    records = {}
    shoe_source = json.loads((Path(work) / "shoe-fit.json").read_text())
    for side in ('left', 'right'):
        points, _, faces, _ = fit.parse_obj(Path(work) / f'fitted-shoe-{side}-upper.obj')
        triangles = points[np.array([[i for i, _ in face] for face in faces])]
        anchors = []

        def surface(x, z):
            a, b, c = triangles[:, 0], triangles[:, 1], triangles[:, 2]
            den = (b[:, 2]-c[:, 2])*(a[:, 0]-c[:, 0]) + (c[:, 0]-b[:, 0])*(a[:, 2]-c[:, 2])
            safe = np.where(abs(den) > 1e-14, den, 1.)
            u = ((b[:, 2]-c[:, 2])*(x-c[:, 0])+(c[:, 0]-b[:, 0])*(z-c[:, 2]))/safe
            v = ((c[:, 2]-a[:, 2])*(x-c[:, 0])+(a[:, 0]-c[:, 0])*(z-c[:, 2]))/safe
            w = 1-u-v
            valid = (abs(den)>1e-14) & (u>=-1e-7) & (v>=-1e-7) & (w>=-1e-7)
            y = u*a[:, 1]+v*b[:, 1]+w*c[:, 1]
            y[~valid] = -np.inf
            index = int(y.argmax())
            if not np.isfinite(y[index]):
                raise RuntimeError(f'Original lace point is outside the real {side} vamp: {(x,z)}')
            return float(y[index]), index, [float(u[index]), float(v[index]), float(w[index])]

        vertices, uv, emitted = [], [], []
        sections, samples = 8, 9
        width, thickness = .0028, .00065

        def ribbon(path, lift):
            centers = []
            for x, z in path:
                y, source_triangle, bary = surface(x, z)
                centers.append([x, y + lift, z])
                anchors.append({'xz_m':[float(x),float(z)],'generated_upper_obj_triangle':source_triangle,'original_shoe_source_triangle':shoe_source[side]['upper_source_triangle_ids'][source_triangle],'barycentric':bary,'surface_y_m':y,'lace_center_lift_m':lift})
            centers = np.array(centers)
            first = len(vertices)
            for index, center in enumerate(centers):
                tangent = centers[min(index+1,len(centers)-1)]-centers[max(index-1,0)]
                tangent /= np.linalg.norm(tangent)
                across = np.cross(tangent, [0,1,0]); across /= np.linalg.norm(across)
                normal = np.cross(across, tangent); normal /= np.linalg.norm(normal)
                for section in range(sections):
                    angle = 2*np.pi*section/sections
                    vertices.append(center + across*np.cos(angle)*width + normal*np.sin(angle)*thickness)
                    uv.append([index/(len(centers)-1), section/sections])
            for ring in range(len(centers)-1):
                for section in range(sections):
                    a=first+ring*sections+section; b=first+ring*sections+(section+1)%sections
                    c=a+sections; d=b+sections
                    for tri in ((a,c,b),(b,c,d)):
                        # Authored geometry starts in game space. Verify the
                        # real outward face winding before the OBJ writer's
                        # source-handedness conversion.
                        p=np.array([vertices[i] for i in tri]); radial=p.mean(0)-(centers[ring]+centers[ring+1])*.5
                        desired=tri if np.cross(p[1]-p[0],p[2]-p[0])@radial>0 else tuple(reversed(tri))
                        emitted.append(tuple((i,i) for i in reversed(desired)))

        rows = [-.108,-.091,-.074,-.057,-.040,-.023]
        for index in range(len(rows)-1):
            for direction in (-1,1):
                t=np.linspace(0,1,samples)
                x=direction*.019*(1-2*t)
                z=rows[index]*(1-t)+rows[index+1]*t
                ribbon(np.stack([x,z],axis=1), .0016 if direction<0 else .0030)
        # Two compact tied loops, supported by the real tongue surface.
        for direction in (-1,1):
            t=np.linspace(0,1,17)
            x=direction*(.004+.015*np.sin(np.pi*t))
            z=-.042+.008*np.sin(2*np.pi*t)
            ribbon(np.stack([x,z],axis=1), .004)
        fit.write_obj(Path(output)/f'fitted_shoe_{side}_laces.obj',np.asarray(vertices),np.asarray(uv),emitted)
        records[side]={'authorship':'Original flat criss-cross laces and tied loops; fitted to actual imported upper, no third-party lace geometry.', 'rows_z_m':rows,'lace_width_m':width*2,'lace_thickness_m':thickness*2,'vertices':len(vertices),'triangles':len(emitted),'bounds_m':[np.min(vertices,axis=0).tolist(),np.max(vertices,axis=0).tolist()],'vamp_anchors':anchors}
    (Path(output)/'lace-fit.json').write_text(json.dumps(records,indent=2)+'\n')
