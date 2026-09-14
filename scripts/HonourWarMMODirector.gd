class_name HonourWarMMODirector
extends Node3D

const SAVE = preload("res://scripts/SaveSystem.gd")
const TELEPORT = preload("res://scripts/TeleportSystem.gd")

const TOWN_CENTER := Vector3(12.925,0.0,12.65)
const WARP_POINTS := {
    0:{"name":"Prontera","x":595.0,"y":340.0},
    1:{"name":"Payon Forest","x":613.0,"y":352.0},
    2:{"name":"Geffen Ruins","x":631.0,"y":364.0},
    3:{"name":"Morroc Desert","x":649.0,"y":376.0},
    4:{"name":"Ice Cavern","x":667.0,"y":388.0},
    5:{"name":"Dragon Sanctuary","x":685.0,"y":400.0},
    6:{"name":"War Arena","x":703.0,"y":412.0}
}
const QUESTS := [
    {"id":"q_roads","name":"Clear the Roads","target":8,"reward":700,"xp":900},
    {"id":"q_goblin","name":"Goblin Breakthrough","target":12,"reward":1200,"xp":1600},
    {"id":"q_dragon","name":"Dragon Hunt","target":5,"reward":4000,"xp":5500},
    {"id":"q_mvp","name":"MVP Guardian","target":1,"reward":10000,"xp":14000}
]

var game:Node
var legacy:Node
var hero:Dictionary={}
var ui:CanvasLayer
var quest_label:Label
var info_label:Label
var activity:RichTextLabel
var warp_edit:LineEdit
var active_quest:Dictionary={}
var quest_progress:int=0
var party:Array[String]=[]
var world:Node3D
var last_monster_signature:String=""
var save_timer:float=0.0

func _ready()->void:
    call_deferred("_bootstrap")
    set_process(true)

func _bootstrap()->void:
    game=get_tree().current_scene
    if game==null:
        return
    legacy=game.get("legacy") as Node
    if legacy==null:
        return
    var hv:Variant=legacy.get("hero")
    if not hv is Dictionary:
        return
    hero=hv
    _ensure_state()
    _build_world()
    _build_ui()

func _process(delta:float)->void:
    if game==null or not is_instance_valid(game):
        _bootstrap()
        return
    save_timer+=delta
    if save_timer>=10.0:
        save_timer=0.0
        _save()
    _watch_combat()
    _refresh_ui()

func _ensure_state()->void:
    if not hero.has("zeny"): hero["zeny"]=2500
    if not hero.has("storage"): hero["storage"]={"zeny":0}
    if not hero.has("party"): hero["party"]=[]
    if not hero.has("guild"): hero["guild"]={"name":"","level":1,"exp":0,"members":1}
    if not hero.has("quest_board"): hero["quest_board"]={"active":"","progress":0,"completed":[]}
    if not hero.has("battle_rank"): hero["battle_rank"]={"rating":1000,"wins":0,"losses":0}
    if not hero.has("dungeon_record"): hero["dungeon_record"]={}
    var q:Dictionary=hero["quest_board"]
    var qid:String=str(q.get("active",""))
    for def in QUESTS:
        if str(def["id"])==qid:
            active_quest=def.duplicate(true)
            quest_progress=int(q.get("progress",0))
            break
    var p:Variant=hero.get("party",[])
    if p is Array: party=(p as Array).duplicate()

func _build_world()->void:
    var old:=game.get_node_or_null("HW_MMOServiceWorld")
    if old!=null: old.queue_free()
    world=Node3D.new()
    world.name="HW_MMOServiceWorld"
    game.add_child(world)
    _service(TOWN_CENTER+Vector3(-7,0,-7),"QUEST HALL",Color("#a77d4d"),Color("#5e3435"))
    _service(TOWN_CENTER+Vector3(7,0,-7),"MARKET",Color("#6c8c71"),Color("#38564c"))
    _service(TOWN_CENTER+Vector3(-7,0,8),"BLACKSMITH",Color("#79889a"),Color("#343d4e"))
    _service(TOWN_CENTER+Vector3(7,0,8),"GUILD HALL",Color("#8f6b9b"),Color("#4e365c"))
    _portal(TOWN_CENTER+Vector3(0,0,-2),"WARP CRYSTAL",Color("#64d3ff"),2.6)
    _portal(Vector3(31,0,-2),"GEFFEN RUINS",Color("#9f76eb"),1.8)
    _portal(Vector3(-27,0,22),"ICE CAVERN",Color("#78c8ee"),1.8)
    _portal(Vector3(28,0,-20),"DRAGON SANCTUARY",Color("#e27b6a"),1.8)
    _arena()

