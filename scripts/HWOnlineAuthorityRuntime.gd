extends Node

## Honour War authoritative-session runtime.
## The server owns accepted gameplay events. Clients may request actions, but
## malformed, unsupported, oversized, unauthenticated, or rate-limited requests
## never enter the authoritative event stream.

signal authoritative_event_received(event:Dictionary)
signal authoritative_action_accepted(event:Dictionary)
signal authority_action_rejected(peer_id:int, action:String, reason:String)
signal authentication_succeeded(peer_id:int, username:String, player:Dictionary)
signal authentication_failed(peer_id:int, username:String, reason:String)
signal player_persistence_failed(peer_id:int, username:String, reason:String)
signal peer_session_closing(peer_id:int, username:String, player:Dictionary)

const GameDataClass = preload("res://scripts/GameData.gd")
const AccountDatabaseClass = preload("res://scripts/HWAccountDatabase.gd")

const PROTOCOL_VERSION:int = 3
const DEFAULT_PORT:int = 24567
const MAX_PLAYERS:int = 16
const MAX_ACTIONS_PER_WINDOW:int = 30
const ACTION_WINDOW_SECONDS:float = 1.0
const MAX_PAYLOAD_KEYS:int = 24
const MAX_PAYLOAD_DEPTH:int = 3
const MAX_ARRAY_ITEMS:int = 64
const MAX_STRING_LENGTH:int = 256
const MIN_PASSWORD_LENGTH:int = 8
const ACCOUNT_CHALLENGE_TTL_SECONDS:float = 30.0

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
var account_database:RefCounted
var _login_nonces:Dictionary = {}
var _authenticated_peers:Dictionary = {}
var _peer_players:Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    account_database = AccountDatabaseClass.new()

func start_server(port:int = DEFAULT_PORT) -> bool:
    if account_database == null:
        account_database = AccountDatabaseClass.new()
    if not account_database.load_database():
        push_error("Honour War account database could not be loaded")
        return false
    var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
    var error:int = peer.create_server(port,MAX_PLAYERS)
    if error != OK:
        return false
    multiplayer.multiplayer_peer = peer
    is_server_authority = true
    session_id = "%s-%s" % [Time.get_datetime_string_from_system(true),PROTOCOL_VERSION]
    connected_peers.clear()
    _action_windows.clear()
    _login_nonces.clear()
    _authenticated_peers.clear()
    _peer_players.clear()
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
    _action_windows.clear()
    _wire_peer_signals()
    return true

func stop_session() -> void:
    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = null
    connected_peers.clear()
    _action_windows.clear()
    _login_nonces.clear()
    _authenticated_peers.clear()
    _peer_players.clear()
    is_server_authority = false
    session_id = "offline"
    last_sequence = 0
    state_revision = 0

func request_register(username:String,password:String) -> void:
    if is_server_authority:
        _register_local(multiplayer.get_unique_id(),username,password)
        return
    if multiplayer.multiplayer_peer == null:
        authentication_failed.emit(multiplayer.get_unique_id(),username,"offline")
        return
    if not AccountDatabaseClass.validate_username(username):
        authentication_failed.emit(multiplayer.get_unique_id(),username,"invalid_username")
        return
    if password.length() < MIN_PASSWORD_LENGTH:
        authentication_failed.emit(multiplayer.get_unique_id(),username,"password_too_short")
        return
    var salt:String = _new_salt()
    var verifier:String = AccountDatabaseClass.password_verifier(password,salt)
    _server_register.rpc_id(1,username.strip_edges(),salt,verifier)

func request_login(username:String,password:String) -> void:
    if is_server_authority:
        authentication_failed.emit(multiplayer.get_unique_id(),username,"server_use_local_login")
        return
    if multiplayer.multiplayer_peer == null:
        authentication_failed.emit(multiplayer.get_unique_id(),username,"offline")
        return
    if not AccountDatabaseClass.validate_username(username):
        authentication_failed.emit(multiplayer.get_unique_id(),username,"invalid_username")
        return
    if password.length() < MIN_PASSWORD_LENGTH:
        authentication_failed.emit(multiplayer.get_unique_id(),username,"password_too_short")
        return
    set_meta("pending_login_password",password)
    _server_begin_login.rpc_id(1,username.strip_edges().to_lower())

