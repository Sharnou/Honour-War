class_name HeroPetComboSystem
extends Node

signal combo_changed(count:int, grade:String)
signal combo_triggered(name:String, count:int)

@export var combo_timeout:float=2.2
@export var max_combo:int=30
@export var synergy_threshold:int=5

var game:Node
var combat:Node
var combo_count:int=0
var last_actor:String=""
var last_event_time:float=0.0
var last_target:Dictionary={}
var last_target_hp:int=-1
var last_pet_uses:int=-1
var last_hero_timer:float=0.0
var finisher_cooldown:float=0.0

func _ready()->void:
    game=get_parent()
    combat=game.get_node_or_null("LegacyGame/CombatRuntime") if game else null

func _process(_delta:float)->void:
    if game==null or combat==null: return
    var hero_value:Variant=game.get("hero")
    if not hero_value is Dictionary: return
    var hero:Dictionary=hero_value
    var target_value:Variant=combat.get("target")
    if not target_value is Dictionary:
        _decay()
        return
    var target:Dictionary=target_value
    var target_changed:bool=target!=last_target
    if target_changed:
        last_target=target
        last_target_hp=int(target.get("hp",0))
    var pet_value:Variant=hero.get("pet",{})
    var pet:Dictionary=pet_value if pet_value is Dictionary else {}
    var pet_uses:int=int(pet.get("skill_uses",0))
    var pet_event:bool=last_pet_uses>=0 and pet_uses>last_pet_uses
    last_pet_uses=pet_uses
    var hero_timer:float=float(combat.get("hero_attack_timer"))
    var hero_event:bool=last_hero_timer>0.55 and hero_timer<0.12
    last_hero_timer=hero_timer
    var hp_now:int=int(target.get("hp",0))
    var damage_event:bool=last_target_hp>=0 and hp_now<last_target_hp
    last_target_hp=hp_now
    if damage_event:
        if pet_event and not hero_event:
            _register_hit("pet",target)
        elif hero_event and not pet_event:
            _register_hit("hero",target)
        elif last_actor=="hero":
            _register_hit("pet",target)
        else:
            _register_hit("hero",target)
    if finisher_cooldown>0.0: finisher_cooldown=max(0.0,finisher_cooldown-_delta)
    if combo_count>=synergy_threshold:
        _apply_synergy(hero,target)

func _register_hit(actor:String,target:Dictionary)->void:
    var now:float=Time.get_ticks_msec()/1000.0
    if last_event_time<=0.0 or now-last_event_time>combo_timeout or actor==last_actor:
        combo_count=1
    else:
        combo_count=min(max_combo,combo_count+1)
    last_actor=actor
    last_event_time=now
    var grade:String=_grade()
    combo_changed.emit(combo_count,grade)
    if combo_count in [5,10,15,20,25,30]:
        var name:String="Bond Combo %d" % combo_count
        combo_triggered.emit(name,combo_count)
        if game.has_method("log_message"):
            game.call("log_message","%s! Hero + Pet synergy reached %d hits." % [name,combo_count])

func _apply_synergy(hero:Dictionary,target:Dictionary)->void:
    var now:float=Time.get_ticks_msec()/1000.0
    hero["temporary_power_until"]=max(float(hero.get("temporary_power_until",0.0)),now+0.45)
    hero["combo_power_bonus"]=min(0.35,float(combo_count)*0.01)
    var pet_value:Variant=hero.get("pet",{})
    if pet_value is Dictionary:
        var pet:Dictionary=pet_value
        pet["combo_power_bonus"]=min(0.35,float(combo_count)*0.01)
        pet["combo_until"]=now+0.8
    if target is Dictionary:
        target["bond_mark_until"]=now+0.9
        target["bond_mark_bonus"]=min(0.30,float(combo_count)*0.01)

func force_finisher()->bool:
    if combo_count<synergy_threshold or finisher_cooldown>0.0: return false
    finisher_cooldown=8.0
    combo_count=max(0,combo_count-3)
    combo_triggered.emit("Bond Finisher",combo_count)
    if game.has_method("log_message"):
        game.call("log_message","Bond Finisher activated: hero and pet unleash synchronized power!")
    return true

func _decay()->void:
    if combo_count<=0 or last_event_time<=0.0: return
    if Time.get_ticks_msec()/1000.0-last_event_time>combo_timeout:
        combo_count=0
        last_actor=""
        combo_changed.emit(0,"None")

func _grade()->String:
    if combo_count>=25: return "Legendary"
    if combo_count>=20: return "Mythic"
    if combo_count>=15: return "Epic"
    if combo_count>=10: return "Great"
    if combo_count>=5: return "Good"
    return "Building"
