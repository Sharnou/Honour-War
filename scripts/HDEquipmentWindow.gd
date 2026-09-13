class_name HDEquipmentWindow
extends CanvasLayer

const CharacterInventory=preload("res://scripts/CharacterInventorySystem.gd")
const Character=preload("res://scripts/CharacterProgressionSystem.gd")
const Items=preload("res://scripts/ItemDatabase.gd")
const Save=preload("res://scripts/SaveSystem.gd")

const PANEL:=Color("#101722f4")
const PANEL2:=Color("#1a2533f5")
const BORDER:=Color("#c7a55e")
const TEXT:=Color("#eee7d7")
const MUTED:=Color("#9aa9ba")
const EMPTY:=Color("#27313e")

var game:Node
var legacy:Node
var window:Panel
var body:Control
var stats_label:Label
var slot_nodes:Dictionary={}
var visible_state:bool=false

const SLOT_NAMES:Array[String]=["head","head_middle","head_lower","armor","garment","weapon","offhand","shoes","accessory_1","accessory_2"]

func _ready()->void:
    game=get_parent()
    if game==null: return
    legacy=game.get("legacy") as Node
    _build()
    hide_window()

func _build()->void:
    window=Panel.new()
    window.name="EquipmentWindow"
    window.set_anchors_preset(Control.PRESET_CENTER)
    window.position=Vector2(-380,-300)
    window.size=Vector2(760,600)
    window.add_theme_stylebox_override("panel",_style(PANEL))
    add_child(window)

    var title_bar:=Panel.new()
    title_bar.position=Vector2(0,0)
    title_bar.size=Vector2(760,42)
    title_bar.add_theme_stylebox_override("panel",_style(Color("#080d14f5")))
    window.add_child(title_bar)
    var title:=Label.new()
    title.text="EQUIPMENT"
    title.position=Vector2(16,7)
    title.add_theme_font_size_override("font_size",18)
    title.add_theme_color_override("font_color",TEXT)
    title_bar.add_child(title)
    var close:=Button.new()
    close.text="X"
    close.position=Vector2(716,6)
    close.size=Vector2(34,30)
    close.pressed.connect(hide_window)
    title_bar.add_child(close)

    body=Control.new()
    body.position=Vector2(12,52)
    body.size=Vector2(736,536)
    window.add_child(body)

    var center:=Panel.new()
    center.position=Vector2(238,32)
    center.size=Vector2(255,438)
    center.add_theme_stylebox_override("panel",_style(PANEL2))
    body.add_child(center)
    var mannequin:=Mannequin.new()
    mannequin.position=Vector2(55,28)
    mannequin.size=Vector2(145,350)
    center.add_child(mannequin)
    var equipped_title:=Label.new()
    equipped_title.text="EQUIPPED LOADOUT"
    equipped_title.position=Vector2(63,385)
    equipped_title.add_theme_color_override("font_color",MUTED)
    center.add_child(equipped_title)

    stats_label=Label.new()
    stats_label.position=Vector2(510,42)
    stats_label.size=Vector2(220,430)
    stats_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    stats_label.add_theme_color_override("font_color",TEXT)
    body.add_child(stats_label)

    var positions:Dictionary={
        "head":Vector2(56,22),"head_middle":Vector2(56,100),"head_lower":Vector2(56,178),
        "armor":Vector2(56,300),"garment":Vector2(56,378),"weapon":Vector2(510,238),
        "offhand":Vector2(510,318),"shoes":Vector2(252,462),"accessory_1":Vector2(510,462),"accessory_2":Vector2(615,462)
    }
    for slot in SLOT_NAMES:
        _add_slot(slot,positions[slot])

func _add_slot(slot:String,pos:Vector2)->void:
    var panel:=Panel.new()
    panel.name="Slot_"+slot
    panel.position=pos
    panel.size=Vector2(100,70)
    panel.add_theme_stylebox_override("panel",_style(EMPTY))
    body.add_child(panel)
    var icon:=EquipmentIcon.new()
    icon.slot=slot
    icon.position=Vector2(8,8)
    icon.size=Vector2(50,50)
    panel.add_child(icon)
    var label:=Label.new()
    label.name="Item"
    label.position=Vector2(58,8)
    label.size=Vector2(38,54)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",8)
    label.add_theme_color_override("font_color",TEXT)
    panel.add_child(label)
    slot_nodes[slot]={"label":label,"icon":icon}

func _process(_delta:float)->void:
    if visible_state: _refresh()

func show_window()->void:
    visible_state=true
    if window!=null: window.visible=true
    _refresh()

func hide_window()->void:
    visible_state=false
    if window!=null: window.visible=false

func _normalize_equipment(hero:Dictionary)->void:
    CharacterInventory.ensure_state(hero)
    var equipment:Dictionary=hero["equipment"]
    var catalogue:Dictionary=Items.all()
    var changed:bool=false
    var weapon:Variant=equipment.get("weapon",null)
    var weapon_id:String=str(weapon.get("id",weapon.get("name",""))) if weapon is Dictionary else str(weapon)
    if weapon_id=="Novice Weapon" or weapon_id=="":
        equipment["weapon"]=catalogue["Novice Sword"].duplicate(true)
        equipment["weapon"]["id"]="Novice Sword"
        changed=true
    elif catalogue.has(weapon_id) and weapon is String:
        equipment["weapon"]=catalogue[weapon_id].duplicate(true)
        equipment["weapon"]["id"]=weapon_id
        changed=true
    var armor:Variant=equipment.get("armor",null)
    var armor_id:String=str(armor.get("id",armor.get("name",""))) if armor is Dictionary else str(armor)
    if armor_id=="":
        equipment["armor"]=catalogue["Novice Armor"].duplicate(true)
        equipment["armor"]["id"]="Novice Armor"
        changed=true
    elif catalogue.has(armor_id) and armor is String:
        equipment["armor"]=catalogue[armor_id].duplicate(true)
        equipment["armor"]["id"]=armor_id
        changed=true
    hero["equipment"]=equipment
    if changed: Save.save_game(hero)

