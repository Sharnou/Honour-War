#!/usr/bin/env python3
"""Validate that a captured PNG contains non-trivial rendered pixels.

Uses only Python's standard library so GitHub runners do not need Pillow.
Supports the 8-bit non-interlaced RGB/RGBA PNGs produced by the Unreal Engine Windows runtime capture.
"""

from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c

def read_png(path: Path) -> tuple[int, int, int, bytes]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG file")
    pos = 8
    width = height = bit_depth = color_type = interlace = None
    idat = bytearray()
    while pos < len(data):
        if pos + 8 > len(data):
            raise ValueError("truncated PNG chunk header")
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        ctype = data[pos + 4:pos + 8]
        start = pos + 8
        end = start + length
        if end + 4 > len(data):
            raise ValueError("truncated PNG chunk")
        payload = data[start:end]
        pos = end + 4
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
        elif ctype == b"IDAT":
            idat.extend(payload)
        elif ctype == b"IEND":
            break
    if width is None or height is None or bit_depth is None or color_type is None:
        raise ValueError("PNG is missing IHDR")
    if bit_depth != 8 or color_type not in (2, 6):
        raise ValueError(f"unsupported PNG format: bit_depth={bit_depth}, color_type={color_type}")
    if interlace != 0:
        raise ValueError("interlaced PNG is not supported")
    channels = 4 if color_type == 6 else 3
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    expected = height * (stride + 1)
    if len(raw) != expected:
        raise ValueError(f"unexpected decompressed PNG size: {len(raw)} != {expected}")

    rows = bytearray()
    prev = bytearray(stride)
    cursor = 0
    for _ in range(height):
        f = raw[cursor]
        cursor += 1
        scan = bytearray(raw[cursor:cursor + stride])
        cursor += stride
        for i in range(stride):
            left = scan[i - channels] if i >= channels else 0
            up = prev[i]
            up_left = prev[i - channels] if i >= channels else 0
            if f == 1:
                scan[i] = (scan[i] + left) & 255
            elif f == 2:
                scan[i] = (scan[i] + up) & 255
            elif f == 3:
                scan[i] = (scan[i] + ((left + up) // 2)) & 255
            elif f == 4:
                scan[i] = (scan[i] + paeth(left, up, up_left)) & 255
            elif f != 0:
                raise ValueError(f"unknown PNG row filter {f}")
        rows.extend(scan)
        prev = scan
    return width, height, channels, bytes(rows)

def main() -> int:
    if len(sys.argv) != 2:
        print("usage: real_game_screenshot_content_qa.py <png>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    if not path.is_file() or path.stat().st_size <= 10_000:
        print("REAL_GAME_SCREENSHOT_CONTENT_FAIL: screenshot missing or too small")
        return 1
    try:
        width, height, channels, pixels = read_png(path)
    except Exception as exc:
        print(f"REAL_GAME_SCREENSHOT_CONTENT_FAIL: {exc}")
        return 1
    # Windows CI can apply display/DPI scaling to the exported window.
    # Accept a genuine 16:9 runtime viewport down to 960x540; higher-resolution
    # Linux captures remain fully supported.
    if width < 960 or height < 540:
        print(f"REAL_GAME_SCREENSHOT_CONTENT_FAIL: unexpected dimensions {width}x{height}")
        return 1

    step = max(1, min(width, height) // 160)
    count = 0
    dark = 0
    total = [0, 0, 0]
    minimum = 255
    maximum = 0
    for y in range(0, height, step):
        row = y * width * channels
        for x in range(0, width, step):
            i = row + x * channels
            rgb = pixels[i:i + 3]
            if len(rgb) < 3:
                continue
            r, g, b = rgb
            total[0] += r
            total[1] += g
            total[2] += b
            minimum = min(minimum, r, g, b)
            maximum = max(maximum, r, g, b)
            count += 1
            if max(r, g, b) < 12:
                dark += 1
    mean = sum(total) / (3.0 * max(count, 1))
    dark_ratio = dark / max(count, 1)
    spread = maximum - minimum
    print(f"REAL_GAME_SCREENSHOT_CONTENT: {width}x{height} mean={mean:.2f} spread={spread} dark_ratio={dark_ratio:.4f}")
    if mean < 18.0 or spread < 45 or dark_ratio > 0.97:
        print("REAL_GAME_SCREENSHOT_CONTENT_FAIL: rendered frame is too uniform/dark")
        return 1
    print("REAL_GAME_SCREENSHOT_CONTENT_PASS")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
