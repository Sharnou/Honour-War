class_name CombatRuntime
extends Node

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
    var hero_interval:float=CombatRules.class_attack_interval(hero)
    if target!=null and hero_attack_timer>=hero_interval and _hero_in_attack_range(hero,target):
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
    hero["max_hp"]=max(1,int(hero.get("base_max_hp",100))+int(growth["hp"]))
    hero["max_sp"]=max(1,int(hero.get("base_max_sp",50))+int(growth["sp"]))
    hero["hp"]=min(int(hero.get("hp",hero["max_hp"])),int(hero["max_hp"]))
    hero["sp"]=min(int(hero.get("sp",hero["max_sp"])),int(hero["max_sp"]))

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
    hero["max_sp"]=max_sp+int(hero.get("age_sp_bonus",0))
    hero["sp"]=min(int(hero["max_sp"]),int(hero.get("sp",hero["max_sp"]))+max(1,int(max_sp/20)))
    if hero.get("pet",{}) is Dictionary:
        var pet:Dictionary=hero["pet"]
        pet["sp"]=min(int(pet.get("max_sp",30)),int(pet.get("sp",30))+1)

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
            if int(monster["hp"])<=0: finish_monster(monster)

func hero_strike(hero:Dictionary,monster:Dictionary)->void:
    if int(hero.get("hp",0))<=0: return
    var class_id:=str(hero.get("class","Warrior"))
    var base:=18
    match class_id:
        "Warrior": base=18
        "Mage": base=23
        "Archer": base=20
        "Ranger": base=22
        "Thief": base=19
        "Acolyte": base=15
        "Merchant": base=17
    var passive:Dictionary=SkillSystem.combat_stats(hero)
    var power:int=base+int(hero.get("level",1))*2+int(hero.get("refine",0))*2+int(passive["power_bonus"])+int(hero.get("age_power_bonus",0))
    if float(hero.get("temporary_power_until",0.0))>now_seconds(): power=int(float(power)*1.30)
    var combo_bonus:float=float(hero.get("combo_power_bonus",0.0))
    if combo_bonus>0.0: power=int(float(power)*(1.0+min(0.35,combo_bonus)))
    var critical_chance:int=int(passive["crit_bonus"])+int(hero.get("age_crit_bonus",0))
    if class_id=="Thief": critical_chance+=10
    if class_id=="Archer" or class_id=="Ranger": critical_chance+=6
    var critical:bool=rng.randi_range(1,100)<=min(75,critical_chance)
    var damage:int=power+rng.randi_range(0,9)
    if critical: damage=int(float(damage)*1.75)
    damage=max(1,damage-int(monster.get("defense",0)))
    monster["hp"]=int(monster.get("hp",0))-damage
    monster["hit_flash"]=0.16
    if class_id=="Thief" and rng.randf()<0.35: MonsterDetails.apply_poison(monster,damage,6.0)
    if class_id=="Mage" and rng.randf()<0.20: monster["slow_until"]=now_seconds()+3.0
    hero_attack_landed.emit(monster,damage,critical)
    var prefix:String="CRITICAL " if critical else ""
    game.call("log_message","Auto attack: %s%d damage to Lv.%d %s." % [prefix,damage,int(monster.get("level",1)),str(monster.get("name","Monster"))])
    if int(monster["hp"])<=0: finish_monster(monster)

func pet_strike(hero:Dictionary,monster:Dictionary)->void:
    if not hero.get("pet",{}) is Dictionary: return
    var pet:Dictionary=hero["pet"]
    if int(pet.get("hp",0))<=0: return
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    if hero_pos.distance_to(monster["pos"])>CombatRules.pet_attack_distance_map(pet): return
    var damage:int=PetSystem.power(pet)+rng.randi_range(0,7)
    pet["skill_uses"]=int(pet.get("skill_uses",0))+1
    var special:bool=int(pet["skill_uses"])%5==0
    if special:
        damage+=PetSystem.skill_power(pet)
        var role:=str(pet.get("role",""))
        if role=="Healer":
            var heal:int=PetSystem.heal_power(pet)+int(SkillSystem.combat_stats(hero)["healing_bonus"])
            hero["hp"]=min(int(hero.get("max_hp",1)),int(hero.get("hp",0))+heal)
            call_vfx("heal",hero_pos,str(heal),false)
        if role=="Guardian" or role=="Tank": pet["guard_until"]=now_seconds()+2.5
        if role=="Assassin" and rng.randf()<0.30: MonsterDetails.apply_poison(monster,damage,5.0)
    var dealt:int=max(1,damage-int(monster.get("defense",0)))
    monster["hp"]=int(monster.get("hp",0))-dealt
    monster["hit_flash"]=0.20
    pet_attack_landed.emit(monster,dealt,special)
    if special: game.call("log_message","%s unleashes %s for %d damage!" % [pet.get("name","Pet"),pet.get("skills",["Pet Skill"])[0],dealt])
    if int(monster["hp"])<=0: finish_monster(monster)

