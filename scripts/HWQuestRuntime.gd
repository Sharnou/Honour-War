extends Node

## In-game quest tracker for Honour War. Offline/server-authoritative sessions
## mutate the local player directly; online clients submit validated `quest`
## actions and consume the synchronized player snapshot from the event stream.

const QUESTS = preload("res://scripts/QuestSystem.gd")
const AUTHORITY_PATH:String = "/root/HWOnlineAuthorityRuntime"
const PANEL_POSITION:=Vector2(1450,315)
const PANEL_SIZE:=Vector2(425,490)

var scene_root:Node
var legacy:Node
var hero:Dictionary={}
var panel:Panel
var content:VBoxContainer
var status_label:Label
var last_signature:String=""

func _ready()->void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    call_deferred("_initialize")

func _initialize()->void:
    _find_game()
    _build_hud()
    var authority:Node=get_node_or_null(AUTHORITY_PATH)
    if authority!=null and not authority.authoritative_event_received.is_connected(_on_authoritative_event):
        authority.authoritative_event_received.connect(_on_authoritative_event)
    _refresh(true)

func _process(_delta:float)->void:
    if scene_root==null or scene_root!=get_tree().current_scene:
        _find_game()
    if legacy==null or not is_instance_valid(legacy):
        return
    var candidate:Variant=legacy.get("hero")
    if candidate is Dictionary:
        hero=candidate
    QUESTS.ensure_state(hero)
    _refresh(false)

func _find_game()->void:
    scene_root=get_tree().current_scene
    if scene_root==null:
        return
    legacy=scene_root.get_node_or_null("LegacyGame")
    if legacy==null:
        legacy=scene_root.get_node_or_null("LegacyGame/CombatRuntime")

func _build_hud()->void:
    if panel!=null or get_tree().current_scene==null:
        return
    var layer:CanvasLayer=CanvasLayer.new()
    layer.name="QuestTrackerLayer"
    get_tree().current_scene.add_child(layer)
    panel=Panel.new()
    panel.name="QuestTracker"
    panel.position=PANEL_POSITION
    panel.size=PANEL_SIZE
    layer.add_child(panel)
    var margin:MarginContainer=MarginContainer.new()
    margin.add_theme_constant_override("margin_left",14)
    margin.add_theme_constant_override("margin_top",12)
    margin.add_theme_constant_override("margin_right",14)
    margin.add_theme_constant_override("margin_bottom",12)
    panel.add_child(margin)
    content=VBoxContainer.new()
    content.add_theme_constant_override("separation",6)
    margin.add_child(content)
    var title:Label=Label.new()
    title.text="QUEST TRACKER"
    title.add_theme_font_size_override("font_size",22)
    content.add_child(title)
    status_label=Label.new()
    status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    content.add_child(status_label)

func _refresh(force:bool)->void:
    if content==null:
        return
    var active:Array[String]=QUESTS.active_quests(hero)
    var available:Array[Dictionary]=QUESTS.available_quests(hero)
    var signature:String="%s|%s|%s" % [JSON.stringify(active),JSON.stringify(available),str(hero.get("level",1))]
    for quest_id:String in active:
        var summary:Dictionary=QUESTS.progress_summary(hero,quest_id)
        signature+="|"+JSON.stringify(summary)
    if not force and signature==last_signature:
        return
    last_signature=signature
    for child:Node in content.get_children():
        if child!=content.get_child(0) and child!=content.get_child(1):
            child.queue_free()
    status_label.text="Level %d • Active %d/%d" % [int(hero.get("level",1)),active.size(),QUESTS.MAX_ACTIVE_QUESTS]
    if active.is_empty():
        var empty:Label=Label.new()
        empty.text="No active quests. Accept a quest below."
        content.add_child(empty)
    else:
        for quest_id:String in active:
            content.add_child(_quest_row(QUESTS.progress_summary(hero,quest_id),true))
    var divider:HSeparator=HSeparator.new()
    content.add_child(divider)
    var available_title:Label=Label.new()
    available_title.text="AVAILABLE QUESTS"
    available_title.add_theme_font_size_override("font_size",17)
    content.add_child(available_title)
    var count:int=0
    for row:Dictionary in available:
        if not bool(row.get("available",false)):
            continue
        content.add_child(_available_row(row))
        count+=1
        if count>=4:
            break
    if count==0:
        var none:Label=Label.new()
        none.text="No new quests available at this level or the active limit is reached."
        none.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        content.add_child(none)

