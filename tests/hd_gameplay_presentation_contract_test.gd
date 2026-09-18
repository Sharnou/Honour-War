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
const FIFTH = preload("res://scripts/FifthJobDatabase.gd")
const RENT = preload("res://scripts/HWSSRentRuntime.gd")
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

    var fourth_job_expected:Dictionary = {
        "Warrior":"Transcendent Knight",
        "Mage":"Transcendent Wizard",
        "Archer":"Transcendent Ranger",
        "Thief":"Transcendent Assassin",
        "Acolyte":"Transcendent Saint",
        "Merchant":"Transcendent Forge Master"
    }
    var fifth_job_expected:Dictionary = {
        "Warrior":"War Emperor",
        "Mage":"Arcane Sovereign",
        "Archer":"Celestial Ranger",
        "Thief":"Shadow Emperor",
        "Acolyte":"Divine Saint",
        "Merchant":"Forge Overlord"
    }
    for class_id:Variant in fourth_job_expected.keys():
        var fourth_hero:Dictionary = {"class":str(class_id),"level":150,"class_branch":""}
        check("Fourth Job Lv150 " + str(class_id), DATA.class_rank_for_hero(fourth_hero) == str(fourth_job_expected[class_id]))
        var fifth_hero:Dictionary = {"class":str(class_id),"level":200,"class_branch":""}
        check("Fifth Job Lv200 " + str(class_id), DATA.class_rank_for_hero(fifth_hero) == str(fifth_job_expected[class_id]))
    var below_fourth:Dictionary = {"class":"Warrior","level":149,"class_branch":""}
    check("Fourth Job locked below Lv150", DATA.class_rank_for_hero(below_fourth) == "Lord Knight")
    check("Super Champion is not an Acolyte job", DATA.class_rank_for_hero({"class":"Acolyte","level":200,"class_branch":"Saint"}) == "Divine Saint")
    check("Super Champion is rental-only", RENT.SS_CLASS_NAME == "Super Champion (Rental Only)")

    for class_id:Variant in fifth_job_expected.keys():
        var id:String = str(class_id)
        var equipment:Dictionary = FIFTH.equipment(id)
        var cards:Array = FIFTH.top_cards(id)
        check("Fifth Job has full equipment " + id, equipment.size() == 10)
        check("Fifth Job has top cards " + id, cards.size() == 3)
        check("Fifth Job weapon is 4-slot " + id, int(equipment["weapon"].get("card_slots",0)) == 4)
        check("Fifth Job drops are rare " + id, float(equipment["weapon"].get("drop_rate_percent",1.0)) <= 0.025 and float(cards[2].get("drop_rate_percent",1.0)) <= 0.0025)
        var top_monster:Dictionary = {"name":"Thanatos","level":300,"mvp":true}
        check("Fifth Job top-monster eligibility " + id, bool(FIFTH.drop_table(top_monster,id).get("eligible",false)))

    var hero:Dictionary = DATA.new_hero()
    var age_bonus:Dictionary = DATA.age_strength_bonus(22)
    check("age combat scaling", int(age_bonus.get("atk",0)) > 0 and int(age_bonus.get("hp",0)) > 0)
    check("hero persistence baseline", hero.has("age") and hero.has("online_days") and hero.has("pet"))

    var refine_at_18:float = WORLD.refinement_chance(18,1,0)
    var refine_at_60:float = WORLD.refinement_chance(60,1,0)
    check("age refinement bonus is one percent per year", is_equal_approx(refine_at_60-refine_at_18,0.42))

    var aging_hero:Dictionary = {"age_origin":18,"age":18,"online_days":0.0}
    ONLINE_AGE.normalize(aging_hero)
    aging_hero["online_days"] = 3.0
    ONLINE_AGE.normalize(aging_hero)
    check("online age recalculates for saved heroes", int(aging_hero.get("age",0)) == 19)
    check("online age grants refine bonus", is_equal_approx(ONLINE_AGE.refine_success_bonus(aging_hero),0.01))

    var combat_status_text:String = FileAccess.get_file_as_string("res://scripts/CombatRuntime.gd")
    check("MVP burn tick runtime", combat_status_text.contains("burn_until") and combat_status_text.contains("burn_tick"))
    check("MVP curse runtime", combat_status_text.contains("curse_until") and combat_status_text.contains("0.80"))
    check("MVP fear runtime", combat_status_text.contains("fear_until") and combat_status_text.contains("0.55"))
    check("MVP crowd control runtime", combat_status_text.contains("freeze_until") and combat_status_text.contains("stagger_until") and combat_status_text.contains("slow_until"))
    var fire_weak_target:Dictionary = {"name":"Fire Dragon","level":300,"mvp":true}
    var fire_match:float = MONSTERS.skill_damage_multiplier("Mage","mage_frost_prison",fire_weak_target)
    var fire_resist:float = MONSTERS.skill_damage_multiplier("Mage","mage_comet",fire_weak_target)
    check("elemental weakness bonus", is_equal_approx(fire_match,1.25))
    check("elemental resistance penalty", is_equal_approx(fire_resist,0.88))
    var combat_runtime_text:String = FileAccess.get_file_as_string("res://scripts/CombatRuntime.gd")
    var combat_rules_text:String = FileAccess.get_file_as_string("res://scripts/CombatRules.gd")
    check("specialization combat wiring", combat_runtime_text.contains("ClassTreeSystem.branch_bonus"))
    check("specialization range wiring", combat_rules_text.contains("ClassTreeSystem.branch_bonus"))
    for class_id:Variant in definitions.keys():
        var profile:Dictionary = TREE.class_profile(str(class_id))
        for branch_name:String in profile.get("branches",[]):
            var branch_hero:Dictionary = {"class":str(class_id),"level":25,"class_branch":branch_name,"class_mastery":0}
            var branch_bonus:Dictionary = TREE.branch_bonus(branch_hero)
            var has_effect:bool = false
            for bonus_value:Variant in branch_bonus.values():
                if abs(float(bonus_value)) > 0.0:
                    has_effect = true
                    break
            check("specialization has combat effect %s / %s" % [str(class_id),branch_name], has_effect)

    check("3D combat uses canonical progression stats", combat_runtime_text.contains("CharacterProgression.stats(hero)"))
    check("3D auto-attacks use canonical class formulas", combat_runtime_text.contains("ClassFormula.physical_power(hero)") and combat_runtime_text.contains("ClassFormula.magic_power(hero)"))
    check("3D incoming damage uses canonical defense", combat_runtime_text.contains("ClassFormula.defense(hero)"))

    var reset_hero:Dictionary = DATA.new_hero()
    reset_hero["stats"] = {"str":10,"agi":11,"vit":12,"int":13,"dex":14,"luk":15}
    reset_hero["stat_points"] = 7
    var reset_refund:int = preload("res://scripts/CharacterProgressionSystem.gd").reset_stats(reset_hero)
    check("stat reset returns exact allocated points", reset_refund == 69 and int(reset_hero.get("stat_points",0)) == 76)
    var high_level_hero:Dictionary = DATA.new_hero()
    high_level_hero["level"] = 250
    high_level_hero["stats"] = {"str":99,"agi":99,"vit":99,"int":99,"dex":99,"luk":99}
    var high_level_stats:Dictionary = preload("res://scripts/CharacterProgressionSystem.gd").stats(high_level_hero)
    check("level 250 has scaled live HP", int(high_level_stats.get("max_hp",0)) > 7000)
    var skill_bar_text:String = FileAccess.get_file_as_string("res://scripts/HWSkillBarRuntime.gd")
    check("skill hotkeys 1-8", skill_bar_text.contains("KEY_1") and skill_bar_text.contains("KEY_8") and skill_bar_text.contains("func _use_slot"))
    var main_runtime_text:String = FileAccess.get_file_as_string("res://scripts/Main.gd")
    check("player skill action runtime", main_runtime_text.contains("func use_skill(skill_id:String)->void:"))
    check("Acolyte offensive healing skills continue into combat", main_runtime_text.contains('if skill_id=="aco_sanctuary" or target==null:'))
    check("Warrior defense break skills", main_runtime_text.contains('"war_earthbreaker","war_emperors_judgment","war_immortal_arsenal"') and main_runtime_text.contains("defense_break_percent"))
    check("Mage defense break and burning skills", main_runtime_text.contains('"mage_void_lance","mage_arcane_overload"') and main_runtime_text.contains('skill_id=="mage_comet" or skill_id=="mage_meteor_surge"'))
    check("Archer trap control", main_runtime_text.contains('skill_id=="arch_trap"') and main_runtime_text.contains("root_until"))
    check("live combat consumes defense break", combat_runtime_text.contains("func effective_monster_defense(monster:Dictionary)->int") and combat_runtime_text.contains("defense_break_until"))
    check("live combat processes monster burn", combat_runtime_text.contains("burn_until") and combat_runtime_text.contains("burn_tick"))
    check("live combat stops rooted monsters", combat_runtime_text.contains('monster.get("root_until",0.0)') and combat_runtime_text.contains("continue"))
    check("age SP bonus is not double counted", not combat_runtime_text.contains('hero["max_sp"]=max_sp+int(hero.get("age_sp_bonus",0))'))
    var skill_test_hero:Dictionary = DATA.new_hero()
    SKILLS.ensure_state(skill_test_hero)
    skill_test_hero["sp"] = 100
    skill_test_hero["skill_cooldowns"] = {}
    var first_skill:String = str(SKILLS.all_skills(str(skill_test_hero.get("class","Warrior")))[0].get("id",""))
    var skill_result:Dictionary = SKILLS.use(skill_test_hero,first_skill,100.0)
    check("learned skill executes", bool(skill_result.get("ok",false)))
    check("skill consumes SP", int(skill_test_hero.get("sp",100)) < 100)
    check("skill starts cooldown", float(skill_test_hero.get("skill_cooldowns",{}).get(first_skill,0.0)) > 100.0)

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

    for name:Variant in MVP.definitions().keys():
        var boss_name:String = str(name)
        var boss_details:Dictionary = MONSTERS.details({"name":boss_name,"level":int(MVP.definitions()[name].get("level",1)),"mvp":true})
        check("MVP combat identity " + boss_name, str(boss_details.get("element","Neutral")) != "Neutral" and str(boss_details.get("role","Melee")) != "Melee")
        check("MVP weakness " + boss_name, str(boss_details.get("weakness","Neutral")) != "Neutral")
        check("MVP status profile " + boss_name, str(boss_details.get("status","None")) != "None")

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
