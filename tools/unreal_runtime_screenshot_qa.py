#!/usr/bin/env python3
"""Dependency-free PNG sanity gate for real Unreal runtime screenshots."""

from __future__ import annotations
import struct
import sys
import zlib
from pathlib import Path

def read_png(path: Path):
    data=path.read_bytes()
    if data[:8]!=b"\x89PNG\r\n\x1a\n": raise ValueError("not PNG")
    pos=8; width=height=bit_depth=color_type=None; raw=b""
    while pos<len(data):
        length=struct.unpack(">I",data[pos:pos+4])[0]; kind=data[pos+4:pos+8]
        chunk=data[pos+8:pos+8+length]; pos+=12+length
        if kind==b"IHDR": width,height,bit_depth,color_type,_,_,_=struct.unpack(">IIBBBBB",chunk)
        elif kind==b"IDAT": raw+=chunk
        elif kind==b"IEND": break
    if bit_depth!=8 or color_type not in (2,6): raise ValueError(f"unsupported PNG format {color_type}/{bit_depth}")
    channels=3 if color_type==2 else 4
    stride=width*channels
    decoded=zlib.decompress(raw)
    rows=[]; prev=bytearray(stride); p=0
    for _ in range(height):
        f=decoded[p]; p+=1; scan=bytearray(decoded[p:p+stride]); p+=stride
        for i in range(stride):
            left=scan[i-channels] if i>=channels else 0
            up=prev[i]
            ul=prev[i-channels] if i>=channels else 0
            if f==1: scan[i]=(scan[i]+left)&255
            elif f==2: scan[i]=(scan[i]+up)&255
            elif f==3: scan[i]=(scan[i]+((left+up)//2))&255
            elif f==4:
                q=left+up-ul; pa=abs(q-left); pb=abs(q-up); pc=abs(q-ul)
                pr=left if pa<=pb and pa<=pc else (up if pb<=pc else ul)
                scan[i]=(scan[i]+pr)&255
            elif f!=0: raise ValueError("unsupported PNG filter")
        rows.append(scan); prev=scan
    total=0; min_v=255; max_v=0; dark=0; count=0
    for row in rows:
        for i in range(0,stride,channels):
            v=(int(row[i])+int(row[i+1])+int(row[i+2]))/3
            total+=v; min_v=min(min_v,int(v)); max_v=max(max_v,int(v))
            dark += 1 if v<12 else 0; count+=1
    mean=total/count
    dark_ratio=dark/count
    return width,height,mean,max_v-min_v,dark_ratio

if len(sys.argv)!=2:
    print("usage: unreal_runtime_screenshot_qa.py <png>"); sys.exit(2)
path=Path(sys.argv[1])
if not path.is_file():
    print(f"UNREAL_SCREENSHOT_FAIL: missing {path}"); sys.exit(1)
w,h,mean,spread,dark=read_png(path)
if w<1280 or h<720:
    print(f"UNREAL_SCREENSHOT_FAIL: resolution {w}x{h}"); sys.exit(1)
if mean<28 or spread<35 or dark>0.90:
    print(f"UNREAL_SCREENSHOT_FAIL: suspicious frame mean={mean:.1f} spread={spread} dark={dark:.3f}"); sys.exit(1)
print(f"UNREAL_SCREENSHOT_PASS: {w}x{h}, mean={mean:.1f}, spread={spread}, dark={dark:.3f}")
