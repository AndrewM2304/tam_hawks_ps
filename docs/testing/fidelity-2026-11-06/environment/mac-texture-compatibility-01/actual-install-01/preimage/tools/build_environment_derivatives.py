#!/usr/bin/env python3
"""Build bounded CC0 material derivatives; --verify-only never writes.

Requires Pillow and NumPy only for asset authoring, never at game runtime.
The unchanged provider JPEGs and their independent provenance stay retained.
"""
from __future__ import annotations
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import sys

# Verification must not create local authoring-module bytecode caches either.
sys.dont_write_bytecode = True
import numpy as np
from PIL import Image, ImageFilter, __version__ as PIL_VERSION
from fetch_environment_materials import ROOT, DEST, apply_import_policy, verify

OUTPUT = DEST / "derived"

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def image_array(path: Path, size: int) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB").resize((size, size), Image.Resampling.LANCZOS), dtype=np.float32) / 255.0

def delit(pixels: np.ndarray, strength: float) -> np.ndarray:
    # A bounded broad-illumination correction preserves the photographic joints
    # and blade detail while reducing the light patch repeated at every tile.
    source = Image.fromarray(np.uint8(np.clip(pixels * 255.0 + 0.5, 0, 255)))
    broad = np.asarray(source.filter(ImageFilter.GaussianBlur(pixels.shape[0] / 10)), dtype=np.float32) / 255.0
    luminance = np.maximum(np.sum(broad * np.array([0.2126, 0.7152, 0.0722]), axis=2, keepdims=True), 0.04)
    gain = np.clip(float(luminance.mean()) / luminance, 0.65, 1.5)
    return np.clip(pixels * (1.0 + strength * (gain - 1.0)), 0, 1)

def mirror_tile(pixels: np.ndarray, normal: bool = False) -> np.ndarray:
    # Four reflected quadrants share identical border pixels. For tangent-space
    # normals, the reflected tangent component changes sign with each axis.
    horizontal = pixels[:, ::-1].copy()
    if normal: horizontal[:, :, 0] = 1.0 - horizontal[:, :, 0]
    top = np.concatenate([pixels, horizontal], axis=1)
    bottom = top[::-1, :].copy()
    if normal: bottom[:, :, 1] = 1.0 - bottom[:, :, 1]
    return np.concatenate([top, bottom], axis=0)

def png(pixels: np.ndarray) -> bytes:
    output = io.BytesIO()
    Image.fromarray(np.uint8(np.clip(pixels * 255.0 + 0.5, 0, 255))).save(output, format="PNG", optimize=False)
    return output.getvalue()

def build(manifest: dict) -> tuple[dict[str, bytes], dict]:
    sources = manifest["materials"]
    result: dict[str, bytes] = {}
    grass = sources["T_grass01"]
    for channel, resource in grass["files"].items():
        pixels = image_array(ROOT / resource.removeprefix("res://"), 512)
        if channel == "albedo":
            pixels = delit(pixels, 0.7)
            grey = np.sum(pixels * np.array([0.2126, 0.7152, 0.0722]), axis=2, keepdims=True)
            pixels = pixels * 0.38 + grey * 0.62
            pixels *= np.array([86.0, 99.0, 65.0]) / 255.0 / pixels.mean(axis=(0, 1))
        elif channel == "ambient_occlusion":
            # The provider's broad baked illumination must not darken patches
            # a second time. Retain fine contact detail at restrained contrast.
            pixels = delit(pixels, 0.7)
            pixels = np.clip(0.75 + (pixels - pixels.mean()) * 0.4, 0, 1)
        result["grass_" + channel + ".png"] = png(mirror_tile(pixels, channel == "normal_opengl"))
    paving_resource = sources["pavement_01"]["files"]["albedo"]
    result["pavement_albedo.png"] = png(delit(image_array(ROOT / paving_resource.removeprefix("res://"), 2048), 0.75))
    receipt = {"schema": 1, "generator": "tools/build_environment_derivatives.py",
        "algorithm": "bounded broad-luminance correction; muted grass colour; reflected 2x2 grass with tangent-normal sign correction",
        "authoring_versions": {"Pillow": PIL_VERSION, "NumPy": np.__version__},
        "licence": "CC0-1.0; derivatives of the exact retained maps in ../manifest.json",
        "source_manifest_sha256": sha((DEST / "manifest.json").read_bytes()),
        "source_sha256": {key: sources[key]["file_sha256"] for key in ["T_grass01", "pavement_01"]},
        "physical_width_m": {"grass": 3.0, "pavement": 1.5},
        "physical_scale_note": "Grass contains two original authored1.5m tiles per axis; paving retains the provider1.5m width.",
        "gpu_policy": "These replace existing map bindings: same4maps resident, no extra sampling or draw family; mipmapped VRAM compression, grass1K/paving2K.",
        "files": {name: {"sha256": sha(data), "bytes": len(data), "dimensions_px": list(Image.open(io.BytesIO(data)).size)} for name, data in result.items()}}
    return result, receipt

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    manifest = json.loads((DEST / "manifest.json").read_text())
    verify(manifest)
    images, receipt = build(manifest)
    if args.verify_only:
        saved = json.loads((OUTPUT / "manifest.json").read_text())
        if saved != receipt: raise ValueError("Derivative recipe/source/output receipt changed")
        for name, data in images.items():
            if (OUTPUT / name).read_bytes() != data: raise ValueError(name + ": derivative is not reproducible")
            settings = (OUTPUT / (name + ".import")).read_text()
            expected = {"compress/mode": "2", "compress/normal_map": "1" if "normal_opengl" in name else "2",
                "mipmaps/generate": "true", "process/normal_map_invert_y": "false",
                "process/size_limit": "1024" if name.startswith("grass_") else "2048"}
            for key, value in expected.items():
                if not re.search(rf"^{re.escape(key)}={re.escape(value)}$", settings, flags=re.MULTILINE):
                    raise ValueError(name + ": import contract differs: " + key)
        print("DERIVATIVES_VERIFY: 4 maps / complete repeat identity / import contracts passed; no network or writes")
        return
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, data in images.items():
        target = OUTPUT / name
        temporary = target.with_suffix(".png.tmp")
        temporary.write_bytes(data)
        os.replace(temporary, target)
        channel = "normal_opengl" if "normal_opengl" in name else "albedo"
        apply_import_policy(target, "T_grass01" if name.startswith("grass_") else "pavement_01", channel)
    (OUTPUT / "manifest.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("DERIVATIVES_BUILD: 4 replacement maps generated atomically")

if __name__ == "__main__": main()
