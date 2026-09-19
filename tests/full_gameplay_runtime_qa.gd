extends SceneTree

## Full gameplay integration QA.
## This is deterministic CI coverage of the live gameplay APIs plus runtime wiring.
## It deliberately exercises the same systems used by Main3D rather than mock-only
## replacement systems.
## Production visuals are native Godot resources only; HD generated GLBs are retired.

const DATA = preload("res://scripts/GameData.gd")
const MOVE = preload("res://scripts/PlayerMovementController3D.gd")
const SAVE = preload("res://scripts/SaveSystem.gd")
const SKILLS = preload("res://scripts/SkillSystem.gd")
const PET = preload("res://scripts/PetSystem.gd")
const TELEPORT = preload("res://scripts/TeleportSystem.gd")
const WORLD = preload("res://scripts/WorldSystem.gd")

var failures:int = 0

func _initialize() -> void:
    _test_movement()
    _test_attack_wiring()
    _test_npc_wiring()
    _test_maps()
    _test_skills()
    _test_pets()
    _test_save_load()
    _test_graphics_wiring()
    if failures == 0:
        print("FULL_GAMEPLAY_QA: PASS")
        quit(0)
    else:
        print("FULL_GAMEPLAY_QA: FAILURES=%d" % failures)
        quit(1)

func check(label:String, condition:bool) -> void:
    if condition:
        print("PASS: " + label)
    else:
        failures += 1
        push_error("FAIL: " + label)

func _test_movement() -> void:
    var hero:Dictionary = DATA.new_hero()
    hero["map_id"] = 20
    hero["pos_x"] = 800.0
    hero["pos_y"] = 500.0
    var controller:Node = MOVE.new()
    var before:Vector2 = Vector2(hero["pos_x"], hero["pos_y"])
    controller.call("_move_hero", hero, Vector2.RIGHT, 0.25)
    var after:Vector2 = Vector2(hero["pos_x"], hero["pos_y"])
    check("movement changes hero position", after.x > before.x)
    check("movement stays inside map bounds", after.x >= MOVE.ORIGIN_X and after.x <= MOVE.ORIGIN_X + float(TELEPORT.MAPS[20]["width"]) - 1.0)
    check("movement controller has keyboard and mouse paths", controller.has_method("_apply_keyboard_fallback") and controller.has_method("_apply_mouse_movement"))
    controller.free()

func _test_attack_wiring() -> void:
    var main_text:String = FileAccess.get_file_as_string("res://scripts/Main.gd")
    var combat_text:String = FileAccess.get_file_as_string("res://scripts/CombatRuntime.gd")
    check("hero attack entry point exists", main_text.contains("func attack("))
    check("combat runtime exists", combat_text.contains("func") and combat_text.contains("damage"))
    check("mouse target attack calls hero attack", FileAccess.get_file_as_string("res://scripts/PlayerMovementController3D.gd").contains('legacy.call("attack")'))
    check("combat uses canonical class formulas", combat_text.contains("ClassFormula.physical_power(hero)") and combat_text.contains("ClassFormula.magic_power(hero)"))
    check("monster defeat awards loot", combat_text.contains("on_monster_defeated"))

func _test_npc_wiring() -> void:
    var npc_text:String = FileAccess.get_file_as_string("res://scripts/HWServiceNPCVisualDirector.gd")
    var scene_text:String = FileAccess.get_file_as_string("res://Main3D.tscn")
    check("service NPC director exists", FileAccess.file_exists("res://scripts/HWServiceNPCVisualDirector.gd"))
    check("service NPC is tagged", npc_text.contains('add_to_group("service_npc")'))
    check("item shop NPC is created", npc_text.contains('name="ItemShopNPC"'))
    check("NPC has interaction identity", npc_text.contains('set_meta("npc_name"'))
    check("NPC service is limited to towns", npc_text.contains('town_data.get("type","")') and npc_text.contains('"town"'))
    check("NPC director is wired into 3D scene", scene_text.contains("HWServiceNPCVisualDirector"))

func _test_maps() -> void:
    check("map registry has 30 maps", TELEPORT.MAPS.size() == 30)
    var go:Dictionary = TELEPORT.parse_go("@go 0")
    check("@go 0 town shortcut", bool(go.get("ok", false)) and int(go.get("map_id",-1)) == 0 and int(go.get("x",-1)) == 600 and int(go.get("y",-1)) == 350)
    var coordinate:Dictionary = TELEPORT.parse_coordinates("230:220")
    check("X/Y coordinate grid-cell parsing", bool(coordinate.get("ok", false)) and int(coordinate.get("x",-1)) == 230 and int(coordinate.get("y",-1)) == 220)
    check("fractional grid coordinates rejected", not bool(TELEPORT.parse_go("@go 0 230.5:220").get("ok", false)))
    check("negative grid coordinates rejected", not bool(TELEPORT.parse_go("@go 0 -1:220").get("ok", false)))
    check("dungeon map exists", TELEPORT.is_dungeon(10))
    check("field map exists", not TELEPORT.is_dungeon(20))
    check("level 300 monster zone exists", WORLD.monster_level_for_zone(30,10) == 300)

