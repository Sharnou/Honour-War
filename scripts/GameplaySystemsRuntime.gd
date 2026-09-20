class_name GameplaySystemsRuntime
extends CanvasLayer

const CombatRules=preload("res://scripts/CombatRules.gd")
const AGE=preload("res://scripts/OnlineAgeSystem.gd")
const INV=preload("res://scripts/EventInventorySystem.gd")
const CODEX=preload("res://scripts/MonsterDetailsSystem.gd")
const CHARACTER_INV=preload("res://scripts/CharacterInventorySystem.gd")
const CHARACTER=preload("res://scripts/CharacterProgressionSystem.gd")
const EQUIPMENT=preload("res://scripts/EquipmentProgressionSystem.gd")
const ITEMS=preload("res://scripts/ItemDatabase.gd")
const CARDS=preload("res://scripts/CardDatabase.gd")
const SKILLS=preload("res://scripts/SkillSystem.gd")
const PET=preload("res://scripts/PetProgressionSystem.gd")
const PET_SKILLS=preload("res://scripts/PetSkillSystem.gd")
const SAVE=preload("res://scripts/SaveSystem.gd")

var game:Node3D
var legacy:Node
var panel:PanelContainer
var body:VBoxContainer
var mode:String="character"
var timer:float=0.0
var hero:Dictionary={}
var selected_item:String=""
var selected_slot:String=""
var selected_card:String=""
var status_label:Label

func _ready()->void:
    game=get_parent() as Node3D
    call_deferred("_bind")

func _bind()->void:
    if game==null: return
    legacy=game.get_node_or_null("LegacyGame")
    _build_ui()

func _process(delta:float)->void:
    timer+=delta
    if timer<0.5: return
    timer=0.0
    if legacy==null: return
    var value:Variant=legacy.get("hero")
    if value is Dictionary:
        hero=value
        CHARACTER_INV.ensure_state(hero)
        SKILLS.ensure_state(hero)
        var pet:Variant=hero.get("pet",{})
        if pet is Dictionary: PET.ensure_state(pet)
        _refresh(hero)

func _build_ui()->void:
    panel=PanelContainer.new()
    panel.name="GameplayInteractionPanel"
    panel.position=Vector2(1260,85)
    panel.size=Vector2(620,735)
    add_child(panel)
    panel.visible=false
    var root:=VBoxContainer.new()
    root.add_theme_constant_override("separation",5)
    panel.add_child(root)
    var title:=Label.new()
    title.text="HONOUR WAR  •  PROGRESSION"
    title.add_theme_font_size_override("font_size",16)
    root.add_child(title)
    var scroll:=ScrollContainer.new()
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    root.add_child(scroll)
    body=VBoxContainer.new()
    body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation",5)
    scroll.add_child(body)
    status_label=Label.new()
    status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    root.add_child(status_label)
    var hint:=Label.new()
    hint.text="HOTKEYS  C Character • P Pet • K Skills • I Inventory • E Equipment • R Refine • M Map • O System • V Status • ESC Close"
    root.add_child(hint)

func _set_mode(next:String)->void:
    mode=next
    if next!="equipment": selected_slot=""
    if next!="skills": selected_card=""
    selected_item="" if next!="inventory" else selected_item
    timer=1.0
    _open_window()

func _unhandled_key_input(event:InputEvent)->void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE:
        if panel != null and panel.visible:
            _close_window()
            get_viewport().set_input_as_handled()
        return
    var key:=event.keycode
    var target: String = ""
    match key:
        KEY_C: target="character"
        KEY_P: target="pet"
        KEY_K: target="skills"
        KEY_I: target="inventory"
        KEY_E: target="equipment"
        KEY_R: target="refine"
        KEY_M: target="map"
        KEY_O: target="system"
        KEY_V: target="status"
        _:
            return
    _toggle_mode(target)
    get_viewport().set_input_as_handled()

func _toggle_mode(target:String)->void:
    if panel == null:
        return
    if panel.visible and mode == target:
        _close_window()
    else:
        _set_mode(target)

