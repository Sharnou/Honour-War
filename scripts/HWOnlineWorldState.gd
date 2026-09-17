extends Node

## Server-authoritative persistent world state for connected players.
## The client may predict movement locally, but accepted position/map changes are
## validated here and the authoritative event is broadcast by HWOnlineAuthorityRuntime.

const AUTHORITY_PATH:String = "/root/HWOnlineAuthorityRuntime"
const TELEPORT = preload("res://scripts/TeleportSystem.gd")
const GameDataClass = preload("res://scripts/GameData.gd")

const MOVE_SPEED_UNITS_PER_SECOND:float = 210.0
const MOVE_LATENCY_TOLERANCE:float = 42.0
const SAVE_INTERVAL_SECONDS:float = 5.0
const MAX_MAP_ID:int = 1000

var authority:Node
var last_positions:Dictionary = {}
var last_position_times:Dictionary = {}
var save_timers:Dictionary = {}
var local_authenticated_player:Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind_authority")

func _bind_authority() -> void:
    authority = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        return
    if not authority.authentication_succeeded.is_connected(_on_authentication_succeeded):
        authority.authentication_succeeded.connect(_on_authentication_succeeded)
    if not authority.authentication_failed.is_connected(_on_authentication_failed):
        authority.authentication_failed.connect(_on_authentication_failed)
    if not authority.authoritative_action_accepted.is_connected(_on_server_action_accepted):
        authority.authoritative_action_accepted.connect(_on_server_action_accepted)
    if not authority.authoritative_event_received.is_connected(_on_authoritative_event):
        authority.authoritative_event_received.connect(_on_authoritative_event)

func _process(delta:float) -> void:
    if authority == null or not is_instance_valid(authority):
        _bind_authority()
        return
    if not authority.is_authority():
        return
    var expired:Array[int] = []
    for peer_id in save_timers.keys():
        var value:float = float(save_timers[peer_id]) + delta
        save_timers[peer_id] = value
        if value >= SAVE_INTERVAL_SECONDS:
            expired.append(int(peer_id))
    for peer_id in expired:
        _persist_peer(peer_id)

func _on_authentication_succeeded(peer_id:int,username:String,player:Dictionary) -> void:
    if authority.is_authority():
        authority.set_player_for_peer(peer_id,player)
        last_positions[peer_id] = Vector2(float(player.get("pos_x",595.0)),float(player.get("pos_y",340.0)))
        last_position_times[peer_id] = Time.get_ticks_msec() / 1000.0
        save_timers[peer_id] = 0.0
    else:
        if peer_id == multiplayer.get_unique_id():
            local_authenticated_player = player.duplicate(true)

func _on_authentication_failed(_peer_id:int,_username:String,_reason:String) -> void:
    if not authority.is_authority():
        local_authenticated_player = {}

func _on_server_action_accepted(event:Dictionary) -> void:
    if not authority.is_authority():
        return
    _apply_server_action(event)

func _apply_server_action(event:Dictionary) -> void:
    var peer_id:int = int(event.get("sender",0))
    if peer_id <= 0 or not authority.is_peer_authenticated(peer_id):
        return
    var action:String = str(event.get("action",""))
    var payload:Variant = event.get("payload",{})
    if not payload is Dictionary:
        return
    var data:Dictionary = authority.player_for_peer(peer_id)
    if data.is_empty():
        return
    match action:
        "move": _apply_move(peer_id,data,payload)
        "warp": _apply_warp(peer_id,data,payload)
        _:
            return
    authority.set_player_for_peer(peer_id,data)

