extends Node

## Rental-only AI hero. Never available from Create New Character.
const RENT_PRICE_ZENY:int = 1000000
const SS_CLASS_NAME:String = "SS (SUPER SHAMBION)"
const SS_LEVEL:int = 0
const SS_MAX_LEVEL:int = 250
const SS_DEFAULT_SKILL:String = "Asura Strike"
const SS_RENT_NPC_NAME:String = "Rent"
const COLLECTION_ITEM_LIMIT:int = 50
const COLLECTION_CARD_LIMIT:int = 20

const SS_RARE_ITEMS:Array[String] = [
    "SS Shambion Fist", "SS Shambion Robe", "SS Shambion Mantle", "SS Shambion Hood", "SS Shambion Boots",
    "SS Shambion Belt", "SS Shambion Ring", "SS Shambion Pendant", "SS Shambion Eye", "SS Shambion Seal",
    "SS Iron Palm", "SS Crimson Knuckle", "SS Azure Knuckle", "SS Golden Knuckle", "SS Black Knuckle",
    "SS Dragon Wrap", "SS Spirit Wrap", "SS Battle Wrap", "SS Sacred Wrap", "SS Veteran Wrap",
    "SS Power Band", "SS Spirit Band", "SS Vital Band", "SS Focus Band", "SS Asura Band",
    "SS Warrior Charm", "SS Monk Charm", "SS Guardian Charm", "SS Phoenix Charm", "SS Dragon Charm",
    "SS Combat Cloak", "SS Storm Cloak", "SS Flame Cloak", "SS Frost Cloak", "SS Shadow Cloak",
    "SS Ancient Boots", "SS Swift Boots", "SS Heavy Boots", "SS Sacred Boots", "SS Dragon Boots",
    "SS Life Talisman", "SS Mana Talisman", "SS Strength Talisman", "SS Spirit Talisman", "SS Asura Talisman",
    "SS Crown of Resolve", "SS Crown of Power", "SS Crown of Spirit", "SS Crown of Valor", "SS Crown of Shambion"
]
const SS_RARE_CARDS:Array[String] = [
    "SS Shambion Card", "Asura Master Card", "Spirit Master Card", "Iron Palm Card", "Dragon Fist Card",
    "Phoenix Fist Card", "Ancient Monk Card", "Grand Master Card", "Battle Sage Card", "War Saint Card",
    "Resolve Card", "Power Card", "Spirit Card", "Vitality Card", "Focus Card",
    "Asura Force Card", "Asura Burst Card", "Asura Soul Card", "Shambion Guardian Card", "Shambion Legend Card"
]

var rented:bool = false
var owner_character_age:int = 18
var ss:Dictionary = {}
var rent_panel:Panel

func rent(hero_age:int, zeny:int) -> Dictionary:
    if rented:
        return {"ok":false,"reason":"already_rented","ss":ss.duplicate(true)}
    if zeny < RENT_PRICE_ZENY:
        return {"ok":false,"reason":"insufficient_zeny","required":RENT_PRICE_ZENY}
    owner_character_age = maxi(18, hero_age)
    rented = true
    ss = _new_ss()
    return {"ok":true,"cost":RENT_PRICE_ZENY,"ss":ss.duplicate(true)}

func stop_renting() -> Dictionary:
    rented = false
    ss = {}
    if rent_panel != null and is_instance_valid(rent_panel):
        rent_panel.queue_free()
        rent_panel = null
    return {"ok":true,"rented":false}

func is_rented() -> bool:
    return rented

func get_ss() -> Dictionary:
    return ss.duplicate(true)

func set_equipment(slot:String, item_id:String) -> bool:
    if not rented or ss.is_empty() or slot.strip_edges().is_empty():
        return false
    var equipment:Dictionary = ss.get("equipment",{})
    equipment[slot] = item_id.strip_edges()
    ss["equipment"] = equipment
    return true

func set_status_points(stats:Dictionary) -> bool:
    if not rented or ss.is_empty():
        return false
    var clean:Dictionary = {}
    for key in stats.keys():
        clean[str(key)] = maxi(0, int(stats[key]))
    ss["status_points"] = clean
    return true