func _open_window()->void:
    if panel == null:
        return
    panel.visible=true
    panel.position=Vector2(1260,85)
    panel.size=Vector2(620,735)
    _install_closebar()

func _install_closebar()->void:
    if panel == null:
        return
    var existing:=panel.get_node_or_null("UIWindowClose")
    if existing != null:
        return
    var close:=Button.new()
    close.name="UIWindowClose"
    close.text="CLOSE"
    close.tooltip_text="Close this window. Press the same hotkey again to reopen."
    close.custom_minimum_size=Vector2(0,36)
    close.pressed.connect(_close_window)
    var root:=panel.get_child(0) as VBoxContainer
    if root != null:
        root.add_child(close)
        root.move_child(close,0)

func _close_window()->void:
    if panel != null:
        panel.visible=false
    _set_status("UI closed")

func _clear_body()->void:
    for child in body.get_children(): child.queue_free()

func _heading(text:String)->void:
    var label:=Label.new()
    label.text=text
    label.add_theme_font_size_override("font_size",15)
    body.add_child(label)

func _button(text:String,action:Callable)->Button:
    var button:=Button.new()
    button.text=text
    button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    button.pressed.connect(action)
    body.add_child(button)
    return button

func _refresh(current:Dictionary)->void:
    AGE.normalize(current)
    INV.ensure_inventory(current)
    if mode=="character": _character(current)
    elif mode=="skills": _skills(current)
    elif mode=="pet": _pet(current)
    elif mode=="inventory": _inventory(current)
    elif mode=="equipment": _equipment(current)
    elif mode=="refine": _refine(current)
    elif mode=="events": _events(current)
    elif mode=="map": _map(current)
    elif mode=="system": _system(current)
    elif mode=="status": _status_points(current)
    else: _monster(current)

func _character(current:Dictionary)->void:
    _clear_body()
    _heading("CHARACTER / LIVE PROGRESSION")
    var stats:Dictionary=CHARACTER.stats(current)
    var growth:Dictionary=AGE.strength_bonus(current)
    var xp:Dictionary=CHARACTER.xp_progress(current)
    var class_id:String=str(current.get("class","Warrior"))
    var label:=Label.new()
    label.text="Level %d / 250  •  %s  •  Power %d\nXP %d / %d  •  %.1f%%  •  Stat Points %d\nAge %d • %s • %.1f online days\nZeny %d\n\nATK %d  MATK %d  DEF %d  MDEF %d\nHP %d/%d  SP %d/%d\nCRIT %.1f  HIT %d  FLEE %d  Healing %d\n\nClass attack interval %.2fs\nAge bonus: ATK +%d  DEF +%d  HP +%d  SP +%d" % [int(current.get("level",1)),class_id,CHARACTER.combat_power(current),int(xp["xp"]),int(xp["next"]),float(xp["ratio"])*100.0,int(current.get("stat_points",0)),int(current.get("age",18)),AGE.title(int(current.get("age",18))),float(current.get("online_days",0.0)),int(current.get("zeny",0)),int(stats["atk"]),int(stats["matk"]),int(stats["def"]),int(stats["mdef"]),int(current.get("hp",stats["max_hp"])),int(stats["max_hp"]),int(current.get("sp",stats["max_sp"])),int(stats["max_sp"]),float(stats["crit"]),int(stats["hit"]),int(stats["flee"]),int(stats["healing"]),float(CombatRules.class_attack_interval(current)),int(growth["atk"]),int(growth["def"]),int(growth["hp"]),int(growth["sp"])]
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    body.add_child(label)
    _heading("STAT ALLOCATION • 99 CAP")
    for stat in CHARACTER.STAT_NAMES:
        var row:=HBoxContainer.new()
        body.add_child(row)
        var text:=Label.new()
        text.text="%s  %d / 99" % [stat.to_upper(),int(current.get("stats",{}).get(stat,1))]
        text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(text)
        var one:=Button.new(); one.text="+1"; one.disabled=int(current.get("stat_points",0))<=0; one.pressed.connect(_allocate_stat.bind(stat,1)); row.add_child(one)
        var five:=Button.new(); five.text="+5"; five.disabled=int(current.get("stat_points",0))<=0; five.pressed.connect(_allocate_stat.bind(stat,5)); row.add_child(five)
    _button("RESET STATS",Callable(self,"_reset_stats"))
    _button("SKILL TREE",Callable(self,"_set_mode").bind("skills"))
    _button("PET PROGRESSION",Callable(self,"_set_mode").bind("pet"))