func monster_phase(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    var pet:Dictionary=hero.get("pet",{})
    var now:float=now_seconds()
    for monster in monsters.duplicate():
        if not monster is Dictionary or int(monster.get("hp",0))<=0: continue
        var attack_range:float=CombatRules.monster_attack_distance(monster)
        if hero_pos.distance_to(monster["pos"])>attack_range: continue
        var attack:int=max(1,int(monster.get("attack",int(monster.get("level",1))*4)))
        if bool(monster.get("mvp",false)): attack=int(float(attack)*1.25)
        var role:=str(pet.get("role",""))
        var pet_alive:bool=int(pet.get("hp",0))>0
        var threat_active:bool=pet_alive and float(monster.get("target_pet_until",0.0))>now
        var guard_active:bool=pet_alive and float(pet.get("guard_until",0.0))>now
        var target_pet:bool=pet_alive and (role=="Tank" or role=="Guardian") and (threat_active or guard_active or rng.randf()<0.35)
        if float(hero.get("temporary_evasion_until",0.0))>now and rng.randf()<0.40:
            call_vfx("miss",hero_pos,"MISS",false); continue
        if target_pet:
            var pet_damage:int=max(1,int(float(attack)*0.75)-int(pet.get("refine",0)))
            pet["hp"]=max(0,int(pet.get("hp",0))-pet_damage)
            call_vfx("hit",hero_pos+Vector2(34,24),str(pet_damage),false)
            monster_attack_landed.emit("pet",pet_damage)
            if int(pet["hp"])<=0: revive_pet(hero)
        else:
            var stats:Dictionary=SkillSystem.combat_stats(hero)
            var defense:int=int(stats["defense_bonus"])+int(hero.get("refine",0))+int(hero.get("age_defense_bonus",0))
            if float(hero.get("temporary_defense_until",0.0))>now: defense+=20
            var hero_damage:int=max(1,attack-defense)
            hero["hp"]=max(0,int(hero.get("hp",0))-hero_damage)
            call_vfx("hit",hero_pos,str(hero_damage),false)
            monster_attack_landed.emit("hero",hero_damage)
        if int(hero.get("hp",0))<=0: respawn_hero(hero)

func mvp_skill_phase(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array: return
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    for monster in monsters:
        if not monster is Dictionary or not bool(monster.get("mvp",false)) or int(monster.get("hp",0))<=0: continue
        if hero_pos.distance_to(monster["pos"])>190.0: continue
        var skill_damage:int=max(1,int(monster.get("attack",100))*2)
        var defense:int=int(SkillSystem.combat_stats(hero)["defense_bonus"])+int(hero.get("age_defense_bonus",0))
        skill_damage=max(1,skill_damage-defense)
        hero["hp"]=max(0,int(hero.get("hp",0))-skill_damage)
        call_vfx("mvp",hero_pos,str(monster.get("mvp_skill","MVP SKILL")),false)
        call_vfx("hit",hero_pos,str(skill_damage),true)
        monster_attack_landed.emit("hero",skill_damage)
        game.call("log_message","%s casts %s for %d damage!" % [monster.get("title",monster.get("name","MVP")),monster.get("mvp_skill","MVP Skill"),skill_damage])
        if int(hero.get("hp",0))<=0: respawn_hero(hero)

func revive_pet(hero:Dictionary)->void:
    var pet:Dictionary=hero.get("pet",{})
    pet["hp"]=max(1,int(pet.get("max_hp",60))/2)
    pet["revive_until"]=now_seconds()+3.0
    hero["pet"]=pet
    game.call("log_message","%s is knocked down and returns with %d HP." % [pet.get("name","Pet"),pet["hp"]])

func finish_monster(monster:Dictionary)->void:
    call_vfx("monster_death",monster["pos"],"",false)
    if game.has_method("defeat_monster"): game.call("defeat_monster",monster)
    var hero=game.get("hero")
    if hero is Dictionary:
        EventInventory.record_monster(hero,monster)
        EventInventory.record_event_progress(hero,"daily_hunt",1)
        if str(monster.get("name",""))=="Bloody Knight": EventInventory.record_event_progress(hero,"blood_moon",1)
        var gained:Array=LootSystem.on_monster_defeated(hero,monster,rng)
        if gained.size()>0: game.call("log_message","Auto-loot: %s" % ", ".join(gained))
        SaveSystem.save_game(hero)
    target=null
    target_changed.emit({})

func respawn_hero(hero:Dictionary)->void:
    hero["hp"]=hero["max_hp"]
    hero["sp"]=hero.get("max_sp",100)
    hero["pos_x"]=595.0
    hero["pos_y"]=340.0
    if hero.get("pet",{}) is Dictionary: hero["pet"]["hp"]=hero["pet"].get("max_hp",60)
    game.call("log_message","You were defeated. Your bonded pet revived with you at the safe point.")
    call_vfx("heal",Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0))),"FULL",false)

func call_vfx(kind:String,position:Vector2,label:String,critical:bool)->void:
    if game and game.has_method("show_3d_combat_number") and kind in ["hit","heal"]:
        game.call("show_3d_combat_number",position,int(label) if label.is_valid_int() else 0,critical,"enemy" if kind=="hit" else "hero")
    if game and game.has_method("play_combat_effect"):
        game.call("play_combat_effect",kind,position,label,critical)

func now_seconds()->float:
    return Time.get_ticks_msec()/1000.0