func set_behavior(follow:bool=true, heal:bool=true, fight:bool=true) -> bool:
    if not rented or ss.is_empty():
        return false
    ss["behavior"] = {"follow":follow,"heal":heal,"fight":fight}
    return true

func get_collection_limits() -> Dictionary:
    return {"items":COLLECTION_ITEM_LIMIT,"cards":COLLECTION_CARD_LIMIT}

func get_collection_lists() -> Dictionary:
    return {"items":SS_RARE_ITEMS.duplicate(),"cards":SS_RARE_CARDS.duplicate()}

func is_ss_rare_item(item_id:String) -> bool:
    return item_id in SS_RARE_ITEMS

func is_ss_rare_card(card_id:String) -> bool:
    return card_id in SS_RARE_CARDS

func can_create_as_character_class(class_id:String) -> bool:
    var normalized:String = class_id.strip_edges().to_upper()
    return normalized != "SS" and normalized != SS_CLASS_NAME.to_upper()

func get_rent_npc_profile(map_id:String) -> Dictionary:
    return {"name":SS_RENT_NPC_NAME,"map":map_id,"level":0,"class":SS_CLASS_NAME,"rental_only":true,"price_zeny":RENT_PRICE_ZENY}

func open_rent_panel() -> void:
    if rent_panel != null and is_instance_valid(rent_panel):
        rent_panel.queue_free()
        rent_panel = null
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    var layer:CanvasLayer = CanvasLayer.new()
    layer.name = "SSRentPanelLayer"
    scene.add_child(layer)
    rent_panel = Panel.new()
    rent_panel.name = "SSRentPanel"
    rent_panel.position = Vector2(560,170)
    rent_panel.size = Vector2(800,680)
    layer.add_child(rent_panel)
    var title:Label = Label.new()
    title.text = "RENT — SS (SUPER SHAMBION)"
    title.position = Vector2(28,18)
    title.add_theme_font_size_override("font_size",28)
    rent_panel.add_child(title)
    var details:Label = Label.new()
    details.text = "Level 0  •  Age " + str(int(ss.get("age",owner_character_age))) + "  •  Asura Strike\nFollow • Heal • Fight  •  Rental only\nCollection: 50 rare items + 20 rare cards  •  Price: 1,000,000 Zeny"
    details.position = Vector2(28,62)
    details.add_theme_font_size_override("font_size",17)
    rent_panel.add_child(details)
    _add_section_label("Behavior",Vector2(28,130))
    _add_check("Follow",bool(ss.get("behavior",{}).get("follow",true)),Vector2(28,165),Callable(self,"_toggle_follow"))
    _add_check("Heal",bool(ss.get("behavior",{}).get("heal",true)),Vector2(150,165),Callable(self,"_toggle_heal"))
    _add_check("Fight",bool(ss.get("behavior",{}).get("fight",true)),Vector2(270,165),Callable(self,"_toggle_fight"))
    _add_section_label("Status Points",Vector2(28,220))
    var stat_names:Array[String] = ["STR","AGI","VIT","INT","DEX","LUK"]
    for i in stat_names.size():
        var stat:String = stat_names[i]
        var spin:SpinBox = SpinBox.new()
        spin.position = Vector2(28 + i * 122,255)
        spin.size = Vector2(108,42)
        spin.min_value = 0
        spin.max_value = 9999
        spin.value = int(ss.get("status_points",{}).get(stat,0))
        spin.value_changed.connect(_on_status_changed.bind(stat))
        rent_panel.add_child(spin)
        var lab:Label = Label.new()
        lab.text = stat
        lab.position = Vector2(28 + i * 122,296)
        rent_panel.add_child(lab)
    _add_section_label("Equipment",Vector2(28,340))
    var slots:Array[String] = ["Weapon","Armor","Garment","Footgear","Accessory 1","Accessory 2"]
    for i in slots.size():
        var edit:LineEdit = LineEdit.new()
        edit.placeholder_text = slots[i]
        edit.text = str(ss.get("equipment",{}).get(slots[i],""))
        edit.position = Vector2(28 + (i % 3) * 250,375 + (i / 3) * 52)
        edit.size = Vector2(230,40)
        edit.text_submitted.connect(_on_equipment_submitted.bind(slots[i]))
        rent_panel.add_child(edit)
    var rent_button:Button = Button.new()
    rent_button.text = "RENT — 1,000,000 Zeny"
    rent_button.position = Vector2(28,535)
    rent_button.size = Vector2(270,56)
    rent_button.disabled = rented
    rent_button.pressed.connect(_rent_from_current_hero)
    rent_panel.add_child(rent_button)
    var go:Button = Button.new()
    go.text = "GO — END RENTAL"
    go.position = Vector2(320,535)
    go.size = Vector2(220,56)
    go.disabled = not rented
    go.pressed.connect(stop_renting)
    rent_panel.add_child(go)
    var close:Button = Button.new()
    close.text = "Close"
    close.position = Vector2(560,535)
    close.size = Vector2(150,56)
    close.pressed.connect(_close_panel)
    rent_panel.add_child(close)