func _refresh()->void:
    if legacy==null or not is_instance_valid(legacy): return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    _normalize_equipment(hero)
    var equipment:Dictionary=hero["equipment"]
    var catalogue:Dictionary=Items.all()
    for slot in SLOT_NAMES:
        var entry:Dictionary=slot_nodes[slot]
        var label:Label=entry["label"] as Label
        var icon:EquipmentIcon=entry["icon"] as EquipmentIcon
        var raw:Variant=equipment.get(slot,null)
        var item_id:String=""
        var refine:int=0
        if raw is Dictionary:
            item_id=str(raw.get("id",raw.get("name","")))
            refine=int(raw.get("refine",0))
        elif raw is String:
            item_id=str(raw)
        if not catalogue.has(item_id): item_id=""
        label.text=item_id if item_id!="" else "Empty"
        if refine>0 and item_id!="": label.text=item_id+" +"+str(refine)
        icon.item_name=item_id
        icon.queue_redraw()
    var stats:Dictionary=Character.stats(hero)
    stats_label.text="LIVE STATS\n\nATK      %d\nMATK     %d\nDEF      %d\nMDEF     %d\nHP       %d / %d\nSP       %d / %d\nHIT      %d\nFLEE     %d\nCRIT     %.1f\nHEALING  %d\n\nLevel %d / 250\nPower %d\n\nAll equipped items\nare applied to live stats." % [int(stats["atk"]),int(stats["matk"]),int(stats["def"]),int(stats["mdef"]),int(hero.get("hp",0)),int(stats["max_hp"]),int(hero.get("sp",0)),int(stats["max_sp"]),int(stats["hit"]),int(stats["flee"]),float(stats["crit"]),int(stats["healing"]),int(hero.get("level",1)),Character.combat_power(hero)]

func _style(bg:Color)->StyleBoxFlat:
    var style:=StyleBoxFlat.new()
    style.bg_color=bg
    style.border_color=BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    style.shadow_color=Color(0,0,0,0.5)
    style.shadow_size=7
    return style

class EquipmentIcon extends Control:
    var slot:String=""
    var item_name:String=""
    func _draw()->void:
        var ink:=Color("#d8bf6d")
        var dark:=Color("#0a1017")
        draw_rect(Rect2(Vector2.ZERO,size),dark,true)
        draw_rect(Rect2(Vector2.ZERO,size),ink,false,1.0)
        var c:=size*0.5
        var lower:String=item_name.to_lower()
        if slot=="weapon" or lower.contains("sword") or lower.contains("blade") or lower.contains("staff") or lower.contains("bow") or lower.contains("mace") or lower.contains("hammer"):
            draw_line(Vector2(14,43),Vector2(38,13),ink,5.0)
            draw_line(Vector2(10,36),Vector2(29,46),ink,3.0)
        elif slot=="armor":
            draw_arc(c+Vector2(0,6),21.0,PI,TAU,18,ink,4.0)
            draw_line(Vector2(16,16),Vector2(16,43),ink,4.0)
            draw_line(Vector2(40,16),Vector2(40,43),ink,4.0)
        elif slot in ["head","head_middle","head_lower"]:
            draw_arc(c+Vector2(0,5),18.0,PI,TAU,18,ink,4.0)
            draw_line(Vector2(14,30),Vector2(42,30),ink,4.0)
        elif slot=="shoes":
            draw_line(Vector2(16,24),Vector2(16,42),ink,6.0)
            draw_line(Vector2(16,42),Vector2(43,42),ink,6.0)
        elif slot=="garment":
            draw_line(Vector2(18,10),Vector2(10,44),ink,4.0)
            draw_line(Vector2(38,10),Vector2(46,44),ink,4.0)
            draw_line(Vector2(10,44),Vector2(46,44),ink,4.0)
        elif slot=="offhand":
            draw_circle(c,17.0,Color("#63778d"))
            draw_arc(c,17.0,0.0,TAU,32,ink,3.0)
        else:
            draw_circle(c,8.0,ink)
            draw_arc(c,17.0,0.0,TAU,32,ink,3.0)

class Mannequin extends Control:
    func _draw()->void:
        var skin:=Color("#c79070")
        var armor:=Color("#8393a2")
        var cloth:=Color("#3c4652")
        var gold:=Color("#c8aa5e")
        var dark:=Color("#1d232c")
        draw_circle(Vector2(72,52),24.0,skin)
        draw_arc(Vector2(72,48),27.0,PI*1.05,PI*1.95,20,dark,8.0)
        draw_rect(Rect2(42,80,60,92),cloth,true)
        draw_rect(Rect2(47,85,50,58),armor,true)
        draw_line(Vector2(49,95),Vector2(25,155),armor,13.0)
        draw_line(Vector2(95,95),Vector2(119,155),armor,13.0)
        draw_line(Vector2(58,170),Vector2(50,275),armor,20.0)
        draw_line(Vector2(86,170),Vector2(94,275),armor,20.0)
        draw_rect(Rect2(38,264,28,16),dark,true)
        draw_rect(Rect2(78,264,28,16),dark,true)
        draw_line(Vector2(72,100),Vector2(72,145),gold,5.0)
