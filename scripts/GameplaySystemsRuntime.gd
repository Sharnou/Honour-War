class_name GameplaySystemsRuntime
extends CanvasLayer

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
var tabs:HBoxContainer
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
    _wire_toolbar()

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
    var root:=VBoxContainer.new()
    root.add_theme_constant_override("separation",5)
    panel.add_child(root)
    var title:=Label.new()
    title.text="HONOUR WAR  •  PROGRESSION"
    title.add_theme_font_size_override("font_size",16)
    root.add_child(title)
    tabs=HBoxContainer.new()
    root.add_child(tabs)
    var entries:Array=[["character","CHAR"],["skills","SKILLS"],["pet","PET"],["inventory","INV"],["equipment","EQUIP"],["refine","REFINE"],["events","EVENTS"],["monster","MONSTER"]]
    for entry in entries:
        var button:=Button.new()
        button.text=str(entry[1])
        button.pressed.connect(_set_mode.bind(str(entry[0])))
        tabs.add_child(button)
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
    hint.text="I Inventory  C Character  K Skills  P Pet  E Events  M Monster"
    root.add_child(hint)

func _wire_toolbar()->void:
    var ui:=game.get_node_or_null("HDUIStyleDirector")
    if ui==null: return
    var toolbar:Variant=ui.get("toolbar")
    if not toolbar is HBoxContainer: return
    var buttons:Array=toolbar.get_children()
    for i in buttons.size():
        var button:Variant=buttons[i]
        if button is BaseButton: button.pressed.connect(_toolbar_action.bind(i))

func _toolbar_action(index:int)->void:
    match index:
        0: _set_mode("character")
        1: _set_mode("pet")
        2: _set_mode("skills")
        3: _set_mode("inventory")
        4: _set_mode("equipment")
        5: _set_mode("refine")
        6: _set_mode("character")

func _set_mode(next:String)->void:
    mode=next
    if next!="equipment": selected_slot=""
    if next!="skills": selected_card=""
    selected_item="" if next!="inventory" else selected_item
    timer=1.0

func _unhandled_key_input(event:InputEvent)->void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    match event.keycode:
        KEY_I: _set_mode("inventory")
        KEY_C: _set_mode("character")
        KEY_K: _set_mode("skills")
        KEY_P: _set_mode("pet")
        KEY_E: _set_mode("events")
        KEY_M: _set_mode("monster")

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
        var one:=Button.new()
        one.text="+1"
        one.disabled=int(current.get("stat_points",0))<=0
        one.pressed.connect(_allocate_stat.bind(stat,1))
        row.add_child(one)
        var five:=Button.new()
        five.text="+5"
        five.disabled=int(current.get("stat_points",0))<=0
        five.pressed.connect(_allocate_stat.bind(stat,5))
        row.add_child(five)
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
    _clear_body()
    SKILLS.ensure_state(current)
    var class_id:String=str(current.get("class","Warrior"))
    _heading("%s SKILL TREE • %d SKILL POINTS" % [class_id.to_upper(),int(current.get("skill_points",0))])
    for skill in SKILLS.all_skills(class_id):
        var id:String=str(skill["id"])
        var level:int=SKILLS.skill_level(current,id)
        var req_ok:bool=SKILLS.can_learn(current,id)
        var row:=HBoxContainer.new()
        body.add_child(row)
        var info:=Label.new()
        info.text="%s  Lv.%d/%d  • Req Lv.%d • Cost %d\n%s" % [str(skill["name"]),level,int(skill["max_level"]),int(skill["required_level"]),int(skill["cost"]),str(skill["description"])]
        info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var learn:=Button.new()
        learn.text="LEARN"
        learn.disabled=not req_ok
        learn.pressed.connect(_learn_skill.bind(id))
        row.add_child(learn)
    _heading("Active skills are automatically rotated by the authoritative combat runtime when learned and affordable.")

func _learn_skill(skill_id:String)->void:
    if SKILLS.learn(hero,skill_id):
        SAVE.save_game(hero)
        _set_status("✓ Skill learned: "+skill_id)
    else: _set_status("✕ Skill requirements or skill points not met.")
    timer=1.0