func _add_section_label(text_value:String, at:Vector2) -> void:
    var label:Label = Label.new()
    label.text = text_value
    label.position = at
    label.add_theme_font_size_override("font_size",20)
    rent_panel.add_child(label)

func _add_check(text_value:String, checked:bool, at:Vector2, callback:Callable) -> void:
    var box:CheckBox = CheckBox.new()
    box.text = text_value
    box.button_pressed = checked
    box.position = at
    box.size = Vector2(110,40)
    box.toggled.connect(callback)
    rent_panel.add_child(box)

func _toggle_follow(value:bool) -> void:
    var b:Dictionary = ss.get("behavior",{}).duplicate(true)
    set_behavior(value,bool(b.get("heal",true)),bool(b.get("fight",true)))

func _toggle_heal(value:bool) -> void:
    var b:Dictionary = ss.get("behavior",{}).duplicate(true)
    set_behavior(bool(b.get("follow",true)),value,bool(b.get("fight",true)))

func _toggle_fight(value:bool) -> void:
    var b:Dictionary = ss.get("behavior",{}).duplicate(true)
    set_behavior(bool(b.get("follow",true)),bool(b.get("heal",true)),value)

func _on_status_changed(value:float, stat:String) -> void:
    var stats:Dictionary = ss.get("status_points",{}).duplicate(true)
    stats[stat] = maxi(0,int(value))
    set_status_points(stats)

func _on_equipment_submitted(value:String, slot:String) -> void:
    set_equipment(slot,value)

func _close_panel() -> void:
    if rent_panel != null and is_instance_valid(rent_panel):
        rent_panel.queue_free()
        rent_panel = null

func _rent_from_current_hero() -> void:
    var hero_age:int = 18
    var zeny:int = 0
    var scene:Node = get_tree().current_scene
    var legacy:Node = scene.get_node_or_null("LegacyGame") if scene != null else null
    if legacy != null:
        var hero_value:Variant = legacy.get("hero")
        if hero_value is Dictionary:
            hero_age = int(hero_value.get("age",18))
            zeny = int(hero_value.get("zeny",0))
    var result:Dictionary = rent(hero_age,zeny)
    if bool(result.get("ok",false)):
        _set_hero_zeny(zeny-RENT_PRICE_ZENY)
    open_rent_panel()

func _set_hero_zeny(value:int) -> void:
    var scene:Node = get_tree().current_scene
    var legacy:Node = scene.get_node_or_null("LegacyGame") if scene != null else null
    if legacy == null:
        return
    var hero_value:Variant = legacy.get("hero")
    if hero_value is Dictionary:
        hero_value["zeny"] = maxi(0,value)
        legacy.set("hero",hero_value)

func _new_ss() -> Dictionary:
    return {"name":"SS","class":SS_CLASS_NAME,"level":SS_LEVEL,"max_level":SS_MAX_LEVEL,"age":owner_character_age,"skill":SS_DEFAULT_SKILL,"behavior":{"follow":true,"heal":true,"fight":true},"equipment":{},"status_points":{"STR":0,"AGI":0,"VIT":0,"INT":0,"DEX":0,"LUK":0},"rare_items_total":SS_RARE_ITEMS.size(),"rare_cards_total":SS_RARE_CARDS.size(),"rent_npc":SS_RENT_NPC_NAME,"go_button":"GO"}