func _quest_row(summary:Dictionary,active:bool)->Control:
    var box:VBoxContainer=VBoxContainer.new()
    box.add_theme_constant_override("separation",2)
    var title:Label=Label.new()
    title.text=str(summary.get("name","Quest"))
    title.add_theme_font_size_override("font_size",16)
    box.add_child(title)
    for objective:Dictionary in summary.get("objectives",[]):
        var current:int=int(objective.get("current",0))
        var required:int=int(objective.get("required",1))
        var line:Label=Label.new()
        line.text="  %s: %d / %d" % [str(objective.get("target","Target")),current,required]
        box.add_child(line)
    var buttons:HBoxContainer=HBoxContainer.new()
    if bool(summary.get("complete",false)):
        var claim:Button=Button.new()
        claim.text="Claim Reward"
        claim.pressed.connect(_claim.bind(str(summary.get("id",""))))
        buttons.add_child(claim)
    else:
        var progress:Label=Label.new()
        progress.text="In progress"
        buttons.add_child(progress)
    if active:
        var abandon:Button=Button.new()
        abandon.text="Abandon"
        abandon.pressed.connect(_abandon.bind(str(summary.get("id",""))))
        buttons.add_child(abandon)
    box.add_child(buttons)
    return box

func _available_row(row:Dictionary)->Control:
    var box:HBoxContainer=HBoxContainer.new()
    var label:Label=Label.new()
    label.text="%s  (Lv.%d)" % [str(row.get("name","Quest")),int(row.get("level_req",1))]
    label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    box.add_child(label)
    var accept:Button=Button.new()
    accept.text="Accept"
    accept.pressed.connect(_accept.bind(str(row.get("id",""))))
    box.add_child(accept)
    return box

func _accept(quest_id:String)->void:
    _submit_or_local("accept",quest_id)

func _claim(quest_id:String)->void:
    _submit_or_local("claim",quest_id)

func _abandon(quest_id:String)->void:
    _submit_or_local("abandon",quest_id)

func _submit_or_local(command:String,quest_id:String)->void:
    var authority:Node=get_node_or_null(AUTHORITY_PATH)
    var online:bool=authority!=null and not authority.is_authority() and authority.multiplayer!=null and authority.multiplayer.has_multiplayer_peer()
    if online:
        authority.request_action("quest",{"command":command,"quest_id":quest_id})
        return
    var ok:bool=false
    if command=="accept":
        ok=QUESTS.accept_quest(hero,quest_id)
    elif command=="claim":
        var result:Dictionary=QUESTS.claim_quest(hero,quest_id)
        ok=bool(result.get("ok",false))
        if ok and legacy!=null and legacy.has_method("log_message"):
            legacy.call("log_message","Quest reward claimed: %s" % str(result.get("name",quest_id)))
    elif command=="abandon":
        ok=QUESTS.abandon_quest(hero,quest_id)
    if ok:
        legacy.set("hero",hero)
        _refresh(true)

func _on_authoritative_event(event:Dictionary)->void:
    if str(event.get("action",""))!="quest":
        return
    var payload:Dictionary=event.get("payload",{})
    var snapshot:Variant=payload.get("player_snapshot",null)
    if snapshot is Dictionary and legacy!=null:
        hero=snapshot.duplicate(true)
        legacy.set("hero",hero)
        _refresh(true)
