extends Node

## Server-authoritative party service for Honour War.
## Party membership is never accepted from an unauthenticated peer and is capped
## at four members. The gameplay authority remains responsible for combat/state.

signal party_updated(snapshot:Dictionary)
signal party_invite_received(party_id:String,leader_id:int)
signal party_action_rejected(reason:String)

const AUTHORITY_PATH:String = "/root/HWOnlineAuthorityRuntime"
const MAX_PARTY_SIZE:int = 4

var parties:Dictionary = {}
var peer_party:Dictionary = {}
var invitations:Dictionary = {}
var next_party_id:int = 1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func request_create_party() -> void:
    if _is_server():
        _create_party_for_peer(multiplayer.get_unique_id())
    else:
        _server_create_party.rpc_id(1)

func request_invite(target_peer_id:int) -> void:
    if _is_server():
        _invite_peer(multiplayer.get_unique_id(),target_peer_id)
    else:
        _server_invite.rpc_id(1,target_peer_id)

func request_accept_invite(party_id:String) -> void:
    if _is_server():
        _accept_invite(multiplayer.get_unique_id(),party_id)
    else:
        _server_accept_invite.rpc_id(1,party_id)

func request_leave_party() -> void:
    if _is_server():
        _leave_party(multiplayer.get_unique_id())
    else:
        _server_leave_party.rpc_id(1)

func request_kick(target_peer_id:int) -> void:
    if _is_server():
        _kick_peer(multiplayer.get_unique_id(),target_peer_id)
    else:
        _server_kick.rpc_id(1,target_peer_id)

func get_peer_party_id(peer_id:int) -> String:
    return str(peer_party.get(peer_id,""))

func get_party_snapshot(party_id:String) -> Dictionary:
    var party:Variant = parties.get(party_id,{})
    return party.duplicate(true) if party is Dictionary else {}

func _is_server() -> bool:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    return authority != null and authority.is_authority()

func _authority() -> Node:
    return get_node_or_null(AUTHORITY_PATH)

func _authenticated(peer_id:int) -> bool:
    var authority:Node = _authority()
    return authority != null and authority.is_peer_authenticated(peer_id)

func _username(peer_id:int) -> String:
    var authority:Node = _authority()
    return authority.username_for_peer(peer_id) if authority != null else ""

func _peer_connected(peer_id:int) -> bool:
    if peer_id <= 0 or multiplayer == null or not multiplayer.has_multiplayer_peer():
        return false
    if peer_id == multiplayer.get_unique_id():
        return false
    return multiplayer.get_peers().has(peer_id)

func _create_party_for_peer(peer_id:int) -> void:
    if not _authenticated(peer_id):
        _reject(peer_id,"authentication_required")
        return
    if peer_party.has(peer_id):
        _reject(peer_id,"already_in_party")
        return
    var party_id:String = "party-%04d" % next_party_id
    next_party_id += 1
    parties[party_id] = {"id":party_id,"leader":peer_id,"members":[peer_id],"created_by":_username(peer_id)}
    peer_party[peer_id] = party_id
    _send_snapshot(party_id)

func _invite_peer(sender:int,target:int) -> void:
    if not _authenticated(sender) or not _authenticated(target):
        _reject(sender,"authentication_required")
        return
    var party_id:String = get_peer_party_id(sender)
    if party_id.is_empty():
        _reject(sender,"not_in_party")
        return
    var party:Dictionary = get_party_snapshot(party_id)
    if int(party.get("leader",0)) != sender:
        _reject(sender,"leader_required")
        return
    var members:Array = party.get("members",[])
    if members.size() >= MAX_PARTY_SIZE:
        _reject(sender,"party_full")
        return
    if peer_party.has(target):
        _reject(sender,"target_already_in_party")
        return
    var pending:Array = invitations.get(target,[])
    if not pending.has(party_id):
        pending.append(party_id)
    invitations[target] = pending
    if _peer_connected(target):
        _client_party_invite.rpc_id(target,party_id,sender)

