extends Node

## Bridges validated network `quest` actions into the persistent quest system.
## The authority emits its action signal synchronously before broadcasting the
## event, allowing this bridge to attach a result without changing the protocol.

const QUESTS = preload("res://scripts/QuestSystem.gd")
const AUTHORITY_PATH:String = "/root/HWOnlineAuthorityRuntime"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind_authority")

func _bind_authority() -> void:
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null:
        return
    if not authority.authoritative_action_accepted.is_connected(_on_authoritative_action):
        authority.authoritative_action_accepted.connect(_on_authoritative_action)

func _on_authoritative_action(event:Dictionary) -> void:
    if str(event.get("action",""))!="quest":
        return
    var authority:Node = get_node_or_null(AUTHORITY_PATH)
    if authority == null or not authority.is_authority():
        return
    var sender:int = int(event.get("sender",0))
    if sender<=0 or not authority.is_peer_authenticated(sender):
        event["payload"]["result"]={"ok":false,"reason":"authentication_required"}
        return
    var player:Dictionary = authority.player_for_peer(sender)
    var payload:Dictionary = event.get("payload",{})
    var command:String = str(payload.get("command","summary")).strip_edges().to_lower()
    var quest_id:String = str(payload.get("quest_id","")).strip_edges()
    QUESTS.ensure_state(player)
    var result:Dictionary={"ok":false,"reason":"invalid_command"}

    match command:
        "list":
            result={"ok":true,"reason":"listed","available":QUESTS.available_quests(player),"active":_active_summaries(player)}
        "summary":
            var summary:Dictionary=QUESTS.progress_summary(player,quest_id)
            result={"ok":not summary.is_empty(),"reason":"summary" if not summary.is_empty() else "quest_not_found","quest":summary}
        "accept":
            var accepted:bool=QUESTS.accept_quest(player,quest_id)
            result={"ok":accepted,"reason":"accepted" if accepted else "accept_failed","quest_id":quest_id}
            if accepted:
                result["quest"]=QUESTS.progress_summary(player,quest_id)
        "claim":
            result=QUESTS.claim_quest(player,quest_id)
        "abandon":
            var removed:bool=QUESTS.abandon_quest(player,quest_id)
            result={"ok":removed,"reason":"abandoned" if removed else "abandon_failed","quest_id":quest_id}
        _:
            result={"ok":false,"reason":"invalid_command","command":command}

    event["payload"]["result"]=result
    if bool(result.get("ok",false)) and command in ["accept","claim","abandon"]:
        authority.set_player_for_peer(sender,player)
        authority.save_player_for_peer(sender,player)

func _active_summaries(hero:Dictionary)->Array[Dictionary]:
    var result:Array[Dictionary]=[]
    for quest_id:String in QUESTS.active_quests(hero):
        result.append(QUESTS.progress_summary(hero,quest_id))
    return result
