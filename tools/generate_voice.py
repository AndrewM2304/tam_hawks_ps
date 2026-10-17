#!/usr/bin/env python3
"""Generate original NPC barks with the already installed, inspected Flite 2.2.

No downloads/installations/network; see docs/testing/AUDIO.md and retained licences.
"""
from __future__ import annotations

import array
import ctypes
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import wave

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "game/audio/generated"
LIBRARY_DIR = Path("/usr/lib/x86_64-linux-gnu")
LIBRARY_HASHES = {
    "libflite.so.2.2": "490ffd91ee67acbe4279a6b736dafdacba7a88211985960282e27c0d2d7c6eaf",
    "libflite_usenglish.so.2.2": "bd46f4507c4cfd14a470ea4775778518af55d7ce9a688c77606607c3414b0357",
    "libflite_cmulex.so.2.2": "0bbf45f1cdc8f045ea04723494e6f870fe695f9926e75a4c8c2c9916e3970bb8",
    "libflite_cmu_us_kal16.so.2.2": "8f701f8618eda9b912ba249ddecda3f9f4af8148072c9df8f9e82e16b84cabd3",
}
BARKS = {"landing": "Some landing.", "cone": "Mind the cone.", "again": "One more run."}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare_pcm(source: Path, destination: Path) -> dict:
    with wave.open(str(source), "rb") as clip:
        rate = clip.getframerate()
        if clip.getnchannels() != 1 or clip.getsampwidth() != 2 or rate != 16000:
            raise RuntimeError("Unexpected Flite output format; review source before continuing")
        values = array.array("h", clip.readframes(clip.getnframes()))
    if sys.byteorder != "little":
        values.byteswap()
    if not 1600 <= len(values) <= rate * 5:
        raise RuntimeError("Bark duration is outside the 0.1–5 second limit")
    peak = max(abs(value) for value in values)
    if peak < 32:
        raise RuntimeError("Synthesized bark is unexpectedly silent")
    scale = (0.55 * 32767) / peak
    fade = int(rate * 0.008)
    for index, value in enumerate(values):
        envelope = min(1.0, index / fade, (len(values) - 1 - index) / fade)
        values[index] = round(value * scale * envelope)
    if sys.byteorder != "little":
        values.byteswap()
    with wave.open(str(destination), "wb") as clip:
        clip.setnchannels(1)
        clip.setsampwidth(2)
        clip.setframerate(rate)
        clip.writeframes(values.tobytes())
    return {"sample_rate": rate, "frames": len(values), "seconds": len(values) / rate,
            "sha256": digest(destination)}


def main() -> None:
    for filename, expected in LIBRARY_HASHES.items():
        path = LIBRARY_DIR / filename
        if not path.is_file() or digest(path) != expected:
            raise SystemExit(f"Pinned installed Flite library unavailable/different: {filename}. "
                             "No download attempted; review provenance before changing pins.")
    core = ctypes.CDLL(str(LIBRARY_DIR / "libflite.so.2.2"), mode=ctypes.RTLD_GLOBAL)
    language = ctypes.CDLL(str(LIBRARY_DIR / "libflite_usenglish.so.2.2"), mode=ctypes.RTLD_GLOBAL)
    lexicon = ctypes.CDLL(str(LIBRARY_DIR / "libflite_cmulex.so.2.2"), mode=ctypes.RTLD_GLOBAL)
    voice_lib = ctypes.CDLL(str(LIBRARY_DIR / "libflite_cmu_us_kal16.so.2.2"), mode=ctypes.RTLD_GLOBAL)
    core.flite_init.argtypes = []
    core.flite_init.restype = ctypes.c_int
    core.flite_text_to_wave.argtypes = [ctypes.c_char_p, ctypes.c_void_p]
    core.flite_text_to_wave.restype = ctypes.c_void_p
    core.cst_wave_save_riff.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    core.cst_wave_save_riff.restype = ctypes.c_int
    core.delete_wave.argtypes = [ctypes.c_void_p]
    core.delete_wave.restype = None
    voice_lib.register_cmu_us_kal16.argtypes = [ctypes.c_char_p]
    voice_lib.register_cmu_us_kal16.restype = ctypes.c_void_p
    voice_lib.unregister_cmu_us_kal16.argtypes = [ctypes.c_void_p]
    voice_lib.unregister_cmu_us_kal16.restype = None
    if core.flite_init() != 0:
        raise RuntimeError("Flite initialization failed")
    voice = voice_lib.register_cmu_us_kal16(None)
    if not voice:
        raise RuntimeError("Built-in kal16 voice registration failed")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = {
        "generator": "tools/generate_voice.py", "engine": "installed Debian libflite1 2.2-7",
        "upstream_commit": "e9e2e37c329dbe98bfeb27a1828ef9a71fa84f88",
        "voice": "cmu_us_kal16", "libraries_sha256": LIBRARY_HASHES,
        "processing": "original text; normalize peak to 0.55; 8ms endpoint fades; mono PCM16 16000Hz",
        "notices": ["docs/licences/third-party/flite-COPYING.txt",
                    "docs/licences/third-party/flite-debian-copyright.txt",
                    "docs/licences/third-party/flite-kal16-LICENSE.txt"], "barks": {},
    }
    try:
        with tempfile.TemporaryDirectory(prefix="tam-hawks-voice-") as directory:
            for key, text in BARKS.items():
                waveform = core.flite_text_to_wave(text.encode("utf-8"), voice)
                if not waveform:
                    raise RuntimeError(f"Flite produced no waveform for {key}")
                raw = Path(directory) / f"{key}-raw.wav"
                try:
                    if core.cst_wave_save_riff(waveform, str(raw).encode()) != 0:
                        raise RuntimeError(f"Flite could not save {key}")
                finally:
                    core.delete_wave(waveform)
                destination = OUTPUT / f"{key}.wav"
                metadata = prepare_pcm(raw, destination)
                manifest["barks"][key] = {"text": text, "file": destination.name, **metadata}
    finally:
        voice_lib.unregister_cmu_us_kal16(voice)
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest["barks"], indent=2))


if __name__ == "__main__":
    main()
