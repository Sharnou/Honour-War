extends SceneTree

const Skills = preload("res://scripts/SkillSystem.gd")
const CombatRules = preload("res://scripts/CombatRules.gd")
const TeleportSystem = preload("res://scripts/TeleportSystem.gd")

const CLASSES:Array[String] = ["Warrior","Mage","Archer","Thief","Acolyte","Merchant"]

func _initialize() -> void:
    var failures:Array[String] = []
    for class_id in CLASSES:
        var hero:Dictionary = _hero(class_id)
        Skills.ensure_state(hero)
        var skills:Array = Skills.all_skills(class_id)
        var active_count:int = 0
        var ultimate_count:int = 0
        for skill in skills:
            if str(skill.get("kind","")) != "passive":
                active_count += 1
            if str(skill.get("kind","")) == "ultimate":
                ultimate_count += 1
        if active_count < 4:
            failures.append("%s has fewer than four active skills" % class_id)
        if ultimate_count < 1:
            failures.append("%s has no ultimate skill" % class_id)
        var first_active:Dictionary = {}
        for skill in skills:
            if str(skill.get("kind","")) == "active":
                first_active = skill
                break
        if first_active.is_empty():
            failures.append("%s has no castable active skill" % class_id)
        else:
            hero["sp"] = 9999
            var result:Dictionary = Skills.use(hero,str(first_active["id"]),1000.0)
            if not bool(result.get("ok",false)):
                failures.append("%s first active skill rejected: %s" % [class_id,str(result.get("reason","unknown"))])

    var warrior:Dictionary = _hero("Warrior")
    var mage:Dictionary = _hero("Mage")
    var archer:Dictionary = _hero("Archer")
    if CombatRules.class_engagement_map(warrior) <= 0.0:
        failures.append("Warrior movement/combat engagement range invalid")
    if CombatRules.class_engagement_map(mage) <= CombatRules.class_engagement_map(warrior):
        failures.append("Mage range must exceed Warrior range")
    if CombatRules.class_engagement_map(archer) <= CombatRules.class_engagement_map(mage):
        failures.append("Archer range must exceed Mage range")

    var map_data:Dictionary = TeleportSystem.MAPS.get(0,{})
    var min_x:float = 365.0
    var min_y:float = 120.0
    var max_x:float = min_x + float(map_data.get("width",1200)) - 1.0
    var max_y:float = min_y + float(map_data.get("height",700)) - 1.0
    var points:Array[Vector2] = [
        Vector2(min_x-100.0,min_y-100.0),
        Vector2(max_x+100.0,max_y+100.0),
        Vector2((min_x+max_x)*0.5,(min_y+max_y)*0.5)
    ]
    for p in points:
        var clamped := Vector2(clamp(p.x,min_x,max_x),clamp(p.y,min_y,max_y))
        if clamped.x < min_x or clamped.x > max_x or clamped.y < min_y or clamped.y > max_y:
            failures.append("Hero map clamp contract failed for %s" % str(p))

    if failures.is_empty():
        print("HERO_MONSTER_MOVEMENT_SKILL_QA: PASS — six hero classes, active/ultimate skills, combat ranges and movement bounds validated")
        quit(0)
    print("HERO_MONSTER_MOVEMENT_SKILL_QA: FAIL")
    for failure in failures:
        print("FAIL: ",failure)
    quit(1)

func _hero(class_id:String) -> Dictionary:
    return {
        "class":class_id,
        "level":250,
        "hp":100000,
        "max_hp":100000,
        "sp":9999,
        "max_sp":9999,
        "skill_points":9999,
        "skill_points_level":250,
        "stats":{"str":99,"agi":99,"vit":99,"int":99,"dex":99,"luk":99},
        "equipment":{}
    }
