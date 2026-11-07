#!/usr/bin/env python3
"""Bake the rider's cropped CC0 skin and original cloth/roughness/normal maps.

Skin diffuse is a masked derivative of the explicitly licensed MakeHuman system
skin, retaining only the visible head/hands. Roughness and fine normals are
painted analytically in anatomical space. Cloth, suede and hair are original
periodic material studies. Requires the already installed numpy and Pillow.
"""
from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game/art/rider"
OUT.mkdir(parents=True, exist_ok=True)
SKIN_SOURCE = ROOT / ".local/downloads/mh_skin/young_lightskinned_male_diffuse.png"
SKIN_SHA256 = "862a26e335e958b70534cb5f0d7c47ef30ab148a56c42b3e9da969cf76f12963"


def save(name, data):
    path = OUT / name
    temporary = OUT / ("." + name + ".tmp")
    Image.fromarray(np.uint8(np.clip(data, 0, 1) * 255 + .5)).save(temporary, format="PNG")
    temporary.replace(path)


def resize_map(name, size):
    image = Image.open(OUT / name)
    temporary = OUT / ("." + name + ".tmp")
    image.resize((size, size), Image.Resampling.LANCZOS).save(temporary, format="PNG")
    temporary.replace(OUT / name)


def normal_map(height, strength):
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * strength
    dy = (np.roll(height, 1, 0) - np.roll(height, -1, 0)) * strength
    n = np.stack((-dx, -dy, np.ones_like(dx)), -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * .5 + .5


def noise(x, y, z=0):
    return np.sin(x * 127.1 + y * 311.7 + z * 74.7) * np.cos(x * 269.5 - y * 183.3 + z * 246.1)


def paint_skin(p, hand=False):
    x, y, z = p[..., 0], p[..., 1], p[..., 2]
    grain = noise(x * 330, y * 330, z * 330)
    mottling = noise(x * 14, y * 14, z * 14) * .018 + noise(x * 42, y * 42, z * 42) * .008
    rgb = np.empty((*x.shape, 3), np.float32)
    rgb[:] = [.77, .565, .465]
    rgb += mottling[..., None] * [1, .56, .37]
    rgb += grain[..., None] * .004
    roughness = np.full(x.shape, .64, np.float32)
    if not hand:
        front = np.clip((-z - .015) / .045, 0, 1)
        # Broad anatomical pigment and unshaven follicle tone. Nothing is baked
        # as a directional light: the game lights retain responsibility for form.
        cheeks = np.exp(-((np.abs(x) - .047) / .024) ** 2 - ((y + .007) / .030) ** 2) * front
        rgb += cheeks[..., None] * [.025, -.026, -.022]
        mouth = np.exp(-(x / .027) ** 6 - ((y + .046) / .007) ** 2) * front
        rgb = rgb * (1 - mouth[..., None] * .77) + np.array([.58, .32, .30]) * mouth[..., None] * .77
        chin = np.exp(-(x / .052) ** 4 - ((y + .080) / .035) ** 2) * front
        sideburns = np.exp(-((np.abs(x) - .064) / .016) ** 4 - ((y + .018) / .057) ** 4) * front
        stubble = np.clip(chin * .24 + sideburns * .35, 0, .45)
        follicles = np.clip((noise(x * 530, y * 530, z * 530) - .40) * 3, 0, 1)
        rgb *= 1 - (stubble * (.12 + follicles * .24))[..., None]
        brow_curve = .059 + .004 * np.sin(np.clip((np.abs(x) - .012) / .05, 0, 1) * np.pi)
        eyebrow = np.exp(-((np.abs(x) - .035) / .024) ** 6 - ((y - brow_curve) / .0043) ** 4) * front
        fibers = .55 + .45 * np.sin((x * 1.4 + y) * 6800 + np.sin(x * 530) * 1.2) ** 2
        brow = eyebrow * fibers * .80
        rgb = rgb * (1 - brow[..., None]) + np.array([.19, .13, .105]) * brow[..., None]
        eye_socket = np.exp(-((np.abs(x) - .030) / .019) ** 4 - ((y - .035) / .013) ** 2) * front
        rgb *= 1 - eye_socket[..., None] * [.065, .095, .082]
        nose = np.exp(-(x / .018) ** 2 - ((y + .006) / .030) ** 2) * front
        roughness -= nose * .18 + mouth * .1
    else:
        # Fingers/knuckles retain the anatomical mesh rather than drawn outlines.
        knuckles = np.exp(-((y + .10) / .025) ** 2)
        rgb += knuckles[..., None] * [.025, -.014, -.015]
    return rgb, roughness, grain


def bake_skin(name, size=2048):
    vertices, uvs, faces = [], [], []
    source = ROOT / "game/art/assets/makehuman_hm08" / f"{name}.obj"
    for line in source.read_text().splitlines():
        values = line.split()
        if not values:
            continue
        if values[0] == "v":
            vertices.append(list(map(float, values[1:4])))
        elif values[0] == "vt":
            uvs.append(list(map(float, values[1:3])))
        elif values[0] == "f":
            face = [tuple(int(i) - 1 for i in v.split("/")[:2]) for v in values[1:]]
            for i in range(1, len(face) - 1):
                faces.append([face[0], face[i], face[i + 1]])
    positions = np.array(vertices)
    texcoords = np.array(uvs)
    if not SKIN_SOURCE.exists() or hashlib.sha256(SKIN_SOURCE.read_bytes()).hexdigest() != SKIN_SHA256:
        raise RuntimeError("Run python3 tools/rider_asset_acquire.py to obtain the verified CC0 source skin.")
    licensed_diffuse = np.asarray(Image.open(SKIN_SOURCE).convert("RGB").resize((size, size), Image.Resampling.LANCZOS), dtype=np.float32) / 255.0
    canvas = np.zeros((size, size, 3), np.float32)
    rough = np.zeros((size, size), np.float32)
    pores = np.zeros((size, size), np.float32)
    mask = np.zeros((size, size), bool)
    for face in faces:
        vi, ti = np.array(face).T
        uv = texcoords[ti] * [size - 1, -(size - 1)] + [0, size - 1]
        x0, y0 = np.floor(uv.min(0)).astype(int).clip(0, size - 1)
        x1, y1 = np.ceil(uv.max(0)).astype(int).clip(0, size - 1)
        yy, xx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        a, b, c = uv
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-8:
            continue
        w0 = ((b[1] - c[1]) * (xx - c[0]) + (c[0] - b[0]) * (yy - c[1])) / den
        w1 = ((c[1] - a[1]) * (xx - c[0]) + (a[0] - c[0]) * (yy - c[1])) / den
        w2 = 1 - w0 - w1
        inside = (w0 >= -.001) & (w1 >= -.001) & (w2 >= -.001)
        p = w0[..., None] * positions[vi[0]] + w1[..., None] * positions[vi[1]] + w2[..., None] * positions[vi[2]]
        rgb, r, h = paint_skin(p, name != "head")
        canvas[y0:y1 + 1, x0:x1 + 1][inside] = licensed_diffuse[y0:y1 + 1, x0:x1 + 1][inside]
        rough[y0:y1 + 1, x0:x1 + 1][inside] = r[inside]
        pores[y0:y1 + 1, x0:x1 + 1][inside] = h[inside]
        mask[y0:y1 + 1, x0:x1 + 1] |= inside
    # Dilate islands to avoid dark mip seams; no exterior background enters skin.
    for _ in range(12):
        for axis in [0, 1]:
            for direction in [-1, 1]:
                neighbor = np.roll(mask, direction, axis)
                add = ~mask & neighbor
                canvas[add] = np.roll(canvas, direction, axis)[add]
                rough[add] = np.roll(rough, direction, axis)[add]
                pores[add] = np.roll(pores, direction, axis)[add]
                mask |= add
    canvas[~mask] = [.77, .565, .465]
    rough[~mask] = .64
    save(f"{name}_albedo.png", canvas)
    save(f"{name}_roughness.png", rough)
    save(f"{name}_normal.png", normal_map(pores, .035))
    resize_map(f"{name}_roughness.png", 512)
    resize_map(f"{name}_normal.png", 1024 if name == "head" else 512)


def bake_textiles(size=512):
    y, x = np.mgrid[:size, :size] / size
    # The diagonal twill advances one thread every two wefts; finer fibers are
    # low amplitude so mipmapped normal play does not glitter or form moire.
    warp = np.cos(x * np.pi * 128)
    weft = np.cos(y * np.pi * 128)
    twill = np.cos((x - y) * np.pi * 64)
    fibers = noise(x * 105, y * 105)
    grain = .50 + warp * .075 + weft * .06 + twill * .08 + fibers * .025
    base = .90 + twill * .025 + fibers * .016
    save("cloth_albedo.png", np.stack([base, base, base], -1))
    save("cloth_normal.png", normal_map(grain, .48))
    save("cloth_roughness.png", .84 + grain * .10)
    suede = .90 + noise(x * 34, y * 34) * .025 + fibers * .014
    save("suede_albedo.png", np.stack([suede, suede, suede], -1))
    save("suede_normal.png", normal_map(fibers, .13))
    # Original cropped-hair study; strand direction is combed rather than a
    # uniform plastic sphere. The normal amount remains small at chase distance.
    strands = np.sin(x * np.pi * 350 + np.sin(y * 7) * 7)
    locks = .76 + strands * .08 + noise(x * 35, y * 35) * .07
    save("hair_albedo.png", np.stack([locks, locks * .94, locks * .84], -1))


if __name__ == "__main__":
    for name in ["head", "left_hand", "right_hand"]:
        bake_skin(name, 2048 if name == "head" else 1024)
    bake_textiles()
    records = {p.name: {"sha256": hashlib.sha256(p.read_bytes()).hexdigest(), "bytes": p.stat().st_size} for p in sorted(OUT.glob("*.png"))}
    (OUT / "manifest.json").write_text(json.dumps({"schema": 1,
        "authorship": "Skin albedos are masked CC0 MakeHuman derivatives; all cloth/hair/suede, roughness and normal maps are original deterministic painting. No AI-generated images.",
        "skin_source": {"url": "https://files2.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip",
            "member": "skins/young_caucasian_male/young_lightskinned_male_diffuse.png", "sha256": SKIN_SHA256,
            "licence": "CC0-1.0", "notice": "game/art/rider/SKIN-NOTICE.md",
            "adaptation": "Retain only UV triangles of the existing cropped head/hand meshes; neutral-fill unused atlas, dilate island edges12pixels, downsample hands to1024. Full source body atlas is not distributed."},
        "geometry_uv_source": "Existing CC0 MakeHuman cropped meshes; see game/art/assets/makehuman_hm08/manifest.json",
        "generator": "tools/rider_asset_bake.py", "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "resolution_policy": "Head albedo2048, head normal1024; hands albedo1024; remaining maps512. Original native skateboard atlas preserved.", "maps": records}, indent=2) + "\n")
    print(f"Baked {len(records)} rider maps")
