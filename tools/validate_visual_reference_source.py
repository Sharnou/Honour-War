from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Screenshot"

EXPECTED = [
    "ChatGPT Image Sep 7, 2026, 03_54_35 PM.png",
    "ChatGPT Image Sep 8, 2026, 12_13_55 AM.png",
    "ChatGPT Image Sep 8, 2026, 12_30_08 AM.png",
    "ChatGPT Image Sep 14, 2026, 02_17_52 PM.png",
    "ChatGPT Image Sep 15, 2026, 11_17_00 PM.png",
    "ChatGPT Image Sep 16, 2026, 12_22_47 AM.png",
    "ChatGPT Image Sep 18, 2026, 11_57_21 PM.png",
]

def fail(message: str) -> None:
    print("VISUAL_SOURCE_CONTRACT: FAIL :: " + message)
    sys.exit(1)

if not SOURCE.is_dir():
    fail("Screenshot/ source folder is missing")

missing = [name for name in EXPECTED if not (SOURCE / name).is_file()]
if missing:
    fail("missing canonical reference image(s): " + ", ".join(missing))

invalid = [name for name in EXPECTED if (SOURCE / name).stat().st_size < 100000]
if invalid:
    fail("reference image unexpectedly small/corrupt: " + ", ".join(invalid))

pngs = sorted(path.name for path in SOURCE.glob("*.png"))
unexpected = [name for name in pngs if name not in EXPECTED]
if unexpected:
    print("VISUAL_SOURCE_CONTRACT: INFO :: additional PNG references present: " + ", ".join(unexpected))

print("VISUAL_SOURCE_CONTRACT: PASS")
print("Direct visual source: Screenshot/")
print(f"Canonical reference images: {len(EXPECTED)}")
for name in EXPECTED:
    print("SOURCE :: Screenshot/" + name)
