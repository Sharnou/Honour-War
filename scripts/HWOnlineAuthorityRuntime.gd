extends Node

## Honour War authoritative-session runtime.
## The server owns accepted gameplay events. Clients may request actions, but
## malformed, unsupported, oversized, or rate-limited requests never enter the
## authoritative event stream.

signal authoritative_event_received(event:Dictionary)
signal authority_action_rejected(peer_id:int, action:String, reason:String)

const PROTOCOL_VERSION:int = 2
const DEFAULT_PORT:int = 24567
const MAX_PLAYERS:int = 16
const MAX_ACTIONS_PER_WINDOW:int = 30
const ACTION_WINDOW_SECONDS:float = 1.0
const MAX_PAYLOAD_KEYS:int = 24
const MAX_STRING_LENGTH:int = 256

const ALLOWED_ACTIONS:Array[String] = [
    "move", "attack", "cast_skill", "use_skill", "use_item", "equip", "unequip",
    "refine", "refine_pet", "loot", "interact", "chat", "pet_action", "quest",
    "craft", "buy", "sell", "warp", "rent_ss"
]

var session_id:String = "offline"
var is_server_authority:bool = false
var connected_peers:Array[int] = []
var last_sequence:int = 0
var state_revision:int = 0
var _action_windows:Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func start_server(port:int = DEFAULT_PORT) -> bool:
    var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
    var error:int = peer.create_server(port,MAX_PLAYERS)
    if error != OK:
        return false
    multiplayer.multiplayer_peer = peer
    is_server_authority = true
    session_id = "%s-%s" % [Time.get_datetime_string_from_system(true),PROTOCOL_VERSION]
    connected_peers.clear()
    _action_windows.clear()
    last_sequence = 0
    state_revision = 0
    _wire_peer_signals()
    return true

func connect_client(address:String,port:int = DEFAULT_PORT) -> bool:
    var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
    var error:int = peer.create_client(address,port)
    if error != OK:
        return false
    multiplayer.multiplayer_peer = peer
    is_server_authority = false
    connected_peers.clear()
    _wire_peer_signals()
    return true

func stop_session() -> void:
    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = null
    connected_peers.clear()
    _action_windows.clear()
    is_server_authority = false
    session_id = "offline"
    last_sequence = 0
    state_revision = 0

func request_action(action:String,payload:Dictionary = {}) -> void:
    var clean_action:String = _normalize_action(action)
    if clean_action.is_empty():
        return
    if not _action_is_allowed(clean_action):
        authority_action_rejected.emit(multiplayer.get_unique_id(),clean_action,"unsupported_action")
        return
    if not _validate_payload(clean_action,payload):
        authority_action_rejected.emit(multiplayer.get_unique_id(),clean_action,"invalid_payload")
        return
    if is_server_authority:
        _accept_action(multiplayer.get_unique_id(),clean_action,payload)
        return
    if multiplayer.multiplayer_peer == null:
        authority_action_rejected.emit(multiplayer.get_unique_id(),clean_action,"offline")
        return
    _server_receive_action.rpc_id(1,clean_action,payload.duplicate(true))

@rpc("any_peer","reliable")
func _server_receive_action(action:String,payload:Dictionary) -> void:
    if not multiplayer.is_server():
        return
    var sender:int = multiplayer.get_remote_sender_id()
    var clean_action:String = _normalize_action(action)
    if sender <= 0:
        _reject_remote(sender,clean_action,"invalid_sender")
        return
    if not _action_is_allowed(clean_action):
        _reject_remote(sender,clean_action,"unsupported_action")
        return
    if not _validate_payload(clean_action,payload):
        _reject_remote(sender,clean_action,"invalid_payload")
        return
    if not _consume_action_budget(sender):
        _reject_remote(sender,clean_action,"rate_limited")
        return
    _accept_action(sender,clean_action,payload)

func _accept_action(sender:int,action:String,payload:Dictionary) -> void:
    # All gameplay mutations must pass through this server-side boundary.
    if not _action_is_allowed(action) or not _validate_payload(action,payload):
        _reject_remote(sender,action,"validation_failed")
        return
    last_sequence += 1
    state_revision += 1
    var event:Dictionary = {
        "protocol":PROTOCOL_VERSION,
        "session":session_id,
        "sequence":last_sequence,
        "revision":state_revision,
        "sender":sender,
        "action":action,
        "payload":payload.duplicate(true)
    }
    _broadcast_authoritative_event.rpc(event)
    _dispatch_event(event)

