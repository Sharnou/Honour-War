class_name HDCombatRangeRuntime
extends CombatRuntime

## Authoritative class-range override while retaining the existing combat pipeline.
## Swordsman/Warrior must enter melee range; Archer can attack from long range.

const SWORDSMAN_MAP_RANGE:float = 44.0
const ARCHER_MAP_RANGE:float = 220.0

func _process(delta:float)->void:
    if game==null or not game.get("hero") is Dictionary:
        return
    var hero:Dictionary=game.get("hero")
    hero_attack_timer+=delta
    pet_attack_timer+=delta
    monster_attack_timer+=delta
    sp_regen_timer+=delta
    mvp_skill_timer+=delta
    if game.get("pet_attack_timer") != null:
        game.set("pet_attack_timer",0.0)
    SkillSystem.ensure_state(hero)
    LootSystem.ensure_state(hero)
    decorate_world_monsters(hero)
    _update_class_target(hero)
    move_monsters(delta,hero)
    regenerate_sp(hero)
    update_status_effects(hero)
    if target!=null:
        var range:=_hero_map_range(hero)
        var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
        var distance:=hero_pos.distance_to(target.get("pos",hero_pos))
        if distance<=range and hero_attack_timer>=HERO_ATTACK_INTERVAL:
            hero_attack_timer=0.0
            hero_strike(hero,target)
    if target!=null and pet_attack_timer>=PET_ATTACK_INTERVAL:
        pet_attack_timer=0.0
        pet_strike(hero,target)
    if monster_attack_timer>=MONSTER_ATTACK_INTERVAL:
        monster_attack_timer=0.0
        monster_phase(hero)
    if mvp_skill_timer>=7.0:
        mvp_skill_timer=0.0
        mvp_skill_phase(hero)

func _hero_map_range(hero:Dictionary)->float:
    var class_id:=str(hero.get("class","Warrior")).to_lower()
    if class_id=="archer" or class_id=="ranger":
        return ARCHER_MAP_RANGE
    return SWORDSMAN_MAP_RANGE

func _update_class_target(hero:Dictionary)->void:
    var monsters=game.get("monsters")
    if not monsters is Array:
        target=null
        target_changed.emit({})
        return
    var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
    var selection_range:=ARCHER_MAP_RANGE if str(hero.get("class","Warrior")).to_lower() in ["archer","ranger"] else 260.0
    var best=null
    var best_distance:=selection_range
    for monster in monsters:
        if not monster is Dictionary or int(monster.get("hp",0))<=0:
            continue
        var distance:=hero_pos.distance_to(monster.get("pos",hero_pos))
        if distance<best_distance:
            best=monster
            best_distance=distance
    if best!=target:
        target=best
        target_changed.emit(target if target is Dictionary else {})