func _allocate_stat(stat:String,amount:int)->void:
    var before:Dictionary=CHARACTER.stats(hero)
    if CHARACTER.allocate(hero,stat,amount):
        var after:Dictionary=CHARACTER.stats(hero)
        _set_status("✓ %s +%d • ATK %d→%d • HP %d→%d" % [stat.to_upper(),amount,int(before["atk"]),int(after["atk"]),int(before["max_hp"]),int(after["max_hp"])])
    else: _set_status("✕ Stat point unavailable or stat cap reached.")
    timer=1.0

func _reset_stats()->void:
    var refund:int=CHARACTER.reset_stats(hero)
    _set_status("✓ Stats reset • %d points refunded." % refund)
    timer=1.0

func _skills(current:Dictionary)->void:
    _clear_body(); SKILLS.ensure_state(current)
    var class_id:String=str(current.get("class","Warrior"))
    _heading("%s SKILL TREE • %d SKILL POINTS" % [class_id.to_upper(),int(current.get("skill_points",0))])
    var class_hint:=Label.new()
    class_hint.text="8 skills • 5 tiers • active / passive / ultimate • click LEARN to spend points"
    class_hint.add_theme_color_override("font_color",Color("#9eabb8"))
    body.add_child(class_hint)
    for skill in SKILLS.all_skills(class_id):
        var id:String=str(skill["id"]); var level:int=SKILLS.skill_level(current,id); var req_ok:bool=SKILLS.can_learn(current,id)
        var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",8); body.add_child(row)
        var badge:=SkillBadge.new(); badge.tier=int(skill["tier"]); badge.kind=str(skill["kind"]); badge.level=level; badge.custom_minimum_size=Vector2(58,58); row.add_child(badge)
        var info:=Label.new()
        info.text="%s  Lv.%d/%d  • TIER %d • Req Lv.%d • Cost %d\n%s" % [str(skill["name"]),level,int(skill["max_level"]),int(skill["tier"]),int(skill["required_level"]),int(skill["cost"]),str(skill["description"])]
        info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        info.add_theme_font_size_override("font_size",11)
        row.add_child(info)
        var learn:=Button.new(); learn.text="LEARN" if level<int(skill["max_level"]) else "MAX"; learn.custom_minimum_size=Vector2(82,44); learn.disabled=not req_ok; learn.pressed.connect(_learn_skill.bind(id)); row.add_child(learn)
    _heading("Active skills are used by the combat runtime; passive effects remain active after learning. Ultimate skills require their prerequisite chain.")

func _map(current:Dictionary)->void:
    _clear_body()
    var map_name:=_map_name(current)
    _heading("WORLD MAP • "+map_name)
    var coord:=Label.new()
    coord.text="Current position  X %d : Y %d\nFast travel: @go [map] [x]:[y]" % [int(current.get("pos_x",0))-365,int(current.get("pos_y",0))-120]
    coord.add_theme_color_override("font_color",Color("#efe8d8"))
    body.add_child(coord)
    var preview:=WorldMapPreview.new()
    preview.map_id=int(current.get("map_id",0))
    preview.custom_minimum_size=Vector2(520,300)
    body.add_child(preview)
    var marker:=Label.new()
    marker.text="Legend  • Town  • Dungeon  • Field  • Bank\nAll world maps retain authored terrain/detail layers in the live 3D scene."
    marker.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    marker.add_theme_color_override("font_color",Color("#9eabb8"))
    body.add_child(marker)
    _button("OPEN TELEPORT COMMAND",Callable(self,"_set_status").bind("@go 0 230:220 ready"))