@rpc("authority","reliable")
func _broadcast_authoritative_event(event:Dictionary) -> void:
    if int(event.get("protocol",0)) != PROTOCOL_VERSION:
        return
    state_revision = maxi(state_revision,int(event.get("revision",state_revision)))
    _dispatch_event(event)

func _dispatch_event(event:Dictionary) -> void:
    authoritative_event_received.emit(event)
    var scene:Node = get_tree().current_scene
    if scene != null and scene.has_method("on_authoritative_event"):
        scene.call("on_authoritative_event",event)

@rpc("authority","reliable")
func _client_receive_rejection(action:String,reason:String) -> void:
    authority_action_rejected.emit(multiplayer.get_unique_id(),action,reason)

func _reject_remote(peer_id:int,action:String,reason:String) -> void:
    authority_action_rejected.emit(peer_id,action,reason)
    if peer_id > 0:
        _client_receive_rejection.rpc_id(peer_id,action,reason)

func _normalize_action(action:String) -> String:
    return action.strip_edges().to_lower()

func _action_is_allowed(action:String) -> bool:
    return action in ALLOWED_ACTIONS

func _validate_payload(action:String,payload:Dictionary) -> bool:
    if payload.size() > MAX_PAYLOAD_KEYS:
        return false
    for key in payload.keys():
        if str(key).length() > MAX_STRING_LENGTH:
            return false
    match action:
        "move":
            return _finite_number(payload.get("x",0.0)) and _finite_number(payload.get("y",0.0)) and absf(float(payload.get("x",0.0))) <= 1.0 and absf(float(payload.get("y",0.0))) <= 1.0
        "attack":
            return _positive_int(payload.get("target_id",payload.get("target",0)))
        "cast_skill", "use_skill":
            return _bounded_string(payload.get("skill",""),MAX_STRING_LENGTH)
        "use_item", "equip", "unequip", "refine", "refine_pet", "loot", "interact", "quest", "craft", "buy", "sell":
            return payload.is_empty() or _bounded_dictionary_strings(payload)
        "chat":
            return _bounded_string(payload.get("message",""),MAX_STRING_LENGTH)
        "pet_action":
            return _bounded_string(payload.get("action",""),MAX_STRING_LENGTH)
        "warp":
            return _positive_or_zero_int(payload.get("map_id",0)) and _finite_number(payload.get("x",0.0)) and _finite_number(payload.get("y",0.0))
        "rent_ss":
            return true
        _:
            return false

func _bounded_dictionary_strings(payload:Dictionary) -> bool:
    for value in payload.values():
        if value is String and str(value).length() > MAX_STRING_LENGTH:
            return false
    return true

func _bounded_string(value:Variant,max_length:int) -> bool:
    return value is String and str(value).length() <= max_length and not str(value).strip_edges().is_empty()

func _finite_number(value:Variant) -> bool:
    if not (value is float or value is int):
        return false
    return is_finite(float(value))

func _positive_int(value:Variant) -> bool:
    return value is int and int(value) > 0

func _positive_or_zero_int(value:Variant) -> bool:
    return value is int and int(value) >= 0

func _consume_action_budget(peer_id:int) -> bool:
    var now:float = Time.get_ticks_msec() / 1000.0
    var entries:Array = _action_windows.get(peer_id,[])
    var fresh:Array = []
    for timestamp in entries:
        if now - float(timestamp) <= ACTION_WINDOW_SECONDS:
            fresh.append(timestamp)
    if fresh.size() >= MAX_ACTIONS_PER_WINDOW:
        _action_windows[peer_id] = fresh
        return false
    fresh.append(now)
    _action_windows[peer_id] = fresh
    return true

func _wire_peer_signals() -> void:
    if multiplayer.peer_connected.is_connected(_on_peer_connected) == false:
        multiplayer.peer_connected.connect(_on_peer_connected)
    if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected) == false:
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(peer_id:int) -> void:
    if not connected_peers.has(peer_id):
        connected_peers.append(peer_id)
    if is_server_authority:
        _action_windows[peer_id] = []

func _on_peer_disconnected(peer_id:int) -> void:
    connected_peers.erase(peer_id)
    _action_windows.erase(peer_id)

func is_authority() -> bool:
    return is_server_authority

func get_session_snapshot() -> Dictionary:
    return {
        "protocol":PROTOCOL_VERSION,
        "session":session_id,
        "authority":is_server_authority,
        "revision":state_revision,
        "sequence":last_sequence,
        "peers":connected_peers.duplicate(),
        "max_players":MAX_PLAYERS,
        "rate_limit":MAX_ACTIONS_PER_WINDOW
    }
