extends SceneTree

const SKILLS = preload("res://scripts/SkillSystem.gd")
const PET_SKILLS = preload("res://scripts/PetSkillSystem.gd")
const TELEPORT = preload("res://scripts/TeleportSystem.gd")

var failures:Array[String]=[]
var scene:Node
var taskbar:Node
var systems:Node

func _init()->void:
    scene=load("res://Main3D.tscn").instantiate()
    root.add_child(scene)
    call_deferred("_run")

func _run()->void:
    for _i in range(18):
        await process_frame
    taskbar=scene.find_child("HDMMOTaskbar",true,false)
    systems=scene.find_child("GameplaySystemsRuntime",true,false)
    _check(taskbar!=null,"HDMMOTaskbar exists")
    _check(systems!=null,"GameplaySystemsRuntime exists")
    _check(ResourceLoader.exists("res://assets/ui/skill_icons_atlas.svg"),"skill icon atlas exists")
    var chat:=scene.find_child("HDChatBootstrap",true,false)
    _check(chat!=null,"chat system exists")
    if chat!=null:
        _check(chat.has_method("toggle_chat"),"chat toggle action exists")
        var chat_button:=chat.find_child("ChatToggle",true,false) as Button
        _check(chat_button!=null,"chat toggle button exists")
        _check(str(chat_button.text).contains("ENTER"),"chat Enter hotkey is advertised")
    var skill_bar:=scene.find_child("HWFinalSkillQuickbar",true,false)
    _check(skill_bar!=null,"final skill shortcut bar exists")
    if skill_bar!=null:
        var slots:=skill_bar.find_children("SkillSlot_*","Button",true,false)
        _check(slots.size()==8,"final skill shortcut bar has 8 slots")
        for slot_value in slots:
            var slot:=slot_value as Button
            _check(slot.tooltip_text.length()>0,"every skill shortcut has tooltip")
    _check(TELEPORT.MAPS.size()>=30,"full registered map catalog is present")
    for map_id in TELEPORT.MAPS.keys():
        _check(TELEPORT.MAPS[map_id].has("type"),"map %s has authored map type" % str(map_id))
    var hero_visual:=scene.get("hero_visual") as Node3D
    var pet_visual:=scene.get("pet_visual") as Node3D
    _check(hero_visual!=null,"live hero visual exists")
    _check(pet_visual!=null,"live pet visual exists")
    if hero_visual!=null:
        _check(hero_visual.find_child("HWCharacterDetailV2",true,false)!=null,"hero native detail layer attached")
    if pet_visual!=null:
        _check(pet_visual.find_child("HWPetDetailV2",true,false)!=null,"pet native detail layer attached")
    var detail:=scene.find_child("HWHDDetailPassVNext",true,false)
    _check(detail!=null,"HD map detail pass exists")
    if detail!=null:
        var generated:Node=detail.get("root") as Node
        _check(generated!=null and generated.get_child_count()>=100,"current map has dense authored detail objects")
    if systems!=null:
        _test_modes()
        _test_skill_trees()
        _test_pet_tree()
    _test_equipment()
    if failures.is_empty():
        print("UI_SURFACE_QA=PASS")
        quit(0)
    else:
        for failure in failures:
            push_error("UI QA: "+failure)
        print("UI_SURFACE_QA=FAIL count=%d" % failures.size())
        quit(1)

