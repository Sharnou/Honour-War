class_name HDCombatRangeRuntime
extends CombatRuntime

## Compatibility facade retained for existing scenes.
## CombatRuntime remains the only combat loop. This subclass only supplies
## progression-aware hero strike/defense behavior through virtual overrides.

const Formula=preload("res://scripts/ClassCombatFormula.gd")
const Character=preload("res://scripts/CharacterProgressionSystem.gd")
const SkillSystem=preload("res://scripts/SkillSystem.gd")

func hero_strike(hero:Dictionary,monster:Dictionary)->void:
    if int(hero.get("hp",0))<=0: return
    SkillSystem.ensure_state(hero)
    var class_id:String=str(hero.get("class","Warrior"))
    var active_skill:Dictionary={}
    var best_power:int=-1
    for skill in SkillSystem.all_skills(class_id):
        if str(skill.get("kind",""))=="passive": continue
        var skill_id:String=str(skill.get("id",""))
        if SkillSystem.skill_level(hero,skill_id)<=0: continue
        if not SkillSystem.is_ready(hero,skill_id,now_seconds()): continue
        var cost:int=SkillSystem.sp_cost(hero,skill_id)
        if int(hero.get("sp",0))<cost: continue
        var skill_power:int=SkillSystem.power(hero,skill_id)
        if skill_power>best_power:
            best_power=skill_power
            active_skill=skill

    var damage:int
    var critical:bool=false
    if not active_skill.is_empty():
        var skill_id:String=str(active_skill["id"])
        var result:Dictionary=SkillSystem.use(hero,skill_id,now_seconds())
        if bool(result.get("ok",false)):
            var magical:bool=class_id=="Mage" or class_id=="Acolyte"
            damage=Formula.skill_damage(hero,int(result.get("power",0)),magical)
            if class_id=="Archer" or class_id=="Ranger" or class_id=="Thief":
                critical=rng.randi_range(1,100)<=int(Formula.critical_chance(hero))
            if critical:
                damage=int(round(float(damage)*1.75))
            damage=max(1,damage-int(monster.get("defense",0))*0.65)
            _apply_skill_effect(hero,monster,skill_id)
            monster["hp"]=int(monster.get("hp",0))-damage
            monster["hit_flash"]=0.20
            hero_attack_landed.emit(monster,damage,critical)
            game.call("log_message","%s uses %s Lv.%d for %d damage." % [class_id,str(active_skill["name"]),int(result.get("level",1)),damage])
            if int(monster["hp"])<=0: finish_monster(monster)
            return

    var base_power:int=Formula.physical_power(hero)
    if class_id=="Mage" or class_id=="Acolyte": base_power=Formula.magic_power(hero)
    var variance:int=rng.randi_range(0,9)
    var power:int=base_power+variance
    var crit_chance:float=Formula.critical_chance(hero)
    critical=rng.randf()*100.0<=crit_chance
    if critical: power=int(round(float(power)*1.75))
    power=int(round(float(power)*float(SkillSystem.combat_stats(hero).get("damage_multiplier",1.0))))
    var damage_after_def:int=max(1,power-int(monster.get("defense",0)))
    monster["hp"]=int(monster.get("hp",0))-damage_after_def
    monster["hit_flash"]=0.16
    if class_id=="Thief" and rng.randf()<0.35: MonsterDetails.apply_poison(monster,damage_after_def,6.0)
    if class_id=="Mage" and rng.randf()<0.20: monster["slow_until"]=now_seconds()+3.0
    hero_attack_landed.emit(monster,damage_after_def,critical)
    game.call("log_message","Auto attack: %s%d damage to Lv.%d %s." % [("CRITICAL " if critical else ""),damage_after_def,int(monster.get("level",1)),str(monster.get("name","Monster"))])
    if int(monster["hp"])<=0: finish_monster(monster)

func _apply_skill_effect(hero:Dictionary,monster:Dictionary,skill_id:String)->void:
    match skill_id:
        "war_guardian_roar", "war_berserker", "mer_fortify":
            hero["temporary_defense_until"]=now_seconds()+4.0
        "mage_frost_prison":
            monster["slow_until"]=now_seconds()+5.0
        "thief_smoke":
            hero["temporary_evasion_until"]=now_seconds()+3.0
        "aco_sanctuary", "aco_seraphic_light", "aco_heaven_gate":
            var stats:Dictionary=Character.stats(hero)
            var heal:int=int(stats.get("healing",0))+max(20,int(stats.get("max_hp",100)*0.08))
            hero["hp"]=min(int(stats.get("max_hp",100)),int(hero.get("hp",0))+heal)
        "mer_arsenal_overlord":
            hero["temporary_power_until"]=now_seconds()+8.0
            var pet:Dictionary=hero.get("pet",{})
            if not pet.is_empty(): pet["temporary_power_until"]=now_seconds()+8.0
        _:
            pass

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
        var role:String=str(pet.get("role",""))
        var pet_alive:bool=int(pet.get("hp",0))>0
        var threat_active:bool=pet_alive and float(monster.get("target_pet_until",0.0))>now
        var guard_active:bool=pet_alive and float(pet.get("guard_until",0.0))>now
        var target_pet:bool=pet_alive and (role=="Tank" or role=="Guardian") and (threat_active or guard_active or rng.randf()<0.35)
        if float(hero.get("temporary_evasion_until",0.0))>now and rng.randf()<0.40:
            call_vfx("miss",hero_pos,"MISS",false)
            continue
        if target_pet:
            var pet_damage:int=max(1,int(float(attack)*0.75)-int(pet.get("refine",0)))
            pet["hp"]=max(0,int(pet.get("hp",0))-pet_damage)
            call_vfx("hit",hero_pos+Vector2(34,24),str(pet_damage),false)
            monster_attack_landed.emit("pet",pet_damage)
            if int(pet["hp"])<=0: revive_pet(hero)
        else:
            var defense:int=Formula.defense(hero)
            if float(hero.get("temporary_defense_until",0.0))>now: defense+=20
            var hero_damage:int=max(1,attack-defense)
            hero["hp"]=max(0,int(hero.get("hp",0))-hero_damage)
            call_vfx("hit",hero_pos,str(hero_damage),false)
            monster_attack_landed.emit("hero",hero_damage)
        if int(hero.get("hp",0))<=0: respawn_hero(hero)
