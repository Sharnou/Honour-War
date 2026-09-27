#!/usr/bin/env python3
"""Validate that a captured AVIF contains a structurally valid AV1 image container.

The checker is intentionally dependency-free. It validates ISO-BMFF structure,
AVIF-compatible brands and the presence of media/metadata boxes. Pixel-quality
judgement remains a runtime evidence concern and is not replaced by this header
check.
"""

from __future__ import annotations
import struct
import sys
from pathlib import Path

AVIF_BRANDS = {b"avif", b"avis"}


def read_box(data: bytes, offset: int):
    if offset + 8 > len(data):
        return None
    size = struct.unpack(">I", data[offset:offset + 4])[0]
    typ = data[offset + 4:offset + 8]
    header = 8
    if size == 1:
        if offset + 16 > len(data):
            return None
        size = struct.unpack(">Q", data[offset + 8:offset + 16])[0]
        header = 16
    elif size == 0:
        size = len(data) - offset
    if size < header or offset + size > len(data):
        return None
    return size, typ, header


def validate_avif(path: Path) -> tuple[bool, str]:
    data = path.read_bytes()
    if len(data) <= 10_000:
        return False, "screenshot missing or too small"
    pos = 0
    boxes = []
    while pos < len(data):
        box = read_box(data, pos)
        if box is None:
            return False, "invalid ISO-BMFF box structure"
        size, typ, header = box
        boxes.append(typ)
        pos += size
    if b"ftyp" not in boxes:
        return False, "missing ftyp box"
    ftyp = read_box(data, 0)
    if ftyp is None or ftyp[1] != b"ftyp":
        return False, "first box is not ftyp"
    payload_start = ftyp[2]
    major = data[payload_start:payload_start + 4]
    if major not in AVIF_BRANDS:
        compatible = set()
        size, _, header = ftyp
        payload_end = size
        p = payload_start + 8
        while p + 4 <= payload_end:
            compatible.add(data[p:p + 4])
            p += 4
        if not (compatible & AVIF_BRANDS):
            return False, "file has no AVIF-compatible brand"
    if b"meta" not in boxes:
        return False, "missing AVIF metadata box"
    if b"mdat" not in boxes:
        return False, "missing AVIF media data box"
    return True, f"boxes={len(boxes)} bytes={len(data)}"


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: real_game_screenshot_content_qa.py <avif>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    if path.suffix.lower() != ".avif":
        print("REAL_GAME_SCREENSHOT_CONTENT_FAIL: screenshot must be AVIF")
        return 1
    try:
        ok, detail = validate_avif(path)
    except Exception as exc:
        print(f"REAL_GAME_SCREENSHOT_CONTENT_FAIL: {exc}")
        return 1
    if not ok:
        print(f"REAL_GAME_SCREENSHOT_CONTENT_FAIL: {detail}")
        return 1
    print(f"REAL_GAME_SCREENSHOT_CONTENT_PASS: {detail}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