func _system(current:Dictionary)->void:
    _clear_body()
    _heading("SYSTEM • UI & SAVE")
    var label:=Label.new()
    label.text="Autosave is active. Current hero: %s • Level %d • Age %d\nRenderer target: Godot 4.7.2 Forward+\nUI target: readable at 1920×1080 and responsive to smaller viewports." % [str(current.get("name","Hero")),int(current.get("level",1)),int(current.get("age",18))]
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    body.add_child(label)
    _button("SAVE NOW",Callable(self,"_save_now"))
    _button("UI SCALE 90%",Callable(self,"_set_ui_scale").bind(0.90))
    _button("UI SCALE 100%",Callable(self,"_set_ui_scale").bind(1.00))
    _button("UI SCALE 110%",Callable(self,"_set_ui_scale").bind(1.10))
    _button("UI SCALE 120%",Callable(self,"_set_ui_scale").bind(1.20))
    _button("RESET UI SCALE",Callable(self,"_set_ui_scale").bind(1.00))
    _heading("INPUT")
    var hint:=Label.new(); hint.text="C Character • P Pet • K Skills • I Inventory • E Equipment • R Refine • M Map • O System • V Status • same hotkey closes"; body.add_child(hint)

func _save_now()->void:
    SAVE.save_game(hero)
    _set_status("✓ Game saved successfully.")

func _learn_skill(skill_id:String)->void:
    if SKILLS.learn(hero,skill_id): SAVE.save_game(hero); _set_status("✓ Skill learned: "+skill_id)
    else: _set_status("✕ Skill requirements or skill points not met.")
    timer=1.0

func _status_points(current:Dictionary)->void:
    _clear_body()
    _heading("STATUS POINTS • CHARACTER STATS")
    var points:=int(current.get("stat_points",0))
    var summary:=Label.new()
    summary.text="Available Status Points: %d\nEach stat has a maximum of 99." % points
    summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    body.add_child(summary)
    var stats:Dictionary=current.get("stats",{})
    for stat in CHARACTER.STAT_NAMES:
        var row:=HBoxContainer.new()
        body.add_child(row)
        var value:=Label.new()
        value.text="%s   %d / 99" % [stat.to_upper(),int(stats.get(stat,1))]
        value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(value)
        var one:=Button.new()
        one.text="+1"
        one.disabled=points<=0 or int(stats.get(stat,1))>=99
        one.pressed.connect(_allocate_stat.bind(stat,1))
        row.add_child(one)
        var five:=Button.new()
        five.text="+5"
        five.disabled=points<=0 or int(stats.get(stat,1))>=99
        five.pressed.connect(_allocate_stat.bind(stat,5))
        row.add_child(five)
    _button("CLOSE",Callable(self,"_close_window"))

func _pet(current:Dictionary)->void:
    _clear_body()
    var pet_value:Variant=current.get("pet",{})
    if not pet_value is Dictionary: _heading("PET SYSTEM"); body.add_child(Label.new()); return
    var pet:Dictionary=pet_value; PET.ensure_state(pet)
    var species:String=str(pet.get("species",pet.get("name","Wolf Cub"))); var stats:Dictionary=PET.combat_stats(pet); var next:int=PET.xp_to_next(int(pet.get("level",1)))
    _heading("%s • %s • LEVEL %d / 250" % [str(pet.get("name","Pet")),species,int(pet.get("level",1))])
    var label:=Label.new(); label.text="XP %d / %d • Skill Points %d\nLoyalty %d%% • Refine +%d\nAttack %d • Magic %d • Defense %d • HP %d • Crit %d • Range %.1fm" % [int(pet.get("xp",0)),next,int(pet.get("skill_points",0)),int(pet.get("loyalty",100)),int(pet.get("refine",0)),int(stats["attack"]),int(stats["magic"]),int(stats["defense"]),int(stats["hp"]),int(stats["crit"]),float(stats["range"])]
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(label)
    _heading("PET SKILL TREE"); PET_SKILLS.ensure_state(pet)
    for skill in PET_SKILLS.all_skills(species):
        var id:String=str(skill["id"]); var level:int=PET_SKILLS.skill_level(pet,id); var can:bool=PET_SKILLS.can_learn(pet,id)
        var row:=HBoxContainer.new(); body.add_child(row)
        var info:=Label.new(); info.text="%s Lv.%d/%d • Req %d • Cost %d" % [str(skill["name"]),level,int(skill["max_level"]),int(skill["required_level"]),int(skill["cost"])]
        info.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(info)
        var learn:=Button.new(); learn.text="LEARN"; learn.disabled=not can; learn.pressed.connect(_learn_pet_skill.bind(id)); row.add_child(learn)
    _button("REFINE PET +1",Callable(self,"_refine_pet"))

