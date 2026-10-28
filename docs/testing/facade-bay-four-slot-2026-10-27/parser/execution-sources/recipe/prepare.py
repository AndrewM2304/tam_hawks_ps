"""Stage/configure/finalize one source-bound disposable native comparison.

No engine invocation, runtime mutation or historical-receipt replacement.
The orchestrator owns the exclusive import/render window.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
VARIANT = ROOT.parent
PROOF = VARIANT.parent
STONE = ("sandstone_basecolor.png", "sandstone_normal_opengl.png", "sandstone_orm.png")
ORIGINAL = (*STONE, "opaque_glazing_basecolor.png")
VARIANTS = ("fitted", "reduced", "atlas_compressed", "atlas_lossless")
RECIPES = ("prepare.py", "render.gd", "project.godot", "run.sh", "xorg.conf")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def stage(output, repo, candidate):
    paths = {"recipe/" + name: ROOT / name for name in RECIPES}
    paths.update({name: repo / name for name in
                  ("game/levels/art/facade_bay.gd", "game/levels/glasgow_square.gd")})
    paths.update({"proof/" + str(path.relative_to(PROOF)): path
                  for path in sorted(PROOF.rglob("*")) if path.is_file()
                  and VARIANT not in path.parents
                  and not any(part in (".godot", ".local", "__pycache__") for part in path.parts)})
    paths.update({"reduced/" + name: candidate / name for name in
                  ("glasgow_bay_near.glb", "glasgow_bay_mid.glb", "glasgow_bay_far.glb",
                   "generation.json", "part-triangles.json.gz")})
    paths["reduced/generator.py"] = VARIANT / "generator.py"
    for name in ("audit.py", "audit.json", "reproducibility.json"):
        paths["reduced/" + name] = VARIANT / name
    before = {name: sha(path) for name, path in sorted(paths.items())}
    audit = json.loads((VARIANT / "audit.json").read_text())
    assert audit["passed"] and audit["repeat_metadata_and_part_payload_byte_identical"]
    assert audit["auditor_sha256"] == sha(VARIANT / "audit.py")
    assert audit["candidate_manifest_sha256"] == sha(candidate / "generation.json")
    assert audit["part_triangle_payload_sha256"] == sha(candidate / "part-triangles.json.gz")
    for asset in audit["assets"]:
        assert asset["sha256"] == sha(candidate / asset["file"])
    snapshots = output / "execution-sources"
    snapshots.mkdir()
    (snapshots / ".gdignore").write_bytes(b"")
    for name, path in paths.items():
        snapshot = snapshots / name
        snapshot.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, snapshot)
        assert sha(snapshot) == before[name], "Execution input copy differs: " + name
    for name in ("project.godot", "render.gd"):
        shutil.copyfile(ROOT / name, output / name)
    executed = {name: sha(output / name) for name in ("project.godot", "render.gd")}
    assert all(executed[name] == sha(ROOT / name) for name in executed)
    assets = []
    for variant in VARIANTS:
        source = (PROOF / "fitted/generated" if variant == "fitted" else
                  candidate if variant == "reduced" else PROOF / "two_surface/generated")
        (output / variant).mkdir()
        for lod in ("near", "mid", "far"):
            name = "glasgow_bay_" + lod + ".glb"
            target = output / variant / name
            shutil.copyfile(source / name, target)
            triangles = (18392 if variant == "fitted" else 9864) if lod == "near" else (3544 if lod == "mid" else 648)
            surfaces = 2 if variant.startswith("atlas_") else 4
            assets.append({"path": variant + "/" + name, "variant": variant,
                           "lod": lod, "sha256": sha(target), "triangles": triangles, "surfaces": surfaces})
    (output / "textures").mkdir()
    textures = []
    for name in (*ORIGINAL, "accent_basecolor.png", "accent_basecolor_lossless.png", "accent_orm.png"):
        source_name = "accent_basecolor.png" if name == "accent_basecolor_lossless.png" else name
        source = (PROOF / "two_surface/textures" if name.startswith("accent_") else PROOF / "textures") / source_name
        target = output / "textures" / name
        shutil.copyfile(source, target)
        role = "normal_opengl_linear" if "normal" in name else "orm_linear" if "orm" in name else "basecolour_srgb"
        textures.append({"path": "textures/" + name, "role": role, "sha256": sha(target),
                         "mipmaps": name != "accent_orm.png", "size": 128 if name == "accent_orm.png" else 1024,
                         "compress_mode": 0 if name == "accent_basecolor_lossless.png" else 2})
    assert (output / "textures/accent_basecolor.png").read_bytes() == (output / "textures/accent_basecolor_lossless.png").read_bytes()
    manifest = {"schema": 1, "sources_sha256": before,
                "source_paths": {name: str(path.resolve()) for name, path in paths.items()},
                "staged_executed_recipes_sha256": executed, "assets": assets, "textures": textures,
                "variant_texture_maps": {"fitted": list(ORIGINAL), "reduced": list(ORIGINAL),
                    "atlas_compressed": [*STONE, "accent_basecolor.png", "accent_orm.png"],
                    "atlas_lossless": [*STONE, "accent_basecolor_lossless.png", "accent_orm.png"]},
                "expected_imported_texture_bytes": {"fitted": 3495320, "reduced": 3495320,
                    "atlas_compressed": 3503512, "atlas_lossless": 6998751},
                "import_policy": {"original_maps": "vram_compressed", "accent_compressed": "vram_compressed",
                    "accent_lossless": "same original PNG with lossless colour import only",
                    "accent_orm": "vram_compressed_without_mips", "all_colour_mips": True},
                "limits": "Source-bound isolated static comparison. Actual imported bytes are not resident GPU memory; no timing, Mac or full-city result."}
    write_json(output / "input-manifest.json", manifest)
    assert before == {name: sha(path) for name, path in paths.items()}, "Source changed during staging"


def set_parameter(path, key, value):
    text = path.read_text()
    pattern = r"(?m)^" + re.escape(key) + r"=.*$"
    if re.search(pattern, text):
        text = re.sub(pattern, key + "=" + value, text)
    else:
        assert "[params]" in text
        text += "\n" + key + "=" + value + "\n"
    path.write_text(text)


def configure(output):
    manifest = json.loads((output / "input-manifest.json").read_text())
    for asset in manifest["assets"]:
        for key, value in {"meshes/generate_lods": "false", "meshes/ensure_tangents": "true", "animation/import": "false"}.items():
            set_parameter(output / (asset["path"] + ".import"), key, value)
    for texture in manifest["textures"]:
        parameters = {"compress/mode": str(texture["compress_mode"]), "compress/high_quality": "false",
                      "compress/normal_map": "1" if texture["role"] == "normal_opengl_linear" else "2",
                      "mipmaps/generate": "true" if texture["mipmaps"] else "false", "mipmaps/limit": "-1",
                      "process/normal_map_invert_y": "false", "process/hdr_as_srgb": "false",
                      "process/size_limit": str(texture["size"]), "detect_3d/compress_to": "0"}
        for key, value in parameters.items():
            set_parameter(output / (texture["path"] + ".import"), key, value)
    write_json(output / "configured-import-hashes.json",
               {str(path.relative_to(output)): sha(path) for path in sorted(output.rglob("*.import"))})


def finalize(output):
    import numpy as np
    from PIL import Image
    manifest = json.loads((output / "input-manifest.json").read_text())
    after = {name: sha(Path(path)) for name, path in manifest["source_paths"].items()}
    assert after == manifest["sources_sha256"], "Source changed during comparison"
    write_json(output / "source-after.json", after)
    for name, expected in manifest["staged_executed_recipes_sha256"].items():
        assert sha(output / name) == expected == sha(ROOT / name), "Executed copy differs: " + name
    for name, expected in manifest["sources_sha256"].items():
        assert sha(output / "execution-sources" / name) == expected, "Retained execution source differs: " + name
    for item in manifest["assets"] + manifest["textures"]:
        assert sha(output / item["path"]) == item["sha256"], item["path"]
    for name in ("import-initial.log", "import-configured.log", "engine.log"):
        text = (output / name).read_text()
        assert not any(marker in text for marker in ("ERROR:", "SCRIPT ERROR:", "Parse Error:")), name
    report = json.loads((output / "report.json").read_text())
    assert not report["errors"] and len(report["images"]) == 32
    assert len(report["native_lod_samples"]) == 44 and len(report["meshes"]) == 12 and len(report["textures"]) == 7
    assert report["variant_imported_texture_data_bytes"] == manifest["expected_imported_texture_bytes"]
    assert report["environment"]["shadow_max_distance"] == 75.0
    images, decoded = [], {}
    for item in report["images"]:
        assert item["actual_holder_primitive_delta"] == item["expected_triangles"]
        path = output / item["image"]
        with Image.open(path) as image:
            image.load()
            assert image.size == (1920, 1080) and image.format == "PNG"
            rgb = np.asarray(image.convert("RGB"))
        assert float(rgb.std()) > 4 and len(np.unique(rgb[::8, ::8].reshape((-1, 3)), axis=0)) > 64
        decoded[path.name] = rgb
        images.append({"file": path.name, "sha256": sha(path),
                       "decoded_rgb_sha256": hashlib.sha256(rgb.tobytes()).hexdigest(), "dimensions": [1920, 1080]})
    mips = []
    for item in report["decoded_imported_mip_images"]:
        path = output / item["image"]
        with Image.open(path) as image:
            image.load()
            assert list(image.size) == item["size"] and image.format == "PNG"
            pixels = np.asarray(image.convert("RGB"))
        mips.append({**item, "sha256": sha(path), "decoded_rgb_sha256": hashlib.sha256(pixels.tobytes()).hexdigest()})
    assert len(mips) == 34
    comparisons = []
    for view in sorted({item["view"] for item in report["images"]}):
        baseline = decoded["fitted-" + view + ".png"]
        for variant in VARIANTS[1:]:
            delta = np.abs(decoded[variant + "-" + view + ".png"].astype(np.int16) - baseline.astype(np.int16))
            comparisons.append({"view": view, "variant": variant,
                                "mean_absolute_srgb_byte_difference": float(delta.mean()),
                                "changed_pixel_fraction": float(np.mean(np.any(delta > 0, axis=2))),
                                "scope": "Diagnostic difference; no automatic visual acceptance threshold"})
    receipt = {"schema": 1, "status": "Actual imports, native LODs and decoded captures passed; scoped visual review follows separately",
               "unchanged_sources": len(after), "source_before_sha256": manifest["sources_sha256"], "source_after_sha256": after,
               "executed_recipe_sha256": manifest["staged_executed_recipes_sha256"], "images": images,
               "decoded_imported_mips": mips, "matched_differences": comparisons,
               "report_sha256": sha(output / "report.json"),
               "variant_imported_texture_data_bytes": report["variant_imported_texture_data_bytes"],
               "performance_measurement": False, "mac_result": False, "runtime_files_written": False,
               "fixture_shadow_range_m": 75, "current_balanced_shadow_range_m": 45,
               "limits": "Four variants loaded together; map image-data sizes are not resident GPU memory. No current Balanced timing, full-city/final art, physical controls or owner acceptance result."}
    write_json(output / "receipt.json", receipt)
    print("REDUCED_FOUR_SLOT_PREVIEW_RECEIPT", len(images), "PNGs;", len(mips), "mip PNGs;", len(after), "stable inputs")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("stage", "configure", "finalize"))
    parser.add_argument("output", type=Path)
    parser.add_argument("--repo", type=Path, default=PROOF.parents[1])
    parser.add_argument("--candidate-output", type=Path, default=VARIANT / "generated")
    args = parser.parse_args()
    output = args.output.resolve()
    assert output.is_relative_to(ROOT / "runs") and output.is_dir(), "Use a fresh disposable preview/runs subdirectory"
    if args.action == "stage":
        stage(output, args.repo.resolve(), args.candidate_output.resolve())
    else:
        {"configure": configure, "finalize": finalize}[args.action](output)


if __name__ == "__main__":
    main()