func _test_modes()->void:
    var expected=["character","pet","skills","inventory","equipment","refine","map","system"]
    var keys=[KEY_C,KEY_P,KEY_K,KEY_I,KEY_E,KEY_R,KEY_M,KEY_O]
    for i in range(expected.size()):
        systems.panel.visible=false
        var event:=InputEventKey.new()
        event.keycode=keys[i]
        event.pressed=true
        systems._unhandled_key_input(event)
        await process_frame
        _check(systems.panel.visible,"hotkey opens "+expected[i])
        _check(str(systems.get("mode"))==expected[i],"hotkey selects "+expected[i])
        var close:=systems.panel.find_child("UIWindowClose",true,false) as Button
        _check(close!=null,"close button exists for "+expected[i])
        systems._unhandled_key_input(event)
        await process_frame
        _check(not systems.panel.visible,"same hotkey closes "+expected[i])
    # V is an intentional alias for the merged Equipment + Status window.
    systems.panel.visible=false
    var status_event:=InputEventKey.new()
    status_event.keycode=KEY_V
    status_event.pressed=true
    systems._unhandled_key_input(status_event)
    await process_frame
    _check(systems.panel.visible,"V opens merged Equipment + Status window")
    _check(str(systems.get("mode"))=="equipment","V selects merged Equipment + Status window")
    var merged_body:=systems.get("body") as Control
    _check(merged_body!=null and merged_body.get_child_count()>=16,"merged Equipment + Status window renders status allocation and equipment slots")
    var merged_text:String=""
    if merged_body!=null:
        for child in merged_body.get_children():
            if child is Label:
                merged_text+=" "+str((child as Label).text)
    _check(merged_text.contains("STATUS POINTS AVAILABLE"),"merged window contains status-point allocation")
    _check(merged_text.contains("EQUIPMENT SLOTS"),"merged window contains equipment section")
    systems._unhandled_key_input(status_event)
    await process_frame
    _check(not systems.panel.visible,"V closes merged Equipment + Status window")
    systems._set_mode("character")
    await process_frame
    var panel:=systems.get("panel") as Control
    _check(panel!=null and panel.size.x>=590.0 and panel.size.y>=700.0,"progression panel production size is usable")

func _test_skill_trees()->void:
    for class_id in ["Warrior","Mage","Archer","Thief","Acolyte","Merchant"]:
        var skills:Array=SKILLS.all_skills(class_id)
        _check(skills.size()==8,class_id+" has complete 8-skill tree")
        for skill in skills:
            _check(str(skill.get("name","")).length()>0,class_id+" skill has name")
            _check(str(skill.get("description","")).length()>0,class_id+" skill has description")
            _check(int(skill.get("tier",0))>=1,class_id+" skill has tier")
    systems.call("_set_mode","skills")
    await process_frame
    var body:=systems.get("body") as Control
    _check(body!=null and body.get_child_count()>=9,"skill tree renders all skills plus heading")

func _test_pet_tree()->void:
    var pet_value:Variant=systems.get("hero").get("pet",{}) if systems.get("hero") is Dictionary else {}
    _check(pet_value is Dictionary,"hero has fighting pet state")
    if pet_value is Dictionary:
        var species:=str(pet_value.get("species",pet_value.get("name","Wolf Cub")))
        var skills:Array=PET_SKILLS.all_skills(species)
        _check(skills.size()>0,"pet skill tree exists for "+species)

func _test_equipment()->void:
    if systems==null: return
    systems.panel.visible=false
    var event:=InputEventKey.new()
    event.keycode=KEY_E
    event.pressed=true
    systems._unhandled_key_input(event)
    await process_frame
    _check(systems.panel.visible and str(systems.get("mode"))=="equipment","equipment hotkey opens merged equipment/status window")
    var close:=systems.panel.find_child("UIWindowClose",true,false) as Button
    _check(close!=null,"merged equipment/status window has close button")
    var body:=systems.get("body") as Control
    _check(body!=null and body.get_child_count()>=16,"merged equipment/status panel renders status allocation and all equipment slots")
    var labels_text:String=""
    if body!=null:
        for child in body.get_children():
            if child is Label:
                labels_text+=" "+str((child as Label).text)
    _check(labels_text.contains("STATUS POINTS AVAILABLE"),"merged equipment/status panel exposes status points")
    _check(labels_text.contains("EQUIPMENT SLOTS"),"merged equipment/status panel exposes equipment section")
    systems._unhandled_key_input(event)
    await process_frame
    _check(not systems.panel.visible,"equipment hotkey closes merged equipment/status window")

func _check(ok:bool,message:String)->void:
    if not ok: failures.append(message)
