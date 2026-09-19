extends Node

const HWAccountDatabaseClass = preload("res://scripts/HWAccountDatabaseClass.gd")

## Persistent automatic-login service.
## A successful password login can issue a revocable bearer token. The client
## stores the token locally, not the account password. The server stores only
## a SHA-256 digest of the token. Auto-login rotates the token after success.

signal auto_login_token_issued(peer_id:int, username:String, token:String)

const AUTHORITY_PATH:String = "/root/HWOnlineAuthorityRuntime"
const DEFAULT_PATH:String = "user://honour_war_auto_login_tokens.json"
const SCHEMA_VERSION:int = 1
const TOKEN_LENGTH:int = 64
const GameDataClass = preload("res://scripts/GameData.gd")

var path:String = DEFAULT_PATH
var tokens:Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_tokens()

func load_tokens() -> bool:
    tokens.clear()
    if not FileAccess.file_exists(path):
        return true
    var file:FileAccess = FileAccess.open(path,FileAccess.READ)
    if file == null:
        return false
    var parsed:Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        return false
    var root:Dictionary = parsed
    if int(root.get("schema",0)) != SCHEMA_VERSION:
        return false
    var raw_tokens:Variant = root.get("tokens",{})
    if not raw_tokens is Dictionary:
        return false
    tokens = raw_tokens.duplicate(true)
    return true

func flush() -> bool:
    var file:FileAccess = FileAccess.open(path,FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({"schema":SCHEMA_VERSION,"tokens":tokens}))
    file.close()
    return true

func issue_token(username:String) -> String:
    var normalized:String = username.strip_edges().to_lower()
    if normalized.is_empty():
        return ""
    var rng:RandomNumberGenerator = RandomNumberGenerator.new()
    rng.randomize()
    var token:String = (normalized + ":" + str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec()) + ":" + str(rng.randi()) + ":" + str(rng.randi())).sha256_text()
    tokens[normalized] = {
        "digest":token.sha256_text(),
        "issued_at":Time.get_unix_time_from_system()
    }
    if not flush():
        tokens.erase(normalized)
        return ""
    return token

func authenticate_token(username:String,token:String) -> bool:
    var normalized:String = username.strip_edges().to_lower()
    if normalized.is_empty() or token.length() != TOKEN_LENGTH:
        return false
    var record:Variant = tokens.get(normalized,{})
    if not record is Dictionary:
        return false
    var digest:String = str(record.get("digest",""))
    return _constant_time_equal(digest,token.sha256_text())

func revoke_token(username:String) -> bool:
    var normalized:String = username.strip_edges().to_lower()
    if not tokens.has(normalized):
        return true
    tokens.erase(normalized)
    return flush()

func request_issue_token() -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        return
    if authority.is_server_authority:
        _issue_for_peer(multiplayer.get_unique_id())
        return
    if multiplayer.multiplayer_peer != null:
        _server_issue_auto_login_token.rpc_id(1)

func request_auto_login(username:String,token:String) -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null or username.strip_edges().is_empty() or token.is_empty():
        return
    if authority.is_server_authority:
        _auto_login_local(multiplayer.get_unique_id(),username,token)
        return
    if multiplayer.multiplayer_peer != null:
        _server_auto_login.rpc_id(1,username.strip_edges().to_lower(),token)

func revoke_current_token(username:String) -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        return
    if authority.is_server_authority:
        revoke_token(username)
    elif multiplayer.multiplayer_peer != null:
        _server_revoke_auto_login_token.rpc_id(1,username.strip_edges().to_lower())

func _issue_for_peer(peer_id:int) -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null or not authority.is_peer_authenticated(peer_id):
        return
    var username:String = authority.username_for_peer(peer_id)
    var token:String = issue_token(username)
    if token.is_empty():
        return
    if not authority.is_server_authority:
        _client_auto_login_token.rpc_id(peer_id,username,token)
    auto_login_token_issued.emit(peer_id,username,token)

func _auto_login_local(peer_id:int,username:String,token:String) -> void:
    _authenticate_for_peer(peer_id,username,token)

func _authenticate_for_peer(peer_id:int,username:String,token:String) -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null or not authority.is_server_authority:
        return
    var normalized:String = username.strip_edges().to_lower()
    if peer_id <= 0 or not HWAccountDatabaseClass.validate_username(normalized) or not authenticate_token(normalized,token):
        if peer_id > 0:
            if peer_id == multiplayer.get_unique_id():
                authority.authentication_failed.emit(peer_id,normalized,"auto_login_invalid")
            else:
                authority._client_auth_failure.rpc_id(peer_id,normalized,"auto_login_invalid")
        return
    var account_database:RefCounted = authority.account_database
    if account_database == null or not account_database.account_exists(normalized):
        if peer_id == multiplayer.get_unique_id():
            authority.authentication_failed.emit(peer_id,normalized,"auto_login_invalid")
        else:
            authority._client_auth_failure.rpc_id(peer_id,normalized,"auto_login_invalid")
        return
    var player:Dictionary = account_database.load_player(normalized,GameDataClass.new_hero())
    player["account_username"] = normalized
    if not player.has("gender"):
        player["gender"] = HWOnlineAuthorityRuntime.gender_from_username(normalized)
    authority._authenticated_peers[peer_id] = normalized
    authority._peer_players[peer_id] = player.duplicate(true)
    account_database.mark_login(normalized)
    if peer_id == multiplayer.get_unique_id():
        authority.authentication_succeeded.emit(peer_id,normalized,player)
        authority._client_auth_success(normalized,player.duplicate(true),authority.session_id)
    else:
        authority._client_auth_success.rpc_id(peer_id,normalized,player.duplicate(true),authority.session_id)
        authority.authentication_succeeded.emit(peer_id,normalized,player)
    var rotated:String = issue_token(normalized)
    if not rotated.is_empty():
        if peer_id == multiplayer.get_unique_id():
            auto_login_token_issued.emit(peer_id,normalized,rotated)
        else:
            _client_auto_login_token.rpc_id(peer_id,normalized,rotated)
            auto_login_token_issued.emit(peer_id,normalized,rotated)

@rpc("any_peer","reliable")
func _server_issue_auto_login_token() -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null or not multiplayer.is_server():
        return
    var sender:int = multiplayer.get_remote_sender_id()
    _issue_for_peer(sender)

@rpc("any_peer","reliable")
func _server_auto_login(username:String,token:String) -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null or not multiplayer.is_server():
        return
    var sender:int = multiplayer.get_remote_sender_id()
    _authenticate_for_peer(sender,username,token)

@rpc("any_peer","reliable")
func _server_revoke_auto_login_token() -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null or not multiplayer.is_server():
        return
    var sender:int = multiplayer.get_remote_sender_id()
    if sender <= 0 or not authority.is_peer_authenticated(sender):
        return
    revoke_token(authority.username_for_peer(sender))

@rpc("authority","reliable")
func _client_auto_login_token(username:String,token:String) -> void:
    auto_login_token_issued.emit(multiplayer.get_unique_id(),username,token)

func _constant_time_equal(left:String,right:String) -> bool:
    if left.length() != right.length():
        return false
    var result:int = 0
    for index in left.length():
        result |= left.unicode_at(index) ^ right.unicode_at(index)
    return result == 0