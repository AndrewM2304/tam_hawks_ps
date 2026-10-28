"""Bind a completed optional lossless trial to the preserved compressed control.

Read-only inputs, one diagnostic JSON in the lossless run; no engine launch.
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("compressed", type=Path)
    parser.add_argument("lossless", type=Path)
    args = parser.parse_args()
    runs = [args.compressed.resolve(), args.lossless.resolve()]
    assert runs[0] != runs[1]
    assert all(p.is_relative_to(ROOT / "runs") for p in runs)
    names = ["receipt.json", "report.json", "input-manifest.json", "paint-diagnostic.json"]
    inputs = {str(p / n): sha(p / n) for p in runs for n in names}
    reports = [json.loads((p / "report.json").read_text()) for p in runs]
    receipts = [json.loads((p / "receipt.json").read_text()) for p in runs]
    assert reports[1]["import_policy"]["accent_colour"] == "lossless"
    for field in ["environment", "lighting", "native_lod_samples"]:
        assert reports[0][field] == reports[1][field], field
    graph = lambda r: [{k:v for k,v in m.items() if k != "resource_id"} for m in r["materials"]]
    assert graph(reports[0]) == graph(reports[1]), "Material graph changed"
    mesh_fields = ["path", "sha256", "surfaces", "triangles", "surface_formats", "bounds_min", "bounds_size", "auto_mesh_lods"]
    assert [[{k:m[k] for k in mesh_fields} for m in r["meshes"]] for r in reports][0] == [
        {k:m[k] for k in mesh_fields} for m in reports[1]["meshes"]], "Mesh contract changed"
    textures = [{Path(t["path"]).stem:t for t in r["textures"]} for r in reports]
    shared_fields = ["path", "source_sha256", "size", "role", "mipmap_count", "has_mipmaps", "resource_class"]
    for name, old in textures[0].items():
        new = textures[1][name]
        fields = shared_fields + ([] if name == "accent_basecolor" else ["compressed", "image_format", "imported_data_bytes"])
        assert {k:old[k] for k in fields} == {k:new[k] for k in fields}, name
    old, new = [t["accent_basecolor"] for t in textures]
    assert old["compressed"] and not new["compressed"] and new["import_compress_mode"] == 0
    assert sha(runs[0]/"mip-accent_orm-00.png") == sha(runs[1]/"mip-accent_orm-00.png"), "ORM readback changed"
    assert receipts[0]["imported_colour_and_orm_analysis"]["actual_imported_no_mip_orm"] == receipts[1]["imported_colour_and_orm_analysis"]["actual_imported_no_mip_orm"]
    image_fields = ["image", "camera_position", "target", "fov", "variant", "view", "source_sha256", "expected_native_lod", "actual_holder_primitive_delta"]
    assert [[{k:i[k] for k in image_fields} for i in r["images"]] for r in reports][0] == [
        {k:i[k] for k in image_fields} for i in reports[1]["images"]], "Image fixture changed"
    pairs = []
    for row in reports[1]["images"]:
        paths = [p / row["image"] for p in runs]
        arrays = [np.asarray(Image.open(p).convert("RGB")) for p in paths]
        assert arrays[0].shape == arrays[1].shape == (1080,1920,3)
        delta = np.abs(arrays[0].astype(np.int16)-arrays[1].astype(np.int16))
        pairs.append({"image":row["image"], "sha256":[sha(p) for p in paths],
                      "decoded_identical":bool(np.array_equal(*arrays)),
                      "mean_absolute_byte_rgb":float(delta.mean()), "max_byte_channel":int(delta.max()),
                      "pixels_changed":int(np.count_nonzero(np.any(delta != 0,axis=2)))})
    candidate_names = ["sandstone_basecolor", "sandstone_normal_opengl", "sandstone_orm", "accent_basecolor", "accent_orm"]
    totals = [sum(t[n]["imported_data_bytes"] for n in candidate_names) for t in textures]
    result = {"schema":1, "script_sha256":sha(Path(__file__)), "input_sha256":inputs,
              "verified_unchanged":"Geometry, UV source assets, materials, production lighting, image camera/stages, all texture source bytes, all non-accent-colour imported data and actual ORM readback",
              "accent_colour":{"compressed":old, "lossless":new,
                               "imported_data_byte_delta":new["imported_data_bytes"]-old["imported_data_bytes"]},
              "candidate_total_imported_data_bytes":{"compressed":totals[0], "lossless":totals[1], "delta":totals[1]-totals[0]},
              "matched_images":pairs,
              "fitted_controls_decoded_identical":all(p["decoded_identical"] for p in pairs if p["image"].startswith("fitted-")),
              "colour_mip_analyses":{label:r["imported_colour_and_orm_analysis"]["actual_imported_colour_mips"] for label,r in zip(["compressed","lossless"],receipts)},
              "limits":"Imported image-data bytes are not resident GPU memory. Pixel differences are diagnostic, not art acceptance or performance. Lossless colour does not change atlas regions or remove coarse-mip mixing; ORM remains compressed. Runtime assets/defaults unchanged; Mac, timing, live integration and final art gates remain open."}
    assert inputs == {path:sha(Path(path)) for path in inputs}, "Input changed"
    output = runs[1]/"lossless-comparison.json"
    output.write_text(json.dumps(result,indent=2)+"\n")
    print("LOSSLESS_COMPARISON",sha(output),"candidate imported-byte delta",totals[1]-totals[0])


if __name__ == "__main__":
    main()
