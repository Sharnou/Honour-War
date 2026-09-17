extends SceneTree

## Headless regression suite for the four-player party service.

const AUTHORITY = preload("res://scripts/HWOnlineAuthorityRuntime.gd")
const PARTY = preload("res://scripts/HWPartyService.gd")

var failures:int = 0

func _initialize() -> void:
    var authority:Node = AUTHORITY.new()
    authority.name = "HWOnlineAuthorityRuntime"
    root.add_child(authority)
    var started:bool = authority.start_server(24569)
    _check("authority server starts",started)
    if not started:
        authority.free()
        quit(1)
        return

    for peer_id in [1,2,3,4,5]:
        authority._authenticated_peers[peer_id] = "qa_user_%d" % peer_id

    var party:Node = PARTY.new()
    party.name = "HWPartyService"
    root.add_child(party)

    party._create_party_for_peer(1)
    var party_id:String = party.get_peer_party_id(1)
    _check("party created",not party_id.is_empty())
    _check("creator becomes leader",int(party.get_party_snapshot(party_id).get("leader",0)) == 1)
    _check("party starts with one member",party.get_party_snapshot(party_id).get("members",[]).size() == 1)

    for peer_id in [2,3,4]:
        party._invite_peer(1,peer_id)
        _check("invite recorded for peer %d" % peer_id,party.invitations.get(peer_id,[]).has(party_id))
        party._accept_invite(peer_id,party_id)

    var full:Dictionary = party.get_party_snapshot(party_id)
    _check("party reaches four members",full.get("members",[]).size() == PARTY.MAX_PARTY_SIZE)

    party._invite_peer(1,5)
    _check("fifth member invite rejected when full",not party.invitations.get(5,[]).has(party_id))

    party._kick_peer(2,3)
    _check("non-leader cannot kick",party.get_party_snapshot(party_id).get("members",[]).has(3))

    party._remove_member(party_id,1)
    var after_leave:Dictionary = party.get_party_snapshot(party_id)
    _check("leader leave preserves party",not after_leave.is_empty())
    _check("leadership transfers after leader leaves",int(after_leave.get("leader",0)) == 2)
    _check("leader removed from member list",not after_leave.get("members",[]).has(1))

    party.free()
    authority.stop_session()
    authority.free()

    if failures == 0:
        print("PASS: Honour War party service regression suite")
        quit(0)
    print("FAIL: Honour War party service regression suite: %d failure(s)" % failures)
    quit(1)

func _check(label:String,condition:bool) -> void:
    if condition:
        print("PASS: ",label)
    else:
        failures += 1
        print("FAIL: ",label)
