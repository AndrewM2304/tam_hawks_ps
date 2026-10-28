"""Offline atlas construction; importing this module performs no image work.

All UV arguments here use Blender's bottom-origin convention. PNG arrays use
top-origin rows. The audit independently samples exported, top-origin glTF UVs.
"""
from pathlib import Path
import hashlib
import json
import shutil

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
PROOF = ROOT.parent
DOMAIN = (-1.75, -0.25, 1.75, 8.0)
STONE_MAPS = ("sandstone_basecolor.png", "sandstone_normal_opengl.png", "sandstone_orm.png")
# Half-open pixel rectangles on a reference 512-pixel grid, with 16-pixel
# gutters. Multiples of four keep regions aligned on the 128-pixel ORM map.
RECTS = {1: (16, 432, 224, 496), 2: (16, 16, 496, 400), 3: (272, 432, 496, 496)}
CLASS_NAMES = {1: "paint", 2: "opaque_glazing", 3: "metal"}
LINEAR_COLOURS = {1: (0.028, 0.085, 0.067), 3: (0.105, 0.095, 0.069)}
ORM = {1: (1.0, 0.48, 0.0), 2: (1.0, 0.32, 0.0), 3: (1.0, 0.46, 0.65)}


def srgb_to_linear(value):
    value = np.asarray(value, dtype=np.float64)
    return np.where(value <= 0.04045, value / 12.92, ((value + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(value):
    value = np.clip(value, 0, 1)
    return np.where(value <= 0.0031308, value * 12.92, 1.055 * value ** (1 / 2.4) - 0.055)


def core_rect(material, size):
    assert size in (128, 512, 1024)
    return tuple(int(coordinate * size / 512) for coordinate in RECTS[material])


def uv_rect(material, colour_size):
    x0, y0, x1, y1 = core_rect(material, colour_size)
    # Map into texel centres; leave the entire surrounding gutter available
    # to filtering. ORM shares these normalized coordinates, not a second UV.
    return ((x0 + 0.5) / colour_size, (y0 + 0.5) / colour_size,
            (x1 - 0.5) / colour_size, (y1 - 0.5) / colour_size)


def remap_uv(source_uv, material, colour_size):
    u, v = source_uv
    a, b, c, d = DOMAIN
    assert a - 1e-5 <= u <= c + 1e-5 and b - 1e-5 <= v <= d + 1e-5, (material, source_uv)
    x0, y0, x1, y1 = uv_rect(material, colour_size)
    return (x0 + (u - a) / (c - a) * (x1 - x0), y0 + (v - b) / (d - b) * (y1 - y0))


def repeat_lookup(linear_image, u, v):
    """Bilinear source REPEAT, with interpolation in linear colour space."""
    height, width = linear_image.shape[:2]
    x, y = np.asarray(u) * width - 0.5, (1 - np.asarray(v)) * height - 0.5
    left, top = np.floor(x).astype(np.int64), np.floor(y).astype(np.int64)
    fx, fy = (x - left)[..., None], (y - top)[..., None]
    upper = linear_image[top % height, left % width] * (1 - fx) + linear_image[top % height, (left + 1) % width] * fx
    lower = linear_image[(top + 1) % height, left % width] * (1 - fx) + linear_image[(top + 1) % height, (left + 1) % width] * fx
    return upper * (1 - fy) + lower * fy


def save_rgb(path, linear_pixels, colour):
    encoded = linear_to_srgb(linear_pixels) if colour else np.clip(linear_pixels, 0, 1)
    pixels = np.rint(encoded * 255).astype(np.uint8)
    Image.fromarray(pixels, mode="RGB").save(path, compress_level=9)


def make_atlases(colour_size=1024):
    assert colour_size in (512, 1024)
    output = ROOT / "textures"
    output.mkdir(parents=True, exist_ok=True)
    source = srgb_to_linear(np.asarray(Image.open(PROOF / "textures/opaque_glazing_basecolor.png").convert("RGB")) / 255.0)
    records = {}
    for kind, size in (("colour", colour_size), ("orm", 128)):
        image = np.empty((size, size, 3), dtype=np.float64)
        image[:] = LINEAR_COLOURS[1] if kind == "colour" else ORM[1]
        gutter = size // 32
        for material in (1, 2, 3):
            x0, y0, x1, y1 = core_rect(material, size)
            # Work in bottom-origin grid coordinates, then invert PNG rows.
            xx, yy = np.meshgrid(np.arange(x0 - gutter, x1 + gutter), np.arange(y0 - gutter, y1 + gutter))
            cx, cy = np.clip(xx, x0, x1 - 1), np.clip(yy, y0, y1 - 1)
            if kind == "colour" and material == 2:
                a, b, c, d = DOMAIN
                u = a + (cx - x0) / (x1 - x0 - 1) * (c - a)
                v = b + (cy - y0) / (y1 - y0 - 1) * (d - b)
                values = repeat_lookup(source, u, v)
            else:
                values = LINEAR_COLOURS[material] if kind == "colour" else ORM[material]
            image[size - 1 - yy, xx] = values
        name = "accent_basecolor.png" if kind == "colour" else "accent_orm.png"
        save_rgb(output / name, image, kind == "colour")
        records[name] = {"dimensions_px": [size, size], "role": "sRGB base colour" if kind == "colour" else "linear R=AO, G=roughness, B=metallic",
                         "core_rects_bottom_origin_px": {CLASS_NAMES[k]: core_rect(k, size) for k in RECTS}, "edge_extrusion_px": gutter}
    for name in STONE_MAPS:
        shutil.copyfile(PROOF / "textures" / name, output / name)
        records[name] = {"dimensions_px": [1024, 1024], "unchanged_original": True}
    for name, record in records.items():
        raw = (output / name).read_bytes()
        record.update(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    result = {"schema": 1, "colour_size": colour_size, "orm_size": 128, "source_domain_blender_uv": DOMAIN,
              "atlas_uv_rects_blender": {CLASS_NAMES[k]: uv_rect(k, colour_size) for k in RECTS},
              "source_glazing_sha256": hashlib.sha256((PROOF / "textures/opaque_glazing_basecolor.png").read_bytes()).hexdigest(),
              "method": "Bake original bilinear REPEAT over a bounded UV field; continuous affine mesh UVs; no per-vertex fract",
              "maps": records, "mip_limit": "Gutters reduce neighbouring-region bleed; deep mips still require measured error and rendered review"}
    (ROOT / "atlas.json").write_text(json.dumps(result, indent=2) + "\n")
    return result
