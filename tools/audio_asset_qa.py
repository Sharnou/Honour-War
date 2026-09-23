#!/usr/bin/env python3
"""Static QA gate for the original Honour War audio source pack."""
from __future__ import annotations
import json,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; MANIFEST=ROOT/"data"/"honour_war_audio_manifest.json"
def main():
    data=json.loads(MANIFEST.read_text(encoding="utf-8")); items=data["gameplay_sfx"]+data["class_music"]; assert len(data["gameplay_sfx"])==8 and len(data["class_music"])==7
    for item in items:
        p=ROOT/item["path"]; assert p.is_file(),f"missing audio: {item['path']}"
        with wave.open(str(p),"rb") as w: assert w.getnchannels()==1 and w.getsampwidth()==2 and w.getframerate()==11025 and w.getnframes()>1000
        assert item["original"] is True
    print("HONOUR WAR AUDIO QA"); print("PASS: 8 gameplay SFX + 7 class piano loops exist as PCM WAV source assets."); return 0
if __name__=="__main__": raise SystemExit(main())
