class_name HWFinalSystemsRuntime
extends CanvasLayer

## Final Honour War city-war systems: soldiers, guarded banks, tower defense,
## automatic soldier replacement and persistent city-war state.
const SAVE = preload("res://scripts/SaveSystem.gd")
const MAX_SOLDIER_LEVEL:int = 50
const MAX_SOLDIERS:int = 50
const BANK_COUNT:int = 6
const MAX_TOWER_LEVEL:int = 10

var game:Node3D
var legacy:Node
var hero:Dictionary
var root_panel:PanelContainer
var status_label:Label
var stats_label:Label
var timer:float = 0.0
var income_timer:float = 0.0
var production_timer:float = 0.0

func _ready()->void:
    game = get_parent() as Node3D
    call_deferred("_bind")

func _bind()->void:
    if game == null:
        return
    legacy = game.get_node_or_null("LegacyGame")
    _build_ui()

func _process(delta:float)->void:
    timer += delta
    production_timer += delta
    income_timer += delta
    if legacy == null or not is_instance_valid(legacy):
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    hero = value
    _ensure_state(hero)
    if production_timer >= 8.0:
        production_timer = 0.0
        _produce_soldier()
    if income_timer >= 10.0:
        income_timer = 0.0
        _bank_income()
    if timer >= 1.0:
        timer = 0.0
        _refresh_ui()
        SAVE.save_game(hero)

func _ensure_state(current:Dictionary)->void:
    if not current.has("war_system") or not current["war_system"] is Dictionary:
        current["war_system"] = {}
    var war:Dictionary = current["war_system"]
    if not war.has("soldiers") or not war["soldiers"] is Array:
        war["soldiers"] = []
    if not war.has("dead_soldiers"):
        war["dead_soldiers"] = 0
    if not war.has("respawn_groups"):
        war["respawn_groups"] = 0
    if not war.has("production_level"):
        war["production_level"] = 1
    if not war.has("banks") or not war["banks"] is Dictionary:
        war["banks"] = {}
    if not war.has("tower_level"):
        war["tower_level"] = 1
    if not war.has("tower_wave"):
        war["tower_wave"] = 0
    if not war.has("tower_score"):
        war["tower_score"] = 0
    for index in BANK_COUNT:
        var key:String = "Bank %d" % (index + 1)
        if not war["banks"].has(key):
            war["banks"][key] = {"guard_hp":250 + index * 180,"guard_max_hp":250 + index * 180,"unlocked":false,"income":0,"soldiers":0}

func _produce_soldier()->void:
    var war:Dictionary = hero["war_system"]
    var soldiers:Array = war["soldiers"]
    if soldiers.size() >= MAX_SOLDIERS:
        return
    var n:int = soldiers.size() + int(war.get("dead_soldiers",0)) + 1
    var level:int = clamp(1 + int(hero.get("level",1)) / 5, 1, MAX_SOLDIER_LEVEL)
    soldiers.append({"id":"SOLDIER-%03d" % n,"level":level,"alive":true,"skills":["Auto Strike","Guard Stance"],"bank":""})
    war["soldiers"] = soldiers
    _set_status("Soldier produced: SOLDIER-%03d • Lv.%d" % [n,level])

func _bank_income()->void:
    var war:Dictionary = hero["war_system"]
    var banks:Dictionary = war["banks"]
    var total_income:int = 0
    var soldiers:Array = war["soldiers"]
    for key_value in banks.keys():
        var key:String = str(key_value)
        var bank:Dictionary = banks[key]
        if not bool(bank.get("unlocked",false)):
            continue
        var stationed:int = 0
        for soldier_value in soldiers:
            if soldier_value is Dictionary and bool(soldier_value.get("alive",false)) and str(soldier_value.get("bank","")) == key:
                stationed += 1
        bank["soldiers"] = stationed
        var gain:int = stationed * (8 + int(war.get("production_level",1)) * 2)
        bank["income"] = int(bank.get("income",0)) + gain
        total_income += gain
    if total_income > 0:
        hero["zeny"] = int(hero.get("zeny",0)) + total_income
        _set_status("Bank income +%d Zeny" % total_income)

func _unlock_next_bank()->void:
    var war:Dictionary = hero["war_system"]
    var banks:Dictionary = war["banks"]
    for i in BANK_COUNT:
        var key:String = "Bank %d" % (i + 1)
        var bank:Dictionary = banks[key]
        if bool(bank.get("unlocked",false)):
            continue
        var hp:int = int(bank.get("guard_hp",0))
        hp -= 250
        bank["guard_hp"] = max(0,hp)
        if hp <= 0:
            bank["unlocked"] = true
            _set_status("Guard defeated • %s unlocked. Station soldiers to earn automatic Zeny." % key)
        else:
            _set_status("%s guard hit • %d HP remaining" % [key,hp])
        break

