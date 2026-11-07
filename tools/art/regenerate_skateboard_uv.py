"""Reproduce the admitted board derivative from the pinned project-owned base.
The original Blender build remains tools/art/build_skateboard.py; this wrapper
uses its byte-pinned archived output to make the UV stage deterministic.
Dependencies: requirements-board.txt. No network/runtime generation.
"""
from pathlib import Path
import argparse,gzip,hashlib,importlib.util,tempfile
ROOT=Path(__file__).resolve().parent
BASE_SHA="d5a68a8bd94fa8ad5c374ceddeb3804cc38d7ef780c5b87d3093ef8e15431f99"
OUTPUT_SHA="76103e39e5ed91c5c8381d38c58af8272915952f000ba475dbda30206b7d0943"
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--out',type=Path,default=ROOT.parents[1]/'game/art/assets/tam_skateboard');args=parser.parse_args()
 raw=gzip.decompress((ROOT/'source/tam_skateboard-base.glb.gz').read_bytes())
 if hashlib.sha256(raw).hexdigest()!=BASE_SHA:raise SystemExit('Base board source pin mismatch')
 spec=importlib.util.spec_from_file_location('board_uv',ROOT/'finish_board_uv.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
 with tempfile.TemporaryDirectory(prefix='tam-board-source-') as folder:
  source=Path(folder)/'base.glb';source.write_bytes(raw);module.finish(module.GLB(source),args.out)
 if hashlib.sha256((args.out/'tam_skateboard.glb').read_bytes()).hexdigest()!=OUTPUT_SHA:raise SystemExit('Generated board differs from admitted output')
 print('Board derivative exact admitted SHA256 '+OUTPUT_SHA)
if __name__=='__main__':main()
