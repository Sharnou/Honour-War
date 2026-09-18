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
const OnlineAge=preload("res://scripts/OnlineAgeSystem.gd")
const MonsterDetails=preload("res://scripts/MonsterDetailsSystem.gd")
const EventInventory=preload("res://scripts/EventInventorySystem.gd")
const ClassTreeSystem=preload("res://scripts/ClassTreeSystem.gd")
const CharacterProgression=preload("res://scripts/CharacterProgressionSystem.gd")
const ClassFormula=preload("res://scripts/ClassCombatFormula.gd")

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
    var p:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    return p.distance_to(monster.get("pos",p))<=CombatRules.class_engagement_map(hero)

func _pet_in_attack_range(hero:Dictionary,monster:Dictionary)->bool:
    var pet:Dictionary=hero.get("pet",{})
    if pet.is_empty(): return false
    var p:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    return p.distance_to(monster.get("pos",p))<=CombatRules.pet_attack_distance_map(pet)

func decorate_world_monsters(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    for monster in monsters:
        if monster is Dictionary:
            MVPSystem.decorate(monster,rng,int(hero.get("level",1)))
            if not monster.has("attack"): monster["attack"]=max(5,int(monster.get("level",1))*4)
            if not monster.has("defense"): monster["defense"]=max(1,int(monster.get("level",1))*2)
            if not monster.has("max"): monster["max"]=int(monster.get("hp",1))
            monster["attack_range_map"]=CombatRules.monster_attack_distance(monster)
            var details:Dictionary=MonsterDetails.details(monster)
            monster["element"]=details["element"]
            monster["status"]=details["status"]
            monster["poison_resist"]=details["poison_resist"]
            monster["danger"]=details["danger"]

func update_target(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    var p:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    var best=null
    var best_distance:=float(CombatRules.class_rule(hero).get("target_acquire_m",18.0))/CombatRules.WORLD_SCALE
    for monster in monsters:
        if not monster is Dictionary or int(monster.get("hp",0))<=0: continue
        var distance:=p.distance_to(monster.get("pos",p))
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
        var pos:Vector2=monster.get("pos",hero_pos)
        var distance:=hero_pos.distance_to(pos)
        var attack_range:float=CombatRules.monster_attack_distance(monster)
        if distance>CHASE_RANGE or distance<=attack_range or float(monster.get("root_until",0.0))>now_seconds(): continue
        var speed:float=MONSTER_SPEED
        if float(monster.get("slow_until",0.0))>now_seconds(): speed*=0.45
        pos=CombatRules.snap_map_point(pos+pos.direction_to(hero_pos)*speed*delta)
        monster["pos"]=pos

func regenerate_sp(hero:Dictionary)->void:
    if sp_regen_timer<SP_REGEN_INTERVAL: return
    sp_regen_timer=0.0
    var max_sp:int=int(SkillSystem.combat_stats(hero)["max_sp"])
    hero["max_sp"]=max_sp
    hero["sp"]=min(max_sp,int(hero.get("sp",max_sp))+max(1,int(max_sp/20)))

func update_hero_status_effects(hero:Dictionary)->void:
    var now:=now_seconds()
    if float(hero.get("burn_until",0.0))>now and float(hero.get("burn_tick",0.0))<=now:
        hero["burn_tick"]=now+1.0
        hero["hp"]=max(0,int(hero.get("hp",0))-max(1,int(hero.get("burn_damage",4))))
        if int(hero["hp"])<=0: respawn_hero(hero)
    for key in ["curse_until","fear_until","stagger_until","freeze_until","slow_until"]:
        if float(hero.get(key,0.0))<=now: hero.erase(key)

func _hero_can_attack(hero:Dictionary)->bool:
    var now:=now_seconds()
    return float(hero.get("freeze_until",0.0))<=now and float(hero.get("stagger_until",0.0))<=now

func update_status_effects(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    var now:=now_seconds()
    for monster in monsters:
        if not monster is Dictionary: continue
        if float(monster.get("poison_until",0.0))>now and float(monster.get("poison_tick",0.0))<=now:
            monster["poison_tick"]=now+1.0
            monster["hp"]=int(monster.get("hp",0))-max(1,int(monster.get("poison_damage",3)))
        if float(monster.get("burn_until",0.0))>now and float(monster.get("burn_tick",0.0))<=now:
            monster["burn_tick"]=now+1.0
            monster["hp"]=int(monster.get("hp",0))-max(1,int(monster.get("burn_damage",4)))
        if int(monster.get("hp",0))<=0: finish_monster(monster)

func effective_monster_defense(monster:Dictionary)->int:
    var defense:=max(0,int(monster.get("defense",0)))
    if float(monster.get("defense_break_until",0.0))>now_seconds():
        defense=int(round(float(defense)*(1.0-clamp(float(monster.get("defense_break_percent",0.0)),0.0,0.80))))
    return defense

func hero_strike(hero:Dictionary,monster:Dictionary)->void:
    var stats:Dictionary=SkillSystem.combat_stats(hero)
    var class_id:=str(hero.get("class","Warrior"))
    var power:int=ClassFormula.magic_power(hero) if class_id in ["Mage","Acolyte"] else ClassFormula.physical_power(hero)
    power=max(1,power+int(stats.get("power_bonus",0)))
    var branch_bonus:Dictionary=ClassTreeSystem.branch_bonus(hero)
    power=int(round(float(power)*(1.0+float(branch_bonus.get("damage",0.0)))))
    var critical:bool=rng.randi_range(1,100)<=min(75,int(stats.get("crit_bonus",0))+int(hero.get("age_crit_bonus",0))+int(branch_bonus.get("crit",0.0)))
    var damage:=power+rng.randi_range(0,9)
    if critical: damage=int(float(damage)*1.75)
    var damage:=max(1,damage-effective_monster_defense(monster))
    if float(hero.get("fear_until",0.0))>now_seconds():
        damage=max(1,int(round(float(damage)*0.55)))
    monster["hp"]=int(monster.get("hp",0))-damage
    if class_id=="Thief" and rng.randf()<0.35: MonsterDetails.apply_poison(monster,damage,6.0)
    if class_id=="Mage" and rng.randf()<0.20: monster["slow_until"]=now_seconds()+3.0
    hero_attack_landed.emit(monster,damage,critical)
    if int(monster["hp"])<=0: finish_monster(monster)

func pet_strike(hero:Dictionary,monster:Dictionary)->void:
    var pet:Dictionary=hero.get("pet",{})
    if pet.is_empty() or int(pet.get("hp",0))<=0: return
    var damage:=max(1,int(PetSystem.power(pet))+rng.randi_range(0,7))
    var special:bool=int(pet.get("skill_uses",0))%5==0
    if special: damage+=PetSystem.skill_power(pet)
    pet["skill_uses"]=int(pet.get("skill_uses",0))+1
    damage=max(1,damage-effective_monster_defense(monster))
    monster["hp"]=int(monster.get("hp",0))-damage
    pet_attack_landed.emit(monster,damage,special)
    if int(monster["hp"])<=0: finish_monster(monster)

func monster_phase(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    for monster in monsters:
        if not monster is Dictionary or int(monster.get("hp",0))<=0: continue
        if hero_pos.distance_to(monster.get("pos",hero_pos))>CombatRules.monster_attack_distance(monster): continue
        var attack:int=max(1,int(monster.get("attack",int(monster.get("level",1))*4)))
        if bool(monster.get("mvp",false)): attack=int(float(attack)*1.25)
        var branch_bonus:Dictionary=ClassTreeSystem.branch_bonus(hero)
        var defense:=int(round(float(ClassFormula.defense(hero)+int(hero.get("refine",0)))*(1.0+float(branch_bonus.get("defense",0.0)))))
        var damage:=max(1,attack-defense)
        var mvp_details:Dictionary=MonsterDetails.details(monster)
        var status_name:String=str(mvp_details.get("status",""))
        var status_chance:float=float(mvp_details.get("status_chance",0.0))
        if bool(monster.get("mvp",false)) and status_name!="" and status_name!="None" and rng.randf()<status_chance:
            if status_name.contains("Fear"):
                hero["fear_until"]=max(float(hero.get("fear_until",0.0)),now_seconds()+3.0)
                hero["fear_duration"]=3.0
            if status_name.contains("Curse"):
                hero["curse_until"]=max(float(hero.get("curse_until",0.0)),now_seconds()+3.0)
            if status_name.contains("Stagger"):
                hero["stagger_until"]=max(float(hero.get("stagger_until",0.0)),now_seconds()+1.5)
            if status_name.contains("Freeze"):
                hero["freeze_until"]=max(float(hero.get("freeze_until",0.0)),now_seconds()+2.0)
            if status_name.contains("Slow"):
                hero["slow_until"]=max(float(hero.get("slow_until",0.0)),now_seconds()+3.0)
        hero["hp"]=max(0,int(hero.get("hp",0))-damage)
        monster_attack_landed.emit("hero",damage)
        if int(hero["hp"])<=0: respawn_hero(hero)
        if str(monster.get("name",""))==CicciEvent.BOSS_NAME:
            CicciManager.on_cicci_hit(game,int(Time.get_unix_time_from_system()))

func mvp_skill_phase(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    for monster in monsters:
        if not monster is Dictionary or not bool(monster.get("mvp",false)) or int(monster.get("hp",0))<=0: continue
        if hero_pos.distance_to(monster.get("pos",hero_pos))>190.0: continue
        var damage:=max(1,int(monster.get("attack",100))*2-ClassFormula.defense(hero))
        hero["hp"]=max(0,int(hero.get("hp",0))-damage)
        monster_attack_landed.emit("hero",damage)
        if int(hero["hp"])<=0: respawn_hero(hero)

func revive_pet(hero:Dictionary)->void:
    var pet:Dictionary=hero.get("pet",{})
    pet["hp"]=max(1,int(pet.get("max_hp",60))/2)
    hero["pet"]=pet

func finish_monster(monster:Dictionary)->void:
    if game.has_method("defeat_monster"): game.call("defeat_monster",monster)
    var hero=game.get("hero")
    if hero is Dictionary:
        EventInventory.record_monster(hero,monster)
        var gained:Array=LootSystem.on_monster_defeated(hero,monster,rng)
        if gained.size()>0: game.call("log_message","Auto-loot: %s" % ", ".join(gained))
        SaveSystem.save_game(hero)
    target=null
    target_changed.emit({})

func respawn_hero(hero:Dictionary)->void:
    hero["hp"]=hero.get("max_hp",100)
    hero["sp"]=hero.get("max_sp",50)
    hero["pos_x"]=595.0
    hero["pos_y"]=340.0
    if hero.get("pet",{}) is Dictionary: hero["pet"]["hp"]=hero["pet"].get("max_hp",60)

func call_vfx(kind:String,position:Vector2,label:String,critical:bool)->void:
    if game and game.has_method("play_combat_effect"): game.call("play_combat_effect",kind,position,label,critical)

func now_seconds()->float:
    return Time.get_ticks_msec()/1000.0
