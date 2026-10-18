"""Stage/configure/audit one disposable Godot project; no engine invocation.

Run through run.sh only after the explicit render-window release. All writes
are beneath preview/runs; originals, fitted assets and runtime remain read-only.
"""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import re
import shutil
import sys

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parent
CANDIDATE = ROOT.parent
PROOF = CANDIDATE.parent
REPO = PROOF.parents[1]
FITTED = REPO / "game/art/assets/glasgow_bay"
RECIPES = ("run.sh", "prepare.py", "render.gd", "project.godot", "xorg.conf")
PRODUCTION = ("game/levels/art/facade_bay.gd", "game/levels/glasgow_square.gd")
STONE = ("sandstone_basecolor.png", "sandstone_normal_opengl.png", "sandstone_orm.png")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def inputs():
    paths = [*(ROOT / name for name in RECIPES), *(REPO / name for name in PRODUCTION),
             PROOF / "audit.py", CANDIDATE / "audit.json", CANDIDATE / "reproducibility.json", FITTED / "manifest.json",
             *sorted((CANDIDATE / "generated").glob("*.glb")), *sorted(FITTED.glob("*.glb")),
             *sorted((CANDIDATE / "textures").glob("*.png")), *sorted((FITTED / "textures").glob("*.png"))]
    return {str(path.relative_to(REPO)): sha(path) for path in paths}


def stage(output, accent_colour_lossless=False):
    before = inputs()
    assert len(list((CANDIDATE / "generated").glob("*.glb"))) == 3
    for name in STONE:
        assert (CANDIDATE / "textures" / name).read_bytes() == (FITTED / "textures" / name).read_bytes()
    for name in ("project.godot", "render.gd"):
        shutil.copyfile(ROOT / name, output / name)
    staged_recipes = {name:sha(output/name) for name in ("project.godot", "render.gd")}
    assert all(staged_recipes[name] == sha(ROOT/name) for name in staged_recipes)
    assets = []
    expected = {"candidate": {"near": (9864, 2), "mid": (3544, 2), "far": (648, 2)},
                "fitted": {"near": (18392, 4), "mid": (3544, 4), "far": (648, 4)}}
    for variant, source in (("candidate", CANDIDATE / "generated"), ("fitted", FITTED)):
        (output / variant).mkdir()
        for lod in ("near", "mid", "far"):
            name = "glasgow_bay_" + lod + ".glb"
            shutil.copyfile(source / name, output / variant / name)
            triangles, surfaces = expected[variant][lod]
            assets.append({"path": variant + "/" + name, "variant": variant, "lod": lod, "sha256": sha(source / name), "triangles": triangles, "surfaces": surfaces})
    (output / "textures").mkdir()
    maps = []
    for name in (*STONE, "opaque_glazing_basecolor.png", "accent_basecolor.png", "accent_orm.png"):
        source = CANDIDATE / "textures" / name if name.startswith("accent_") else FITTED / "textures" / name
        shutil.copyfile(source, output / "textures" / name)
        role = "normal_opengl_linear" if "normal" in name else ("orm_linear" if "orm" in name else "basecolour_srgb")
        maps.append({"path": "textures/" + name, "role": role, "sha256": sha(source), "mipmaps": name != "accent_orm.png", "size": 128 if name == "accent_orm.png" else 1024,
            "compress_mode":0 if accent_colour_lossless and name == "accent_basecolor.png" else 2})
    shutil.copyfile(CANDIDATE / "audit.json", output / "source-asset-audit.json")
    write_json(output / "input-manifest.json", {"schema": 1, "sources_sha256": before, "staged_executed_recipes_sha256":staged_recipes, "assets": assets, "textures": maps,
        "import_policy":{"accent_colour":"lossless" if accent_colour_lossless else "vram_compressed", "optional_diagnostic_only":accent_colour_lossless,
            "default_is_vram_compressed":True, "other_maps_unchanged":True},
        "limits": "Isolated source-bound comparison; live integration, owner acceptance and Mac/FPS gates remain open."})
    assert before == inputs(), "Source changed while staging"


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
        path = output / (asset["path"] + ".import")
        for key, value in {"meshes/generate_lods": "false", "meshes/ensure_tangents": "true", "animation/import": "false"}.items():
            set_parameter(path, key, value)
    for texture in manifest["textures"]:
        path = output / (texture["path"] + ".import")
        parameters = {"compress/mode": str(texture["compress_mode"]), "compress/high_quality": "false", "compress/normal_map": "1" if texture["role"] == "normal_opengl_linear" else "2",
            "mipmaps/generate": "true" if texture["mipmaps"] else "false", "mipmaps/limit": "-1",
            "process/normal_map_invert_y": "false", "process/hdr_as_srgb": "false", "process/size_limit": str(texture["size"]), "detect_3d/compress_to": "0"}
        for key, value in parameters.items():
            set_parameter(path, key, value)
    write_json(output / "configured-import-hashes.json", {str(p.relative_to(output)): sha(p) for p in sorted(output.rglob("*.import"))})