func _learn_pet_skill(skill_id:String)->void:
    var pet_value:Variant=hero.get("pet",{})
    if pet_value is Dictionary and PET_SKILLS.learn(pet_value,skill_id): SAVE.save_game(hero); _set_status("✓ Pet skill learned: "+skill_id)
    else: _set_status("✕ Pet skill requirements or points not met.")
    timer=1.0

func _refine_pet()->void:
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return
    var result:Dictionary=PET.refine(pet_value,0.5)
    if bool(result.get("ok",false)): SAVE.save_game(hero)
    _show_result(result,"Pet refinement complete"); timer=1.0

func _inventory(current:Dictionary)->void:
    _clear_body(); _heading("INVENTORY • %d ZENY" % int(current.get("zeny",0)))
    var inv_value:Variant=current.get("inventory",{}); var inv:Dictionary=inv_value if inv_value is Dictionary else {}
    for item_value in inv.keys():
        var id:String=str(item_value); var amount:int=int(inv[item_value].get("amount",0)) if inv[item_value] is Dictionary else int(inv[item_value])
        if amount<=0: continue
        var data:Dictionary=ITEMS.all().get(id,{})
        var row:=HBoxContainer.new(); body.add_child(row)
        var item_button:=Button.new(); item_button.text="%s x%d" % [id,amount]; item_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL; item_button.pressed.connect(_select_item.bind(id)); row.add_child(item_button)
        var type:String=str(data.get("type",""))
        if type=="Consumable": var use:=Button.new(); use.text="USE"; use.pressed.connect(_use_item.bind(id)); row.add_child(use)
        elif type in ["Weapon","Armor","Accessory"]: var equip:=Button.new(); equip.text="EQUIP"; equip.pressed.connect(_equip_item.bind(id)); row.add_child(equip)

func _select_item(item_id:String)->void: selected_item=item_id; timer=1.0
func _equip_item(item_id:String)->void:
    var result:Dictionary=CHARACTER_INV.equip(hero,item_id); _show_result(result,"Equipped "+item_id); if bool(result.get("ok",false)): selected_item=""; timer=1.0
func _use_item(item_id:String)->void: var result:Dictionary=CHARACTER_INV.use_consumable(hero,item_id); _show_result(result,"Used "+item_id); timer=1.0

func _equipment(current:Dictionary)->void:
    _clear_body(); _heading("EQUIPMENT • LIVE STATS")
    var stats:Dictionary=CHARACTER.stats(current); var summary:=Label.new(); summary.text="Power %d • ATK %d • MATK %d • DEF %d • MDEF %d • HP %d • SP %d" % [CHARACTER.combat_power(current),int(stats["atk"]),int(stats["matk"]),int(stats["def"]),int(stats["mdef"]),int(stats["max_hp"]),int(stats["max_sp"] )]; body.add_child(summary)
    for slot in ["weapon","armor","head","head_middle","head_lower","garment","shoes","offhand","accessory_1","accessory_2"]:
        var equipment:Dictionary=current.get("equipment",{}); var raw:Variant=equipment.get(slot,null); var name:String="Empty"; var refine:int=0
        if raw is Dictionary: name=str(raw.get("id",raw.get("name","Unknown"))); refine=int(raw.get("refine",current.get("equipment_refine",{}).get(slot,0)))
        elif raw is String: name=str(raw); refine=int(current.get("equipment_refine",{}).get(slot,0))
        var row:=HBoxContainer.new(); body.add_child(row); var choose:=Button.new(); choose.text="%s: %s +%d" % [slot.to_upper(),name,refine]; choose.size_flags_horizontal=Control.SIZE_EXPAND_FILL; choose.pressed.connect(_select_slot.bind(slot)); row.add_child(choose)
        if name!="Empty": var remove:=Button.new(); remove.text="UNEQUIP"; remove.pressed.connect(_unequip_slot.bind(slot)); row.add_child(remove)
    if selected_slot!="": _heading("SELECTED SLOT • "+selected_slot.to_upper()); _button("REFINE SELECTED",Callable(self,"_refine_selected")); _button("CHOOSE CARD",Callable(self,"_show_card_picker"))

