class_name HDEquipmentWindow
extends CanvasLayer

const CharacterInventory=preload("res://scripts/CharacterInventorySystem.gd")
const Character=preload("res://scripts/CharacterProgressionSystem.gd")
const Items=preload("res://scripts/ItemDatabase.gd")
const Save=preload("res://scripts/SaveSystem.gd")

const PANEL:=Color("#121923f2")
const PANEL2:=Color("#1b2634f5")
const BORDER:=Color("#c7a55e")
const TEXT:=Color("#eee7d7")
const MUTED:=Color("#9aa9ba")
const EMPTY:=Color("#303946")

var game:Node
var legacy:Node
var window:Panel
var body:Control
var stats_label:Label
var slot_nodes:Dictionary={}
var visible_state:bool=true

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
    title_bar.add_theme_stylebox_override("panel",_style(Color("#0b1018f5")))
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
    center.position=Vector2(250,35)
    center.size=Vector2(236,430)
    center.add_theme_stylebox_override("panel",_style(PANEL2))
    body.add_child(center)
    var silhouette:=ColorRect.new()
    silhouette.position=Vector2(75,52)
    silhouette.size=Vector2(86,250)
    silhouette.color=Color("#344252")
    silhouette.mouse_filter=Control.MOUSE_FILTER_IGNORE
    center.add_child(silhouette)
    var hero_text:=Label.new()
    hero_text.text="EQUIPPED\n\nWeapon\nArmor\nHead\nGarment\nShoes\nAccessories"
    hero_text.position=Vector2(42,310)
    hero_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    hero_text.size=Vector2(150,105)
    hero_text.add_theme_color_override("font_color",MUTED)
    center.add_child(hero_text)

    stats_label=Label.new()
    stats_label.position=Vector2(505,42)
    stats_label.size=Vector2(225,430)
    stats_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    stats_label.add_theme_color_override("font_color",TEXT)
    body.add_child(stats_label)

    var positions:Dictionary={
        "head":Vector2(70,25),"head_middle":Vector2(70,105),"head_lower":Vector2(70,185),
        "armor":Vector2(70,285),"garment":Vector2(70,385),"weapon":Vector2(520,255),
        "offhand":Vector2(520,355),"shoes":Vector2(250,455),"accessory_1":Vector2(520,455),"accessory_2":Vector2(620,455)
    }
    for slot in SLOT_NAMES:
        _add_slot(slot,str(positions.get(slot,Vector2.ZERO)))

func _add_slot(slot:String,pos_text:String)->void:
    var pos:Vector2=Vector2(pos_text.split(",")[0].replace("(",""),pos_text.split(",")[1].replace(")","")) if pos_text.contains(",") else Vector2.ZERO
    var panel:=Panel.new()
    panel.name="Slot_"+slot
    panel.position=pos
    panel.size=Vector2(92,70)
    panel.add_theme_stylebox_override("panel",_style(EMPTY))
    body.add_child(panel)
    var icon:=EquipmentIcon.new()
    icon.slot=slot
    icon.position=Vector2(7,7)
    icon.size=Vector2(50,50)
    panel.add_child(icon)
    var label:=Label.new()
    label.name="Item"
    label.position=Vector2(56,10)
    label.size=Vector2(32,50)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",9)
    label.add_theme_color_override("font_color",TEXT)
    panel.add_child(label)
    var button:=Button.new()
    button.flat=true
    button.position=Vector2(0,0)
    button.size=Vector2(92,70)
    button.mouse_filter=Control.MOUSE_FILTER_IGNORE
    panel.add_child(button)
    slot_nodes[slot]={"panel":panel,"icon":icon,"label":label}

func _process(_delta:float)->void:
    if visible_state:
        _refresh()

func show_window()->void:
    visible_state=true
    window.visible=true
    _refresh()

func hide_window()->void:
    visible_state=false
    if window!=null: window.visible=false

func toggle_window()->void:
    if visible_state: hide_window()
    else: show_window()

