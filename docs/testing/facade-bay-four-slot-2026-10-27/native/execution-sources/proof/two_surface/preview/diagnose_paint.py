"""Read-only post-capture investigation of paint patterning.

python3 -B .../preview/diagnose_paint.py .../preview/runs/comparison-XXXXXX
Writes one separately source-bound diagnostic beside the admitted receipt;
never rewrites that receipt or launches an engine. Installed NumPy/Pillow only.
"""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import sys

import numpy as np
from PIL import Image

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
PROOF = ROOT.parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run", type=Path)
    run = parser.parse_args().run.resolve()
    assert run.is_relative_to(ROOT / "runs") and (run / "receipt.json").exists()
    files = ["receipt.json", "report.json", "textures/accent_basecolor.png", "textures/accent_orm.png",
             "mip-accent_basecolor-00.png", "mip-accent_orm-00.png",
             "fitted/glasgow_bay_near.glb", "candidate/glasgow_bay_near.glb"]
    hashes = {name:sha(run/name) for name in files}
    regions = {"paint":(32,864,448,992), "metal":(544,864,992,992)}
    rectangles = {}
    for kind, source, imported, size in [("colour","textures/accent_basecolor.png","mip-accent_basecolor-00.png",1024),
                                        ("orm","textures/accent_orm.png","mip-accent_orm-00.png",128)]:
        a = np.asarray(Image.open(run/source).convert("RGB"))
        b = np.asarray(Image.open(run/imported).convert("RGB"))
        for name, coordinates in regions.items():
            x0,y0,x1,y1 = [v*size//1024 for v in coordinates]
            original, decoded = a[size-y1:size-y0,x0:x1], b[size-y1:size-y0,x0:x1]
            values,counts = np.unique(decoded.reshape((-1,3)),axis=0,return_counts=True)
            rectangles[kind+"_"+name] = {"source_unique_rgb":np.unique(original.reshape((-1,3)),axis=0).tolist(),
                "actual_imported_unique_rgb":values.tolist(), "pixel_counts":counts.tolist(), "first_4x4_rgb":decoded[:4,:4].tolist(),
                "column_mean_range_rgb":(decoded.mean(axis=0).max(axis=0)-decoded.mean(axis=0).min(axis=0)).tolist(),
                "row_mean_range_rgb":(decoded.mean(axis=1).max(axis=0)-decoded.mean(axis=1).min(axis=0)).tolist()}
    spec = importlib.util.spec_from_file_location("original_glb_reader",PROOF/"audit.py")
    reader = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(reader)
    faces = {}
    for variant in ("fitted","candidate"):
        document,binary,_ = reader.glb(run/variant/"glasgow_bay_near.glb")
        rows = []
        for primitive in document["meshes"][0]["primitives"]:
            if primitive["material"] != 1: continue
            attributes = primitive["attributes"]
            positions,normals,uvs = [reader.accessor(document,binary,attributes[key]) for key in ("POSITION","NORMAL","TEXCOORD_0")]
            indices = [item[0] for item in reader.accessor(document,binary,primitive["indices"])]
            for offset in range(0,len(indices),3):
                triangle = indices[offset:offset+3]
                if all(abs(positions[k][2]-.245)<1e-5 and 2.97<positions[k][1]<3.59 and abs(positions[k][0])<3.07 for k in triangle):
                    rows.append({"positions":[positions[k] for k in triangle], "normals":[normals[k] for k in triangle], "uv0":[uvs[k] for k in triangle]})
        assert len(rows)==2, "Expected the two broad fascia front triangles"
        faces[variant] = rows
    assert [row["positions"] for row in faces["fitted"]] == [row["positions"] for row in faces["candidate"]]
    assert hashes == {name:sha(run/name) for name in files}, "Diagnostic input changed"
    imported_pattern = len(rectangles["colour_paint"]["actual_imported_unique_rgb"]) > 1
    report = {"schema":1, "script_sha256":sha(Path(__file__)), "reader_sha256":sha(PROOF/"audit.py"), "input_sha256":hashes,
        "flat_source_vs_actual_imported_rectangles":rectangles, "same_position_fascia_front_triangles":faces,
        "imported_colour_paint_has_pattern":imported_pattern,
        "finding":("Uniform source paint becomes a multi-colour imported pattern. Actual imported format and pixel palette identify texture-compression changes; no-mip ORM is checked separately." if imported_pattern else
                   "The actual imported base-level paint remains a single colour; no colour-compression pattern is present. Compressed no-mip ORM and changed chamfer normals are still separate possible contributors to rendered differences."),
        "limit":"Chamfer changes also alter weighted corner normals and smooth highlights. This texture readback alone does not attribute every changed rendered pixel solely to colour compression; ORM compression and colour-region mip mixing remain separate effects.",
        "disposition":"Capture/import evidence admitted; paint banding and coarse colour-mip contamination remain quality gates before live use."}
    (run/"paint-diagnostic.json").write_text(json.dumps(report,indent=2)+"\n")
    print("PAINT_DIAGNOSTIC",sha(run/"paint-diagnostic.json"),"source/decoded texture and fascia geometry comparison complete")


if __name__ == "__main__":
    main()
