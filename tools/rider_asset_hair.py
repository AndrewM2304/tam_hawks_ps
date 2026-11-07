#!/usr/bin/env python3
"""Original short swept fiber geometry rooted in the retained CC0 scalp crop.

Writes one opaque native mesh, not thousands of nodes or transparent draw calls.
No external program or third-party hair image is used. All units are metres.
"""
from pathlib import Path
import hashlib
import json
import math
import random

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "game/art/assets/makehuman_hm08/hair.obj"
DEST = ROOT / "game/art/rider/short_crop.obj"
CLUMPS = 1050


def unit(v):
    return v / max(float(np.linalg.norm(v)), 1e-12)


def main():
    points, uv, normals, faces = [], [], [], []
    for line in SOURCE.read_text().splitlines():
        p = line.split()
        if not p:
            continue
        if p[0] == "v":
            points.append(list(map(float, p[1:4])))
        elif p[0] == "vt":
            uv.append(list(map(float, p[1:3])))
        elif p[0] == "vn":
            normals.append(list(map(float, p[1:4])))
        elif p[0] == "f":
            face = [tuple(int(i) - 1 for i in t.split("/")) for t in p[1:]]
            faces += [(face[0], face[i], face[i + 1]) for i in range(1, len(face) - 1)]
    points, uv, normals = np.array(points), np.array(uv), np.array(normals)
    crown = np.clip((points[:, 1] - .045) / .09, 0, 1)
    crown = crown * crown * (3 - 2 * crown)
    volume = crown * (.006 + .0015 * np.sin(points[:, 0] * 100 + points[:, 2] * 36))
    points += normals * volume[:, None]
    out_points, out_uv, out_normals, out_faces = [], [], [], []

    def triangle(vertices, coords, ns):
        start = len(out_points) + 1
        out_points.extend(vertices)
        out_uv.extend(coords)
        out_normals.extend(ns)
        out_faces.append((start, start + 1, start + 2))

    areas = []
    for face in faces:
        vi, ti, ni = np.array(face).T
        p = points[vi]
        areas.append(float(np.linalg.norm(np.cross(p[1] - p[0], p[2] - p[0]))) * .5)
        triangle(p, uv[ti], normals[ni])
    rng = random.Random(80261106)
    choices = rng.choices(range(len(faces)), weights=areas, k=CLUMPS)
    for choice in choices:
        vi, ti, ni = np.array(faces[choice]).T
        a, b = rng.random(), rng.random()
        if a + b > 1:
            a, b = 1 - a, 1 - b
        weights = np.array([1 - a - b, a, b])
        origin = weights @ points[vi]
        n = unit(weights @ normals[ni])
        texture = weights @ uv[ti]
        comb = np.array([.30, -.10, -.95])
        tangent = unit(comb - n * float(comb @ n))
        across = unit(np.cross(n, tangent))
        crown_factor = min(1, max(0, (origin[1] - .04) / .1))
        length = (.0035 + .009 * crown_factor) * rng.uniform(.72, 1.25)
        width = rng.uniform(.00028, .00055)
        path = []
        for step in range(4):
            t = step / 3
            center = origin + tangent * length * t + n * (.0018 * math.sin(math.pi * t) + .00015)
            half = across * max(.000025, width * (1 - t) ** .7)
            path.append((center - half, center + half))
        for step in range(3):
            a, b = path[step]
            c, d = path[step + 1]
            coords = [texture, texture + [.001, 0], texture + [0, .002]]
            triangle([a, c, b], coords, [n, n, n])
            triangle([b, c, d], coords, [n, n, n])
    lines = ["# Original short swept fiber derivative of retained CC0 MakeHuman scalp.",
             "# See short_crop.json and SKIN-NOTICE.md; one opaque mesh, metres/Y-up.", "o ShortSweptCrop"]
    lines += ["v " + " ".join(f"{v:.8f}" for v in p) for p in out_points]
    lines += ["vt " + " ".join(f"{v:.8f}" for v in p) for p in out_uv]
    lines += ["vn " + " ".join(f"{v:.8f}" for v in p) for p in out_normals]
    lines += ["f " + " ".join(f"{i}/{i}/{i}" for i in f) for f in out_faces]
    pending = DEST.with_name("." + DEST.name + ".tmp")
    pending.write_text("\n".join(lines) + "\n")
    pending.replace(DEST)
    metadata = DEST.with_suffix(".json")
    pending_metadata = metadata.with_name("." + metadata.name + ".tmp")
    pending_metadata.write_text(json.dumps({"source": "game/art/assets/makehuman_hm08/hair.obj",
        "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(), "source_licence": "CC0-1.0; retained MakeHuman notices",
        "adaptation": "Original deterministic volume fit and 1050 tapered opaque three-segment fiber clumps, merged with scalp into one native surface.",
        "generator": "tools/rider_asset_hair.py", "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "mesh_sha256": hashlib.sha256(DEST.read_bytes()).hexdigest(), "triangles": len(out_faces),
        "bound_min_m": np.min(out_points, axis=0).tolist(), "bound_max_m": np.max(out_points, axis=0).tolist(),
        "runtime": "One opaque native mesh surface copied once at startup and shared between actors; no per-frame geometry rebuilding."}, indent=2) + "\n")
    pending_metadata.replace(metadata)
    print(f"Short crop: {len(out_faces)}triangles /1surface")


if __name__ == "__main__":
    main()
