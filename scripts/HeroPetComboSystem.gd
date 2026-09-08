class_name HeroPetComboSystem
extends Node

signal combo_changed(count:int, grade:String)
signal combo_triggered(name:String, count:int)
signal finisher_executed(damage:int, target:Node)

@export var combo_timeout:float=2.2
@export var max_combo:int=30
@export var synergy_threshold:int=5
@export var finisher_cooldown_duration:float=8.0

var game:Node
var combat:Node
var events:Node
var combo_count:int=0
var last_actor:String=""
var last_event_time:float=0.0
var last_target:Dictionary={}
var finisher_cooldown:float=0.0

func _ready()->void:
    game=get_parent()
    combat=game.get_node_or_null("LegacyGame/CombatRuntime") if game else null
    events=game.get_node_or_null("CombatEventBus") if game else null
    if events:
        events.hero_attack_landed.connect(_on_hero_attack)
        events.pet_attack_landed.connect(_on_pet_attack)

func _process(delta:float)->void:
    if finisher_cooldown>0.0: finisher_cooldown=max(0.0,finisher_cooldown-delta)
    _decay()

func _on_hero_attack(target:Dictionary,damage:int,critical:bool)->void:
    _register_hit("hero",target)
    if game and game.has_method("log_message") and critical:
        game.call("log_message","Bond link: Hero critical strike landed for %d." % damage)

func _on_pet_attack(target:Dictionary,damage:int,special:bool)->void:
    _register_hit("pet",target)
    if game and game.has_method("log_message") and special:
        game.call("log_message","Bond link: Pet special strike landed for %d." % damage)

func _register_hit(actor:String,target:Dictionary)->void:
    var now:float=Time.get_ticks_msec()/1000.0
    if target!=last_target:
        last_target=target
        combo_count=0
        last_actor=""
    if last_event_time<=0.0 or now-last_event_time>combo_timeout or actor==last_actor:
        combo_count=1
    else:
        combo_count=min(max_combo,combo_count+1)
    last_actor=actor
    last_event_time=now
    _apply_synergy(target)
    var grade:String=_grade()
    combo_changed.emit(combo_count,grade)
    if combo_count in [5,10,15,20,25,30]:
        var name:String="Bond Combo %d" % combo_count
        combo_triggered.emit(name,combo_count)
        if game and game.has_method("log_message"):
            game.call("log_message","%s! Hero + Pet synchronized hits reached %d." % [name,combo_count])

func _apply_synergy(target:Dictionary)->void:
    var now:float=Time.get_ticks_msec()/1000.0
    var hero_value:Variant=game.get("hero") if game else null
    if not hero_value is Dictionary: return
    var hero:Dictionary=hero_value
    if combo_count>=synergy_threshold:
        hero["temporary_power_until"]=max(float(hero.get("temporary_power_until",0.0)),now+0.45)
        hero["combo_power_bonus"]=min(0.35,float(combo_count)*0.01)
        var pet_value:Variant=hero.get("pet",{})
        if pet_value is Dictionary:
            var pet:Dictionary=pet_value
            pet["combo_power_bonus"]=min(0.35,float(combo_count)*0.01)
            pet["combo_until"]=now+0.8
        target["bond_mark_until"]=now+0.9
        target["bond_mark_bonus"]=min(0.30,float(combo_count)*0.01)

func force_finisher()->bool:
    if combo_count<synergy_threshold or finisher_cooldown>0.0 or combat==null: return false
    var target_value:Variant=combat.get("target")
    if not target_value is Dictionary: return false
    var target:Dictionary=target_value
    if int(target.get("hp",0))<=0: return false
    var hero_value:Variant=game.get("hero") if game else null
    if not hero_value is Dictionary: return false
    var hero:Dictionary=hero_value
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return false
    var pet:Dictionary=pet_value
    if int(pet.get("hp",0))<=0: return false
    var hero_stats:Dictionary=SkillSystem.combat_stats(hero)
    var pet_stats:Dictionary=PetSkillSystem.combat_stats(pet)
    var bond_multiplier:float=1.0+min(0.75,float(combo_count)*0.025)
    var hero_power:int=int(hero.get("level",1))*4+int(hero.get("refine",0))*3+int(hero_stats.get("power_bonus",0))
    var pet_power:int=PetSystem.power(pet)+int(pet.get("level",1))*2
    var damage:int=max(10,int(float(hero_power+pet_power)*bond_multiplier))
    damage=int(float(damage)*float(pet_stats.get("damage_multiplier",1.0))*1.15)
    damage=max(10,damage-int(target.get("defense",0))/2)
    target["hp"]=int(target.get("hp",0))-damage
    target["hit_flash"]=0.45
    target["bond_mark_until"]=Time.get_ticks_msec()/1000.0+2.0
    target["bond_mark_bonus"]=min(0.50,float(combo_count)*0.015)
    finisher_cooldown=finisher_cooldown_duration
    combo_count=max(0,combo_count-5)
    last_event_time=Time.get_ticks_msec()/1000.0
    combo_changed.emit(combo_count,_grade())
    combo_triggered.emit("Bond Finisher",combo_count)
    if events: events.emit_finisher(target,damage)
    var position:Vector2=target.get("pos",Vector2.ZERO)
    var feedback:Node=game.get_node_or_null("HDCombatFeedback") if game else null
    if feedback:
        var world_position:=Vector3((position.x-595.0)*0.055,1.0,(position.y-340.0)*0.055)
        feedback.show_telegraph("circle",world_position,4.5,0.8)
        feedback.play_skill_effect("bond_finisher",world_position)
        feedback.show_damage(damage,world_position,true)
    if game.has_method("show_3d_combat_number"): game.call("show_3d_combat_number",position,damage,true,"enemy")
    var vfx:Node=game.get_node_or_null("PetSkillVFX")
    if vfx and vfx.has_method("play"):
        vfx.play(str(pet.get("species","Wolf Cub")),"bond_finisher",Vector3((position.x-595.0)*0.055,0.9,(position.y-340.0)*0.055),4.5)
    if game.has_method("log_message"): game.call("log_message","BOND FINISHER! Hero and %s deal %d synchronized damage." % [str(pet.get("name","Pet")),damage])
    if int(target.get("hp",0))<=0 and combat.has_method("finish_monster"): combat.call("finish_monster",target)
    finisher_executed.emit(damage,null)
    return true

func _decay()->void:
    if combo_count<=0 or last_event_time<=0.0: return
    if Time.get_ticks_msec()/1000.0-last_event_time>combo_timeout:
        combo_count=0
        last_actor=""
        combo_changed.emit(0,"None")

func get_grade()->String:
    return _grade()

func _grade()->String:
    if combo_count>=25: return "Legendary"
    if combo_count>=20: return "Mythic"
    if combo_count>=15: return "Epic"
    if combo_count>=10: return "Great"
    if combo_count>=5: return "Good"
    return "Building"
