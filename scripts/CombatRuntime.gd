class_name CombatRuntime
extends Node

const CombatRules=preload("res://scripts/CombatRules.gd")
const SkillSystem=preload("res://scripts/SkillSystem.gd")
const LootSystem=preload("res://scripts/LootSystem.gd")
const MVPSystem=preload("res://scripts/MVPSystem.gd")
const SaveSystem=preload("res://scripts/SaveSystem.gd")
const PetSystem=preload("res://scripts/PetSystem.gd")
const CicciEvent=preload("res://scripts/CicciWeeklyEvent.gd")
const CicciManager=preload("res://scripts/CicciWeeklyEventManager.gd")

signal hero_attack_landed(target:Dictionary,damage:int,critical:bool)
signal pet_attack_landed(target:Dictionary,damage:int,special:bool)
signal monster_attack_landed(target_kind:String,damage:int)
signal target_changed(target:Dictionary)

const HERO_ATTACK_INTERVAL:=0.72
const PET_ATTACK_INTERVAL:=1.15
const MONSTER_ATTACK_INTERVAL:=1.10
const SP_REGEN_INTERVAL:=1.0
const CHASE_RANGE:=260.0
const MONSTER_SPEED:=42.0
const OnlineAge=preload("res://scripts/OnlineAgeSystem.gd")
const MonsterDetails=preload("res://scripts/MonsterDetailsSystem.gd")
const EventInventory=preload("res://scripts/EventInventorySystem.gd")
const ClassTreeSystem=preload("res://scripts/ClassTreeSystem.gd")
const CharacterProgression=preload("res://scripts/CharacterProgressionSystem.gd")
const ClassFormula=preload("res://scripts/ClassCombatFormula.gd")

var game:Node
var hero_attack_timer:=0.0
var pet_attack_timer:=0.0
var monster_attack_timer:=0.0
var sp_regen_timer:=0.0
var mvp_skill_timer:=0.0
var target
var rng:=RandomNumberGenerator.new()

func _ready()->void:
    game=get_parent()
    rng.randomize()
    set_process(true)

func _process(delta:float)->void:
    if game==null or not game.get("hero") is Dictionary: return
    var hero:Dictionary=game.get("hero")
    OnlineAge.normalize(hero)
    _apply_age_power(hero)
    CicciManager.ensure_event(game)
    hero_attack_timer+=delta
    pet_attack_timer+=delta
    monster_attack_timer+=delta
    sp_regen_timer+=delta
    mvp_skill_timer+=delta
    if game.get("pet_attack_timer") != null: game.set("pet_attack_timer",0.0)
    SkillSystem.ensure_state(hero)
    LootSystem.ensure_state(hero)
    EventInventory.ensure_inventory(hero)
    decorate_world_monsters(hero)
    update_target(hero)
    move_monsters(delta,hero)
    regenerate_sp(hero)
    update_status_effects(hero)
    update_hero_status_effects(hero)
    var hero_interval:float=CombatRules.class_attack_interval(hero)
    if float(hero.get("slow_until",0.0))>now_seconds(): hero_interval*=1.35
    if target!=null and hero_attack_timer>=hero_interval and _hero_in_attack_range(hero,target) and _hero_can_attack(hero):
        hero_attack_timer=0.0
        hero_strike(hero,target)
    if target!=null and pet_attack_timer>=CombatRules.pet_attack_interval(hero.get("pet",{})) and _pet_in_attack_range(hero,target):
        pet_attack_timer=0.0
        pet_strike(hero,target)
    if monster_attack_timer>=MONSTER_ATTACK_INTERVAL:
        monster_attack_timer=0.0
        monster_phase(hero)
    if mvp_skill_timer>=7.0:
        mvp_skill_timer=0.0
        mvp_skill_phase(hero)

func _apply_age_power(hero:Dictionary)->void:
    var growth:Dictionary=OnlineAge.strength_bonus(hero)
    hero["age_power_bonus"]=int(growth["atk"])
    hero["age_defense_bonus"]=int(growth["def"])
    hero["age_hp_bonus"]=int(growth["hp"])
    hero["age_sp_bonus"]=int(growth["sp"])
    var live_stats:Dictionary=CharacterProgression.stats(hero)
    hero["max_hp"]=max(1,int(live_stats.get("max_hp",100)))
    hero["max_sp"]=max(1,int(live_stats.get("max_sp",50)))
    hero["hp"]=clampi(int(hero.get("hp",hero["max_hp"])),0,int(hero["max_hp"]))
    hero["sp"]=clampi(int(hero.get("sp",hero["max_sp"])),0,int(hero["max_sp"]))

func _hero_in_attack_range(hero:Dictionary,monster:Dictionary)->bool:
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    return hero_pos.distance_to(monster.get("pos",hero_pos))<=CombatRules.class_engagement_map(hero)

func _pet_in_attack_range(hero:Dictionary,monster:Dictionary)->bool:
    var pet:Dictionary=hero.get("pet",{})
    if pet.is_empty(): return false
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    return hero_pos.distance_to(monster.get("pos",hero_pos))<=CombatRules.pet_attack_distance_map(pet)