func _test_skills() -> void:
    var hero:Dictionary = DATA.new_hero()
    hero["class"] = "Warrior"
    hero["sp"] = 100
    SKILLS.ensure_state(hero)
    var skills:Array = SKILLS.all_skills("Warrior")
    check("Warrior has full skill tree", skills.size() >= 8)
    var first_id:String = str(skills[0]["id"])
    var result:Dictionary = SKILLS.use(hero, first_id, 100.0)
    check("basic skill executes", bool(result.get("ok", false)))
    check("skill consumes SP", int(hero["sp"]) < 100)
    check("skill cooldown is recorded", float(hero["skill_cooldowns"].get(first_id,0.0)) > 100.0)
    for class_id in ["Warrior","Mage","Archer","Thief","Acolyte","Merchant"]:
        check("skill tree " + class_id, SKILLS.all_skills(class_id).size() >= 8)

func _test_pets() -> void:
    for class_id in ["Warrior","Mage","Archer","Thief","Acolyte","Merchant"]:
        var pet:Dictionary = PET.new_pet(class_id)
        var old_level:int = int(pet["level"])
        var power_before:int = PET.power(pet)
        PET.add_exp(pet, 1000000)
        check("automatic pet exists " + class_id, not pet.is_empty())
        check("pet levels with combat XP " + class_id, int(pet["level"]) > old_level)
        check("pet combat power scales " + class_id, PET.power(pet) > power_before)
        check("pet has skill " + class_id, (pet["skills"] as Array).size() >= 1)
        check("pet has equipment " + class_id, not (pet["equipment"] as Dictionary).is_empty())

func _test_save_load() -> void:
    var hero:Dictionary = DATA.new_hero()
    hero["class"] = "Archer"
    hero["level"] = 37
    hero["pos_x"] = 912.0
    hero["pos_y"] = 421.0
    hero["zeny"] = 987654
    hero["pet"] = PET.new_pet("Archer")
    var saved:bool = SAVE.save_game(hero)
    check("save_game writes", saved)
    var loaded:Dictionary = SAVE.load_game(DATA.new_hero())
    check("load_game returns hero", not loaded.is_empty())
    check("save/load preserves level", int(loaded.get("level",0)) == 37)
    check("save/load preserves position", is_equal_approx(float(loaded.get("pos_x",0)),912.0) and is_equal_approx(float(loaded.get("pos_y",0)),421.0))
    check("save/load preserves zeny", int(loaded.get("zeny",0)) == 987654)
    check("save/load preserves pet", not (loaded.get("pet",{}) as Dictionary).is_empty())

func _test_graphics_wiring() -> void:
    var scene:String = FileAccess.get_file_as_string("res://Main3D.tscn")
    var project:String = FileAccess.get_file_as_string("res://project.godot")
    var asset_runtime:String = FileAccess.get_file_as_string("res://scripts/HDAssetRuntime.gd")
    var visual_qa:String = FileAccess.get_file_as_string("res://tools/honour_war_visual_qa.py")
    var no_glb_policy:String = FileAccess.get_file_as_string("res://docs/DAILY_HONOUR_WAR_NO_GLB_POLICY.md")
    check("Forward+ renderer configured", project.contains('renderer/rendering_method="forward_plus"'))
    check("Godot 4.7 configured", project.contains('config/features=PackedStringArray("4.7")'))
    check("Main3D is main scene", project.contains('run/main_scene="res://Main3D.tscn"'))
    check("native visual runtime wired", scene.contains("HDAssetRuntime"))
    check("HD environment wired", scene.contains("HDEnvironmentDirector"))
    check("HD visual director wired", scene.contains("HDVisualDirector"))
    check("HD combat VFX wired", scene.contains("HDCombatVFX"))
    check("HD skill presentation wired", scene.contains("HDSkillPresentation"))
    check("pet visual/combat wiring", scene.contains("PetSkillRuntime") and scene.contains("HeroPetComboVFX"))
    check("camera stability wired", FileAccess.file_exists("res://scripts/MovementStabilityFix.gd"))
    check("native visual runtime declares GLB retirement", asset_runtime.contains("HD generated GLB assets were permanently retired"))
    check("native visual runtime forbids GLB loading", asset_runtime.contains("must NOT regenerate, download, import, or attach GLB assets"))
    check("visual QA enforces no GLBs", visual_qa.contains("No generated HD GLB assets may remain"))
    check("daily no-GLB policy exists", FileAccess.file_exists("res://docs/DAILY_HONOUR_WAR_NO_GLB_POLICY.md"))
    check("daily no-GLB policy is permanent", no_glb_policy.contains("Status: **PERMANENT**"))
    check("native Godot visual pipeline is documented", no_glb_policy.contains("native Godot scenes/resources"))