func _pet(current:Dictionary)->void:
    _clear_body()
    var pet_value:Variant=current.get("pet",{})
    if not pet_value is Dictionary:
        _heading("PET SYSTEM")
        body.add_child(Label.new())
        return
    var pet:Dictionary=pet_value
    PET.ensure_state(pet)
    var species:String=str(pet.get("species",pet.get("name","Wolf Cub")))
    var stats:Dictionary=PET.combat_stats(pet)
    var next:int=PET.xp_to_next(int(pet.get("level",1)))
    _heading("%s • %s • LEVEL %d / 250" % [str(pet.get("name","Pet")),species,int(pet.get("level",1))])
    var label:=Label.new()
    label.text="XP %d / %d  •  Skill Points %d\nLoyalty %d%%  •  Refine +%d\nAttack %d  Magic %d  Defense %d  HP %d  Crit %d  Range %.1fm" % [int(pet.get("xp",0)),next,int(pet.get("skill_points",0)),int(pet.get("loyalty",100)),int(pet.get("refine",0)),int(stats["attack"]),int(stats["magic"]),int(stats["defense"]),int(stats["hp"]),int(stats["crit"]),float(stats["range"])]
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    body.add_child(label)
    _heading("PET SKILL TREE")
    PET_SKILLS.ensure_state(pet)
    for skill in PET_SKILLS.all_skills(species):
        var id:String=str(skill["id"])
        var level:int=PET_SKILLS.skill_level(pet,id)
        var can:bool=PET_SKILLS.can_learn(pet,id)
        var row:=HBoxContainer.new()
        body.add_child(row)
        var info:=Label.new()
        info.text="%s Lv.%d/%d • Req %d • Cost %d" % [str(skill["name"]),level,int(skill["max_level"]),int(skill["required_level"]),int(skill["cost"])]
        info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var learn:=Button.new()
        learn.text="LEARN"
        learn.disabled=not can
        learn.pressed.connect(_learn_pet_skill.bind(id))
        row.add_child(learn)
    _button("REFINE PET +1",Callable(self,"_refine_pet"))

func _learn_pet_skill(skill_id:String)->void:
    var pet_value:Variant=hero.get("pet",{})
    if pet_value is Dictionary and PET_SKILLS.learn(pet_value,skill_id):
        SAVE.save_game(hero)
        _set_status("✓ Pet skill learned: "+skill_id)
    else: _set_status("✕ Pet skill requirements or points not met.")
    timer=1.0

func _refine_pet()->void:
    var pet_value:Variant=hero.get("pet",{})
    if not pet_value is Dictionary: return
    var result:Dictionary=PET.refine(pet_value,0.5)
    if bool(result.get("ok",false)): SAVE.save_game(hero)
    _show_result(result,"Pet refinement complete")
    timer=1.0

func _inventory(current:Dictionary)->void:
    _clear_body()
    _heading("INVENTORY • %d ZENY" % int(current.get("zeny",0)))
    var inv_value:Variant=current.get("inventory",{})
    var inv:Dictionary=inv_value if inv_value is Dictionary else {}
    for item_value in inv.keys():
        var id:String=str(item_value)
        var amount:int=int(inv[item_value].get("amount",0)) if inv[item_value] is Dictionary else int(inv[item_value])
        if amount<=0: continue
        var data:Dictionary=ITEMS.all().get(id,{})
        var row:=HBoxContainer.new()
        body.add_child(row)
        var item_button:=Button.new()
        item_button.text="%s x%d" % [id,amount]
        item_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        item_button.pressed.connect(_select_item.bind(id))
        row.add_child(item_button)
        var type:String=str(data.get("type",""))
        if type=="Consumable":
            var use:=Button.new()
            use.text="USE"
            use.pressed.connect(_use_item.bind(id))
            row.add_child(use)
        elif type in ["Weapon","Armor","Accessory"]:
            var equip:=Button.new()
            equip.text="EQUIP"
            equip.pressed.connect(_equip_item.bind(id))
            row.add_child(equip)
    if selected_item!="":
        var selected:Dictionary=ITEMS.all().get(selected_item,{})
        _heading("SELECTED ITEM • "+selected_item)
        var detail:=Label.new()
        detail.text="Type %s • Rarity %s • Value %d\nATK %d  MATK %d  DEF %d  HP %d  SP %d  Slots %d\n%s" % [str(selected.get("type","Unknown")),str(selected.get("rarity","Common")),int(selected.get("value",0)),int(selected.get("attack",0)),int(selected.get("magic",0)),int(selected.get("defense",0)),int(selected.get("hp",0)),int(selected.get("sp",0)),int(selected.get("card_slots",0)),str(selected.get("effect",selected.get("description","")))]
        detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        body.add_child(detail)

