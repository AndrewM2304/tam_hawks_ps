"""Lossless local PNG encoding for exact native RGBA8 capture bytes.

Godot publishes complete .rgba files by atomic rename. A single bounded worker
converts them to ordinary PNG without changing pixels, then removes the spool.
No third-party dependency, network, image resizing or lossy compression is used.
"""
from __future__ import annotations

import hashlib
import pathlib
import struct
import threading
import time
import zlib

WIDTH, HEIGHT, CHANNELS = 1280, 800, 4
ROW_BYTES = WIDTH * CHANNELS
RAW_BYTES = ROW_BYTES * HEIGHT


def _chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)


def _native_dimensions(width: int, height: int) -> tuple[int, int]:
    if type(width) is not int or type(height) is not int or (width, height) not in ((1280, 800), (640, 400)):
        raise ValueError("Expected declared native1280x800 or focused640x400 integer dimensions")
    return width * CHANNELS, width * height * CHANNELS


def encode_rgba8(data: bytes, width: int = WIDTH, height: int = HEIGHT) -> bytes:
    """Encode all native pixels verbatim; filter 0 makes the proof explicit."""
    row_bytes, raw_bytes = _native_dimensions(width, height)
    if len(data) != raw_bytes:
        raise ValueError(f'Incomplete native RGBA8 buffer: {len(data)} != {raw_bytes}')
    rows = b''.join(b'\0' + data[start:start + row_bytes] for start in range(0, raw_bytes, row_bytes))
    return (b'\x89PNG\r\n\x1a\n'
            + _chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
            + _chunk(b'IDAT', zlib.compress(rows, 1)) + _chunk(b'IEND', b''))


def decode_proven_rgba8(data: bytes, width: int = WIDTH, height: int = HEIGHT) -> bytes:
    """Independently validate every chunk/row and reconstruct native RGBA8."""
    row_bytes, raw_bytes = _native_dimensions(width, height)
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('Invalid PNG signature')
    offset, compressed, dimensions, ended = 8, bytearray(), None, False
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError('Truncated PNG chunk')
        length = struct.unpack('>I', data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + length]
        checksum_bytes = data[offset + 8 + length:offset + 12 + length]
        if len(payload) != length or len(checksum_bytes) != 4:
            raise ValueError('Truncated PNG payload')
        if zlib.crc32(kind + payload) & 0xffffffff != struct.unpack('>I', checksum_bytes)[0]:
            raise ValueError('PNG CRC mismatch')
        if kind == b'IHDR':
            dimensions = struct.unpack('>IIBBBBB', payload)
        elif kind == b'IDAT':
            compressed.extend(payload)
        elif kind == b'IEND':
            ended = True
        offset += length + 12
    if dimensions != (width, height, 8, 6, 0, 0, 0) or not ended:
        raise ValueError('Expected complete full-resolution RGBA8 PNG')
    rows = zlib.decompress(compressed)
    stride = row_bytes + 1
    if len(rows) != height * stride or any(rows[y * stride] != 0 for y in range(height)):
        raise ValueError('Expected complete unfiltered native pixel rows')
    return b''.join(rows[y * stride + 1:(y + 1) * stride] for y in range(height))


class PixelSpoolEncoder:
    """Keep at most 32 pending buffers; fail capture on corruption or backlog."""
    def __init__(self, output: pathlib.Path, width: int = WIDTH, height: int = HEIGHT):
        _native_dimensions(width, height)
        self.width, self.height = width, height
        self.output = output
        self.done = threading.Event()
        self.thread = threading.Thread(target=self._run, name='native-lossless-png', daemon=True)
        self.error: BaseException | None = None
        self.frames = 0
        self.max_backlog = 0
        self.total_seconds = 0.0

    def start(self) -> None:
        self.thread.start()

    def finish(self) -> None:
        self.done.set()
        self.thread.join(timeout=60)
        if self.thread.is_alive():
            raise RuntimeError('Lossless PNG worker did not finish within 60 seconds')
        if self.error is not None:
            raise RuntimeError('Lossless PNG worker failed') from self.error

    def _run(self) -> None:
        try:
            while True:
                pending = sorted(self.output.rglob('*.rgba'))
                self.max_backlog = max(self.max_backlog, len(pending))
                if len(pending) > 32:
                    raise RuntimeError('More than 32 complete native buffers are awaiting lossless encoding')
                for raw in pending:
                    started = time.monotonic()
                    native = raw.read_bytes()
                    png = encode_rgba8(native, self.width, self.height)
                    if hashlib.sha256(decode_proven_rgba8(png, self.width, self.height)).digest() != hashlib.sha256(native).digest():
                        raise RuntimeError('Lossless PNG changed native pixels')
                    destination = raw.with_suffix('.png')
                    temporary = destination.with_suffix('.png.tmp')
                    temporary.write_bytes(png)
                    temporary.replace(destination)
                    raw.unlink()
                    self.frames += 1
                    self.total_seconds += time.monotonic() - started
                if self.done.is_set() and not pending:
                    return
                self.done.wait(0.02)
        except BaseException as error:
            self.error = error