func request_logout() -> void:
    if is_server_authority:
        _logout_peer(multiplayer.get_unique_id())
    elif multiplayer.multiplayer_peer != null:
        _server_logout.rpc_id(1)

func is_peer_authenticated(peer_id:int) -> bool:
    return _authenticated_peers.has(peer_id)

func username_for_peer(peer_id:int) -> String:
    return str(_authenticated_peers.get(peer_id,""))

func player_for_peer(peer_id:int) -> Dictionary:
    var value:Variant = _peer_players.get(peer_id,{})
    return value.duplicate(true) if value is Dictionary else {}

func save_player_for_peer(peer_id:int,player:Dictionary) -> bool:
    if not is_server_authority or not is_peer_authenticated(peer_id):
        return false
    var username:String = username_for_peer(peer_id)
    if username.is_empty():
        return false
    var ok:bool = account_database.save_player(username,player)
    if ok:
        _peer_players[peer_id] = player.duplicate(true)
    else:
        player_persistence_failed.emit(peer_id,username,"database_write_failed")
    return ok

func set_player_for_peer(peer_id:int,player:Dictionary) -> bool:
    if not is_server_authority or not is_peer_authenticated(peer_id) or not player is Dictionary:
        return false
    _peer_players[peer_id] = player.duplicate(true)
    return true

func _register_local(peer_id:int,username:String,password:String) -> void:
    var normalized:String = username.strip_edges().to_lower()
    if not AccountDatabaseClass.validate_username(normalized):
        authentication_failed.emit(peer_id,normalized,"invalid_username")
        return
    if password.length() < MIN_PASSWORD_LENGTH:
        authentication_failed.emit(peer_id,normalized,"password_too_short")
        return
    if account_database.account_exists(normalized):
        authentication_failed.emit(peer_id,normalized,"account_exists")
        return
    var salt:String = _new_salt()
    var verifier:String = AccountDatabaseClass.password_verifier(password,salt)
    var player:Dictionary = GameDataClass.new_hero()
    player["account_username"] = normalized
    if not account_database.create_account(normalized,salt,verifier,player):
        authentication_failed.emit(peer_id,normalized,"account_create_failed")
        return
    authentication_succeeded.emit(peer_id,normalized,player)

@rpc("any_peer","reliable")
func _server_register(username:String,salt:String,verifier:String) -> void:
    if not multiplayer.is_server():
        return
    var sender:int = multiplayer.get_remote_sender_id()
    var normalized:String = username.strip_edges().to_lower()
    if sender <= 0 or not AccountDatabaseClass.validate_username(normalized):
        _send_auth_failure(sender,normalized,"invalid_username")
        return
    if salt.length() < 16 or verifier.length() != 64:
        _send_auth_failure(sender,normalized,"invalid_credentials")
        return
    if account_database.account_exists(normalized):
        _send_auth_failure(sender,normalized,"account_exists")
        return
    var player:Dictionary = GameDataClass.new_hero()
    player["account_username"] = normalized
    if not account_database.create_account(normalized,salt,verifier,player):
        _send_auth_failure(sender,normalized,"account_create_failed")
        return
    _authenticated_peers[sender] = normalized
    _peer_players[sender] = player.duplicate(true)
    _client_auth_success.rpc_id(sender,normalized,player.duplicate(true),session_id)
    authentication_succeeded.emit(sender,normalized,player)

@rpc("any_peer","reliable")
func _server_begin_login(username:String) -> void:
    if not multiplayer.is_server():
        return
    var sender:int = multiplayer.get_remote_sender_id()
    var normalized:String = username.strip_edges().to_lower()
    if sender <= 0 or not account_database.account_exists(normalized):
        _send_auth_failure(sender,normalized,"invalid_credentials")
        return
    var nonce:String = _new_nonce(sender,normalized)
    _login_nonces[sender] = {"username":normalized,"nonce":nonce,"expires":Time.get_unix_time_from_system()+ACCOUNT_CHALLENGE_TTL_SECONDS}
    var record:Dictionary = account_database.get_auth_record(normalized)
    _client_auth_challenge.rpc_id(sender,normalized,str(record.get("salt","")),nonce)

