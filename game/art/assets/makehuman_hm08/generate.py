#!/usr/bin/env python3
"""Regenerate clothed-game anatomical parts from hash-verified CC0 asset data.

Original project tooling; no MakeHuman program code is used. The full body and
macro targets remain in ignored .local/downloads, never in runtime resources.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import urllib.request

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CACHE = ROOT / ".local/downloads/makehuman_hm08"
REVISION = "a8bc2d54ff0ac92e78ff71431b1023eda42bf482"
BASE_URL = f"https://raw.githubusercontent.com/makehumancommunity/makehuman/{REVISION}/"
SOURCES = {
    "base.obj": ("makehuman/data/3dobjs/base.obj", "8e761e6624b8f54536409135d1636da63b32486a90d4897f84e121d144f6fb4c"),
    "caucasian-male-young.target": ("makehuman/data/targets/macrodetails/caucasian-male-young.target", "70e228ba7164737dae664454394536fc5935fa48d333c1a97d77e2dc6eacc5f5"),
    "asian-male-young.target": ("makehuman/data/targets/macrodetails/asian-male-young.target", "ed2e8c191cb6b87b4a2d97c80486acb2604fa549316c7aa2a738a5d5a14334dc"),
    "african-male-young.target": ("makehuman/data/targets/macrodetails/african-male-young.target", "894abc1fbb3d28543a51fef16f89d5d4bdf9aa2e1534413339811a3d47818b7d"),
}


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def mul(a, scale):
    return tuple(x * scale for x in a)


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def normalized(a):
    length = math.sqrt(dot(a, a))
    assert length > 1e-10, "Degenerate source vector"
    return mul(a, 1.0 / length)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def fetch_sources():
    CACHE.mkdir(parents=True, exist_ok=True)
    for name, (path, expected) in SOURCES.items():
        dest = CACHE / name
        if not dest.exists():
            request = urllib.request.Request(BASE_URL + path, headers={"User-Agent": "Tam-Hawks-asset-verifier"})
            with urllib.request.urlopen(request, timeout=40) as response:
                data = response.read(4_000_001)
            assert len(data) <= 4_000_000, "Unexpectedly large source"
            assert digest(data) == expected, f"Source digest mismatch: {name}"
            dest.write_bytes(data)
        assert digest(dest.read_bytes()) == expected, f"Cached source digest mismatch: {name}"


def main():
    fetch_sources()
    original, uvs, groups = [], [], {}
    group = ""
    for line in (CACHE / "base.obj").read_text().splitlines():
        parts = line.split()
        if not parts:
            continue
        if parts[0] == "v":
            original.append(tuple(map(float, parts[1:4])))
        elif parts[0] == "vt":
            uvs.append(tuple(map(float, parts[1:3])))
        elif parts[0] == "g":
            group = parts[1]
        elif parts[0] == "f":
            groups.setdefault(group, []).append(tuple((int(p.split('/')[0])-1, int(p.split('/')[1])-1) for p in parts[1:]))
    vertices = list(original)
    for name in SOURCES:
        if not name.endswith(".target"):
            continue
        for line in (CACHE / name).read_text().splitlines():
            if not line or line.startswith("#"):
                continue
            index, *offset = line.split()
            i = int(index)
            vertices[i] = add(vertices[i], mul(tuple(map(float, offset)), 1/3))

    def marker(name, source=vertices):
        ids = {i for face in groups[name] for i, _ in face}
        return tuple((min(source[i][axis] for i in ids)+max(source[i][axis] for i in ids))/2 for axis in range(3))

    # Accumulate area-weighted normals before cropping so wrist/neck seams remain smooth.
    normals = [(0., 0., 0.) for _ in vertices]
    for face in groups["body"]:
        ids = [v for v, _ in face]
        for j in range(1, len(ids)-1):
            tri = (ids[0], ids[j], ids[j+1])
            normal = cross(sub(vertices[tri[1]], vertices[tri[0]]), sub(vertices[tri[2]], vertices[tri[0]]))
            for i in tri:
                normals[i] = add(normals[i], normal)
    normals = [normalized(n) if dot(n, n)>1e-20 else (0.,1.,0.) for n in normals]
    outputs = {}

    def write_mesh(name, faces, origin, basis, reverse=False, offset=0.):
        safe_faces = []
        split_quads = 0
        for face in faces:
            if len(face) == 4:
                def orientation(indices):
                    points = [vertices[face[i][0]] for i in indices]
                    area = cross(sub(points[1],points[0]),sub(points[2],points[0]))
                    average = tuple(sum(normals[face[i][0]][a] for i in indices) for a in range(3))
                    return dot(area, average)
                # A few tiny lip quads become concave under the adult blend.
                # Select their valid diagonal explicitly instead of trusting
                # an importer's arbitrary quad fan to make an inverted sliver.
                if min(orientation((0,1,2)),orientation((0,2,3))) <= 0 and min(orientation((0,1,3)),orientation((1,2,3))) > 0:
                    safe_faces.extend([tuple(face[i] for i in (0,1,3)),tuple(face[i] for i in (1,2,3))])
                    split_quads += 1
                    continue
            safe_faces.extend(tuple(face[i] for i in (0,j,j+1)) for j in range(1,len(face)-1))
        faces = safe_faces
        ids = sorted({i for face in faces for i, _ in face})
        uv_ids = sorted({i for face in faces for _, i in face})
        lookup, uv_lookup = {v:i+1 for i,v in enumerate(ids)}, {v:i+1 for i,v in enumerate(uv_ids)}
        transform = lambda v: tuple(dot(v, axis) for axis in basis)
        coords = [add(mul(transform(sub(vertices[i], origin)), .1), mul(transform(normals[i]), offset)) for i in ids]
        lines = ["# MakeHuman hm08 CC0 anatomical derivative; see manifest.json and retained notices.", "# Generated by original generate.py; metres, Y-up; no full body/helpers included.", f"o {name}"]
        lines += ["v " + " ".join(f"{x:.8f}" for x in v) for v in coords]
        lines += ["vt " + " ".join(f"{x:.8f}" for x in uvs[i]) for i in uv_ids]
        lines += ["vn " + " ".join(f"{x:.8f}" for x in transform(normals[i])) for i in ids]
        lines += ["s 1"]
        for face in faces:
            ordered = tuple(reversed(face)) if reverse else face
            lines.append("f " + " ".join(f"{lookup[v]}/{uv_lookup[t]}/{lookup[v]}" for v,t in ordered))
        data = ("\n".join(lines)+"\n").encode()
        (HERE / f"{name}.obj").write_bytes(data)
        outputs[f"{name}.obj"] = {"path": f"res://game/art/assets/makehuman_hm08/{name}.obj", "sha256":digest(data), "bytes":len(data), "vertices":len(ids), "faces":len(faces), "triangles":sum(len(f)-2 for f in faces), "concave_quads_split":split_quads, "bounds_min_m":[min(v[a] for v in coords) for a in range(3)], "bounds_max_m":[max(v[a] for v in coords) for a in range(3)], "origin_source":origin, "basis_rows":basis, "outward_offset_m":offset, "selected_vertex_indices_sha256":digest(json.dumps(ids,separators=(',',':')).encode())}

    head_origin = marker("joint-head")
    head_basis = ((1.,0.,0.), (0.,1.,0.), (0.,0.,-1.))
    head_faces = [face for face in groups["body"] if all(original[i][1]>=5.9 for i,_ in face)]
    # Turn the stepped neck crop into a continuous ring inside the opaque collar.
    # The boundary is detected topologically; eyes and mouth are not moved.
    edges, adjacency = {}, {}
    for face in head_faces:
        ids = [i for i,_ in face]
        for i,a in enumerate(ids):
            b = ids[(i+1)%len(ids)]
            key = tuple(sorted((a,b)))
            edges[key] = edges.get(key,0)+1
            adjacency.setdefault(a,set()).add(b)
            adjacency.setdefault(b,set()).add(a)
    boundary = {i for edge,count in edges.items() if count==1 and all((vertices[j][1]-head_origin[1])*.1 < -.065 for j in edge) for i in edge}
    neck_adjustment = {}
    for i in boundary:
        x,y,z = sub(vertices[i],head_origin)
        x,y,z = x*.1,y*.1,-z*.1
        radius = math.sqrt((x/.043)**2+((z-.036)/.039)**2)
        assert radius > 1e-6
        target = add(head_origin,(x/radius*10.,-1.3,-(.036+(z-.036)/radius)*10.))
        neck_adjustment[i] = sub(target,vertices[i])
    visited = set(boundary)
    frontier = set(boundary)
    for weight in (.35,.12):
        following = {j for i in frontier for j in adjacency[i]}-visited
        for j in following:
            nearby = [neck_adjustment[i] for i in sorted(adjacency[j]) if i in frontier and i in neck_adjustment]
            if nearby:
                neck_adjustment[j] = mul(tuple(sum(v[a] for v in nearby)/len(nearby) for a in range(3)),weight)
        visited.update(following)
        frontier = following
    for i,offset in neck_adjustment.items():
        vertices[i] = add(vertices[i],offset)
    # Recompute local surface normals after the neck-only fit.
    head_normals = {i:(0.,0.,0.) for face in head_faces for i,_ in face}
    for face in head_faces:
        ids = [i for i,_ in face]
        for j in range(1,len(ids)-1):
            tri = (ids[0],ids[j],ids[j+1])
            normal = cross(sub(vertices[tri[1]],vertices[tri[0]]),sub(vertices[tri[2]],vertices[tri[0]]))
            for i in tri:
                head_normals[i] = add(head_normals[i],normal)
    for i,normal in head_normals.items():
        normals[i] = normalized(normal)
    write_mesh("head", head_faces, head_origin, head_basis, reverse=True)
    def head_local(v):
        d = mul(sub(v, head_origin), .1)
        return (d[0],d[1],-d[2])
    def scalp_distance(i):
        x,y,z = head_local(vertices[i])
        # Higher at the forehead, lower at the back; interpolate boundary faces
        # instead of producing a saw-toothed hairline along whole source quads.
        forehead = .045 * max(0., min(1., (.025-z)/.13))
        above_ear = .035 * max(0., min(1., (abs(x)-.062)/.012))
        return y - (.025 + forehead + above_ear)
    hair_faces = []
    intersections = {}
    for face in head_faces:
        clipped = []
        for j, current in enumerate(face):
            following = face[(j+1) % len(face)]
            d0, d1 = scalp_distance(current[0]), scalp_distance(following[0])
            if d0 >= 0:
                clipped.append(current)
            if (d0 >= 0) != (d1 >= 0):
                edge = tuple(sorted((current, following)))
                if edge not in intersections:
                    factor = d0 / (d0-d1)
                    v0,t0 = current
                    v1,t1 = following
                    vi,ti = len(vertices),len(uvs)
                    vertices.append(add(vertices[v0],mul(sub(vertices[v1],vertices[v0]),factor)))
                    normals.append(normalized(add(normals[v0],mul(sub(normals[v1],normals[v0]),factor))))
                    uvs.append(add(uvs[t0],mul(sub(uvs[t1],uvs[t0]),factor)))
                    intersections[edge] = (vi,ti)
                clipped.append(intersections[edge])
        if len(clipped) >= 3:
            hair_faces.append(tuple(clipped))
    write_mesh("hair", hair_faces, head_origin, head_basis, reverse=True, offset=.0015)
    for side, label, sign in [("l","left",1), ("r","right",-1)]:
        wrist = marker(f"joint-{side}-hand")
        original_wrist = marker(f"joint-{side}-hand", original)
        original_direction = normalized(sub(marker(f"joint-{side}-finger-3-1", original), original_wrist))
        up = normalized(sub(wrist, marker(f"joint-{side}-finger-3-1")))
        across = sub(marker(f"joint-{side}-finger-5-1"), marker(f"joint-{side}-finger-2-1"))
        # Both hands use local +X roughly toward source +X, +Y toward wrist.
        across = mul(across, sign)
        right = normalized(sub(across, mul(up, dot(across, up))))
        back = normalized(cross(right, up))
        faces = [face for face in groups["body"] if all(original[i][0]*sign>3.3 and dot(sub(original[i],original_wrist), original_direction)>=-.3 for i,_ in face)]
        write_mesh(f"{label}_hand", faces, wrist, (right,up,back))
    manifest = {
        "schema":1, "asset":"MakeHuman hm08 cropped adult head, hands and scalp", "licence":"CC0-1.0", "source_repository":"https://github.com/makehumancommunity/makehuman", "source_revision":REVISION,
        "generator_sha256":digest(Path(__file__).read_bytes()),
        "sources": {name:{"url":BASE_URL+path,"sha256":sha,"bytes":(CACHE/name).stat().st_size} for name,(path,sha) in SOURCES.items()},
        "adaptation": {"generator":"generate.py", "source_units_to_metres":.1, "body_group_only":True, "adult_morph":"Each of three bundled male-young ancestry target displacements weighted 1/3; young corresponds to age 25. The average muscle/weight target is empty and is not needed.", "head_selection":"Original unmorphed body faces with every vertex Y >= 5.9; origin is morphed joint-head; reflect Z and reverse winding.", "hands_selection":"Original body faces wholly beyond wrist plane -0.3 along wrist-to-middle-knuckle and in appropriate |X| > 3.3 side; then transform morphed positions to orthonormal hand-local frame.", "hair_selection":"Clip head faces against local Y >= .025 + .045*clamp((.025-Z)/.13,0,1) + .035*clamp((abs(X)-.062)/.012,0,1), interpolating boundary positions/UV/normals; offset 0.0015 m along smooth normals. Higher forehead and ear clearance, lower rear scalp.", "uvs":"Original UV coordinates retained, with linear interpolation at new hair boundary vertices; no third-party skin texture/material imported.", "normals":"Area-weighted body normals recomputed before crops; no smoothing across disconnected source vertices.", "excluded":"Full unclothed body, all helper/joint render groups, MakeHuman code, textures, clothes and rig."},
        "head_markers_m":{"left_eye":head_local(marker("joint-l-eye")),"right_eye":head_local(marker("joint-r-eye")),"neck":head_local(marker("joint-neck")),"eye_radius_assumed_m":.0138},
        "eye_centers":[head_local(marker("joint-l-eye")),head_local(marker("joint-r-eye"))], "eye_radius":.0138, "outputs": outputs,
        "neck_fit":{"boundary_vertices":len(boundary),"adjusted_vertices":len(neck_adjustment),"bottom_y_m":-.13,"ellipse_center_xz_m":[0.,.036],"ellipse_radii_xz_m":[.043,.039],"neighbor_ring_blends":[.35,.12],"description":"Only the low open neck boundary and two neighboring topology rings are fitted to an ellipse under the opaque collar; facial landmarks are unchanged."},
        "notices":["docs/licences/third-party/makehuman-CC0.txt","docs/licences/third-party/makehuman-LICENCE-SCOPE.txt"],
        "licences":[{"path":path,"sha256":digest((ROOT/path).read_bytes())} for path in ["docs/licences/third-party/makehuman-CC0.txt","docs/licences/third-party/makehuman-LICENCE-SCOPE.txt"]],
        "regenerate":"python3 game/art/assets/makehuman_hm08/generate.py (uses only Python standard library; pinned downloads cached in ignored .local/downloads/makehuman_hm08)"
    }
    (HERE / "manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    for name, record in outputs.items():
        print(name, record["vertices"], "vertices",record["triangles"],"triangles",record["bounds_min_m"],record["bounds_max_m"])
    print("HEAD MARKERS",manifest["head_markers_m"])


if __name__ == "__main__":
    main()