func _apply_move(peer_id:int,player:Dictionary,payload:Dictionary) -> void:
    if not bool(payload.get("absolute",false)):
        return
    var x:float = float(payload.get("x",player.get("pos_x",595.0)))
    var y:float = float(payload.get("y",player.get("pos_y",340.0)))
    var map_id:int = int(player.get("map_id",0))
    var target:Vector2 = _clamp_to_map(map_id,Vector2(x,y))
    var previous:Vector2 = last_positions.get(peer_id,Vector2(float(player.get("pos_x",595.0)),float(player.get("pos_y",340.0))))
    var now:float = Time.get_ticks_msec() / 1000.0
    var elapsed:float = max(0.016,now-float(last_position_times.get(peer_id,now)))
    var max_distance:float = MOVE_SPEED_UNITS_PER_SECOND*elapsed+MOVE_LATENCY_TOLERANCE
    if previous.distance_to(target) > max_distance:
        return
    player["pos_x"] = target.x
    player["pos_y"] = target.y
    last_positions[peer_id] = target
    last_position_times[peer_id] = now
    save_timers[peer_id] = float(save_timers.get(peer_id,0.0))

func _apply_warp(peer_id:int,player:Dictionary,payload:Dictionary) -> void:
    var map_id:int = int(payload.get("map_id",0))
    if map_id < 0 or map_id > MAX_MAP_ID or not TELEPORT.MAPS.has(map_id):
        return
    var x:float = float(payload.get("x",0.0))
    var y:float = float(payload.get("y",0.0))
    var point:Vector2 = _clamp_to_map(map_id,Vector2(365.0+x,120.0+y))
    player["map_id"] = map_id
    player["pos_x"] = point.x
    player["pos_y"] = point.y
    player["last_safe_city"] = TELEPORT.map_name(map_id) if not TELEPORT.is_dungeon(map_id) else str(player.get("last_safe_city","Prontera"))
    last_positions[peer_id] = point
    last_position_times[peer_id] = Time.get_ticks_msec() / 1000.0
    save_timers[peer_id] = 0.0

func _on_authoritative_event(event:Dictionary) -> void:
    if authority != null and authority.is_authority():
        return
    if int(event.get("sender",0)) != multiplayer.get_unique_id():
        return
    var action:String = str(event.get("action",""))
    var payload:Variant = event.get("payload",{})
    if not payload is Dictionary:
        return
    if action == "move" and bool((payload as Dictionary).get("absolute",false)):
        _apply_client_authoritative_move(payload as Dictionary)
    elif action == "warp":
        _apply_client_authoritative_warp(payload as Dictionary)

func _apply_client_authoritative_move(payload:Dictionary) -> void:
    var scene:Node = get_tree().current_scene
    var legacy:Node = scene.get_node_or_null("LegacyGame") if scene != null else null
    if legacy == null:
        return
    var hero:Variant = legacy.get("hero")
    if not hero is Dictionary:
        return
    hero["pos_x"] = float(payload.get("x",hero.get("pos_x",595.0)))
    hero["pos_y"] = float(payload.get("y",hero.get("pos_y",340.0)))
    local_authenticated_player = hero.duplicate(true)

func _apply_client_authoritative_warp(payload:Dictionary) -> void:
    var scene:Node = get_tree().current_scene
    var legacy:Node = scene.get_node_or_null("LegacyGame") if scene != null else null
    if legacy == null:
        return
    var hero:Variant = legacy.get("hero")
    if not hero is Dictionary:
        return
    var map_id:int = int(payload.get("map_id",hero.get("map_id",0)))
    hero["map_id"] = map_id
    hero["pos_x"] = 365.0+float(payload.get("x",0.0))
    hero["pos_y"] = 120.0+float(payload.get("y",0.0))
    local_authenticated_player = hero.duplicate(true)

func _persist_peer(peer_id:int) -> void:
    if authority == null or not authority.is_peer_authenticated(peer_id):
        return
    if authority.save_player_for_peer(peer_id,authority.player_for_peer(peer_id)):
        save_timers[peer_id] = 0.0

func _clamp_to_map(map_id:int,point:Vector2) -> Vector2:
    var data:Dictionary = TELEPORT.MAPS.get(map_id,{})
    var min_x:float = 365.0
    var min_y:float = 120.0
    var max_x:float = min_x+float(data.get("width",1200))-1.0
    var max_y:float = min_y+float(data.get("height",700))-1.0
    return Vector2(clamp(point.x,min_x,max_x),clamp(point.y,min_y,max_y))

func get_local_authenticated_player()->Dictionary:
    return local_authenticated_player.duplicate(true)