func _station_one()->void:
    var war:Dictionary = hero["war_system"]
    var soldiers:Array = war["soldiers"]
    for soldier_value in soldiers:
        if not soldier_value is Dictionary:
            continue
        var soldier:Dictionary = soldier_value
        if not bool(soldier.get("alive",false)) or not str(soldier.get("bank","")).is_empty():
            continue
        var banks:Dictionary = war["banks"]
        for key_value in banks.keys():
            var key:String = str(key_value)
            var bank:Dictionary = banks[key]
            if bool(bank.get("unlocked",false)):
                soldier["bank"] = key
                soldier["skills"] = ["Auto Strike","Guard Stance"]
                _set_status("%s stationed at %s" % [str(soldier.get("id","Soldier")),key])
                return
    _set_status("Produce an idle soldier or unlock a bank first.")

func _build_tower()->void:
    var war:Dictionary = hero["war_system"]
    var level:int = int(war.get("tower_level",1))
    if level >= MAX_TOWER_LEVEL:
        _set_status("Tower defense is at maximum level 10.")
        return
    var cost:int = 500 * level
    if int(hero.get("zeny",0)) < cost:
        _set_status("Tower upgrade requires %d Zeny." % cost)
        return
    hero["zeny"] = int(hero.get("zeny",0)) - cost
    war["tower_level"] = level + 1
    war["tower_wave"] = int(war.get("tower_wave",0)) + 1
    war["tower_score"] = int(war.get("tower_score",0)) + level * 100
    _set_status("Tower Defense upgraded to Lv.%d • Wave %d" % [level + 1,int(war["tower_wave"])])

func _respawn_five()->void:
    var war:Dictionary = hero["war_system"]
    var soldiers:Array = war["soldiers"]
    var restored:int = 0
    for soldier_value in soldiers:
        if restored >= 5:
            break
        if soldier_value is Dictionary and not bool(soldier_value.get("alive",true)):
            soldier_value["alive"] = true
            soldier_value["bank"] = ""
            restored += 1
    if restored == 0:
        _set_status("No fallen soldiers are waiting for five-unit city respawn.")
        return
    war["dead_soldiers"] = max(0,int(war.get("dead_soldiers",0)) - restored)
    war["respawn_groups"] = int(war.get("respawn_groups",0)) + 1
    _set_status("City production respawned %d soldiers." % restored)

func _build_ui()->void:
    root_panel = PanelContainer.new()
    root_panel.name = "FinalWarSystems"
    root_panel.position = Vector2(20,710)
    root_panel.size = Vector2(1040,340)
    add_child(root_panel)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    root_panel.add_child(box)
    var title:=Label.new()
    title.text = "HONOUR WAR • CITY WAR SYSTEMS"
    title.add_theme_font_size_override("font_size",18)
    box.add_child(title)
    stats_label = Label.new()
    stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(stats_label)
    var row:=HBoxContainer.new()
    box.add_child(row)
    _make_button(row,"PRODUCE SOLDIER",Callable(self,"_produce_soldier"))
    _make_button(row,"STATION SOLDIER",Callable(self,"_station_one"))
    _make_button(row,"ATTACK BANK GUARD",Callable(self,"_unlock_next_bank"))
    _make_button(row,"TOWER UPGRADE",Callable(self,"_build_tower"))
    _make_button(row,"RESPAWN 5",Callable(self,"_respawn_five"))
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(status_label)

func _make_button(parent:Container,text:String,action:Callable)->void:
    var button:=Button.new()
    button.text=text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(action)
    parent.add_child(button)

func _refresh_ui()->void:
    if stats_label == null:
        return
    var war:Dictionary = hero.get("war_system",{}) if hero.get("war_system",{}) is Dictionary else {}
    var soldiers:Array = war.get("soldiers",[]) if war.get("soldiers",[]) is Array else []
    var alive:int = 0
    var stationed:int = 0
    for soldier_value in soldiers:
        if soldier_value is Dictionary and bool(soldier_value.get("alive",false)):
            alive += 1
            if not str(soldier_value.get("bank","")).is_empty():
                stationed += 1
    var unlocked:int = 0
    var banks:Dictionary = war.get("banks",{}) if war.get("banks",{}) is Dictionary else {}
    for bank_value in banks.values():
        if bank_value is Dictionary and bool(bank_value.get("unlocked",false)):
            unlocked += 1
    stats_label.text = "Soldiers %d/%d • Alive %d • Stationed %d • Lv.%d\nBanks %d/%d unlocked • Tower Defense Lv.%d • Wave %d • War Score %d" % [soldiers.size(),MAX_SOLDIERS,alive,stationed,int(war.get("production_level",1)),unlocked,BANK_COUNT,int(war.get("tower_level",1)),int(war.get("tower_wave",0)),int(war.get("tower_score",0))]

func _set_status(text:String)->void:
    if status_label != null:
        status_label.text = text