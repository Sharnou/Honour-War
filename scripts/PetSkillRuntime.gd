class_name PetSkillRuntime
extends Node

@export var cast_interval:float=3.5
@export var auto_cast_states:Array[String]=["Assist","Aggressive","Defend"]
@export var low_owner_hp_ratio:float=0.45
@export var emergency_owner_hp_ratio:float=0.28

var game:Node
var combat:Node
var rng:=RandomNumberGenerator.new()
var timer:float=0.0
var last_skill_index:int=-1
var pet_vfx:Node

func _ready()->void:
    game=get_parent()
    combat=game.get_node_or_null("LegacyGame/CombatRuntime") if game else null
    pet_vfx=game.get_node_or_null("PetSkillVFX") if game else null
    rng.randomize()

func _process(delta:float)->void:
    timer+=delta
    if timer<cast_interval: return
    timer=0.0
    _attempt_cast()

func request_skill(skill_id:String)->Dictionary:
    return _cast(skill_id)

func _attempt_cast()->void:
    if game==null or combat==null: return
    var director:Node=game.get_node_or_null("HDPetCombatDirector")
    if director and not auto_cast_states.has(str(director.get("pet_state"))): return
    var hero:Dictionary=_get_hero()
    if hero.is_empty(): return
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return
    var pet:Dictionary=pet_value
    PetSkillSystem.ensure_state(pet)
    var target:Dictionary=_select_target(pet,hero,director)
    if target.is_empty(): return
    var selected:String=_select_best_skill(pet,hero,target,director)
    if selected.is_empty(): return
    _cast(selected,target)

func _select_target(pet:Dictionary,hero:Dictionary,director:Node)->Dictionary:
    var monsters_value:Variant=game.get("monsters")
    if not monsters_value is Array: return {}
    var role:String=str(director.get("pet_role")) if director else str(pet.get("role","Hybrid"))
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    var current:Dictionary=combat.get("target") if combat.get("target") is Dictionary else {}
    var best:Dictionary={}
    var best_score:float=-INF
    for candidate in monsters_value:
        if not candidate is Dictionary or int(candidate.get("hp",0))<=0: continue
        var pos:Vector2=candidate.get("pos",Vector2.ZERO)
        var distance:float=hero_pos.distance_to(pos)
        if distance>220.0: continue
        var score:float=0.0
        var level:int=int(candidate.get("level",1))
        var hp:int=int(candidate.get("hp",1))
        var max_hp:int=max(1,int(candidate.get("max",hp)))
        var hp_ratio:float=float(hp)/float(max_hp)
        if candidate==current: score+=7.0
        if bool(candidate.get("mvp",false)): score+=5.0
        score+=float(level)*0.03
        score+=(1.0-hp_ratio)*4.0
        if role=="Guardian":
            score+=float(candidate.get("pet_threat",0))*0.015
            if float(candidate.get("target_pet_until",0.0))>Time.get_ticks_msec()/1000.0: score+=8.0
        elif role=="DPS":
            score+=(1.0-hp_ratio)*8.0
        elif role=="Ranged":
            score+=max(0.0,5.0-distance*0.01)
        elif role=="Support":
            if float(hero.get("hp",0))/float(max(1,int(hero.get("max_hp",1))))<low_owner_hp_ratio: score+=3.0
        score-=distance*0.012
        if score>best_score:
            best_score=score
            best=candidate
    return best

func _select_best_skill(pet:Dictionary,hero:Dictionary,monster:Dictionary,director:Node)->String:
    var species:String=str(pet.get("species","Wolf Cub"))
    var role:String=str(director.get("pet_role")) if director else str(pet.get("role","Hybrid"))
    var owner_ratio:float=float(hero.get("hp",0))/float(max(1,int(hero.get("max_hp",1))))
    var pet_ratio:float=float(pet.get("hp",0))/float(max(1,int(pet.get("max_hp",1))))
    var monster_ratio:float=float(monster.get("hp",0))/float(max(1,int(monster.get("max",monster.get("hp",1)))))
    var best_id:String=""
    var best_score:float=-INF
    var now:float=Time.get_ticks_msec()/1000.0
    for skill in PetSkillSystem.all_skills(species):
        if str(skill.get("kind",""))=="passive": continue
        var id:String=str(skill.get("id",""))
        if PetSkillSystem.skill_level(pet,id)<=0 or not PetSkillSystem.is_ready(pet,id,now): continue
        var score:float=float(skill.get("power",0))*0.04+float(skill.get("tier",1))*0.5
        var kind:String=str(skill.get("kind",""))
        if kind=="ultimate": score+=8.0
        if role=="Ranged":
            if id.find("mark")>=0: score+=6.0
            if id.find("storm")>=0 or id.find("barrage")>=0 or id.find("meteor")>=0: score+=3.0
        elif role=="DPS":
            score+=float(skill.get("power",0))*0.03
            if monster_ratio<0.35: score+=4.0
            if id.find("rend")>=0 or id.find("fury")>=0 or id.find("apex")>=0: score+=3.0
        elif role=="Guardian":
            if owner_ratio<low_owner_hp_ratio: score+=6.0
            if owner_ratio<emergency_owner_hp_ratio: score+=5.0
            if id.find("guard")>=0 or id.find("heart")>=0 or id.find("howl")>=0: score+=7.0
            if id.find("roar")>=0: score+=4.0
        elif role=="Support":
            if owner_ratio<emergency_owner_hp_ratio: score+=10.0
            elif owner_ratio<low_owner_hp_ratio: score+=7.0
            if id.find("bond")>=0 or id.find("guardian")>=0 or id.find("howl")>=0: score+=6.0
        else:
            if pet_ratio<0.35 and id.find("guard")>=0: score+=4.0
        if int(monster.get("level",1))>int(pet.get("level",1)): score+=1.5
        if id.find("apocalypse")>=0 or id.find("eternity")>=0: score+=2.0
        if score>best_score:
            best_score=score
            best_id=id
    return best_id

