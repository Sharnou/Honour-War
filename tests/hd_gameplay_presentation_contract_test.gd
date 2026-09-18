extends SceneTree

## Permanent HD/gameplay presentation contract.
## Fast, deterministic checks for the systems that must remain connected to the
## authoritative MMORPG runtime without replacing saved progression.

const DATA = preload("res://scripts/GameData.gd")
const TREE = preload("res://scripts/ClassTreeSystem.gd")
const SKILLS = preload("res://scripts/SkillSystem.gd")
const PET = preload("res://scripts/PetSystem.gd")
const MVP = preload("res://scripts/MVPSystem.gd")
const MONSTERS = preload("res://scripts/MonsterDetailsSystem.gd")
const WORLD = preload("res://scripts/WorldSystem.gd")
const ITEMS = preload("res://scripts/ItemDatabase.gd")
const EQUIPMENT = preload("res://scripts/EquipmentSystem.gd")
const LOOT = preload("res://scripts/LootSystem.gd")
const CITY = preload("res://scripts/CitySystem.gd")
const TELEPORT = preload("res://scripts/TeleportSystem.gd")
const ONLINE_AGE = preload("res://scripts/OnlineAgeSystem.gd")

var failures:int = 0

func _initialize() -> void:
    var definitions:Dictionary = DATA.class_definitions()
    check("six classes remain playable", definitions.size() == 6)

    for class_id:Variant in definitions.keys():
        var id:String = str(class_id)
        var definition:Dictionary = definitions[id]
        var profile:Dictionary = TREE.class_profile(id)
        check("five rank stages " + id, definition.get("tree",[]).size() == 5)
        check("four specialization branches " + id, profile.get("branches",[]).size() == 4)
        check("eight+ skills " + id, SKILLS.all_skills(id).size() >= 8)

        var pet:Dictionary = PET.new_pet(id)
        check("automatic pet state " + id, not pet.is_empty())
        check("pet has combat skill " + id, (pet.get("skills",[]) as Array).size() >= 1)
        check("pet has equipment " + id, not (pet.get("equipment",{}) as Dictionary).is_empty())

    for level:int in [1,25,50,100,200,250]:
        var tier:int = DATA.class_tier_for_level(level)
        check("class tier boundary %d" % level, tier >= 0 and tier <= 4)
        check("rank exists %d" % level, not DATA.class_rank_for_level(level,"Warrior").is_empty())

    var hero:Dictionary = DATA.new_hero()
    var age_bonus:Dictionary = DATA.age_strength_bonus(22)
    check("age combat scaling", int(age_bonus.get("atk",0)) > 0 and int(age_bonus.get("hp",0)) > 0)
    check("hero persistence baseline", hero.has("age") and hero.has("online_days") and hero.has("pet"))

    var aging_hero:Dictionary = {"age_origin":18,"age":18,"online_days":0.0}
    ONLINE_AGE.normalize(aging_hero)
    aging_hero["online_days"] = 3.0
    ONLINE_AGE.normalize(aging_hero)
    check("online age recalculates for saved heroes", int(aging_hero.get("age",0)) == 19)
    check("online age grants refine bonus", is_equal_approx(ONLINE_AGE.refine_success_bonus(aging_hero),0.01))

    var item_catalog:Dictionary = ITEMS.all()
    for class_id:Variant in definitions.keys():
        var id:String = str(class_id)
        var weapon_name:String = ""
        match id:
            "Warrior": weapon_name = "Super War Emperor Blade"
            "Mage": weapon_name = "Super Astral Sovereign Staff"
            "Archer": weapon_name = "Super Celestial Longbow"
            "Thief": weapon_name = "Super Eternal Assassin Blade"
            "Acolyte": weapon_name = "Super Heaven Gate Mace"
            "Merchant": weapon_name = "Super Arsenal Overlord Hammer"
        check("endgame weapon " + id, item_catalog.has(weapon_name))
        check("endgame weapon slots " + id, int(item_catalog.get(weapon_name,{}).get("card_slots",0)) == 4)

    for name:Variant in MVP.definitions().keys():
        var mvp_def:Dictionary = MVP.definitions()[name]
        check("MVP level bounded " + str(name), int(mvp_def.get("level",0)) <= DATA.MAX_MONSTER_LEVEL)
        check("MVP has card " + str(name), not str(mvp_def.get("card","")).is_empty())
        check("MVP has loot " + str(name), (mvp_def.get("loot",[]) as Array).size() >= 2)

    var level_300:int = WORLD.monster_level_for_zone(30,10)
    check("monster reaches level 300", level_300 == 300)
    var mvp_details:Dictionary = MONSTERS.details({"name":"Thanatos","level":300,"mvp":true})
    check("level-300 MVP codex", int(mvp_details.get("danger",0)) >= 15 and bool(mvp_details.get("name","") != ""))

    var endgame_hero:Dictionary = DATA.new_hero()
    endgame_hero["class"] = "Warrior"
    LOOT.ensure_state(endgame_hero)
    var rng:RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 300300
    var before:Dictionary = (endgame_hero.get("inventory",{}) as Dictionary).duplicate(true)
    var reward_monster:Dictionary = {
        "name":"Thanatos","level":300,"hp":1,"max":1,"xp":1000,
        "attack":100,"defense":100,"mvp":true,"loot_processed":false
    }
    var gained:Array[String] = LOOT.on_monster_defeated(endgame_hero,reward_monster,rng)
    check("level-300 reward generated", gained.size() >= 4)
    var inventory:Dictionary = endgame_hero.get("inventory",{})
    check("level-300 class weapon awarded", int(inventory.get("Super War Emperor Blade",0)) > int(before.get("Super War Emperor Blade",0)))
    check("level-300 glowing armor awarded", int(inventory.get("Glowing War Emperor Armor",0)) > 0)
    check("level-300 super card awarded", (endgame_hero.get("cards",[]) as Array).has("Super Baphomet Card"))

    EQUIPMENT.ensure_state(endgame_hero)
    check("all equipment slots normalized", (endgame_hero.get("equipment",{}) as Dictionary).size() >= EQUIPMENT.SLOTS.size())

    var city_ids:Array = CITY.city_ids()
    check("town registry", city_ids.size() == DATA.cities().size())
    check("town services", CITY.available_services().size() >= 10)
    for city_id:String in DATA.cities():
        var snapshot:Dictionary = CITY.city_snapshot(city_id)
        check("town snapshot " + city_id, str(snapshot.get("id","")) == city_id and (snapshot.get("services",[]) as Array).size() >= 1)

    for map_id:Variant in TELEPORT.MAPS.keys():
        var map_data:Dictionary = TELEPORT.MAPS[map_id]
        check("map entry " + str(map_id), not str(map_data.get("name","")).is_empty())
        check("map coordinates " + str(map_id), int(map_data.get("spawn_x",-1)) >= 0 and int(map_data.get("spawn_y",-1)) >= 0)

    var scene_text:String = FileAccess.get_file_as_string("res://Main3D.tscn")
    check("HD camera", scene_text.contains('Camera3D'))
    check("HD environment director", scene_text.contains('HDEnvironmentDirector'))
    check("HD visual director", scene_text.contains('HDVisualDirector'))
    check("HD asset runtime", scene_text.contains('HDAssetRuntime'))
    check("HD combat VFX", scene_text.contains('HDCombatVFX'))
    check("HD skill presentation", scene_text.contains('HDSkillPresentation'))
    check("pet combat runtime", scene_text.contains('PetSkillRuntime'))
    check("pet combo VFX", scene_text.contains('HeroPetComboVFX'))
    check("player identity UI", scene_text.contains('HWPlayerIdentityUI'))
    check("MMO taskbar", scene_text.contains('HDMMOTaskbar'))
    check("runtime world content", FileAccess.file_exists("res://scripts/HWHDWorldContentDirector.gd"))
    check("terrain detail pass", FileAccess.file_exists("res://scripts/HWHDHighDetailWorld.gd"))
    check("map theme pass", FileAccess.file_exists("res://scripts/HWMapThemeDirector.gd"))
    check("world props pass", FileAccess.file_exists("res://scripts/HWWorldDetailDirector.gd"))
    check("final presentation pass", FileAccess.file_exists("res://scripts/HWHDFinalPresentationDirector.gd"))
    check("equipment visual pass", FileAccess.file_exists("res://scripts/HDEquipmentVisualDriver.gd"))
    check("monster motion pass", FileAccess.file_exists("res://scripts/HDMonsterMotionDirector.gd"))
    check("camera stability pass", FileAccess.file_exists("res://scripts/MovementStabilityFix.gd"))
    check("UI style pass", FileAccess.file_exists("res://scripts/HDUIStyleDirector.gd"))
    check("no forbidden tween alpha", not _contains_forbidden_tween("res://scripts"))

    if failures == 0:
        print("HONOUR_WAR_HD_PRESENTATION: PASS")
        quit(0)
        return
    print("HONOUR_WAR_HD_PRESENTATION: FAILURES=%d" % failures)
    quit(1)

func check(label:String, condition:bool) -> void:
    if condition:
        print("PASS: " + label)
    else:
        failures += 1
        push_error("FAIL: " + label)

func _contains_forbidden_tween(root_path:String) -> bool:
    var needle:String = "modulate" + ":" + "a"
    var dir:DirAccess = DirAccess.open(root_path)
    if dir == null:
        return false
    dir.list_dir_begin()
    var name:String = dir.get_next()
    while name != "":
        if dir.current_is_dir():
            if _contains_forbidden_tween(root_path + "/" + name):
                dir.list_dir_end()
                return true
        elif name.ends_with(".gd"):
            var content:String = FileAccess.get_file_as_string(root_path + "/" + name)
            if content.contains(needle):
                dir.list_dir_end()
                return true
        name = dir.get_next()
    dir.list_dir_end()
    return false