func _refresh()->void:
    if legacy==null or not is_instance_valid(legacy): return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary: return
    var hero:Dictionary=value
    CharacterInventory.ensure_state(hero)
    var equipment_value:Variant=hero.get("equipment",{})
    var equipment:Dictionary=equipment_value if equipment_value is Dictionary else {}
    var catalogue:Dictionary=Items.all()
    for slot in SLOT_NAMES:
        var data:Dictionary=slot_nodes[slot]
        var label:Label=data["label"] as Label
        var icon:EquipmentIcon=data["icon"] as EquipmentIcon
        var raw:Variant=equipment.get(slot,null)
        var item_id:String=""
        var refine:int=0
        if raw is Dictionary:
            item_id=str(raw.get("id",raw.get("name","")))
            refine=int(raw.get("refine",hero.get("equipment_refine",{}).get(slot,0)))
        elif raw is String:
            item_id=str(raw)
            var refine_map:Variant=hero.get("equipment_refine",{})
            if refine_map is Dictionary: refine=int(refine_map.get(slot,0))
        if not catalogue.has(item_id):
            if slot=="weapon": item_id="Novice Sword"
            elif slot=="armor": item_id="Novice Armor"
        label.text=item_id if item_id!="" else "Empty"
        if refine>0 and item_id!="": label.text=item_id+" +"+str(refine)
        icon.item_name=item_id
        icon.queue_redraw()
    var stats:Dictionary=Character.stats(hero)
    stats_label.text="LIVE STATS\n\nATK      %d\nMATK     %d\nDEF      %d\nMDEF     %d\nHP       %d / %d\nSP       %d / %d\nHIT      %d\nFLEE     %d\nCRIT     %.1f\nHEALING  %d\n\nLevel %d / 250\nPower %d" % [int(stats["atk"]),int(stats["matk"]),int(stats["def"]),int(stats["mdef"]),int(hero.get("hp",0)),int(stats["max_hp"]),int(hero.get("sp",0)),int(stats["max_sp"]),int(stats["hit"]),int(stats["flee"]),float(stats["crit"]),int(stats["healing"]),int(hero.get("level",1)),Character.combat_power(hero)]

func _style(bg:Color)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=bg
    s.border_color=BORDER
    s.set_border_width_all(1)
    s.set_corner_radius_all(5)
    return s

class EquipmentIcon extends Control:
    var slot:String=""
    var item_name:String=""
    func _draw()->void:
        var ink:=Color("#d6b969")
        var dark:=Color("#0b1118")
        draw_rect(Rect2(0,0,size.x,size.y),dark,true)
        draw_rect(Rect2(0,0,size.x,size.y),ink,false,1.0)
        var c:=size*0.5
        if slot=="weapon" or item_name.to_lower().contains("sword") or item_name.to_lower().contains("blade"):
            draw_line(Vector2(15,42),Vector2(38,14),ink,5.0)
            draw_line(Vector2(10,35),Vector2(28,46),ink,3.0)
        elif slot=="armor":
            draw_arc(c+Vector2(0,4),20.0,PI,TAU,16,ink,4.0)
            draw_line(Vector2(18,15),Vector2(18,42),ink,4.0)
            draw_line(Vector2(38,15),Vector2(38,42),ink,4.0)
        elif slot=="head" or slot=="head_middle" or slot=="head_lower":
            draw_arc(c+Vector2(0,4),18.0,PI,TAU,16,ink,4.0)
            draw_line(Vector2(15,30),Vector2(41,30),ink,4.0)
        elif slot=="shoes":
            draw_line(Vector2(16,24),Vector2(16,42),ink,6.0)
            draw_line(Vector2(16,42),Vector2(42,42),ink,6.0)
        elif slot=="garment":
            draw_line(Vector2(18,10),Vector2(10,44),ink,4.0)
            draw_line(Vector2(38,10),Vector2(46,44),ink,4.0)
            draw_line(Vector2(10,44),Vector2(46,44),ink,4.0)
        elif slot=="offhand":
            draw_circle(c,17.0,Color("#65768a"))
            draw_circle(c,17.0,ink,false,3.0)
        else:
            draw_circle(c,8.0,ink)
            draw_circle(c,17.0,ink,false,3.0)
