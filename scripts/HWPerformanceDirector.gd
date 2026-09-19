class_name HWPerformanceDirector
extends Node

## Production performance policy: preserve Forward+ quality while controlling
## expensive effects on weaker hardware. No gameplay state is changed.
var quality:int=2
var frame_accum:float=0.0
var samples:int=0
var fps_ema:float=60.0

func _ready()->void:
    process_priority=1000
    quality=2

func _process(delta:float)->void:
    if delta<=0.0: return
    frame_accum+=delta
    samples+=1
    fps_ema=lerp(fps_ema,1.0/delta,0.04)
    if frame_accum>=3.0:
        frame_accum=0.0
        _apply_policy()

func _apply_policy()->void:
    var target:=60.0 if quality>=2 else 45.0
    if fps_ema<target*0.72 and quality>0:
        quality-=1
    elif fps_ema>target*1.12 and quality<2:
        quality+=1
    RenderingServer.set_default_clear_color(Color(0.035,0.045,0.065,1.0))