func decorate_world_monsters(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    for monster in monsters:
        if monster is Dictionary:
            MVPSystem.decorate(monster,rng,int(hero.get("level",1)))
            if not monster.has("attack"): monster["attack"]=max(5,int(monster.get("level",1))*4)
            if not monster.has("defense"): monster["defense"]=max(1,int(monster.get("level",1))*2)
            if not monster.has("max"): monster["max"]=int(monster.get("hp",1))
            if not monster.has("attack_type"): monster["attack_type"]="Ranged" if bool(monster.get("ranged",false)) else "Melee"
            monster["attack_range_map"]=CombatRules.monster_attack_distance(monster)
            var details:Dictionary=MonsterDetails.details(monster)
            monster["element"]=details["element"]
            monster["status"]=details["status"]
            monster["poison_resist"]=details["poison_resist"]
            monster["danger"]=details["danger"]

func update_target(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array:
        if target!=null: target=null; target_changed.emit({})
        return
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    var acquire:float=float(CombatRules.class_rule(hero).get("target_acquire_m",18.0))/CombatRules.WORLD_SCALE
    var best=null
    var best_distance:=acquire
    for monster in monsters:
        if not monster is Dictionary or int(monster.get("hp",0))<=0: continue
        var distance:=hero_pos.distance_to(monster.get("pos",hero_pos))
        if distance<best_distance:
            best=monster
            best_distance=distance
    if best!=target:
        target=best
        target_changed.emit(target if target is Dictionary else {})

func move_monsters(delta:float,hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    for monster in monsters:
        if not monster is Dictionary or int(monster.get("hp",0))<=0: continue
        var monster_pos:Vector2=monster["pos"]
        var distance:float=hero_pos.distance_to(monster_pos)
        var attack_range:float=CombatRules.monster_attack_distance(monster)
        if distance>CHASE_RANGE or distance<=attack_range: continue
        if float(monster.get("root_until",0.0))>now_seconds(): continue
        var direction:Vector2=monster_pos.direction_to(hero_pos)
        var speed:float=MONSTER_SPEED
        if float(monster.get("slow_until",0.0))>now_seconds(): speed*=0.45
        if bool(monster.get("mvp",false)): speed*=0.90
        monster_pos=CombatRules.snap_map_point(monster_pos+direction*speed*delta)
        monster_pos.x=clamp(monster_pos.x,365.0,1107.0)
        monster_pos.y=clamp(monster_pos.y,120.0,420.0)
        monster["pos"]=monster_pos

func regenerate_sp(hero:Dictionary)->void:
    if sp_regen_timer<SP_REGEN_INTERVAL: return
    sp_regen_timer=0.0
    var stats:Dictionary=SkillSystem.combat_stats(hero)
    var max_sp:int=int(stats["max_sp"])
    hero["max_sp"]=max_sp
    hero["sp"]=min(int(hero["max_sp"]),int(hero.get("sp",hero["max_sp"]))+max(1,int(max_sp/20)))
    if hero.get("pet",{}) is Dictionary:
        var pet:Dictionary=hero["pet"]
        pet["sp"]=min(int(pet.get("max_sp",30)),int(pet.get("sp",30))+1)

func update_hero_status_effects(hero:Dictionary)->void:
    var now:float=now_seconds()
    if float(hero.get("burn_until",0.0))>now and float(hero.get("burn_tick",0.0))<=now:
        hero["burn_tick"]=now+1.0
        var burn_damage:int=max(1,int(hero.get("burn_damage",4)))
        hero["hp"]=max(0,int(hero.get("hp",0))-burn_damage)
        call_vfx("hit",Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0))),str(burn_damage),false)
        if int(hero.get("hp",0))<=0: respawn_hero(hero)
    if float(hero.get("curse_until",0.0))<=now: hero.erase("curse_until")
    if float(hero.get("fear_until",0.0))<=now: hero.erase("fear_until")
    if float(hero.get("stagger_until",0.0))<=now: hero.erase("stagger_until")
    if float(hero.get("freeze_until",0.0))<=now: hero.erase("freeze_until")
    if float(hero.get("slow_until",0.0))<=now: hero.erase("slow_until")

func _hero_can_attack(hero:Dictionary)->bool:
    var now:float=now_seconds()
    return float(hero.get("freeze_until",0.0))<=now and float(hero.get("stagger_until",0.0))<=now

func update_status_effects(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    var now:float=now_seconds()
    for monster in monsters.duplicate():
        if not monster is Dictionary: continue
        if float(monster.get("poison_until",0.0))>now and float(monster.get("poison_tick",0.0))<=now:
            monster["poison_tick"]=now+1.0
            var poison_damage:int=max(1,int(monster.get("poison_damage",int(hero.get("level",1))/2+3)))
            monster["hp"]=int(monster.get("hp",0))-poison_damage
            call_vfx("hit",monster["pos"],str(poison_damage),false)
            if int(monster["hp"])<=0:
                finish_monster(monster)
                continue
        if float(monster.get("burn_until",0.0))>now and float(monster.get("burn_tick",0.0))<=now:
            monster["burn_tick"]=now+1.0
            var burn_damage:int=max(1,int(monster.get("burn_damage",4)))
            monster["hp"]=int(monster.get("hp",0))-burn_damage
            call_vfx("hit",monster["pos"],str(burn_damage),false)
            if int(monster["hp"])<=0: finish_monster(monster)

func effective_monster_defense(monster:Dictionary)->int:
    var defense:int=max(0,int(monster.get("defense",0)))
    var now:float=now_seconds()
    if float(monster.get("defense_break_until",0.0))>now:
        var break_percent:float=clamp(float(monster.get("defense_break_percent",0.0)),0.0,0.80)
        defense=int(round(float(defense)*(1.0-break_percent)))
    return defense

func now_seconds()->float: return Time.get_ticks_msec()/1000.0
