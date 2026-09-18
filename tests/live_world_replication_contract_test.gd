extends SceneTree

## Deterministic contract for live MMORPG world presence replication.

const PROJECT_PATH := "res://project.godot"
const AUTHORITY_PATH := "res://scripts/HWOnlineAuthorityRuntime.gd"
const REPLICATION_PATH := "res://scripts/HWLiveWorldReplication.gd"
const GAME3D_PATH := "res://scripts/Game3D.gd"

func _initialize() -> void:
    _run()
    quit(0)

func _run() -> void:
    var project := FileAccess.get_file_as_string(PROJECT_PATH)
    var authority := FileAccess.get_file_as_string(AUTHORITY_PATH)
    var replication := FileAccess.get_file_as_string(REPLICATION_PATH)
    var game3d := FileAccess.get_file_as_string(GAME3D_PATH)

    _require(project.find('HWLiveWorldReplication="*res://scripts/HWLiveWorldReplication.gd"') >= 0, "live replication autoload missing")
    _require(authority.find("func get_authenticated_player_snapshots() -> Array:") >= 0, "authority snapshot API missing")
    _require(authority.find('"peer_id": peer_id') >= 0, "snapshot peer identity missing")
    _require(authority.find('"map_id": int(player.get("map_id",0))') >= 0, "snapshot map state missing")
    _require(replication.find("const SNAPSHOT_INTERVAL:float = 0.20") >= 0, "replication cadence missing")
    _require(replication.find("@rpc(" + '"authority","unreliable"' + ")") >= 0, "unreliable client snapshot RPC missing")
    _require(replication.find("func get_remote_players(map_id:int = -1) -> Dictionary:") >= 0, "remote player query API missing")
    _require(game3d.find("var remote_visuals:Dictionary = {}") >= 0, "remote visual registry missing")
    _require(game3d.find("func _update_remote_players(delta:float)->void:") >= 0, "remote player rendering pass missing")
    _require(game3d.find('root.add_to_group("network_player")') >= 0, "remote players must be separated from local-player identity")
    _require(game3d.find('root.set_meta("hw_network_player",true)') >= 0, "remote player metadata missing")
    _require(game3d.find("HW_RemoteGeneratedGLB") >= 0, "remote players must prefer generated GLB assets")
    # Match the actual HUD contract without depending on a quoted substring
    # representation that can vary between parser/source transformations.
    _require(game3d.find("ONLINE:") >= 0, "online HUD state missing")
    print("LIVE_WORLD_REPLICATION_CONTRACT_OK")

func _require(condition:bool, message:String) -> void:
    if not condition:
        push_error("LIVE_WORLD_REPLICATION_CONTRACT_FAIL: " + message)
        quit(1)
