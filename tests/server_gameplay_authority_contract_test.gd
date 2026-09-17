extends SceneTree

## Contract for server-authoritative gameplay execution.

func _initialize() -> void:
    var runtime:=FileAccess.get_file_as_string("res://scripts/HWServerGameplayRuntime.gd")
    var project:=FileAccess.get_file_as_string("res://project.godot")
    _require(project.find('HWServerGameplayRuntime="*res://scripts/HWServerGameplayRuntime.gd"') >= 0,"runtime autoload missing")
    _require(runtime.find("func _on_action(event:Dictionary) -> void:") >= 0,"action dispatcher missing")
    _require(runtime.find('"attack"') >= 0 and runtime.find("GameplayFormula.physical_damage") >= 0,"authoritative combat missing")
    _require(runtime.find("LootSystem.on_monster_defeated") >= 0,"authoritative loot progression missing")
    _require(runtime.find("authority.set_player_for_peer(peer_id,player)") >= 0,"authoritative player state commit missing")
    _require(runtime.find("authority.save_player_for_peer(peer_id,player)") >= 0,"periodic persistence missing")
    _require(runtime.find("MAX_MONSTERS_PER_MAP") >= 0 and runtime.find("MAX_MONSTER_LEVEL") >= 0,"bounded monster authority missing")
    print("SERVER_GAMEPLAY_AUTHORITY_CONTRACT_OK")
    quit(0)

func _require(ok:bool,message:String)->void:
    if not ok:
        push_error("SERVER_GAMEPLAY_AUTHORITY_CONTRACT_FAIL: "+message)
        quit(1)