func _select_item(item_id:String)->void:
    selected_item=item_id
    timer=1.0

func _equip_item(item_id:String)->void:
    var result:Dictionary=CHARACTER_INV.equip(hero,item_id)
    _show_result(result,"Equipped "+item_id)
    if bool(result.get("ok",false)): selected_item=""
    timer=1.0

func _use_item(item_id:String)->void:
    var result:Dictionary=CHARACTER_INV.use_consumable(hero,item_id)
    _show_result(result,"Used "+item_id)
    timer=1.0

func _equipment(current:Dictionary)->void:
    _clear_body()
    _heading("EQUIPMENT • LIVE STATS")
    var stats:Dictionary=CHARACTER.stats(current)
    var summary:=Label.new()
    summary.text="Power %d • ATK %d • MATK %d • DEF %d • MDEF %d • HP %d • SP %d" % [CHARACTER.combat_power(current),int(stats["atk"]),int(stats["matk"]),int(stats["def"]),int(stats["mdef"]),int(stats["max_hp"]),int(stats["max_sp"])]
    body.add_child(summary)
    for slot in ["weapon","armor","head","head_middle","head_lower","garment","shoes","offhand","accessory_1","accessory_2"]:
        var equipment:Dictionary=current.get("equipment",{})
        var raw:Variant=equipment.get(slot,null)
        var name:String="Empty"
        var refine:int=0
        if raw is Dictionary:
            name=str(raw.get("id",raw.get("name","Unknown")))
            refine=int(raw.get("refine",current.get("equipment_refine",{}).get(slot,0)))
        elif raw is String:
            name=str(raw)
            refine=int(current.get("equipment_refine",{}).get(slot,0))
        var row:=HBoxContainer.new()
        body.add_child(row)
        var choose:=Button.new()
        choose.text="%s: %s +%d" % [slot.to_upper(),name,refine]
        choose.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        choose.pressed.connect(_select_slot.bind(slot))
        row.add_child(choose)
        if name!="Empty":
            var remove:=Button.new()
            remove.text="UNEQUIP"
            remove.pressed.connect(_unequip_slot.bind(slot))
            row.add_child(remove)
    if selected_slot!="":
        _heading("SELECTED SLOT • "+selected_slot.to_upper())
        _button("REFINE SELECTED",Callable(self,"_refine_selected"))
        _button("CHOOSE CARD",Callable(self,"_show_card_picker"))

func _select_slot(slot:String)->void:
    selected_slot=slot
    selected_card=""
    timer=1.0

func _unequip_slot(slot:String)->void:
    var result:Dictionary=CHARACTER_INV.unequip(hero,slot)
    _show_result(result,"Unequipped "+slot)
    timer=1.0

func _refine(current:Dictionary)->void:
    _clear_body()
    _heading("REFINEMENT • SILENT AUTOSAVE")
    for slot in ["weapon","armor","head","head_middle","head_lower","garment","shoes","offhand","accessory_1","accessory_2"]:
        var raw:Variant=current.get("equipment",{}).get(slot,null)
        if not raw is Dictionary: continue
        var item:Dictionary=raw
        var refine:int=int(item.get("refine",0))
        var chance:float=EQUIPMENT.refine_chance(refine)
        var material:String="Oridecon" if str(item.get("type",""))=="Weapon" and refine>=5 else "Elunium" if str(item.get("type",""))!="Weapon" and refine>=5 else "Phracon"
        var owned:int=int(current.get("inventory",{}).get(material,0))
        if current.get("inventory",{}).get(material,0) is Dictionary: owned=int(current["inventory"][material].get("amount",0))
        var row:=HBoxContainer.new()
        body.add_child(row)
        var text:=Label.new()
        text.text="%s +%d → +%d • %.0f%% • %s x%d" % [str(item.get("id","Item")),refine,refine+1,chance*100.0,material,owned]
        text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(text)
        var button:=Button.new()
        button.text="REFINE"
        button.disabled=owned<=0
        button.pressed.connect(_refine_slot.bind(slot))
        row.add_child(button)

