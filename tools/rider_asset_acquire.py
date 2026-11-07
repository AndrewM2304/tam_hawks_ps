#!/usr/bin/env python3
"""Fetch two verified CC0 skin files with bounded ZIP range reads, not a full pack.

This original developer tool uses the configured HTTP proxy and normal TLS trust.
It performs no authentication, purchase, hosted job or runtime network request.
"""
from pathlib import Path
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
    DEST.mkdir(parents=True, exist_ok=True)
    needed = {name: digest for name, digest in FILES.items() if not (DEST / Path(name).name).exists()
              or hashlib.sha256((DEST / Path(name).name).read_bytes()).hexdigest() != digest}
    if needed:
        with zipfile.ZipFile(BoundedZipSource()) as archive:
            for name, digest in needed.items():
                data = archive.read(name)
                if hashlib.sha256(data).hexdigest() != digest:
                    raise RuntimeError("Source digest mismatch; review upstream before modifying the pinned hash")
                (DEST / Path(name).name).write_bytes(data)
    print("Verified2 CC0 skin source files in .local/downloads/mh_skin")
