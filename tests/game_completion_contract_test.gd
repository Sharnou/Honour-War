extends SceneTree

# Fast deterministic release contract for Honour War.
# Executed by CI with Godot 4.7.2.

const GAME_DATA = preload("res://scripts/GameData.gd")
const SKILLS = preload("res://scripts/SkillSystem.gd")
const SAVE = preload("res://scripts/SaveSystem.gd")
const COMBAT = preload("res://scripts/CombatRules.gd")
const TELEPORT = preload("res://scripts/TeleportSystem.gd")
const PET = preload("res://scripts/PetSystem.gd")
const MAX_GLB_COUNT := 53
var failures := 0

func _initialize() -> void:
    check("main scene", ProjectSettings.get_setting("application/run/main_scene", "") == "res://Main3D.tscn")
    check("Godot 4.7 target", ProjectSettings.get_setting("application/config/features", PackedStringArray()).has("4.7"))
    check("Forward+ renderer", ProjectSettings.get_setting("rendering/renderer/rendering_method", "") == "forward_plus")
    check("pet cap 250", int(PET.MAX_PET_LEVEL) == 250)

    var definitions: Dictionary = GAME_DATA.class_definitions()
    check("six playable classes", definitions.size() == 6)
    for class_id in definitions.keys():
        var id := str(class_id)
        check("skills " + id, SKILLS.all_skills(id).size() >= 8)
        var pet: Dictionary = PET.new_pet(id)
        check("automatic pet " + id, not pet.is_empty() and str(pet.get("species", "")) != "")
        check("pet binding " + id, str(pet.get("owner_class", "")) == id)

    for level in [1, 25, 50, 100, 200, 250]:
        var tier := GAME_DATA.class_tier_for_level(level)
        check("tier boundary %d" % level, tier >= 0 and tier <= 4)

    var hero: Dictionary = GAME_DATA.new_hero()
    SKILLS.ensure_state(hero)
    check("hero level cap", int(hero.get("level", 0)) <= GAME_DATA.MAX_HERO_LEVEL)
    check("hero starting age", int(hero.get("age", 0)) == GAME_DATA.STARTING_AGE)
    var hero_pet: Dictionary = hero.get("pet", {})
    check("hero pet", not hero_pet.is_empty())
    check("no strategy city state", not hero.has("city_building"))
    check("no soldier state", not hero.has("soldiers") and not hero.has("soldier_production"))
    check("no bank state", not hero.has("banks") and not hero.has("bank_territories"))
    check("no tower-defense state", not hero.has("tower_defense") and not hero.has("barracks"))
    var materials: Dictionary = hero.get("materials", {})
    check("refine materials", materials.has_all(["Phracon", "Emveretarcon", "Oridecon"]))
    var inventory: Dictionary = hero.get("inventory", {})
    var equipment: Dictionary = hero.get("equipment", {})
    check("starter weapon", inventory.has("Novice Sword") and str(equipment.get("weapon", "")) == "Novice Sword")
    check("starter armor", inventory.has("Novice Armor"))

    for class_id in definitions.keys():
        hero["class"] = str(class_id)
        check("combat range " + str(class_id), float(COMBAT.class_engagement_map(hero)) > 0.0)
        check("basic skill " + str(class_id), not SKILLS.all_skills(str(class_id)).is_empty())

    var warp: Dictionary = TELEPORT.parse_go("@go 0 230:220")
    check("@go command", bool(warp.get("ok", false)))
    check("@go coordinates", int(warp.get("x", -1)) == 230 and int(warp.get("y", -1)) == 220)

    hero = GAME_DATA.new_hero()
    check("local save", SAVE.save_game(hero))
    var restored: Dictionary = SAVE.load_game(GAME_DATA.new_hero())
    check("save restore", str(restored.get("class", "")) == str(hero.get("class", "")) and int(restored.get("level", 0)) == int(hero.get("level", 0)))

    var scene := FileAccess.get_file_as_string("res://Main3D.tscn")
    check("3D scene", not scene.is_empty())
    check("camera", scene.contains("Camera3D"))
    check("movement stability", scene.contains("MovementStabilityFix"))
    check("legacy state owner", scene.contains("LegacyGame"))
    check("gameplay runtime", scene.contains("GameplaySystemsRuntime"))

    var project := FileAccess.get_file_as_string("res://project.godot")
    check("online authority", project.contains("HWOnlineAuthorityRuntime="))
    check("online login", project.contains("HWOnlineLoginUI="))
    check("party service", project.contains("HWPartyService="))
    check("world state", project.contains("HWOnlineWorldState="))

    var camera := FileAccess.get_file_as_string("res://scripts/MovementStabilityFix.gd")
    check("A/D yaw", camera.contains("KEY_A") and camera.contains("KEY_D"))
    check("W/S pitch", camera.contains("KEY_W") and camera.contains("KEY_S"))
    check("middle mouse orbit", camera.contains("MOUSE_BUTTON_MIDDLE") and camera.contains("target_camera_pitch"))
    check("pitch clamp", camera.contains("MIN_CAMERA_PITCH") and camera.contains("MAX_CAMERA_PITCH"))
    check("authority absolute move", camera.contains("request_action(\"move\"") and camera.contains("\"absolute\":true"))

    var input_policy := FileAccess.get_file_as_string("res://scripts/HW3DInputPolicy.gd")
    check("3D input policy", input_policy.contains("InputMap.action_erase_events(action)"))

    var hud := FileAccess.get_file_as_string("res://scripts/HWPolishedInterfaceV2.gd")
    check("HUD guard", hud.contains("var bound:bool=false") and hud.contains("var bind_queued:bool=false"))
    check("HUD idempotent", hud.contains("is_instance_valid(root)"))

    var auth := FileAccess.get_file_as_string("res://scripts/HWOnlineAuthorityRuntime.gd")
    check("auth gate", auth.contains("is_peer_authenticated(sender)") and auth.contains("authentication_required"))
    check("register", auth.contains("request_register(username:String,password:String)"))
    check("login", auth.contains("request_login(username:String,password:String)"))
    check("player persistence", auth.contains("save_player_for_peer(peer_id:int,player:Dictionary)"))
    check("action validation", auth.contains("validate_move_request") and auth.contains("invalid_world_movement") and auth.contains("authoritative_action_accepted.emit(event)"))
    check("disconnect persistence", auth.contains("peer_session_closing") and auth.contains("account_database.save_player(username,player)"))

    var accounts := FileAccess.get_file_as_string("res://scripts/HWAccountDatabase.gd")
    check("account database", accounts.contains("honour_war_accounts.json") and accounts.contains("password_verifier") and accounts.contains("save_player"))
    var login_ui := FileAccess.get_file_as_string("res://scripts/HWOnlineLoginUI.gd")
    check("login connection gate", login_ui.contains("CONNECTION_CONNECTED") and login_ui.contains("pending_auth_action"))

    var party := FileAccess.get_file_as_string("res://scripts/HWPartyService.gd")
    check("party size 4", party.contains("MAX_PARTY_SIZE:int = 4"))
    check("party auth", party.contains("is_peer_authenticated(peer_id)"))
    check("party flow", party.contains("_server_invite") and party.contains("_server_accept_invite"))

    var world := FileAccess.get_file_as_string("res://scripts/HWOnlineWorldState.gd")
    check("world movement validation", world.contains("validate_move_request(peer_id:int,payload:Dictionary)") and world.contains("MOVE_SPEED_UNITS_PER_SECOND"))
    check("world warp validation", world.contains("validate_warp_request(peer_id:int,payload:Dictionary)") and world.contains("Teleport.MAPS.has(map_id)"))
    check("world disconnect save", world.contains("_on_peer_session_closing") and world.contains("save_player_for_peer"))

    var glb_workflow := FileAccess.get_file_as_string("res://.github/workflows/private-glb-preview-qa.yml")
    check("GLB QA revision pin", glb_workflow.contains("ref: ${{ github.sha }}"))
    check("GLB parser preflight", glb_workflow.contains("Preflight GLB validator parser contract"))
    check("53 generated GLBs", count_files("assets/3d/generated", ".glb") == MAX_GLB_COUNT)
    check("no forbidden tween alpha", not contains_text("scripts", "modulate:a"))

    if failures == 0:
        print("HONOUR_WAR_COMPLETENESS: PASS")
        quit(0)
    print("HONOUR_WAR_COMPLETENESS: FAILURES=%d" % failures)
    quit(1)

func check(label: String, condition: bool) -> void:
    if condition:
        print("PASS: " + label)
    else:
        failures += 1
        push_error("FAIL: " + label)

func count_files(root_path: String, extension: String) -> int:
    var dir := DirAccess.open("res://" + root_path)
    if dir == null:
        return 0
    var count := 0
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        if not dir.current_is_dir() and name.to_lower().ends_with(extension.to_lower()):
            count += 1
        name = dir.get_next()
    dir.list_dir_end()
    return count

func contains_text(root_path: String, needle: String) -> bool:
    var dir := DirAccess.open("res://" + root_path)
    if dir == null:
        return false
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        if dir.current_is_dir():
            if contains_text(root_path + "/" + name, needle):
                dir.list_dir_end()
                return true
        elif name.ends_with(".gd"):
            var text := FileAccess.get_file_as_string("res://" + root_path + "/" + name)
            if text.contains(needle):
                dir.list_dir_end()
                return true
        name = dir.get_next()
    dir.list_dir_end()
    return false
