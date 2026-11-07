#!/usr/bin/env python3
"""Fetch verified CC0 rider sources with bounded ZIP reads, never the full pack.

This original developer tool uses the configured HTTP proxy and normal TLS trust.
It performs no authentication, purchase, hosted job or runtime network request.
"""
from pathlib import Path
import argparse
import json
import hashlib
import io
import urllib.request
import zipfile

PACK = "https://files2.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip"
PACK_BYTES = 280737770
DEST = Path(__file__).resolve().parents[1] / ".local/downloads/mh_skin"
FILES = {
    "skins/young_caucasian_male/young_caucasian_male.mhmat": "6eda60b07ff2afbde078a2535ef3913593d84e9de92b2eb76c30f396a181fe2e",
    "skins/young_caucasian_male/young_lightskinned_male_diffuse.png": "862a26e335e958b70534cb5f0d7c47ef30ab148a56c42b3e9da969cf76f12963",
}


class BoundedZipSource(io.RawIOBase):
    def __init__(self):
        self.position = 0
        with urllib.request.urlopen(urllib.request.Request(PACK, method="HEAD"), timeout=30) as response:
            if int(response.headers["Content-Length"]) != PACK_BYTES:
                raise RuntimeError("Upstream pack changed size; re-inspect provenance before updating the pinned source.")

    def seekable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else PACK_BYTES + offset
        if not 0 <= self.position <= PACK_BYTES:
            raise ValueError("ZIP seek out of bounds")
        return self.position

    def read(self, size=-1):
        if size < 0:
            size = PACK_BYTES - self.position
        if size == 0:
            return b""
        request = urllib.request.Request(PACK, headers={"Range": f"bytes={self.position}-{self.position + size - 1}"})
        with urllib.request.urlopen(request, timeout=30) as response:
            if response.status != 206:
                raise RuntimeError("Server did not honor bounded range; refusing full-pack fallback")
            result = response.read(size + 1)
        if len(result) != size:
            raise RuntimeError("Unexpected HTTP range length")
        self.position += len(result)
        return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fitted", action="store_true", help="Include the pinned authentic hair/outfit/footwear/face asset data.")
    parser.add_argument("--body", action="store_true", help="Fetch the existing four pinned body/morph data files into the ignored cache.")
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    root = args.project_root.resolve()
    DEST = root / ".local/downloads/mh_skin"
    if args.fitted:
        source_manifest = json.loads((root / "game/art/rider/fitted-source-pins.json").read_text())
        if source_manifest["archive"] != PACK or source_manifest["archive_bytes"] != PACK_BYTES:
            raise RuntimeError("Fitted source archive pin differs from the inspected catalogue.")
        FILES.update({member["member"]: member["sha256"] for member in source_manifest["members"]})
    DEST.mkdir(parents=True, exist_ok=True)
    needed = {name: digest for name, digest in FILES.items() if not (DEST / Path(name).name).exists()
              or hashlib.sha256((DEST / Path(name).name).read_bytes()).hexdigest() != digest}
    if needed:
        with zipfile.ZipFile(BoundedZipSource()) as archive:
            for name, digest in needed.items():
                data = archive.read(name)
                if hashlib.sha256(data).hexdigest() != digest:
                    raise RuntimeError("Source digest mismatch; review upstream before modifying the pinned hash")
                temporary = DEST / ("." + Path(name).name + ".tmp")
                temporary.write_bytes(data)
                temporary.replace(DEST / Path(name).name)
    for name, digest in FILES.items():
        if hashlib.sha256((DEST / Path(name).name).read_bytes()).hexdigest() != digest:
            raise RuntimeError(f"Cached source digest mismatch: {name}")
    if args.body:
        body_cache = root / ".local/downloads/makehuman_hm08"
        body_cache.mkdir(parents=True, exist_ok=True)
        manifest = json.loads((root / "game/art/assets/makehuman_hm08/manifest.json").read_text())
        for name, pin in manifest["sources"].items():
            path = body_cache / name
            if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != pin["sha256"]:
                with urllib.request.urlopen(pin["url"], timeout=40) as response:
                    data = response.read(pin["bytes"] + 1)
                if len(data) != pin["bytes"] or hashlib.sha256(data).hexdigest() != pin["sha256"]:
                    raise RuntimeError(f"Body source pin mismatch: {name}")
                temporary = body_cache / ("." + name + ".tmp")
                temporary.write_bytes(data)
                temporary.replace(path)
            if path.stat().st_size != pin["bytes"] or hashlib.sha256(path.read_bytes()).hexdigest() != pin["sha256"]:
                raise RuntimeError(f"Cached body source pin mismatch: {name}")
    print(f"Verified {len(FILES)} selected CC0 archive members" + (" and 4 body/morph sources." if args.body else "."))
