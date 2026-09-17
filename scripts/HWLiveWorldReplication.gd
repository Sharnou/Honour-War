extends Node

## Live MMORPG world-presence replication.
## Server-authoritative movement/map state is broadcast to authenticated clients.
## Gameplay progression remains owned by the authoritative gameplay services.

signal world_snapshot_updated(snapshot:Array)
signal world_chat_received(sender_id:int, username:String, message:String)

const AUTHORITY_PATH:String = "/root/HWOnlineAuthorityRuntime"
const SNAPSHOT_INTERVAL:float = 0.20
const MAX_REMOTE_PLAYERS:int = 15

var authority:Node
var snapshot_elapsed:float = 0.0
var remote_players:Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind_authority")

func _process(delta:float) -> void:
    snapshot_elapsed += delta
    if authority == null or not is_instance_valid(authority):
        _bind_authority()
        return
    if not authority.is_authority():
        return
    if snapshot_elapsed < SNAPSHOT_INTERVAL:
        return
    snapshot_elapsed = 0.0
    _broadcast_world_snapshot()

func _bind_authority() -> void:
    authority = get_node_or_null(AUTHORITY_PATH)

func _broadcast_world_snapshot() -> void:
    if authority == null or not authority.is_authority():
        return
    var values:Variant = authority.get_authenticated_player_snapshots()
    if not values is Array:
        return
    var snapshot:Array = values as Array
    if snapshot.size() > MAX_REMOTE_PLAYERS + 1:
        snapshot = snapshot.slice(0,MAX_REMOTE_PLAYERS + 1)
    _client_world_snapshot.rpc(snapshot)

func _sanitize_snapshot(value:Variant) -> Array:
    if not value is Array:
        return []
    var output:Array = []
    for entry:Variant in value:
        if not entry is Dictionary:
            continue
        var item:Dictionary = entry
        var peer_id:int = int(item.get("peer_id",0))
        if peer_id <= 0:
            continue
        var normalized:Dictionary = {
            "peer_id": peer_id,
            "username": str(item.get("username","Player")).strip_edges().substr(0,32),
            "class": str(item.get("class","Warrior")),
            "level": clamp(int(item.get("level",1)),1,250),
            "age": max(18,int(item.get("age",18))),
            "hp": max(0,int(item.get("hp",0))),
            "max_hp": max(1,int(item.get("max_hp",1))),
            "sp": max(0,int(item.get("sp",0))),
            "max_sp": max(1,int(item.get("max_sp",1))),
            "map_id": max(0,int(item.get("map_id",0))),
            "pos_x": float(item.get("pos_x",595.0)),
            "pos_y": float(item.get("pos_y",340.0)),
            "gender": str(item.get("gender","U"))
        }
        if is_finite(normalized["pos_x"]) and is_finite(normalized["pos_y"]):
            output.append(normalized)
    return output

@rpc("authority","unreliable")
func _client_world_snapshot(snapshot:Array) -> void:
    if authority != null and authority.is_authority():
        return
    var clean:Array = _sanitize_snapshot(snapshot)
    var current_id:int = multiplayer.get_unique_id()
    var next:Dictionary = {}
    for entry:Dictionary in clean:
        var peer_id:int = int(entry.get("peer_id",0))
        if peer_id <= 0 or peer_id == current_id:
            continue
        next[peer_id] = entry
    remote_players = next
    world_snapshot_updated.emit(clean)

func get_remote_players(map_id:int = -1) -> Dictionary:
    var output:Dictionary = {}
    for key:Variant in remote_players.keys():
        var entry:Dictionary = remote_players[key]
        if map_id >= 0 and int(entry.get("map_id",-1)) != map_id:
            continue
        output[key] = entry.duplicate(true)
    return output

func clear_remote_players() -> void:
    remote_players.clear()
    world_snapshot_updated.emit([])

func notify_world_chat(sender_id:int,username:String,message:String) -> void:
    var clean:String = message.strip_edges()
    if clean.is_empty():
        return
    world_chat_received.emit(sender_id,username,clean.substr(0,256))
