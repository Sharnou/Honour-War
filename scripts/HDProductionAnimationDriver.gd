class_name HDProductionAnimationDriver
extends Node

## Drives AnimationPlayer clips inside imported GLB/GLTF actors.
## Expected clips: Idle, Walk, Run, Attack, Critical, Cast, Skill, Hit, Death.
var game:Node
var last_hero_visual:Node3D
var last_hero_anim:String=""
var monster_state:Dictionary={}

func _ready()->void:
    game=get_parent()
    set_process(true)

func _process(_delta:float)->void:
    if game==null: return
    _drive_hero()
    _drive_monsters()

func _drive_hero()->void:
    var hero:Node3D=game.get("hero_visual") as Node3D
    if hero==null or not is_instance_valid(hero): return
    if not bool(hero.get_meta("hw_production_asset",false)): return
    var legacy:Node=game.get("legacy") as Node
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero_data:Dictionary=value
    var desired:String="Idle"
    var pos:Vector2=Vector2(float(hero_data.get("pos_x",0.0)),float(hero_data.get("pos_y",0.0)))
    var last:Vector2=hero_data.get("hd_last_anim_pos",pos)
    var speed:float=pos.distance_to(last)
    hero_data["hd_last_anim_pos"]=pos
    if speed>0.25: desired="Run" if speed>8.0 else "Walk"
    if int(hero_data.get("hp",1))<=0: desired="Death"
    if desired!=last_hero_anim or hero!=last_hero_visual:
        _play_clip(hero,desired)
        last_hero_anim=desired
        last_hero_visual=hero

func _drive_monsters()->void:
    var visuals:Variant=game.get("monster_visuals")
    var legacy:Node=game.get("legacy") as Node
    if not visuals is Dictionary or legacy==null: return
    var monsters_value:Variant=legacy.get("monsters")
    var hero_value:Variant=legacy.get("hero")
    if not monsters_value is Array: return
    var hero_pos:=Vector2.ZERO
    if hero_value is Dictionary:
        hero_pos=Vector2(float(hero_value.get("pos_x",0.0)),float(hero_value.get("pos_y",0.0)))
    var live:Dictionary={}
    for monster in monsters_value:
        if not monster is Dictionary: continue
        var id:String=str(monster.get("id",monster.get("visual_id",monster.get("name","monster"))))
        if id.is_empty() or not visuals.has(id): continue
        var visual:Node3D=visuals[id] as Node3D
        if visual==null or not is_instance_valid(visual): continue
        if not bool(visual.get_meta("hw_production_asset",false)): continue
        live[id]=true
        var hp:int=int(monster.get("hp",0))
        var previous:int=int(monster_state.get(id,hp))
        var desired:String="Idle"
        var pos:Vector2=monster.get("pos",Vector2.ZERO)
        if hp<=0:
            desired="Death"
        elif hp<previous:
            desired="Hit"
        elif pos.distance_to(hero_pos)<70.0:
            desired="Attack"
        elif pos.distance_to(hero_pos)<260.0:
            desired="Walk"
        _play_clip_when_changed(id,visual,desired)
        monster_state[id]=hp
    for id in monster_state.keys():
        if not live.has(id): monster_state.erase(id)

func _play_clip_when_changed(id:String,actor:Node3D,clip:String)->void:
    var state_key:String="clip:"+id
    var current:String=str(monster_state.get(state_key,""))
    if current==clip: return
    _play_clip(actor,clip)
    monster_state[state_key]=clip

func _play_clip(actor:Node3D,clip:String)->void:
    var player:=_find_animation_player(actor)
    if player==null: return
    var names:PackedStringArray=player.get_animation_list()
    var wanted:Array[String]=[clip,clip.to_lower(),clip.capitalize()]
    for candidate in wanted:
        if names.has(candidate):
            player.play(candidate)
            return
    if names.has("Idle"):
        player.play("Idle")
    elif names.has("idle"):
        player.play("idle")

func _find_animation_player(root:Node)->AnimationPlayer:
    for child in root.get_children():
        if child is AnimationPlayer:
            return child as AnimationPlayer
        var nested:AnimationPlayer=_find_animation_player(child)
        if nested!=null: return nested
    return null