func _service(pos:Vector3,title:String,wall:Color,roof:Color)->void:
    var root:=Node3D.new()
    root.name=title.replace(" ","")
    world.add_child(root)
    _box(root,Vector3(5.2,3.5,4.2),pos+Vector3(0,1.75,0),wall)
    var r:=MeshInstance3D.new()
    var rm:=CylinderMesh.new()
    rm.top_radius=0.0
    rm.bottom_radius=3.5
    rm.height=2.1
    rm.radial_segments=6
    r.mesh=rm
    r.position=pos+Vector3(0,4.45,0)
    r.material_override=_mat(roof,0.72,0.0)
    root.add_child(r)
    _box(root,Vector3(0.9,1.8,0.08),pos+Vector3(0,0.9,2.15),Color("#30241f"))
    var label:=Label3D.new()
    label.text=title
    label.position=pos+Vector3(0,5.7,0)
    label.font_size=20
    label.outline_size=6
    label.no_depth_test=true
    root.add_child(label)

func _portal(pos:Vector3,title:String,color:Color,radius:float)->void:
    var ring:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=radius
    mesh.outer_radius=radius+0.12
    mesh.ring_segments=64
    mesh.rings=12
    ring.mesh=mesh
    ring.position=pos+Vector3(0,1.9,0)
    ring.rotation_degrees.x=90.0
    ring.material_override=_glow(color)
    world.add_child(ring)
    var label:=Label3D.new()
    label.text=title
    label.position=pos+Vector3(0,4.0,0)
    label.font_size=18
    label.outline_size=5
    label.no_depth_test=true
    world.add_child(label)

func _arena()->void:
    var a:=MeshInstance3D.new()
    var m:=CylinderMesh.new()
    m.top_radius=7.0
    m.bottom_radius=7.0
    m.height=0.18
    m.radial_segments=64
    a.mesh=m
    a.position=Vector3(-42,0.1,-24)
    a.material_override=_mat(Color("#756b5d"),0.95,0.0)
    world.add_child(a)
    var ring:=MeshInstance3D.new()
    var rm:=TorusMesh.new()
    rm.inner_radius=6.3
    rm.outer_radius=6.45
    rm.ring_segments=64
    ring.mesh=rm
    ring.position=a.position+Vector3(0,0.14,0)
    ring.rotation_degrees.x=90.0
    ring.material_override=_glow(Color("#efbd5b"))
    world.add_child(ring)
    var label:=Label3D.new()
    label.text="WAR ARENA"
    label.position=a.position+Vector3(0,2.1,0)
    label.font_size=24
    label.outline_size=7
    label.no_depth_test=true
    world.add_child(label)

func _build_ui()->void:
    if ui!=null and is_instance_valid(ui): ui.queue_free()
    ui=CanvasLayer.new()
    ui.name="HonourWarMMOUI"
    add_child(ui)
    var root:=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)
    var panel:=Panel.new()
    panel.position=Vector2(18,100)
    panel.size=Vector2(330,525)
    panel.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(panel)
    var title:=Label.new()
    title.text="HONOUR WAR • MMO"
    title.position=Vector2(16,12)
    title.add_theme_font_size_override("font_size",20)
    title.add_theme_color_override("font_color",Color("#e1bd63"))
    panel.add_child(title)
    info_label=Label.new()
    info_label.position=Vector2(16,48)
    info_label.size=Vector2(298,88)
    panel.add_child(info_label)
    quest_label=Label.new()
    quest_label.position=Vector2(16,145)
    quest_label.size=Vector2(298,88)
    quest_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(quest_label)
    _button(panel,"ACCEPT QUEST",Vector2(16,240),_accept_quest)
    _button(panel,"TURN IN QUEST",Vector2(16,280),_turn_quest)
    _button(panel,"BUY POTION",Vector2(16,320),_buy_potion)
    _button(panel,"DEPOSIT 500 ZENY",Vector2(16,360),_deposit)
    _button(panel,"CRAFT SUPPLY",Vector2(16,400),_craft)
    _button(panel,"CREATE / GROW GUILD",Vector2(16,440),_guild)
    _button(panel,"ADD PARTY MEMBER",Vector2(16,480),_party)
    var right:=Panel.new()
    right.position=Vector2(1510,100)
    right.size=Vector2(390,525)
    right.add_theme_stylebox_override("panel",_panel_style())
    root.add_child(right)
    var warp_title:=Label.new()
    warp_title.text="WORLD TRAVEL"
    warp_title.position=Vector2(16,14)
    warp_title.add_theme_color_override("font_color",Color("#e1bd63"))
    right.add_child(warp_title)
    warp_edit=LineEdit.new()
    warp_edit.position=Vector2(16,46)
    warp_edit.size=Vector2(255,36)
    warp_edit.placeholder_text="@go 0 230:220"
    warp_edit.text_submitted.connect(_warp_command)
    right.add_child(warp_edit)
    _button(right,"WARP",Vector2(280,46),func(): _warp_command(warp_edit.text))
    var y:float=95.0
    for map_id in [0,1,2,3,4,5,6]:
        var b:=Button.new()
        b.text=str(WARP_POINTS[map_id]["name"])
        b.position=Vector2(16+(map_id%2)*180,y+float(map_id/2)*42.0)
        b.size=Vector2(165,34)
        b.pressed.connect(func(id:int=map_id): _warp(id))
        right.add_child(b)
    activity=RichTextLabel.new()
    activity.position=Vector2(16,350)
    activity.size=Vector2(350,155)
    activity.bbcode_enabled=true
    right.add_child(activity)

