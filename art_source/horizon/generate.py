#!/usr/bin/env python3
"""Original distant Glasgow-inspired scenery; no photos/downloads/API inputs.

Run from any directory. Pillow/numpy are development-only; neither ships.
The equirectangular landscape is deliberately atmospheric and non-surveyed.
"""
from pathlib import Path
import hashlib
import json
import math
import random

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "game/art/assets/horizon"
W, H = 4096, 2048
CUBE_SIZE = 512


def mix(a, b, t):
    return tuple(round(x * (1 - t) + y * t) for x, y in zip(a, b))


def panorama():
    rng = np.random.default_rng(20261018)
    x = np.arange(W, dtype=np.float32)[None, :] / (W - 1)
    y = np.arange(H, dtype=np.float32)[:, None] / (H - 1)
    # Smooth sky and fully painted ground hemisphere. Slight grain prevents
    # colour quantisation from producing conspicuous broad compression bands.
    top, horizon, ground = (128, 151, 170), (197, 207, 204), (103, 118, 112)
    base = np.zeros((H, W, 3), dtype=np.float32)
    for c in range(3):
        sky = top[c] + (horizon[c] - top[c]) * np.minimum(y / .51, 1) ** .7
        earth = horizon[c] + (ground[c] - horizon[c]) * np.clip((y - .51) / .49, 0, 1) ** .32
        base[:, :, c] = np.where(y < .51, sky, earth)
    clouds = (np.sin(2 * np.pi * (x * 3 + .1)) * np.sin(y * 31 + x * 2 * np.pi)
              + .55 * np.sin(2 * np.pi * x * 7 + y * 43))
    clouds = np.maximum(clouds - .15, 0) * np.exp(-((y - .31) / .13) ** 2) * 5
    base += clouds[:, :, None]
    base += rng.uniform(-.75, .75, (H, W, 1))
    im = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(im)
    u = np.linspace(0, 2 * np.pi, W)
    # Broad west/north hill masses and a lower eastern skyline. The repeat is
    # periodic in azimuth; no giant triangular peaks or uniform skyscraper ring.
    hills = (.5 + .5 * np.cos(u - .9)) ** 2
    for layer, colour in enumerate([(158, 176, 179), (139, 160, 163), (120, 143, 143)]):
        relief = 22 + hills * (62 + layer * 10)
        relief += 16 * np.sin(u * 3 + layer * .7) + 7 * np.sin(u * 7 + .4)
        relief += 3 * np.sin(u * 19 + layer)
        line = H * (.492 + layer * .012) - relief
        points = list(zip(range(W), line.astype(int))) + [(W - 1, H - 1), (0, H - 1)]
        d.polygon(points, fill=colour)
    # A low woodland fringe is incorporated in the far painting, not thousands
    # of scene trees. Draw wrap copies for every skyline element crossing X0.
    r = random.Random(10618)
    for px in range(-8, W + 8, 5):
        theta = (px % W) / (W - 1) * 2 * math.pi
        woods = (.5 + .5 * math.cos(theta - .9)) ** 2
        if woods < .25:
            continue
        py = int(H * .515 - 20 * math.sin(theta * 3) - woods * 36)
        radius = r.randint(3, 7)
        for shift in (-W, 0, W):
            d.ellipse((px + shift - radius, py - radius * 1.5, px + shift + radius, py + radius), fill=(111, 137, 132))
    # Distant original roof/chimney rhythm: muted, no readable fake storefronts.
    # Three discontinuous clusters leave wide hills/woodland sectors visible.
    r = random.Random(230410)
    for centre, span, density in [(.28, .22, 1), (.57, .19, .9), (.84, .18, 1.1)]:
        cursor = int((centre - span / 2) * W)
        end = int((centre + span / 2) * W)
        while cursor < end:
            width = r.randint(20, 55)
            edge = max(0, 1 - abs(cursor / W - centre) / (span / 2)) ** .4
            height = int(r.randint(22, 60) * edge * density)
            base_y = int(H * .545 + 5 * math.sin(cursor * 2 * math.pi / W * 3))
            roof_y = base_y - height
            colour = mix((139, 146, 142), (113, 130, 133), r.random())
            roof = mix(colour, (86, 111, 120), .35)
            for shift in (-W, 0, W):
                a = cursor + shift
                d.rectangle((a, roof_y, a + width, H - 1), fill=colour)
                d.polygon([(a - 2, roof_y), (a + width // 3, roof_y - 8),
                           (a + width - 2, roof_y - 8), (a + width + 2, roof_y)], fill=roof)
                for chimney in range(2, width - 3, 17):
                    d.rectangle((a + chimney, roof_y - 13, a + chimney + 3, roof_y - 5), fill=roof)
                # Broad faint facade planes, not high-contrast sparkling dots.
                for wx in range(5, width - 2, 8):
                    for wy in range(roof_y + 8, base_y, 11):
                        d.rectangle((a + wx, wy, a + wx + 2, wy + 4), fill=mix(colour, (88, 113, 122), .27))
            cursor += width - 1
    # Sparse modern blocks, civic/spire and river-industry accents provide
    # bearings. These are original composites, not claimed exact landmarks.
    for at, width, height in [(.235, 24, 110), (.25, 20, 87), (.586, 21, 102), (.817, 28, 119), (.831, 18, 91)]:
        px, py = int(at * W), int(H * .545)
        colour = (121, 139, 143)
        d.rectangle((px, py - height, px + width, H - 1), fill=colour)
        d.polygon([(px, py-height), (px+width//2, py-height-4), (px+width, py-height)], fill=(112,132,139))
        for floor in range(py - height + 7, py, 8):
            d.line((px + 2, floor, px + width - 2, floor), fill=(130,146,148), width=1)
    px, py = int(.64 * W), int(H * .54)
    d.rectangle((px-7, py-72, px+7, H-1), fill=(117,136,140))
    d.polygon([(px-9,py-72),(px,py-115),(px+9,py-72)], fill=(110,132,139))
    # Ground haze gradually removes painted facade detail below the horizon;
    # no visible horizontal cutoff or empty grey lower hemisphere.
    arr = np.asarray(im).astype(np.float32)
    fade = np.clip((y - .56) / .16, 0, 1)[:, :, None]
    lower = np.zeros_like(arr)
    for c in range(3):
        lower[:, :, c] = 123 + (ground[c] - 123) * np.clip((y - .56) / .44, 0, 1)
    arr = arr * (1 - fade) + lower * fade
    # DXT1 dithers even identical blocks across their four columns. A constant
    # RGB565-representable colour per4x4 end block removes that decoded seam.
    # Only8/4096 columns change; keep fully uniform, continuous poles too.
    def rgb565(colour):
        codes = np.rint(colour / 255 * np.array([31, 63, 31])).astype(int)
        return np.array([(codes[0] << 3) | (codes[0] >> 2),
                         (codes[1] << 2) | (codes[1] >> 4),
                         (codes[2] << 3) | (codes[2] >> 2)])
    arr[:4] = rgb565(arr[:4].mean(axis=(0, 1)))
    arr[-4:] = rgb565(arr[-4:].mean(axis=(0, 1)))
    for row in range(0, H, 4):
        edge = rgb565(arr[row:row+4, :4].mean(axis=(0, 1)))
        arr[row:row+4, :4] = edge
        arr[row:row+4, -4:] = edge
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")


def cubemap(reference):
    """Bake native +X,-X,+Y,-Y,+Z,-Z faces, row-major in a3x2 atlas.

    Pixel-centre sampling and bilinear azimuth wrap match Godot's sky direction
    convention. This is an offline resample, never a runtime image conversion.
    """
    source = np.asarray(reference, dtype=np.float32)
    coord = (np.arange(CUBE_SIZE, dtype=np.float32) + .5) / CUBE_SIZE * 2 - 1
    u, v = np.meshgrid(coord, coord)
    one = np.ones_like(u)
    directions = [(one, -v, -u), (-one, -v, u), (u, one, v),
                  (u, -one, -v), (u, -v, one), (-u, -v, -one)]
    atlas = Image.new("RGB", (CUBE_SIZE * 3, CUBE_SIZE * 2))
    for face, (x, y, z) in enumerate(directions):
        length = np.sqrt(x*x + y*y + z*z)
        azimuth = np.mod(np.arctan2(x, -z) / (2*np.pi), 1)
        elevation = np.arccos(np.clip(y/length, -1, 1)) / np.pi
        sx, sy = azimuth * W - .5, np.clip(elevation * H - .5, 0, H-1)
        ix, iy = np.floor(sx).astype(int), np.floor(sy).astype(int)
        fx, fy = (sx-ix)[..., None], (sy-iy)[..., None]
        a, b = source[iy, ix % W], source[iy, (ix+1) % W]
        c, d = source[np.minimum(iy+1,H-1), ix % W], source[np.minimum(iy+1,H-1), (ix+1) % W]
        pixels = (a*(1-fx)+b*fx)*(1-fy)+(c*(1-fx)+d*fx)*fy
        atlas.paste(Image.fromarray(np.rint(pixels).astype(np.uint8), "RGB"),
                    ((face % 3)*CUBE_SIZE, (face // 3)*CUBE_SIZE))
    return atlas


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    reference = panorama()
    reference.save(OUTPUT / "glasgow_horizon.png", optimize=True)
    cubemap(reference).save(OUTPUT / "glasgow_horizon_cube.png", optimize=True)
    files = {p.name: {"sha256": hashlib.sha256(p.read_bytes()).hexdigest(), "source_bytes": p.stat().st_size,
                      "size": list(Image.open(p).size), "mode": Image.open(p).mode}
             for p in sorted(OUTPUT.glob("*.png"))}
    record = {"original_content": True, "external_inputs": [], "seeded": True,
              "source": "art_source/horizon/generate.py", "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "description": "Original atmospheric composite hills/woodland/tenement/warehouse skyline; not surveyed 360-degree Glasgow.",
              "runtime_texture": "glasgow_horizon_cube.png",
              "reference_only": "glasgow_horizon.png",
              "cube_layout": "3x2 row-major +X,-X,+Y,-Y,+Z,-Z;512px faces",
              "import_budget_bytes": 6 * 1024 * 1024, "files": files}
    (OUTPUT / "manifest.json").write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps(record, indent=2))


if __name__ == "__main__":
    main()
