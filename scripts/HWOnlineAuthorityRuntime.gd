extends Node

## Honour War authoritative-session foundation.
## Server owns combat, progression, rental state, and persistence decisions.
## Clients may request actions; the server validates and broadcasts accepted state.

const PROTOCOL_VERSION:int = 1
const DEFAULT_PORT:int = 24567
const MAX_PLAYERS:int = 16

var session_id:String = "offline"
var is_server_authority:bool = false
var connected_peers:Array[int] = []
var last_sequence:int = 0
var state_revision:int = 0

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
    _wire_peer_signals()
    return true

func connect_client(address:String,port:int = DEFAULT_PORT) -> bool:
    var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
    var error:int = peer.create_client(address,port)
    if error != OK:
        return false
    multiplayer.multiplayer_peer = peer
    is_server_authority = false
    _wire_peer_signals()
    return true

func stop_session() -> void:
    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = null
    connected_peers.clear()
    is_server_authority = false
    session_id = "offline"

func request_action(action:String,payload:Dictionary = {}) -> void:
    var clean_action:String = action.strip_edges()
    if clean_action.is_empty():
        return
    if is_server_authority:
        _accept_action(multiplayer.get_unique_id(),clean_action,payload)
        return
    if multiplayer.multiplayer_peer == null:
        return
    _server_receive_action.rpc_id(1,clean_action,payload)

@rpc("any_peer","reliable")
func _server_receive_action(action:String,payload:Dictionary) -> void:
    if not multiplayer.is_server():
        return
    var sender:int = multiplayer.get_remote_sender_id()
    _accept_action(sender,action,payload)

func _accept_action(sender:int,action:String,payload:Dictionary) -> void:
    # All gameplay mutations must pass through this server-side boundary.
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

@rpc("authority","reliable")
func _broadcast_authoritative_event(event:Dictionary) -> void:
    if int(event.get("protocol",0)) != PROTOCOL_VERSION:
        return
    state_revision = maxi(state_revision,int(event.get("revision",state_revision)))
    # Gameplay systems subscribe by reading the event through this signal-like callback.
    _dispatch_event(event)

func _dispatch_event(event:Dictionary) -> void:
    var scene:Node = get_tree().current_scene
    if scene != null and scene.has_method("on_authoritative_event"):
        scene.call("on_authoritative_event",event)

func _wire_peer_signals() -> void:
    if multiplayer.peer_connected.is_connected(_on_peer_connected) == false:
        multiplayer.peer_connected.connect(_on_peer_connected)
    if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected) == false:
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(peer_id:int) -> void:
    if not connected_peers.has(peer_id):
        connected_peers.append(peer_id)

func _on_peer_disconnected(peer_id:int) -> void:
    connected_peers.erase(peer_id)

func is_authority() -> bool:
    return is_server_authority

func get_session_snapshot() -> Dictionary:
    return {
        "protocol":PROTOCOL_VERSION,
        "session":session_id,
        "authority":is_server_authority,
        "revision":state_revision,
        "sequence":last_sequence,
        "peers":connected_peers.duplicate()
    }
