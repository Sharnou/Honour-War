extends Node
class_name HWSSRentRuntime

## SS (SUPER SHAMBION) is a rental-only AI hero.
## It is never available on Create New Character and has no permanent player-class slot.

const RENT_PRICE_ZENY:int = 1000000
const SS_CLASS_NAME:String = "SS (SUPER SHAMBION)"
const SS_LEVEL:int = 0
const SS_MAX_LEVEL:int = 250
const SS_DEFAULT_SKILL:String = "Asura Strike"
const SS_RENT_NPC_NAME:String = "Rent"

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
    owner_character_age = maxi(18,hero_age)
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
    if not rented or ss.is_empty():
        return false
    var equipment:Dictionary = ss.get("equipment",{})
    equipment[slot] = item_id
    ss["equipment"] = equipment
    return true

func set_status_points(stats:Dictionary) -> bool:
    if not rented or ss.is_empty():
        return false
    ss["status_points"] = stats.duplicate(true)
    return true

func set_behavior(follow:bool=true, heal:bool=true, fight:bool=true) -> bool:
    if not rented or ss.is_empty():
        return false
    ss["behavior"] = {"follow":follow,"heal":heal,"fight":fight}
    return true

func can_create_as_character_class(class_id:String) -> bool:
    return class_id.strip_edges().to_upper() != "SS" and class_id.strip_edges().to_upper() != SS_CLASS_NAME.to_upper()

func get_rent_npc_profile(map_id:String) -> Dictionary:
    return {"name":SS_RENT_NPC_NAME,"map":map_id,"level":0,"class":SS_CLASS_NAME,"rental_only":true,"price_zeny":RENT_PRICE_ZENY}

func open_rent_panel() -> void:
    if rent_panel != null and is_instance_valid(rent_panel):
        rent_panel.queue_free()
        rent_panel = null
    var layer:CanvasLayer = CanvasLayer.new()
    layer.name = "SSRentPanelLayer"
    get_tree().current_scene.add_child(layer)
    rent_panel = Panel.new()
    rent_panel.name = "SSRentPanel"
    rent_panel.position = Vector2(620,250)
    rent_panel.size = Vector2(680,430)
    layer.add_child(rent_panel)
    var title:Label = Label.new()
    title.text = "RENT — SS (SUPER SHAMBION)"
    title.position = Vector2(28,20)
    title.add_theme_font_size_override("font_size",28)
    rent_panel.add_child(title)
    var details:Label = Label.new()
    details.text = "Level 0  •  Same age as your hero  •  Asura Strike\nFollow • Heal • Fight\nFull owner control: Equipment + Status Points\nRental price: 1,000,000 Zeny\nSS can only be obtained from Rent NPCs."
    details.position = Vector2(28,72)
    details.add_theme_font_size_override("font_size",18)
    rent_panel.add_child(details)
    var action:Button = Button.new()
    action.text = "RENT — 1,000,000 Zeny"
    action.position = Vector2(28,260)
    action.size = Vector2(300,60)
    action.disabled = rented
    action.pressed.connect(_rent_from_current_hero)
    rent_panel.add_child(action)
    var go:Button = Button.new()
    go.text = "GO"
    go.position = Vector2(370,260)
    go.size = Vector2(120,60)
    go.disabled = not rented
    go.pressed.connect(stop_renting)
    rent_panel.add_child(go)
    var close:Button = Button.new()
    close.text = "Close"
    close.position = Vector2(28,350)
    close.size = Vector2(160,44)
    close.pressed.connect(func(): rent_panel.queue_free(); rent_panel = null)
    rent_panel.add_child(close)

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
    return {
        "name":"SS",
        "class":SS_CLASS_NAME,
        "level":SS_LEVEL,
        "max_level":SS_MAX_LEVEL,
        "age":owner_character_age,
        "skill":SS_DEFAULT_SKILL,
        "behavior":{"follow":true,"heal":true,"fight":true},
        "equipment":{},
        "status_points":{},
        "rare_items_total":SS_RARE_ITEMS.size(),
        "rare_cards_total":SS_RARE_CARDS.size(),
        "rent_npc":SS_RENT_NPC_NAME,
        "go_button":"GO"
    }