func _select_slot(slot:String)->void: selected_slot=slot; selected_card=""; timer=1.0
func _unequip_slot(slot:String)->void: var result:Dictionary=CHARACTER_INV.unequip(hero,slot); _show_result(result,"Unequipped "+slot); timer=1.0
func _refine(current:Dictionary)->void:
    _clear_body(); _heading("REFINEMENT • SILENT AUTOSAVE")
    for slot in ["weapon","armor","head","head_middle","head_lower","garment","shoes","offhand","accessory_1","accessory_2"]:
        var raw:Variant=current.get("equipment",{}).get(slot,null)
        if not raw is Dictionary: continue
        var item:Dictionary=raw; var refine:int=int(item.get("refine",0)); var chance:float=EQUIPMENT.refine_chance(refine); var material:String="Oridecon" if str(item.get("type",""))=="Weapon" and refine>=5 else "Elunium" if str(item.get("type",""))!="Weapon" and refine>=5 else "Phracon"; var owned:int=int(current.get("inventory",{}).get(material,0))
        var row:=HBoxContainer.new(); body.add_child(row); var text:=Label.new(); text.text="%s +%d → +%d • %.0f%% • %s x%d" % [str(item.get("id","Item")),refine,refine+1,chance*100.0,material,owned]; text.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(text); var button:=Button.new(); button.text="REFINE"; button.disabled=owned<=0; button.pressed.connect(_refine_slot.bind(slot)); row.add_child(button)
func _refine_slot(slot:String)->void: var result:Dictionary=CHARACTER_INV.refine(hero,slot,0.5); _show_result(result,"Refinement attempt complete"); timer=1.0
func _refine_selected()->void: if selected_slot!="": _refine_slot(selected_slot)

func _show_card_picker()->void:
    mode="equipment"; _clear_body(); _heading("CARD SELECTOR • PREVIEW")
    var cards_value:Variant=hero.get("cards",[]); var cards:Array=cards_value if cards_value is Array else []
    for card_value in cards:
        var id:String=str(card_value); var data:Dictionary=CARDS.all().get(id,{}); var row:=HBoxContainer.new(); body.add_child(row); var label:=Label.new(); label.text="%s • %s • %s" % [id,str(data.get("rarity","Common")),str(data.get("bonus",""))]; label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(label); var select:=Button.new(); select.text="SELECT"; select.pressed.connect(_select_card.bind(id)); row.add_child(select)
    _button("BACK",Callable(self,"_set_mode").bind("equipment"))
func _select_card(card_id:String)->void: selected_card=card_id; var data:Dictionary=CARDS.all().get(card_id,{}); _set_status("Card preview: %s • %s" % [card_id,str(data.get("bonus",""))]); timer=1.0
func _insert_card_now()->void:
    if selected_slot=="" or selected_card=="": return
    var result:Dictionary=CHARACTER_INV.insert_card(hero,selected_slot,selected_card); _show_result(result,"Card inserted"); if bool(result.get("ok",false)): selected_card=""; timer=1.0