@rpc("any_peer","reliable")
func _server_finish_login(username:String,response:String) -> void:
    if not multiplayer.is_server():
        return
    var sender:int = multiplayer.get_remote_sender_id()
    var pending:Variant = _login_nonces.get(sender,{})
    if not pending is Dictionary:
        _send_auth_failure(sender,username,"challenge_missing")
        return
    var challenge:Dictionary = pending
    _login_nonces.erase(sender)
    if float(challenge.get("expires",0.0)) < Time.get_unix_time_from_system():
        _send_auth_failure(sender,username,"challenge_expired")
        return
    var normalized:String = str(challenge.get("username",""))
    if normalized != username.strip_edges().to_lower():
        _send_auth_failure(sender,normalized,"challenge_mismatch")
        return
    var nonce:String = str(challenge.get("nonce",""))
    if not account_database.authenticate_challenge(normalized,response,nonce):
        _send_auth_failure(sender,normalized,"invalid_credentials")
        return
    account_database.mark_login(normalized)
    var player:Dictionary = account_database.load_player(normalized,GameDataClass.new_hero())
    player["account_username"] = normalized
    _authenticated_peers[sender] = normalized
    _peer_players[sender] = player.duplicate(true)
    _client_auth_success.rpc_id(sender,normalized,player.duplicate(true),session_id)
    authentication_succeeded.emit(sender,normalized,player)

@rpc("authority","reliable")
func _client_auth_challenge(username:String,salt:String,nonce:String) -> void:
    var password:String = str(get_meta("pending_login_password",""))
    if password.is_empty():
        authentication_failed.emit(multiplayer.get_unique_id(),username,"password_unavailable")
        return
    var verifier:String = AccountDatabaseClass.password_verifier(password,salt)
    var response:String = AccountDatabaseClass.challenge_digest(verifier,nonce)
    set_meta("pending_login_password","")
    _server_finish_login.rpc_id(1,username,response)

@rpc("authority","reliable")
func _client_auth_success(username:String,player:Dictionary,server_session:String) -> void:
    set_meta("account_username",username)
    set_meta("server_session",server_session)
    authentication_succeeded.emit(multiplayer.get_unique_id(),username,player)

@rpc("authority","reliable")
func _client_auth_failure(username:String,reason:String) -> void:
    authentication_failed.emit(multiplayer.get_unique_id(),username,reason)

@rpc("any_peer","reliable")
func _server_logout() -> void:
    if not multiplayer.is_server():
        return
    _logout_peer(multiplayer.get_remote_sender_id())

func _logout_peer(peer_id:int) -> void:
    var username:String = username_for_peer(peer_id)
    var player:Dictionary = player_for_peer(peer_id)
    if is_server_authority and not username.is_empty() and not player.is_empty():
        peer_session_closing.emit(peer_id,username,player)
        account_database.save_player(username,player)
    _authenticated_peers.erase(peer_id)
    _peer_players.erase(peer_id)
    _login_nonces.erase(peer_id)
    if peer_id > 0 and not username.is_empty() and not is_server_authority:
        _client_auth_failure.rpc_id(peer_id,username,"logged_out")

