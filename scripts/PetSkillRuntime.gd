class_name PetSkillRuntime
extends Node

@export var cast_interval:float = 3.5
@export var auto_cast_states:Array[String] = ["Assist", "Aggressive"]

var game:Node
var combat:Node
var rng:=RandomNumberGenerator.new()
var timer:float = 0.0
var last_skill_index:int = -1

func _ready()->void:
    game=get_parent()
    combat=game.get_node_or_null("LegacyGame/CombatRuntime") if game else null
    rng.randomize()

func _process(delta:float)->void:
    timer+=delta
    if timer<cast_interval: return
    timer=0.0
    _attempt_cast()

func _attempt_cast()->void:
    if game==null or combat==null: return
    var hero_value:Variant=game.get("hero")
    if not hero_value is Dictionary: return
    var hero:Dictionary=hero_value
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return
    var pet:Dictionary=pet_value
    if int(pet.get("hp",0))<=0: return
    var director:Node=game.get_node_or_null("HDPetCombatDirector")
    if director and not auto_cast_states.has(str(director.get("pet_state"))): return
    var target_value:Variant=combat.get("target")
    if not target_value is Dictionary: return
    var monster:Dictionary=target_value
    if int(monster.get("hp",0))<=0: return
    PetSkillSystem.ensure_state(pet)
    var species:String=str(pet.get("species","Wolf Cub"))
    var skills:Array=PetSkillSystem.all_skills(species)
    if skills.is_empty(): return
    var now:float=Time.get_ticks_msec()/1000.0
    var chosen:Dictionary={}
    for offset in range(skills.size()):
        var index:int=(last_skill_index+1+offset)%skills.size()
        var skill:Dictionary=skills[index]
        if str(skill.get("kind",""))=="passive": continue
        var id:String=str(skill.get("id",""))
        if PetSkillSystem.skill_level(pet,id)<=0: continue
        if not PetSkillSystem.is_ready(pet,id,now): continue
        chosen=skill
        last_skill_index=index
        break
    if chosen.is_empty(): return
    var skill_id:String=str(chosen["id"])
    var result:Dictionary=PetSkillSystem.use(pet,skill_id,now)
    if not bool(result.get("ok",false)): return
    var raw_damage:int=int(result.get("power",0))
    var level:int=int(pet.get("level",1))
    var scaled:int=raw_damage+int(float(level)*1.8)
    var pet_stats:Dictionary=PetSkillSystem.combat_stats(pet)
    scaled=int(float(scaled)*float(pet_stats.get("damage_multiplier",1.0)))
    var defense:int=int(monster.get("defense",0))
    var dealt:int=max(1,scaled-defense/2+rng.randi_range(0,10))
    monster["hp"]=int(monster.get("hp",0))-dealt
    monster["hit_flash"]=0.28
    var position:Vector2=monster.get("pos",Vector2.ZERO)
    var feedback:Node=game.get_node_or_null("HDCombatFeedback")
    var world_position:=Vector3((position.x-595.0)*0.055,0.9,(position.y-340.0)*0.055)
    if feedback:
        if _is_area(skill): feedback.show_telegraph("circle",world_position,_radius(skill),0.65)
        feedback.play_skill_effect(skill_id,world_position)
        feedback.show_damage(dealt,world_position,dealt>scaled+int(chosen.get("power",0))/2)
    var combat_vfx:Node=game.get_node_or_null("LegacyGame/CombatVFX")
    if combat_vfx and combat_vfx.has_method("skill_cast"):
        combat_vfx.skill_cast(position,skill_id,false)
    if game.has_method("log_message"):
        game.call("log_message","%s casts %s for %d damage." % [str(pet.get("name","Pet")),str(chosen.get("name",skill_id)),dealt])
    if int(monster["hp"])<=0 and combat.has_method("finish_monster"):
        combat.call("finish_monster",monster)

func _is_area(skill:Dictionary)->bool:
    return int(skill.get("tier",1))>=2 or str(skill.get("kind",""))=="ultimate"

func _radius(skill:Dictionary)->float:
    if str(skill.get("kind",""))=="ultimate": return 4.5
    if int(skill.get("tier",1))>=4: return 3.2
    return 2.1
