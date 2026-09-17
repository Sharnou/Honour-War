extends SceneTree

# End-to-end release contract checks for the local Honour War game shell.
# Run with Godot 4.7.2 after an editor import pass:
# godot --headless --editor --path . --quit
# godot --headless --path . --script res://tests/game_completion_contract_test.gd

const GAME_DATA = preload("res://scripts/GameData.gd")
const SKILLS = preload("res://scripts/SkillSystem.gd")
const SAVE = preload("res://scripts/SaveSystem.gd")
const COMBAT = preload("res://scripts/CombatRules.gd")
const TELEPORT = preload("res://scripts/TeleportSystem.gd")
const PET = preload("res://scripts/PetSystem.gd")
const MAX_GLB_COUNT:int = 53

var failures:int = 0

func _initialize() -> void:
    _check("Main3D is the project main scene", ProjectSettings.get_setting("application/run/main_scene", "") == "res://Main3D.tscn")
    _check("Godot 4.7 feature target", ProjectSettings.get_setting("application/config/features", PackedStringArray()).has("4.7"))
    _check("Forward+ renderer selected", ProjectSettings.get_setting("rendering/renderer/rendering_method", "") == "forward_plus")
    _check("pet level cap is 250", int(PET.MAX_PET_LEVEL) == 250)

    var definitions:Dictionary = GAME_DATA.class_definitions()
    _check("six playable classes", definitions.size() == 6)
    for class_id in definitions.keys():
        _check("skill tree exists: " + str(class_id), SKILLS.all_skills(str(class_id)).size() >= 8)
        var pet:Dictionary = PET.new_pet(str(class_id))
        _check("automatic bonded pet: " + str(class_id), not pet.is_empty() and str(pet.get("species", "")).strip_edges() != "")
        _check("pet owner class binding: " + str(class_id), str(pet.get("owner_class", "")) == str(class_id))

    for level in [1, 25, 50, 100, 200, 250]:
        var tier:int = GAME_DATA.class_tier_for_level(level)
        _check("class tier boundary %d" % level, tier >= 0 and tier <= 4)

    var hero:Dictionary = GAME_DATA.new_hero()
    SKILLS.ensure_state(hero)
    _check("hero starts within level cap", int(hero.get("level", 0)) <= GAME_DATA.MAX_HERO_LEVEL)
    _check("hero starts at required age", int(hero.get("age", 0)) == GAME_DATA.STARTING_AGE)
    _check("hero has automatic pet", hero.get("pet", {}) is Dictionary and not (hero.get("pet", {}) as Dictionary).is_empty())
    _check("hero has required refinement materials", hero.get("materials", {}) is Dictionary and (hero.get("materials", {}) as Dictionary).has_all(["Phracon", "Emveretarcon", "Oridecon"]))
    _check("default pet is bound to hero class", str((hero.get("pet", {}) as Dictionary).get("owner_class", "")) == str(hero.get("class", "Warrior")))

    for class_id in definitions.keys():
        hero["class"] = str(class_id)
        var skill_list:Array = SKILLS.all_skills(str(class_id))
        _check("combat range present: " + str(class_id), float(COMBAT.class_engagement_map(hero)) > 0.0)
        _check("basic skill present: " + str(class_id), not skill_list.is_empty())

    var warp:Dictionary = TELEPORT.parse_go("@go 0 230:220")
    _check("coordinate warp command accepted", bool(warp.get("ok", false)))
    _check("coordinate warp preserves X/Y", int(warp.get("x", -1)) == 230 and int(warp.get("y", -1)) == 220)

    hero = GAME_DATA.new_hero()
    var save_ok:bool = SAVE.save_game(hero)
    _check("local save succeeds", save_ok)
    var restored:Dictionary = SAVE.load_game(GAME_DATA.new_hero())
    _check("local save restores hero state", str(restored.get("class", "")) == str(hero.get("class", "")) and int(restored.get("level", 0)) == int(hero.get("level", 0)))

    var main_scene_text:String = FileAccess.get_file_as_string("res://Main3D.tscn")
    _check("Main3D scene exists", not main_scene_text.is_empty())
    _check("MovementStabilityFix scene node present", main_scene_text.contains("MovementStabilityFix"))
    _check("Camera3D scene node present", main_scene_text.contains("Camera3D"))
    _check("LegacyGame state owner preserved", main_scene_text.contains("LegacyGame"))
    _check("Gameplay systems runtime present", main_scene_text.contains("GameplaySystemsRuntime"))

    var project_text:String = FileAccess.get_file_as_string("res://project.godot")
    _check("online authority autoload present", project_text.contains("HWOnlineAuthorityRuntime="))

    var camera_script:String = FileAccess.get_file_as_string("res://scripts/MovementStabilityFix.gd")
    _check("A/D camera yaw contract", camera_script.contains("KEY_A") and camera_script.contains("KEY_D"))
    _check("W/S camera pitch contract", camera_script.contains("KEY_W") and camera_script.contains("KEY_S"))
    _check("middle mouse orbit contract", camera_script.contains("MOUSE_BUTTON_MIDDLE") and camera_script.contains("target_camera_pitch"))
    _check("camera pitch is clamped", camera_script.contains("MIN_CAMERA_PITCH") and camera_script.contains("MAX_CAMERA_PITCH"))

    var input_policy:String = FileAccess.get_file_as_string("res://scripts/HW3DInputPolicy.gd")
    _check("legacy keyboard movement is disabled in 3D", input_policy.contains("InputMap.action_erase_events(action)"))

    var polished_hud:String = FileAccess.get_file_as_string("res://scripts/HWPolishedInterfaceV2.gd")
    _check("polished HUD binding is guarded", polished_hud.contains("var bound:bool=false") and polished_hud.contains("var bind_queued:bool=false"))
    _check("polished HUD build is idempotent", polished_hud.contains("if root!=null and is_instance_valid(root):"))

    var private_glb_workflow:String = FileAccess.get_file_as_string("res://.github/workflows/private-glb-preview-qa.yml")
    _check("private GLB QA pins triggering revision", private_glb_workflow.contains("ref: ${{ github.sha }}"))
    _check("private GLB QA parser preflight present", private_glb_workflow.contains("Preflight GLB validator parser contract"))

    _check("generated GLB inventory is complete", _count_files("assets/3d/generated", ".glb") == MAX_GLB_COUNT)
    _check("forbidden tween alpha pattern absent", not _contains_text("scripts", "modulate:a"))

    if failures == 0:
        print("PASS: Honour War game completion contract")
        quit(0)
    else:
        print("FAIL: Honour War game completion contract: ", failures, " failure(s)")
        quit(1)

