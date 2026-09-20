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
    _check(TELEPORT.MAPS.size()>=30,"full registered map catalog is present")
    for map_id in TELEPORT.MAPS.keys():
        _check(TELEPORT.MAPS[map_id].has("type"),"map %s has authored map type" % str(map_id))
    if taskbar!=null:
        _test_toolbar()
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

func _test_toolbar()->void:
    var hud:Node=taskbar.find_child("HonourWarFinalHUD",true,false)
    _check(hud!=null,"final HUD exists")
    if hud==null: return
    var panels:Array=[]
    for child in hud.get_children():
        if child is PanelContainer: panels.append(child)
    _check(panels.size()>=3,"status/quickbar/systembar panels exist")
    var final_toolbar:=hud.find_child("FinalSystemToolbarPanel",true,false) as Control
    var legacy_quickbar:=hud.find_child("LegacyQuickSkillPanel",true,false) as Control
    _check(final_toolbar!=null and final_toolbar.visible,"final system toolbar remains visible")
    _check(legacy_quickbar==null or not legacy_quickbar.visible,"duplicate legacy quickbar is hidden")
    var systembar:PanelContainer=panels[2] as PanelContainer if panels.size()>2 else null
    if systembar==null: return
    var rows:Array=[]
    for child in systembar.get_children():
        if child is HBoxContainer: rows.append(child)
    var row:HBoxContainer=rows[0] as HBoxContainer if not rows.is_empty() else null
    _check(row!=null,"system toolbar row exists")
    if row==null: return
    _check(row.get_child_count()==8,"all 8 system toolbar buttons exist")
    var icon_count:=0
    for button in row.get_children():
        _check(button is Button,"toolbar entry is clickable Button")
        if button is Button:
            var icons:=button.find_children("*","HUDIcon",true,false)
            icon_count+=icons.size()
            button.emit_signal("pressed")
            await process_frame
    _check(icon_count==8,"all 8 toolbar icons are present")
    var quickbars:=hud.find_children("QuickSlot_*","Button",true,false)
    _check(quickbars.size()==8,"all 8 quick skill slots exist")
    if quickbars.size()>0:
        var first:=quickbars[0] as Button
        _check(first.custom_minimum_size.x>=80.0 and first.custom_minimum_size.y>=60.0,"quick skill slots have production touch/click size")
    var status:Label=hud.find_child("UIActionStatus",true,false) as Label
    _check(status!=null,"toolbar action status exists")

func _test_modes()->void:
    var expected=["character","pet","skills","inventory","equipment","refine","events","monster","map","system"]
    for mode in expected:
        systems.call("_set_mode",mode)
        await process_frame
        _check(str(systems.get("mode"))==mode,"mode "+mode+" opens")
    var panel:=systems.get("panel") as Control
    _check(panel!=null,"progression panel exists")
    if panel!=null:
        _check(panel.size.x>=590.0 and panel.size.y>=700.0,"progression panel production size is usable")

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
    if taskbar==null: return
    taskbar.call("_open","equipment")
    await process_frame
    var window:=scene.find_child("EquipmentWindow",true,false)
    _check(window!=null,"equipment window opens")
    if window!=null:
        var slots:=window.find_children("Slot_*","Panel",true,false)
        _check(slots.size()==10,"all 10 equipment slots exist")
        var panel:=window.get("window") as Control
        _check(panel!=null and panel.size.x>=760.0 and panel.size.y>=600.0,"equipment window size is usable")
        if window.has_method("hide_window"): window.call("hide_window")

func _check(ok:bool,message:String)->void:
    if not ok: failures.append(message)