func _button(parent:Control,text:String,pos:Vector2,callback:Callable)->void:
    var b:=Button.new()
    b.text=text
    b.position=pos
    b.size=Vector2(298 if parent.position.x<500 else 96,34)
    b.pressed.connect(callback)
    parent.add_child(b)

func _refresh_ui()->void:
    if info_label==null or hero.is_empty(): return
    var map_id:int=int(hero.get("map_id",0))
    var map_name:String=str(WARP_POINTS.get(map_id,{"name":"Unknown"})["name"])
    var guild:Dictionary=hero.get("guild",{})
    info_label.text="Level %d / 250\nZeny %d\nMap: %s\nAge %d • Party %d/4\nGuild: %s Lv%d" % [int(hero.get("level",1)),int(hero.get("zeny",0)),map_name,int(hero.get("age",1)),party.size()+1,str(guild.get("name","No Guild")) if not str(guild.get("name","")).is_empty() else "No Guild",int(guild.get("level",1))]
    if active_quest.is_empty():
        quest_label.text="Quest Board\nNo active quest."
    else:
        quest_label.text="%s\nProgress %d/%d\nReward %d Zeny + %d XP" % [str(active_quest["name"]),quest_progress,int(active_quest["target"]),int(active_quest["reward"]),int(active_quest["xp"])]

func _accept_quest()->void:
    if not active_quest.is_empty():
        _activity("[Quest] Finish your current mission first.")
        return
    var done:Array=hero["quest_board"].get("completed",[])
    for def in QUESTS:
        if not done.has(def["id"]):
            active_quest=def.duplicate(true)
            quest_progress=0
            hero["quest_board"]["active"]=def["id"]
            hero["quest_board"]["progress"]=0
            _activity("[Quest] Accepted %s." % str(def["name"]))
            _save()
            return
    hero["quest_board"]["completed"]=[]
    _activity("[Quest] Board reset for a new hunting season.")

func _turn_quest()->void:
    if active_quest.is_empty():
        _activity("[Quest] Nothing to turn in.")
        return
    if quest_progress<int(active_quest["target"]):
        _activity("[Quest] %d/%d complete." % [quest_progress,int(active_quest["target"])])
        return
    hero["zeny"]=int(hero["zeny"])+int(active_quest["reward"])
    hero["quest_board"]["completed"].append(active_quest["id"])
    hero["quest_board"]["active"]=""
    hero["quest_board"]["progress"]=0
    _activity("[Quest] Completed %s." % str(active_quest["name"]))
    active_quest={}
    quest_progress=0
    _save()

func _watch_combat()->void:
    if active_quest.is_empty() or legacy==null: return
    var monsters:Variant=legacy.get("monsters")
    if not monsters is Array: return
    var entries:Array[String]=[]
    for mob in monsters:
        if mob is Dictionary: entries.append(str(mob.get("id",""))+":"+str(mob.get("hp",0)))
    var signature:String="|".join(entries)
    if last_monster_signature.is_empty():
        last_monster_signature=signature
        return
    if signature!=last_monster_signature and entries.size()<last_monster_signature.split("|").size():
        quest_progress=min(quest_progress+1,int(active_quest["target"]))
        hero["quest_board"]["progress"]=quest_progress
    last_monster_signature=signature