func _check(label:String, condition:bool) -> void:
    if not condition:
        failures += 1
        print("FAIL: ", label)
    else:
        print("PASS: ", label)

func _count_files(path:String, extension:String) -> int:
    var total:int = 0
    var dir:DirAccess = DirAccess.open(path)
    if dir == null:
        return 0
    dir.list_dir_begin()
    var name:String = dir.get_next()
    while not name.is_empty():
        if name.begins_with("."):
            name = dir.get_next()
            continue
        var full:String = path.path_join(name)
        if dir.current_is_dir():
            total += _count_files(full, extension)
        elif name.to_lower().ends_with(extension.to_lower()):
            total += 1
        name = dir.get_next()
    dir.list_dir_end()
    return total

func _contains_text(path:String, needle:String) -> bool:
    var dir:DirAccess = DirAccess.open(path)
    if dir == null:
        return false
    dir.list_dir_begin()
    var name:String = dir.get_next()
    while not name.is_empty():
        if name.begins_with("."):
            name = dir.get_next()
            continue
        var full:String = path.path_join(name)
        if dir.current_is_dir():
            if _contains_text(full, needle):
                dir.list_dir_end()
                return true
        elif name.to_lower().ends_with(".gd"):
            if FileAccess.get_file_as_string(full).contains(needle):
                dir.list_dir_end()
                return true
        name = dir.get_next()
    dir.list_dir_end()
    return false
