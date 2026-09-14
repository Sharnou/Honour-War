extends Node

## Lightweight live gameplay HUD. Reads existing LegacyGame state only; it does
## not replace combat, inventory, class or pet systems.

var scene_root:Node
var legacy:Node
var layer:CanvasLayer
var panel:Panel
var title:Label
var stats:Label
var threat:Label
var momentum:Label
var last_monster_count:int = -1
var kill_streak:int = 0
var last_hp:int = -1
var pulse:float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")

func _bind() -> void:
    scene_root = get_tree().current_scene
    if scene_root == null:
        call_deferred("_bind")
        return
    legacy = scene_root.get_node_or_null("LegacyGame")
    if legacy == null:
        legacy = scene_root.get_node_or_null("LegacyGame/CombatRuntime")
    _build()

func _process(delta:float) -> void:
    pulse += delta
    if scene_root == null or not is_instance_valid(scene_root):
        _bind()
        return
    if panel == null:
        _build()
    if legacy == null or not is_instance_valid(legacy):
        legacy = scene_root.get_node_or_null("LegacyGame")
        if legacy == null:
            legacy = scene_root.get_node_or_null("LegacyGame/CombatRuntime")
        return
    _refresh()

func _build() -> void:
    if panel != null:
        return
    layer = CanvasLayer.new()
    layer.name = "HWCombatHUD"
    scene_root.add_child(layer)
    panel = Panel.new()
    panel.position = Vector2(26,24)
    panel.size = Vector2(360,142)
    panel.modulate = Color(1.0,1.0,1.0,0.92)
    layer.add_child(panel)
    var box:VBoxContainer = VBoxContainer.new()
    box.position = Vector2(15,10)
    box.size = Vector2(330,122)
    panel.add_child(box)
    title = Label.new()
    title.text = "HONOUR WAR • BATTLE STATUS"
    title.add_theme_font_size_override("font_size",18)
    box.add_child(title)
    stats = Label.new()
    stats.add_theme_font_size_override("font_size",15)
    box.add_child(stats)
    threat = Label.new()
    threat.add_theme_font_size_override("font_size",15)
    box.add_child(threat)
    momentum = Label.new()
    momentum.add_theme_font_size_override("font_size",15)
    box.add_child(momentum)

func _refresh() -> void:
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    var level:int = int(hero.get("level",1))
    var age:int = int(hero.get("age",0))
    var hp:int = int(hero.get("hp",0))
    var max_hp:int = max(1,int(hero.get("max_hp",1)))
    var sp:int = int(hero.get("sp",0))
    var max_sp:int = max(1,int(hero.get("max_sp",1)))
    var class_id:String = str(hero.get("class","Warrior"))
    var branch:String = str(hero.get("class_branch",""))
    var pet_text:String = "Pet Lv.1"
    var pet_value:Variant = hero.get("pet",{})
    if pet_value is Dictionary:
        var pet:Dictionary = pet_value
        pet_text = str(pet.get("species","Pet"))+" Lv."+str(pet.get("level",1))
    var monsters:int = _monster_count()
    if last_monster_count >= 0 and monsters < last_monster_count:
        kill_streak += 1
    elif monsters > last_monster_count and last_monster_count >= 0:
        kill_streak = max(0,kill_streak-1)
    last_monster_count = monsters
    if last_hp >= 0 and hp < last_hp and hp <= int(float(max_hp)*0.25):
        momentum.text = "Momentum: %d   •   DANGER" % kill_streak
    else:
        momentum.text = "Momentum: %d   •   Combat ready" % kill_streak
    last_hp = hp
    stats.text = "Lv.%d  Age %d  %s" % [level,age,class_id]
    if branch != "":
        stats.text += " / "+branch
    stats.text += "\nHP %d/%d   SP %d/%d   %s" % [hp,max_hp,sp,max_sp,pet_text]
    threat.text = "Threats nearby: %d" % monsters
    var ratio:float = float(hp)/float(max_hp)
    if ratio < 0.25:
        title.text = "HONOUR WAR • CRITICAL HEALTH"
    elif monsters >= 12:
        title.text = "HONOUR WAR • HIGH THREAT"
    else:
        title.text = "HONOUR WAR • BATTLE STATUS"
    panel.modulate.a = 0.90 + sin(pulse*2.0)*0.04

func _monster_count() -> int:
    var value:Variant = legacy.get("monsters")
    if value is Array:
        return (value as Array).size()
    return 0