func _refine_slot(slot:String)->void:
    var result:Dictionary=CHARACTER_INV.refine(hero,slot,0.5)
    _show_result(result,"Refinement attempt complete")
    timer=1.0

func _refine_selected()->void:
    if selected_slot!="": _refine_slot(selected_slot)

func _show_card_picker()->void:
    mode="equipment"
    _clear_body()
    _heading("CARD SELECTOR • PREVIEW")
    var cards_value:Variant=hero.get("cards",[])
    var cards:Array=cards_value if cards_value is Array else []
    for card_value in cards:
        var id:String=str(card_value)
        var data:Dictionary=CARDS.all().get(id,{})
        var row:=HBoxContainer.new()
        body.add_child(row)
        var label:=Label.new()
        label.text="%s • %s • %s" % [id,str(data.get("rarity","Common")),str(data.get("bonus",""))]
        label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var select:=Button.new()
        select.text="SELECT"
        select.pressed.connect(_select_card.bind(id))
        row.add_child(select)
    if cards.is_empty(): body.add_child(Label.new())
    _button("BACK",Callable(self,"_set_mode").bind("equipment"))

func _select_card(card_id:String)->void:
    selected_card=card_id
    var data:Dictionary=CARDS.all().get(card_id,{})
    _set_status("Card preview: %s • %s" % [card_id,str(data.get("bonus",""))])
    timer=1.0

func _insert_card_now()->void:
    if selected_slot=="" or selected_card=="": return
    var result:Dictionary=CHARACTER_INV.insert_card(hero,selected_slot,selected_card)
    _show_result(result,"Card inserted")
    if bool(result.get("ok",false)): selected_card=""
    timer=1.0

func _events(current:Dictionary)->void:
    _clear_body()
    _heading("LIVE EVENTS")
    var progress_value:Variant=current.get("event_progress",{})
    var progress:Dictionary=progress_value if progress_value is Dictionary else {}
    for event in INV.event_catalog():
        var id:String=str(event["id"])
        var label:=Label.new()
        label.text="%s • %dh\n%s\nReward: %s\nProgress %d/%d" % [str(event["name"]),int(event["duration_hours"]),str(event["objective"]),str(event["reward"]),int(progress.get(id,0)),int(event.get("target",1))]
        label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        body.add_child(label)

func _monster(_current:Dictionary)->void:
    _clear_body()
    _heading("MONSTER CODEX")
    var monsters:Variant=legacy.get("monsters") if legacy!=null else []
    if monsters is Array:
        for monster_value in monsters:
            if not monster_value is Dictionary: continue
            var monster:Dictionary=monster_value
            var details:Dictionary=CODEX.details(monster)
            var label:=Label.new()
            label.text="%s Lv.%d • Danger %d\n%s / %s • %s\nHP %d/%d • ATK %d • DEF %d\n%s" % [str(details["name"]),int(details["level"]),int(details["danger"]),str(details["role"]),str(details["element"]),str(details["status"]),int(monster.get("hp",0)),int(monster.get("max",monster.get("hp",0))),int(monster.get("attack",0)),int(monster.get("defense",0)),str(details["description"])]
            label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
            body.add_child(label)

func _show_result(result:Dictionary,success_text:String)->void:
    if bool(result.get("ok",false)):
        _set_status("✓ "+success_text)
    else:
        var reason:String=str(result.get("reason","action_failed")).replace("_"," ").capitalize()
        if result.has("material"): reason+=" • "+str(result["material"])
        _set_status("✕ "+reason)

func _set_status(text:String)->void:
    if status_label!=null: status_label.text=text