func _send_auth_failure(peer_id:int,username:String,reason:String) -> void:
    if peer_id > 0:
        _client_auth_failure.rpc_id(peer_id,username,reason)
    authentication_failed.emit(peer_id,username,reason)

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
        if _consume_action_budget(multiplayer.get_unique_id()):
            _accept_action(multiplayer.get_unique_id(),clean_action,payload)
        else:
            authority_action_rejected.emit(multiplayer.get_unique_id(),clean_action,"rate_limited")
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
    if not is_peer_authenticated(sender):
        _reject_remote(sender,clean_action,"authentication_required")
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
    if not _action_is_allowed(action) or not _validate_payload(action,payload):
        _reject_remote(sender,action,"validation_failed")
        return
    var world:Node = get_node_or_null("/root/HWOnlineWorldState")
    if world != null:
        if action == "move" and bool(payload.get("absolute",false)) and world.has_method("validate_move_request"):
            if not world.validate_move_request(sender,payload):
                _reject_remote(sender,action,"invalid_world_movement")
                return
        elif action == "warp" and world.has_method("validate_warp_request"):
            if not world.validate_warp_request(sender,payload):
                _reject_remote(sender,action,"invalid_world_warp")
                return
    last_sequence += 1
    state_revision += 1
    var event:Dictionary = {
        "protocol":PROTOCOL_VERSION,
        "session":session_id,
        "sequence":last_sequence,
        "revision":state_revision,
        "sender":sender,
        "account":username_for_peer(sender),
        "action":action,
        "payload":payload.duplicate(true)
    }
    authoritative_action_accepted.emit(event)
    _broadcast_authoritative_event.rpc(event)

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
    if not _payload_within_limits(payload,0):
        return false
    match action:
        "move":
            if bool(payload.get("absolute",false)):
                return _finite_number(payload.get("x",0.0)) and _finite_number(payload.get("y",0.0)) and absf(float(payload.get("x",0.0))) <= 100000.0 and absf(float(payload.get("y",0.0))) <= 100000.0
            return _finite_number(payload.get("x",0.0)) and _finite_number(payload.get("y",0.0)) and absf(float(payload.get("x",0.0))) <= 1.0 and absf(float(payload.get("y",0.0))) <= 1.0
        "attack":
            return _positive_int(payload.get("target_id",payload.get("target",0)))
        "cast_skill", "use_skill":
            return _bounded_string(payload.get("skill",""),MAX_STRING_LENGTH)
        "use_item", "equip", "unequip", "refine", "refine_pet", "loot", "interact", "quest", "craft", "buy", "sell":
            return true
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

func _payload_within_limits(value:Variant,depth:int) -> bool:
    if depth > MAX_PAYLOAD_DEPTH:
        return false
    if value is String:
        return str(value).length() <= MAX_STRING_LENGTH
    if value is int or value is float:
        return _finite_number(value)
    if value is bool or value == null:
        return true
    if value is Dictionary:
        var dictionary:Dictionary = value
        if dictionary.size() > MAX_PAYLOAD_KEYS:
            return false
        for key:Variant in dictionary.keys():
            if str(key).length() > MAX_STRING_LENGTH:
                return false
            if not _payload_within_limits(dictionary[key],depth + 1):
                return false
        return true
    if value is Array:
        var array:Array = value
        if array.size() > MAX_ARRAY_ITEMS:
            return false
        for entry:Variant in array:
            if not _payload_within_limits(entry,depth + 1):
                return false
        return true
    return false

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
    var username:String = username_for_peer(peer_id)
    var player:Dictionary = player_for_peer(peer_id)
    if is_server_authority and not username.is_empty() and not player.is_empty():
        peer_session_closing.emit(peer_id,username,player)
        account_database.save_player(username,player)
    connected_peers.erase(peer_id)
    _action_windows.erase(peer_id)
    _login_nonces.erase(peer_id)
    _authenticated_peers.erase(peer_id)
    _peer_players.erase(peer_id)

func _new_salt() -> String:
    var rng:RandomNumberGenerator = RandomNumberGenerator.new()
    rng.randomize()
    return (str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec()) + ":" + str(rng.randi())).sha256_text()

func _new_nonce(peer_id:int,username:String) -> String:
    var rng:RandomNumberGenerator = RandomNumberGenerator.new()
    rng.randomize()
    return (session_id + ":" + str(peer_id) + ":" + username + ":" + str(Time.get_ticks_usec()) + ":" + str(rng.randi())).sha256_text()

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
        "authenticated_players":_authenticated_peers.size(),
        "max_players":MAX_PLAYERS,
        "rate_limit":MAX_ACTIONS_PER_WINDOW
    }
