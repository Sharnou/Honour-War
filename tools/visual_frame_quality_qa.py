from pathlib import Path
import sys

from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
FRAME=ROOT/"visual-captures"/"honour-war-real-game.png"

if not FRAME.is_file():
    print("VISUAL_FRAME_QA: FAIL :: screenshot missing")
    sys.exit(1)

image=Image.open(FRAME).convert("RGB")
width,height=image.size
pixels=list(image.getdata())
count=len(pixels)
luminance=[0.2126*r+0.7152*g+0.0722*b for r,g,b in pixels]
mean_luma=sum(luminance)/max(1,count)
clipped=sum(1 for value in luminance if value>=245.0)/max(1,count)

left=max(0,width//5)
right=min(width,width-width//5)
top=max(0,height//5)
bottom=min(height,height-height//5)
center=image.crop((left,top,right,bottom))
center_pixels=list(center.getdata())
center_luma=[0.2126*r+0.7152*g+0.0722*b for r,g,b in center_pixels]
center_clipped=sum(1 for value in center_luma if value>=245.0)/max(1,len(center_luma))

checks=[
    (width>=1280 and height>=720,f"frame resolution {width}x{height}"),
    (mean_luma<=180.0,f"mean luminance {mean_luma:.1f} <= 180"),
    (clipped<=0.28,f"global clipped-white ratio {clipped:.3f} <= 0.280"),
    (center_clipped<=0.25,f"center clipped-white ratio {center_clipped:.3f} <= 0.250"),
]
failed=0
for ok,message in checks:
    print(("PASS" if ok else "FAIL")+" :: "+message)
    failed += 0 if ok else 1

if failed:
    print(f"VISUAL_FRAME_QA: FAIL :: {failed} checks failed")
    sys.exit(1)
print("VISUAL_FRAME_QA: PASS")