func _cast(skill_id:String,target_override:Dictionary={})->Dictionary:
    if game==null or combat==null: return {"ok":false,"reason":"runtime"}
    var hero:Dictionary=_get_hero()
    if hero.is_empty(): return {"ok":false,"reason":"hero"}
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return {"ok":false,"reason":"pet"}
    var pet:Dictionary=pet_value
    if int(pet.get("hp",0))<=0: return {"ok":false,"reason":"pet_defeated"}
    var target_value:Variant=target_override if not target_override.is_empty() else combat.get("target")
    if not target_value is Dictionary: return {"ok":false,"reason":"no_target"}
    var monster:Dictionary=target_value
    if int(monster.get("hp",0))<=0: return {"ok":false,"reason":"target_defeated"}
    PetSkillSystem.ensure_state(pet)
    var now:float=Time.get_ticks_msec()/1000.0
    var result:Dictionary=PetSkillSystem.use(pet,skill_id,now)
    if not bool(result.get("ok",false)): return result
    var skill:Dictionary=result["skill"]
    var raw_damage:int=int(result.get("power",0))
    var level:int=int(pet.get("level",1))
    var scaled:int=raw_damage+int(float(level)*1.8)
    var stats:Dictionary=PetSkillSystem.combat_stats(pet)
    scaled=int(float(scaled)*float(stats.get("damage_multiplier",1.0)))
    var defense:int=int(monster.get("defense",0))
    var dealt:int=max(1,scaled-defense/2+rng.randi_range(0,10))
    monster["hp"]=int(monster.get("hp",0))-dealt
    monster["hit_flash"]=0.28
    _apply_role_effects(pet,hero,monster,skill,dealt)
    var position:Vector2=monster.get("pos",Vector2.ZERO)
    var world_position:=Vector3((position.x-595.0)*0.055,0.9,(position.y-340.0)*0.055)
    var species:String=str(pet.get("species","Wolf Cub"))
    var radius:float=_radius(skill)
    var feedback:Node=game.get_node_or_null("HDCombatFeedback")
    if feedback:
        if _is_area(skill): feedback.show_telegraph("circle",world_position,radius,0.65)
        feedback.play_skill_effect(skill_id,world_position)
        feedback.show_damage(dealt,world_position,dealt>scaled+int(skill.get("power",0))/2)
    if pet_vfx and pet_vfx.has_method("play"): pet_vfx.play(species,skill_id,world_position,radius)
    var combat_vfx:Node=game.get_node_or_null("LegacyGame/CombatVFX")
    if combat_vfx and combat_vfx.has_method("skill_cast"): combat_vfx.skill_cast(position,skill_id,false)
    if game.has_method("log_message"): game.call("log_message","%s casts %s for %d damage." % [str(pet.get("name","Pet")),str(skill.get("name",skill_id)),dealt])
    if int(monster["hp"])<=0 and combat.has_method("finish_monster"): combat.call("finish_monster",monster)
    return {"ok":true,"skill_name":str(skill.get("name",skill_id)),"skill_id":skill_id,"damage":dealt,"cooldown":float(skill.get("cooldown",0.0))}

func _apply_role_effects(pet:Dictionary,hero:Dictionary,monster:Dictionary,skill:Dictionary,dealt:int)->void:
    var role:String=str(pet.get("role",""))
    var id:String=str(skill.get("id",""))
    var now:float=Time.get_ticks_msec()/1000.0
    if role=="Guardian" or role=="Support":
        if id.find("guard")>=0 or id.find("heart")>=0 or id.find("bond")>=0:
            hero["temporary_defense_until"]=max(float(hero.get("temporary_defense_until",0.0)),now+3.0)
            pet["guard_until"]=now+3.0
        if role=="Support" and float(hero.get("hp",0))/float(max(1,int(hero.get("max_hp",1))))<low_owner_hp_ratio:
            var heal:int=max(1,int(dealt*0.35)+int(pet.get("level",1)))
            hero["hp"]=min(int(hero.get("max_hp",1)),int(hero.get("hp",0))+heal)
            var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
            call_vfx("heal",hero_pos,str(heal),false)
    if role=="Guardian" and (id.find("howl")>=0 or id.find("roar")>=0):
        monster["pet_threat"]=int(monster.get("pet_threat",0))+dealt*3
        monster["target_pet_until"]=now+3.5
    if role=="DPS" or role=="Ranged":
        if int(monster.get("hp",0))<=int(monster.get("max",monster.get("hp",0)))*0.2):
            monster["execution_mark_until"]=now+2.0

func _get_hero()->Dictionary:
    if game==null: return {}
    var value:Variant=game.get("hero")
    return value if value is Dictionary else {}

func _is_area(skill:Dictionary)->bool:
    return int(skill.get("tier",1))>=2 or str(skill.get("kind",""))=="ultimate"

func _radius(skill:Dictionary)->float:
    if str(skill.get("kind",""))=="ultimate": return 4.5
    if int(skill.get("tier",1))>=4: return 3.2
    return 2.1

func call_vfx(kind:String,position:Vector2,text:String,critical:bool)->void:
    var vfx:Node=game.get_node_or_null("LegacyGame/CombatVFX") if game else null
    if vfx==null: return
    if kind=="heal" and vfx.has_method("heal"): vfx.heal(position,int(text))