def finalize(output):
    # Pillow/numpy load only after the engine has stopped, never while an
    # unrelated exclusive profile or ordinary suite owns the machine.
    import numpy as np
    from PIL import Image
    manifest = json.loads((output / "input-manifest.json").read_text())
    assert manifest["sources_sha256"] == inputs(), "Source changed during comparison"
    for name,expected in manifest["staged_executed_recipes_sha256"].items():
        assert sha(output/name) == expected == sha(ROOT/name), "Executed staged recipe changed: "+name
    for entry in manifest["assets"] + manifest["textures"]:
        assert sha(output / entry["path"]) == entry["sha256"], entry["path"]
    for name in ("import-initial.log", "import-configured.log", "engine.log"):
        log = (output / name).read_text()
        assert not any(marker in log for marker in ("ERROR:", "SCRIPT ERROR:", "Parse Error:")), name + " contains an error"
    report = json.loads((output / "report.json").read_text())
    assert not report["errors"] and len(report["images"]) == 16
    for item in report["images"]:
        assert item["actual_holder_primitive_delta"] == item["expected_triangles"], "Captured native stage differs: "+item["image"]
    image_records, decoded = [], {}
    for item in report["images"]:
        path = output / item["image"]
        with Image.open(path) as image:
            image.load()
            assert image.size == (1920, 1080) and image.format == "PNG"
            rgb = np.asarray(image.convert("RGB"))
        assert float(rgb.std()) > 4 and len(np.unique(rgb[::8, ::8].reshape((-1, 3)), axis=0)) > 64, "Empty/flat render: " + path.name
        decoded[path.name] = rgb
        image_records.append({"file": path.name, "sha256": sha(path), "decoded_rgb_sha256": hashlib.sha256(rgb.tobytes()).hexdigest(), "dimensions": [1920, 1080], "rgb_std": float(rgb.std())})
    mip_records = []
    for item in report["decoded_imported_mip_images"]:
        path = output / item["image"]
        with Image.open(path) as image:
            image.load()
            assert list(image.size) == item["size"] and image.format == "PNG"
            pixels = np.asarray(image.convert("RGB"))
        mip_records.append({**item, "sha256":sha(path), "decoded_rgb_sha256":hashlib.sha256(pixels.tobytes()).hexdigest()})
    mip_analysis = imported_mip_analysis(output, report)
    comparisons = []
    for view in sorted({item["view"] for item in report["images"]}):
        left, right = decoded["fitted-" + view + ".png"], decoded["candidate-" + view + ".png"]
        delta = np.abs(left.astype(np.int16) - right.astype(np.int16))
        comparisons.append({"view": view, "mean_absolute_srgb_byte_difference": float(delta.mean()),
            "pixels_with_any_channel_changed_fraction": float(np.mean(np.any(delta > 0, axis=2))),
            "note": "Diagnostic difference, not an automatic visual acceptance threshold"})
    final = {"schema": 1, "status": "Actual imports/rendered native LOD/image decode checks passed; human quality and live integration remain open",
        "import_policy":manifest["import_policy"],
        "unchanged_sources": len(manifest["sources_sha256"]), "sources_sha256": manifest["sources_sha256"],
        "verified_staged_executed_recipes_sha256":manifest["staged_executed_recipes_sha256"],
        "render_report_sha256": sha(output / "report.json"), "images": image_records, "matched_differences": comparisons,
        "decoded_imported_mips":mip_records, "imported_colour_and_orm_analysis":mip_analysis,
        "performance_measurement": False, "mac_result": False, "runtime_files_written": False,
        "retained_counterexample": "source-asset-audit.json simulated_linear_box_mips: ORM class bleeding begins at level 4; this fixture disables mips only for accent_orm"}
    write_json(output / "receipt.json", final)
    print("PREVIEW_RECEIPT", len(image_records), "decoded PNGs;", final["unchanged_sources"], "unchanged source inputs")


