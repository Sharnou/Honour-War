extends Node

## Deterministic runtime audio. Sounds are synthesized from known waveforms at
## startup, keeping the repository self-contained and avoiding unknown assets.
const SAMPLE_RATE:int=22050
var players:Dictionary={}

func _ready()->void:
    for kind in ["hit","skill","level","town"]:
        var p:=AudioStreamPlayer.new()
        p.name="SFX_"+kind
        p.stream=_build_sound(kind)
        add_child(p)
        players[kind]=p

func _build_sound(kind:String)->AudioStreamWAV:
    var duration:float=0.45
    var frames=PackedByteArray()
    var count:int=int(duration*float(SAMPLE_RATE))
    frames.resize(count*2)
    for i in count:
        var t:float=float(i)/float(SAMPLE_RATE)
        var sample:float=0.0
        if kind=="hit":
            var f:float=180.0+420.0*exp(-10.0*t)
            sample=sin(TAU*f*t)*exp(-8.0*t)
        elif kind=="skill":
            var f:float=440.0+220.0*sin(TAU*4.0*t)
            var env:float=pow(sin(PI*minf(1.0,t/duration)),0.8)
            sample=(0.65*sin(TAU*f*t)+0.25*sin(TAU*2.0*f*t))*env
        elif kind=="level":
            var f:float=420.0+600.0*(t/duration)
            sample=0.7*sin(TAU*f*t)*sin(PI*t/duration)
        else:
            var f:float=330.0+110.0*sin(TAU*2.0*t)
            sample=0.45*sin(TAU*f*t)*exp(-1.5*t)
        var value:int=clampi(int(sample*30000.0),-32767,32767)
        frames[i*2]=value & 255
        frames[i*2+1]=(value>>8) & 255
    var wav:=AudioStreamWAV.new()
    wav.format=AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate=SAMPLE_RATE
    wav.stereo=false
    wav.data=frames
    return wav

func play_sfx(kind:String)->void:
    var value:Variant=players.get(kind,null)
    if not is_instance_valid(value) or not value is AudioStreamPlayer:
        return
    var p:AudioStreamPlayer=value as AudioStreamPlayer
    p.play()

func play_hit()->void: play_sfx("hit")
func play_skill()->void: play_sfx("skill")
func play_level_up()->void: play_sfx("level")
func play_town()->void: play_sfx("town")
