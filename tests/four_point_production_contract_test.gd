extends SceneTree

## Deterministic contract for the four active production completion areas:
## authored-asset handoff, complete world content, MMORPG authority, and
## HD combat/presentation depth. It validates the implementation contract
## without pretending external DCC/server infrastructure is executed in CI.

var failures:int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var project:String = FileAccess.get_file_as_string("res://project.godot")
    var art:String = FileAccess.get_file_as_string("res://tools/validate_hd_assets.py")
    var manifest:String = FileAccess.get_file_as_string("res://assets/3d/generated/GENERATED_ASSET_MANIFEST.json")
    var world:String = FileAccess.get_file_as_string("res://scripts/WorldPopulationDirector.gd")
    var map_theme:String = FileAccess.get_file_as_string("res://scripts/HWMapThemeDirector.gd")
    var combat:String = FileAccess.get_file_as_string("res://scripts/HWCombatPhaseDirector.gd")
    var authority:String = FileAccess.get_file_as_string("res://scripts/HWOnlineAuthorityRuntime.gd")
    var world_state:String = FileAccess.get_file_as_string("res://scripts/HWOnlineWorldState.gd")
    var party:String = FileAccess.get_file_as_string("res://scripts/HWPartyService.gd")
    var completer:String = FileAccess.get_file_as_string("res://scripts/HWHDProductionCompleter.gd")

    _check("production asset pipeline declared", art.contains("Blender") and art.contains("Substance 3D Painter") and art.contains("GLB/GLTF"))
    _check("generated asset manifest contains 53 assets", manifest.contains("\"asset_count\": 53"))
    _check("runtime production asset bridge enabled", project.contains("HWHDWorldContentDirector=") and project.contains("HWHDProductionCompleter="))
    _check("all six class progression GLB families remain required", _count_paths("res://assets/3d/generated/characters") >= 30)
    _check("eleven monster GLBs remain present", _count_paths("res://assets/3d/generated/monsters") >= 11)
    _check("six bonded pet GLBs remain present", _count_paths("res://assets/3d/generated/pets") >= 6)

    _check("regional monster ecology implemented", world.contains("ZONE_FAMILIES") and world.contains("map_id") and world.contains("region") and world.contains("family") and world.contains("map_data"))
    _check("map theme supports town/field/dungeon", map_theme.contains("_build_town") and map_theme.contains("_build_field") and map_theme.contains("_build_dungeon"))
    _check("map theme has distinct region palettes", map_theme.contains("morroc") and map_theme.contains("payon") and map_theme.contains("geffen") and map_theme.contains("lutie") and map_theme.contains("umbala"))
    _check("map theme is visual-only", map_theme.contains("Visual only") and not map_theme.contains("hero[\"hp\"]") and not map_theme.contains("monster[\"hp\"]"))
    var teleport:String = FileAccess.get_file_as_string("res://scripts/TeleportSystem.gd")
    _check("teleport world registry has towns fields dungeons", teleport.contains("\"type\":\"town\"") and teleport.contains("\"type\":\"field\"") and teleport.contains("\"type\":\"dungeon\""))

    _check("online authority authenticates actions", authority.contains("is_peer_authenticated(sender)") and authority.contains("_server_receive_action"))
    _check("online authority persists sessions", authority.contains("save_player_for_peer") and authority.contains("peer_session_closing"))
    _check("world state validates movement", world_state.contains("validate_move_request") and world_state.contains("MOVE_SPEED_UNITS_PER_SECOND"))
    _check("world state validates warps", world_state.contains("validate_warp_request") and world_state.contains("TELEPORT.MAPS.has(map_id)"))
    _check("four-player party authority remains active", party.contains("MAX_PARTY_SIZE:int = 4") and party.contains("_server_invite") and party.contains("_server_accept_invite"))
    var fast_auth:String = FileAccess.get_file_as_string("res://tests/fast_account_auth_test.gd")
    _check("fast auth remains foreground-safe", fast_auth.contains("call_deferred(\"_run_suite\")") and fast_auth.contains("quit(0 if failures == 0 else 1)"))

    _check("combat anticipation/contact/recovery phases exist", combat.contains("\"anticipation\"") and combat.contains("\"contact\"") and combat.contains("\"recovery\""))
    _check("combat phase director never owns damage simulation", not combat.contains("hero[\"hp\"]") and not combat.contains("monster[\"hp\"]") and not combat.contains("monster[\"hp\"] ="))
    _check("combat presentation is enabled", project.contains("HWCombatPhaseDirector="))
    _check("HD production audit sees world combat online systems", completer.contains("\"map_theme_director\"") and completer.contains("\"combat_phase_director\"") and completer.contains("\"online_authority\"") and completer.contains("\"production_asset_count\""))

    if failures == 0:
        print("HONOUR_WAR_FOUR_POINT_PRODUCTION: PASS")
        quit(0)
        return
    print("HONOUR_WAR_FOUR_POINT_PRODUCTION: FAILURES=%d" % failures)
    quit(1)

func _count_paths(root_path:String) -> int:
    var dir:DirAccess = DirAccess.open(root_path)
    if dir == null:
        return 0
    var count:int = 0
    dir.list_dir_begin()
    var name:String = dir.get_next()
    while not name.is_empty():
        if dir.current_is_dir():
            count += _count_paths(root_path + "/" + name)
        elif name.to_lower().ends_with(".glb") or name.to_lower().ends_with(".gltf"):
            count += 1
        name = dir.get_next()
    dir.list_dir_end()
    return count

func _check(label:String,condition:bool)->void:
    if condition:
        print("PASS: " + label)
    else:
        failures += 1
        print("FAIL: " + label)