func _events(current:Dictionary)->void:
    _clear_body(); _heading("LIVE EVENTS")
    var progress_value:Variant=current.get("event_progress",{}); var progress:Dictionary=progress_value if progress_value is Dictionary else {}
    for event in INV.event_catalog():
        var id:String=str(event["id"]); var label:=Label.new(); label.text="%s • %dh\n%s\nReward: %s\nProgress %d/%d" % [str(event["name"]),int(event["duration_hours"]),str(event["objective"]),str(event["reward"]),int(progress.get(id,0)),int(event.get("target",1))]; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(label)

func _monster(_current:Dictionary)->void:
    _clear_body(); _heading("MONSTER CODEX")
    var monsters:Variant=legacy.get("monsters") if legacy!=null else []
    if monsters is Array:
        for monster_value in monsters:
            if not monster_value is Dictionary: continue
            var monster:Dictionary=monster_value; var details:Dictionary=CODEX.details(monster); var label:=Label.new(); label.text="%s Lv.%d • Danger %d\n%s / %s • %s\nHP %d/%d • ATK %d • DEF %d\n%s" % [str(details["name"]),int(details["level"]),int(details["danger"]),str(details["role"]),str(details["element"]),str(details["status"]),int(monster.get("hp",0)),int(monster.get("max",monster.get("hp",0))),int(monster.get("attack",0)),int(monster.get("defense",0)),str(details["description"])]; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(label)

class SkillBadge extends Control:
    var tier:int=1
    var kind:String="active"
    var level:int=0
    func _draw()->void:
        var bg:=Color("#162333")
        var edge:=Color("#b99b5b")
        if kind=="ultimate": edge=Color("#e7c96a")
        elif kind=="passive": edge=Color("#7fa6c9")
        draw_rect(Rect2(Vector2.ZERO,size),bg,true)
        draw_rect(Rect2(Vector2.ZERO,size),edge,false,2.0)
        var center:=size*0.5
        draw_circle(center,17.0,Color("#25374b"))
        draw_circle(center,12.0,Color("#101722"))
        for i in range(max(1,tier)):
            var a:=float(i)*TAU/5.0-PI*0.5
            draw_circle(center+Vector2(cos(a),sin(a))*23.0,2.2,edge)
        draw_string(ThemeDB.fallback_font,Vector2(6,16),kind.to_upper().substr(0,3),HORIZONTAL_ALIGNMENT_LEFT,-1,8,edge)
        draw_string(ThemeDB.fallback_font,Vector2(0,size.y-7),("Lv."+str(level)),HORIZONTAL_ALIGNMENT_CENTER,size.x,9,Color("#efe8d8"))

class WorldMapPreview extends Control:
    var map_id:int=0
    func _draw()->void:
        draw_rect(Rect2(Vector2.ZERO,size),Color("#0a121c"),true)
        var cell:=42.0
        for x in range(12):
            for y in range(7):
                var p:=Vector2(float(x)*cell,float(y)*cell)
                var n:=float((x*31+y*17+map_id*13)%7)/7.0
                var c:=Color("#274631").lerp(Color("#8a6b45"),n*0.55)
                draw_rect(Rect2(p+Vector2(1,1),Vector2(cell-2,cell-2)),c,true)
        for i in range(8):
            var x:=30.0+float(i)*62.0
            draw_line(Vector2(x,0),Vector2(x,size.y),Color("#b89d6a66"),1.0)
        draw_circle(Vector2(size.x*0.52,size.y*0.50),7.0,Color("#e7c96a"))
        draw_circle(Vector2(size.x*0.22,size.y*0.28),5.0,Color("#66b7d8"))
        draw_circle(Vector2(size.x*0.78,size.y*0.68),5.0,Color("#d86d6d"))

func _show_result(result:Dictionary,success_text:String)->void:
    if bool(result.get("ok",false)): _set_status("✓ "+success_text)
    else:
        var reason:String=str(result.get("reason","action_failed")).replace("_"," ").capitalize(); if result.has("material"): reason+=" • "+str(result["material"]); _set_status("✕ "+reason)
func _set_status(text:String)->void:
    if status_label!=null: status_label.text=text
