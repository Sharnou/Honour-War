from pathlib import Path
import struct
import sys
import zlib

ROOT=Path(__file__).resolve().parents[1]
FRAME=ROOT/"visual-captures"/"honour-war-real-game.png"

def read_png_rgb(path:Path):
    data=path.read_bytes()
    if data[:8]!=b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos=8
    width=height=bit_depth=color_type=interlace=None
    idat=bytearray()
    while pos<len(data):
        length=struct.unpack(">I",data[pos:pos+4])[0]; pos+=4
        chunk=data[pos:pos+4]; pos+=4
        payload=data[pos:pos+length]; pos+=length
        pos+=4
        if chunk==b"IHDR":
            width,height,bit_depth,color_type,compression,filter_method,interlace=struct.unpack(">IIBBBBB",payload)
        elif chunk==b"IDAT":
            idat.extend(payload)
        elif chunk==b"IEND":
            break
    if width is None or bit_depth!=8 or color_type not in (2,6) or interlace!=0:
        raise ValueError("unsupported PNG format")
    channels=3 if color_type==2 else 4
    stride=width*channels
    raw=zlib.decompress(bytes(idat))
    expected=(stride+1)*height
    if len(raw)!=expected:
        raise ValueError("unexpected PNG scanline size")
    rows=[]
    previous=bytearray(stride)
    offset=0
    for _ in range(height):
        filter_type=raw[offset]; offset+=1
        scan=bytearray(raw[offset:offset+stride]); offset+=stride
        for i in range(stride):
            left=scan[i-channels] if i>=channels else 0
            up=previous[i]
            up_left=previous[i-channels] if i>=channels else 0
            if filter_type==1:
                scan[i]=(scan[i]+left)&255
            elif filter_type==2:
                scan[i]=(scan[i]+up)&255
            elif filter_type==3:
                scan[i]=(scan[i]+((left+up)//2))&255
            elif filter_type==4:
                p=left+up-up_left
                pa=abs(p-left); pb=abs(p-up); pc=abs(p-up_left)
                predictor=left if pa<=pb and pa<=pc else (up if pb<=pc else up_left)
                scan[i]=(scan[i]+predictor)&255
            elif filter_type!=0:
                raise ValueError("unsupported PNG filter")
        rows.append(scan)
        previous=scan
    return width,height,channels,rows

if not FRAME.is_file():
    print("VISUAL_FRAME_QA: FAIL :: screenshot missing")
    sys.exit(1)

try:
    width,height,channels,rows=read_png_rgb(FRAME)
except Exception as exc:
    print("VISUAL_FRAME_QA: FAIL :: PNG decode error: "+str(exc))
    sys.exit(1)

def luminance(row,offset):
    r=row[offset]; g=row[offset+1]; b=row[offset+2]
    return 0.2126*r+0.7152*g+0.0722*b

total=width*height
sum_luma=0.0
clipped=0
center_clipped=0
center_lit=0
center_x0=width//5
center_x1=width-width//5
center_y0=height//5
center_y1=height-height//5
for y,row in enumerate(rows):
    for x in range(width):
        value=luminance(row,x*channels)
        sum_luma+=value
        if value>12.0 and center_x0<=x<center_x1 and center_y0<=y<center_y1:
            center_lit+=1
        if value>=245.0:
            clipped+=1
            if center_x0<=x<center_x1 and center_y0<=y<center_y1:
                center_clipped+=1

mean_luma=sum_luma/max(1,total)
clipped_ratio=clipped/max(1,total)
center_area=(center_x1-center_x0)*(center_y1-center_y0)
center_ratio=center_clipped/max(1,center_area)
center_lit_ratio=center_lit/max(1,center_area)

checks=[
    (width>=1280 and height>=720,f"frame resolution {width}x{height}"),
    (mean_luma<=180.0,f"mean luminance {mean_luma:.1f} <= 180"),
    (clipped_ratio<=0.28,f"global clipped-white ratio {clipped_ratio:.3f} <= 0.280"),
    (center_ratio<=0.25,f"center clipped-white ratio {center_ratio:.3f} <= 0.250"),
    (center_lit_ratio>=0.015,f"center rendered-world ratio {center_lit_ratio:.3f} >= 0.015"),
]
failed=0
for ok,message in checks:
    print(("PASS" if ok else "FAIL")+" :: "+message)
    failed += 0 if ok else 1

if failed:
    print(f"VISUAL_FRAME_QA: FAIL :: {failed} checks failed")
    sys.exit(1)
print("VISUAL_FRAME_QA: PASS")
