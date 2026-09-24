from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CPP = ROOT / "Source" / "HonourWar" / "HonourWarScreenshotDirector.cpp"
HDR = ROOT / "Source" / "HonourWar" / "HonourWarScreenshotDirector.h"
PS1 = ROOT / "Build" / "Run-HonourWar-1h-Soak.ps1"
WF = ROOT / ".github" / "workflows" / "unreal-windows-1h-soak.yml"

for path in (CPP, HDR, PS1, WF):
    if not path.exists():
        raise SystemExit(f"SOAK_CONTRACT_FAIL: missing {path}")

cpp = CPP.read_text(encoding="utf-8")
hdr = HDR.read_text(encoding="utf-8")
ps1 = PS1.read_text(encoding="utf-8")
wf = WF.read_text(encoding="utf-8")

required_classes = [
    "EHonourWarClass::Warrior",
    "EHonourWarClass::Mage",
    "EHonourWarClass::Archer",
    "EHonourWarClass::Thief",
    "EHonourWarClass::Acolyte",
    "EHonourWarClass::Merchant",
    "EHonourWarClass::Ranger",
]

checks = [
    ("HonourWarSoak", "HonourWarSoak" in cpp and "HonourWarSoak" in ps1),
    ("soak header type dependencies", '#include "HonourWarTypes.h"' in hdr and "class AHonourWarMonster;" in hdr),
    ("3600-second session", "Elapsed>=3600.0f" in cpp),
    ("480-second class phases", "ClassElapsed>=480.0f" in cpp),
    ("PASS[CLASS]", 'PASS[CLASS]' in cpp),
    ("PASS[CLASS-END]", 'PASS[CLASS-END]' in cpp and 'FAIL[CLASS-END]' in cpp),
    ("heartbeat", "HEARTBEAT" in cpp),
    ("save coverage", "Player->SaveProgress()" in cpp),
    ("resource recovery", "RestoreVitals()" in cpp),
    ("movement result markers", "PASS[MOVEMENT]" in cpp and "FAIL[MOVEMENT]" in cpp),
    ("per-skill failure markers", "FAIL[SKILL]" in cpp and "before=%s after=%s" in cpp),
    ("manual workflow only", "workflow_dispatch:" in wf and "schedule:" not in wf),
    ("60-minute runtime safety window", "TimeoutSeconds = 3720" in ps1),
]

for label, ok in checks:
    if not ok:
        raise SystemExit(f"SOAK_CONTRACT_FAIL: {label}")

for class_name in required_classes:
    if class_name not in cpp:
        raise SystemExit(f"SOAK_CONTRACT_FAIL: missing class coverage for {class_name}")

if "daily-honour-war-upgrade" in wf.lower() or "daily" in wf.lower():
    raise SystemExit("SOAK_CONTRACT_FAIL: soak workflow must not be a daily/automatic upgrade workflow")

print("HONOUR_WAR_1H_SOAK_CONTRACT_PASS: seven classes, 3600s runtime, 480s phases, save/recovery/heartbeat coverage, manual-only workflow")