func _buy_potion()->void:
    var price:int=max(20,85-int(hero.get("age",1))*2)
    if int(hero.get("zeny",0))<price:
        _activity("[Market] Need %d Zeny." % price)
        return
    hero["zeny"]=int(hero["zeny"])-price
    var inv:Dictionary=hero.get("inventory",{})
    inv["Red Potion"]=int(inv.get("Red Potion",0))+1
    hero["inventory"]=inv
    _activity("[Market] Red Potion purchased for %d Zeny." % price)
    _save()

func _deposit()->void:
    var amount:int=min(500,int(hero.get("zeny",0)))
    if amount<=0:
        _activity("[Storage] No Zeny to deposit.")
        return
    hero["zeny"]=int(hero["zeny"])-amount
    var storage:Dictionary=hero.get("storage",{})
    storage["zeny"]=int(storage.get("zeny",0))+amount
    hero["storage"]=storage
    _activity("[Storage] Deposited %d Zeny." % amount)
    _save()

func _craft()->void:
    var mats:Dictionary=hero.get("materials",{})
    var p:int=int(mats.get("Phracon",0))
    var wood:int=int(mats.get("Wood",0))
    if p<1 and wood<3:
        _activity("[Craft] Need 1 Phracon or 3 Wood.")
        return
    if wood>=3: mats["Wood"]=wood-3
    else: mats["Phracon"]=p-1
    var inv:Dictionary=hero.get("inventory",{})
    inv["Hunter Supply Crate"]=int(inv.get("Hunter Supply Crate",0))+1
    hero["materials"]=mats
    hero["inventory"]=inv
    _activity("[Craft] Hunter Supply Crate created.")
    _save()

func _guild()->void:
    var guild:Dictionary=hero.get("guild",{})
    if str(guild.get("name","")).is_empty():
        guild={"name":"Honour Guard","level":1,"exp":0,"members":1}
        _activity("[Guild] Honour Guard founded.")
    else:
        guild["exp"]=int(guild.get("exp",0))+100
        if int(guild["exp"])>=500:
            guild["exp"]=int(guild["exp"])-500
            guild["level"]=int(guild.get("level",1))+1
            _activity("[Guild] Reached level %d." % int(guild["level"]))
    hero["guild"]=guild
    _save()

func _party()->void:
    if party.size()>=3:
        _activity("[Party] Maximum 4 members reached.")
        return
    var names:Array[String]=["Aeris","Bran","Cira"]
    party.append(names[party.size()])
    hero["party"]=party
    _activity("[Party] %s joined." % party[-1])
    _save()

func _warp_command(command:String)->void:
    var parsed:Variant=TELEPORT.parse_go(command)
    if parsed is Dictionary and bool(parsed.get("ok",false)):
        _warp(int(parsed.get("map_id",0)))
    else:
        _activity("[Warp] Use @go <map> <x>:<y>.")

func _warp(map_id:int)->void:
    if not WARP_POINTS.has(map_id):
        _activity("[Warp] Map %d does not exist." % map_id)
        return
    hero["map_id"]=map_id
    hero["pos_x"]=float(WARP_POINTS[map_id]["x"])
    hero["pos_y"]=float(WARP_POINTS[map_id]["y"])
    _activity("[Warp] %s." % str(WARP_POINTS[map_id]["name"]))
    _save()

func _activity(message:String)->void:
    if activity==null: return
    activity.append_text(message+"\n")
    if activity.get_line_count()>9: activity.scroll_to_line(activity.get_line_count()-1)

func _save()->void:
    if not hero.is_empty(): SAVE.save_game(hero)

func _mat(color:Color,roughness:float,metallic:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=roughness
    m.metallic=metallic
    return m

func _glow(color:Color)->StandardMaterial3D:
    var m:=_mat(color,0.28,0.20)
    m.emission_enabled=true
    m.emission=color.darkened(0.65)
    m.emission_energy_multiplier=1.4
    return m

func _box(parent:Node3D,size:Vector3,pos:Vector3,color:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=size
    n.mesh=mesh
    n.position=pos
    n.material_override=_mat(color,0.78,0.0)
    parent.add_child(n)
    return n

func _panel_style()->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=Color("#0a111bdd")
    s.border_color=Color("#b99b5b")
    s.set_border_width_all(1)
    s.set_corner_radius_all(5)
    return s