def imported_mip_analysis(output, report):
    """Measure actual imported mip pixels at actual triangle-interior UVs.

This quantifies texture data changes, not hardware mip selection or material
BRDF appearance. The actual foreshortened/distant screenshots remain required.
"""
    import numpy as np
    from PIL import Image
    spec = importlib.util.spec_from_file_location("preserved_glb_reader", PROOF / "audit.py")
    reader = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(reader)

    def decode(path, colour):
        pixels = np.asarray(Image.open(path).convert("RGB"), dtype=np.float64) / 255
        if colour:
            pixels = np.where(pixels <= 0.04045, pixels / 12.92, ((pixels + 0.055) / 1.055) ** 2.4)
        return pixels

    def sample(image, uv, repeat=False):
        coordinates = np.asarray(uv) * [image.shape[1], image.shape[0]] - 0.5
        lower = np.floor(coordinates).astype(np.int64)
        weight = coordinates - lower
        x0, y0 = lower[:,0], lower[:,1]
        x1, y1 = x0 + 1, y0 + 1
        if repeat:
            x0, x1, y0, y1 = x0 % image.shape[1], x1 % image.shape[1], y0 % image.shape[0], y1 % image.shape[0]
        else:
            x0, x1 = np.clip(x0,0,image.shape[1]-1), np.clip(x1,0,image.shape[1]-1)
            y0, y1 = np.clip(y0,0,image.shape[0]-1), np.clip(y1,0,image.shape[0]-1)
        wx, wy = weight[:,0:1], weight[:,1:2]
        return (1-wy)*((1-wx)*image[y0,x0]+wx*image[y0,x1])+wy*((1-wx)*image[y1,x0]+wx*image[y1,x1])

    def errors(expected, actual):
        delta = np.abs(expected-actual)
        return {"samples":len(delta), "mean_absolute_linear_rgb":float(delta.mean()),
            "p95_max_channel_linear":float(np.quantile(delta.max(axis=1),0.95)), "maximum_channel_linear":float(delta.max())}

    regions = {"paint":(16,432,224,496), "glazing":(16,16,496,400), "metal":(272,432,496,496)}
    expected_orm = {"paint":(1,.48,0), "glazing":(1,.32,0), "metal":(1,.46,.65)}
    constants = {"paint":(.028,.085,.067), "metal":(.105,.095,.069)}
    samples = {name:[[],[]] for name in regions}
    for lod in ("near","mid","far"):
        document, binary, _ = reader.glb(output / "candidate" / ("glasgow_bay_"+lod+".glb"))
        primitive = document["meshes"][0]["primitives"][1]
        uv = np.asarray(reader.accessor(document,binary,primitive["attributes"]["TEXCOORD_0"]))
        source = np.asarray(reader.accessor(document,binary,primitive["attributes"]["TEXCOORD_1"]))
        indices = np.asarray([row[0] for row in reader.accessor(document,binary,primitive["indices"])]).reshape((-1,3))
        weights = np.asarray(((1/3,1/3,1/3),(.8,.1,.1),(.1,.8,.1),(.1,.1,.8)))
        for triangle in indices:
            centroid = uv[triangle].mean(axis=0)
            bottom = (centroid[0],1-centroid[1])
            names = [name for name,(x0,y0,x1,y1) in regions.items() if x0/512 <= bottom[0] <= x1/512 and y0/512 <= bottom[1] <= y1/512]
            assert len(names)==1, "Actual triangle is outside its colour region"
            samples[names[0]][0].extend(weights @ uv[triangle])
            samples[names[0]][1].extend(weights @ source[triangle])
    reference = decode(output / "mip-opaque_glazing_basecolor-00.png",True)
    orm = decode(output / "mip-accent_orm-00.png",False)
    orm_levels = [item for item in report["decoded_imported_mip_images"] if item["texture"] == "accent_orm"]
    assert len(orm_levels)==1 and orm_levels[0]["level"]==0, "The actual imported accent ORM must have no mip chain"
    orm_results = {}
    colour_results = []
    for name,(mapped,source) in samples.items():
        actual = sample(orm,mapped)
        maximum = float(np.max(abs(actual-expected_orm[name])))
        # Allows one RGB565 quantization step after actual S3TC import. This
        # checks packed channel roles; it is not an uncompressed exact-match.
        assert maximum <= 1/31 + .002, "Imported ORM class/channel contamination: "+name
        orm_results[name] = {"samples":len(mapped), "maximum_linear_channel_error":maximum,
            "mean_effective_R_AO_G_roughness_B_metallic_at_unit_factors":actual.mean(axis=0).tolist()}
    levels = [item for item in report["decoded_imported_mip_images"] if item["texture"]=="accent_basecolor"]
    assert len(levels)>1, "Colour mips must remain enabled"
    for item in levels:
        pixels = decode(output/item["image"],True)
        results = {}
        for name,(mapped,source) in samples.items():
            expected = sample(reference,source,True) if name=="glazing" else np.broadcast_to(constants[name],(len(mapped),3))
            results[name] = errors(expected,sample(pixels,mapped))
        colour_results.append({"level":item["level"], "dimensions":item["size"], "class_errors_vs_base_reference":results})
    return {"actual_imported_no_mip_orm":orm_results, "actual_imported_colour_mips":colour_results,
        "limits":"Class errors include compression, minification and region contamination. No claim about hardware-selected mip or visual acceptability; review matched images separately."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("stage", "configure", "finalize"))
    parser.add_argument("output", type=Path)
    parser.add_argument("--accent-colour-lossless", action="store_true", help="Optional stage-only colour import diagnostic; changes no other map")
    args = parser.parse_args()
    output = args.output.resolve()
    assert output.is_relative_to(ROOT / "runs") and output.is_dir(), "Disposable output must stay under this preview/runs"
    assert not args.accent_colour_lossless or args.action == "stage", "The optional import policy is fixed at fresh staging"
    if args.action == "stage":
        stage(output,args.accent_colour_lossless)
    else:
        {"configure": configure, "finalize": finalize}[args.action](output)


if __name__ == "__main__":
    main()