func _accept_invite(peer_id:int,party_id:String) -> void:
    if not _authenticated(peer_id):
        _reject(peer_id,"authentication_required")
        return
    if peer_party.has(peer_id):
        _reject(peer_id,"already_in_party")
        return
    var pending:Array = invitations.get(peer_id,[])
    if not pending.has(party_id):
        _reject(peer_id,"invite_not_found")
        return
    var party:Variant = parties.get(party_id,{})
    if not party is Dictionary:
        _reject(peer_id,"party_not_found")
        return
    var members:Array = party.get("members",[])
    if members.size() >= MAX_PARTY_SIZE:
        _reject(peer_id,"party_full")
        return
    members.append(peer_id)
    party["members"] = members
    parties[party_id] = party
    peer_party[peer_id] = party_id
    pending.erase(party_id)
    invitations[peer_id] = pending
    _send_snapshot(party_id)

func _leave_party(peer_id:int) -> void:
    var party_id:String = get_peer_party_id(peer_id)
    if party_id.is_empty():
        _reject(peer_id,"not_in_party")
        return
    _remove_member(party_id,peer_id)

func _kick_peer(sender:int,target:int) -> void:
    var party_id:String = get_peer_party_id(sender)
    if party_id.is_empty():
        _reject(sender,"not_in_party")
        return
    var party:Dictionary = get_party_snapshot(party_id)
    if int(party.get("leader",0)) != sender:
        _reject(sender,"leader_required")
        return
    if not party.get("members",[]).has(target):
        _reject(sender,"target_not_in_party")
        return
    if target == sender:
        _reject(sender,"leader_cannot_kick_self")
        return
    _remove_member(party_id,target)

func _remove_member(party_id:String,peer_id:int) -> void:
    var party:Dictionary = get_party_snapshot(party_id)
    if party.is_empty():
        peer_party.erase(peer_id)
        return
    var members:Array = party.get("members",[])
    members.erase(peer_id)
    peer_party.erase(peer_id)
    if members.is_empty():
        parties.erase(party_id)
        invitations.erase(peer_id)
        return
    var leader:int = int(party.get("leader",0))
    if leader == peer_id or not members.has(leader):
        leader = int(members[0])
    party["leader"] = leader
    party["members"] = members
    parties[party_id] = party
    _send_snapshot(party_id)

func _send_snapshot(party_id:String) -> void:
    var party:Dictionary = get_party_snapshot(party_id)
    if party.is_empty():
        return
    var members:Array = party.get("members",[])
    for peer_id in members:
        var target:int = int(peer_id)
        if _peer_connected(target):
            _client_party_snapshot.rpc_id(target,party)
    party_updated.emit(party)

func _reject(peer_id:int,reason:String) -> void:
    party_action_rejected.emit(reason)
    if _peer_connected(peer_id):
        _client_party_rejection.rpc_id(peer_id,reason)

@rpc("any_peer","reliable")
func _server_create_party() -> void:
    if not multiplayer.is_server():
        return
    _create_party_for_peer(multiplayer.get_remote_sender_id())

@rpc("any_peer","reliable")
func _server_invite(target_peer_id:int) -> void:
    if not multiplayer.is_server():
        return
    _invite_peer(multiplayer.get_remote_sender_id(),target_peer_id)

@rpc("any_peer","reliable")
func _server_accept_invite(party_id:String) -> void:
    if not multiplayer.is_server():
        return
    _accept_invite(multiplayer.get_remote_sender_id(),party_id)

@rpc("any_peer","reliable")
func _server_leave_party() -> void:
    if not multiplayer.is_server():
        return
    _leave_party(multiplayer.get_remote_sender_id())

@rpc("any_peer","reliable")
func _server_kick(target_peer_id:int) -> void:
    if not multiplayer.is_server():
        return
    _kick_peer(multiplayer.get_remote_sender_id(),target_peer_id)

@rpc("authority","reliable")
func _client_party_invite(party_id:String,leader_id:int) -> void:
    party_invite_received.emit(party_id,leader_id)

@rpc("authority","reliable")
func _client_party_snapshot(party:Dictionary) -> void:
    party_updated.emit(party)

@rpc("authority","reliable")
func _client_party_rejection(reason:String) -> void:
    party_action_rejected.emit(reason)

func cleanup_peer(peer_id:int) -> void:
    invitations.erase(peer_id)
    var party_id:String = get_peer_party_id(peer_id)
    if not party_id.is_empty() and _is_server():
        _remove_member(party_id,peer_id)
