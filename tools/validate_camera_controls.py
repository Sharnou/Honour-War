#!/usr/bin/env python3
"""Static regression gate for the permanent Honour War camera + sky/fog contract."""
from __future__ import annotations
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CHARACTER=ROOT/"Source"/"HonourWar"/"HonourWarCharacter.cpp"
CONTROLLER=ROOT/"Source"/"HonourWar"/"HonourWarPlayerController.cpp"
WORLD=ROOT/"Source"/"HonourWar"/"HonourWarWorldDirector.cpp"
INPUTS=ROOT/"Config"/"DefaultInput.ini"
RULES=ROOT/"data"/"honour_war_default_rules.json"
def require(text,marker,label):
    if marker not in text: raise SystemExit(f"CAMERA QA ERROR: missing {label}: {marker}")
def main():
    for path in (CHARACTER,CONTROLLER,WORLD,INPUTS,RULES):
        if not path.is_file(): raise SystemExit(f"CAMERA QA ERROR: missing {path.relative_to(ROOT)}")
    character=CHARACTER.read_text(encoding="utf-8"); controller=CONTROLLER.read_text(encoding="utf-8"); world=WORLD.read_text(encoding="utf-8"); inputs=INPUTS.read_text(encoding="utf-8"); rules=json.loads(RULES.read_text(encoding="utf-8"))
    for marker,label in (("CameraBoom->TargetArmLength=900.0f","default camera distance"),("FRotator(-50.0f,45.0f,0.0f)","default isometric camera angle"),("CameraBoom->bEnableCameraLag=true","camera lag"),("CameraBoom->bEnableCameraRotationLag=true","camera rotation lag"),("FMath::Clamp(CameraBoom->TargetArmLength-WheelDelta*120.0f,550.0f,1350.0f)","bounded mouse-wheel zoom")): require(character,marker,label)
    for marker,label in (("HandleMouseClick","left-click interaction"),("SetMouseTarget","monster targeting"),("SetMouseDestination","ground click-to-move"),("bRightMouseDown","right-drag camera"),("RotateCameraFromMouse","mouse orbit"),("SetControlRotation(FRotator(-50.0f,45.0f,0.0f))","camera reset")): require(controller,marker,label)
    for marker,label in (('ActionName="CameraReset"',"Q camera reset"),('ActionName="NextClass"',"C class cycle"),('AxisName="MoveForward",Key=W,Scale=1.000000',"W movement"),('AxisName="MoveForward",Key=S,Scale=-1.000000',"S movement"),('AxisName="MoveRight",Key=D,Scale=1.000000',"D movement"),('AxisName="MoveRight",Key=A,Scale=-1.000000',"A movement"),('AxisName="Turn",Key=MouseX,Scale=1.000000',"mouse X"),('AxisName="LookUp",Key=MouseY,Scale=-1.000000',"mouse Y")): require(inputs,marker,label)
    for marker,label in (("Sun->SetIntensity(9.5f)","sun intensity"),("Sun->SetLightColor(FLinearColor(1.0f,0.94f,0.84f))","sun color"),("Sun->SetRelativeRotation(FRotator(-52,-32,0))","sun rotation"),("Sky->SetMobility(EComponentMobility::Movable)","sky light mobility"),("Sky->Intensity=1.9f","sky light intensity"),("USkyAtmosphereComponent","sky atmosphere"),("Fog->FogDensity=0.0025f","fog density"),("Fog->FogHeightFalloff=0.28f","fog height falloff"),("Post->Settings.BloomIntensity=0.55f","bloom"),("Post->Settings.BloomThreshold=1.2f","bloom threshold"),("Post->Settings.VignetteIntensity=0.18f","vignette"),("Post->Settings.MotionBlurAmount=0.0f","motion blur")): require(world,marker,label)
    lock=rules["visual_identity"]["camera_lock"]; assert lock["locked"] and lock["default_pitch_degrees"]==-50.0 and lock["default_yaw_degrees"]==45.0 and lock["target_arm_length"]==900.0 and lock["zoom_min"]==550.0 and lock["zoom_max"]==1350.0 and lock["zoom_step_per_wheel"]==120.0
    sky=rules["visual_identity"]["map_sky_fog_lock"]; assert sky["locked"] and sky["permanent_daylight"] and sky["fog"]["density"]==0.0025 and sky["fog"]["height_falloff"]==0.28
    print("HONOUR WAR CAMERA + SKY/FOG QA"); print("PASS: locked camera, mouse controls, daylight sky and fog values are unchanged and match canonical rules."); return 0
if __name__=="__main__": raise SystemExit(main())
