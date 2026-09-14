class_name HonourWarMMODirector
extends Node3D

## Honour War MMO gameplay/world layer.
## This layer turns the existing combat prototype into a persistent MMORPG-style loop:
## town services, quests, parties, guild progression, storage, crafting, dungeons,
## warp commands and economy. It is intentionally original rather than a 1:1 copy of
## any existing game's assets or implementation.

const SAVE = preload("res://scripts/SaveSystem.gd")
const TELEPORT = preload("res://scripts/TeleportSystem.gd")
const PET = preload("res://scripts/PetSystem.gd")
const CITY = preload("res://scripts/CitySystem.gd")

const TOWN_CENTER := Vector3(12.925, 0.0, 12.65)
const WARP_POINTS := {
    0: {"name":"Prontera", "pos":Vector3(12.925,0.18,12.65)},
    1: {"name":"Payon Forest", "pos":Vector3(-21.0,0.18,5.0)},
    2: {"name":"Geffen Ruins", "pos":Vector3(45.0,0.18,-6.0)},
    3: {"name":"Morroc Desert", "pos":Vector3(44.0,0.18,28.0)},
    4: {"name":"Ice Cavern", "pos":Vector3(-38.0,0.18,28.0)},
    5: {"name":"Dragon Sanctuary", "pos":Vector3(42.0,0.18,-25.0)},
    6: {"name":"War Arena", "pos":Vector3(-42.0,0.18,-24.0)}
}

const QUESTS := [
    {"id":"q_rats", "name":"Clearing the Roads", "target":8, "reward":700, "xp":900},
    {"id":"q_goblins", "name":"Goblin Breakthrough", "target":12, "reward":1200, "xp":1600},
    {"id":"q_dragons", "name":"Dragon Hunt", "target":5, "reward":4000, "xp":5500},
    {"id":"q_guardian", "name":"MVP Guardian", "target":1, "reward":10000, "xp":14000}
]

var game:Node
var legacy:Node
var hero:Dictionary
var ui:CanvasLayer
var service_panel:Panel
var status:Label
var quest_label:Label
var party_label:Label
var guild_label:Label
var activity_label:RichTextLabel
var warp_edit:LineEdit
var active_quest:Dictionary={}
var quest_progress:int=0
var party:Array[String]=[]
var guild_name:String=""
var last_kill_signature:String=""
var save_accumulator:float=0.0
var world_root:Node3D
var actor_services:Node3D

func _ready()->void:
    game=get_parent()
    if game==null:
        return
    legacy=game.get("legacy") as Node
    if legacy==null:
        return
    var value:Variant=legacy.get("hero")
    if not value is Dictionary:
        return
    hero=value
    _ensure_state()
    call_deferred("_build_world_layer")
    call_deferred("_build_ui")
    set_process(true)

func _process(delta:float)->void:
    save_accumulator+=delta
    if save_accumulator>=12.0:
        save_accumulator=0.0
        _save()
    _refresh_quest_from_combat()
    _refresh_ui()

func _ensure_state()->void:
    if not hero.has("zeny"):
        hero["zeny"]=2500
    if not hero.has("storage"):
        hero["storage"]={}
    if not hero.has("party"):
        hero["party"]=[]
    if not hero.has("guild"):
        hero["guild"]={"name":"", "level":1, "exp":0, "members":1}
    if not hero.has("quest_board"):
        hero["quest_board"]={"active":"", "progress":0, "completed":[]}
    if not hero.has("battle_rank"):
        hero["battle_rank"]={"rating":1000, "wins":0, "losses":0}
    if not hero.has("dungeon_record"):
        hero["dungeon_record"]={}
    guild_name=str((hero["guild"] as Dictionary).get("name",""))
    var q:Dictionary=hero["quest_board"]
    var qid:String=str(q.get("active",""))
    if not qid.is_empty():
        for definition in QUESTS:
            if str(definition["id"])==qid:
                active_quest=definition.duplicate(true)
                quest_progress=int(q.get("progress",0))
                break
    var stored_party:Variant=hero.get("party",[])
    if stored_party is Array:
        party=(stored_party as Array).duplicate()

func _build_world_layer()->void:
    world_root=Node3D.new()
    world_root.name="HW_MMOServiceWorld"
    add_child(world_root)
    actor_services=Node3D.new()
    actor_services.name="ServiceActors"
    world_root.add_child(actor_services)
    _add_world_hub(Vector3(12.925,0.0,12.65))
    _add_warp_hub()
    _add_dungeon_gates()
    _add_arena()

func _build_ui()->void:
    ui=CanvasLayer.new()
    ui.name="HonourWarMMOUI"
    add_child(ui)
    var root:=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_PASS
    ui.add_child(root)

    var left:=Panel.new()
    left.position=Vector2(18,100)
    left.size=Vector2(290,520)
    left.add_theme_stylebox_override("panel",_panel_style(Color("#0b121cd9")))
    root.add_child(left)

    var title:=Label.new()
    title.text="ADVENTURE CENTER"
    title.position=Vector2(16,12)
    title.add_theme_font_size_override("font_size",18)
    title.add_theme_color_override("font_color",Color("#e1bd63"))
    left.add_child(title)

    quest_label=Label.new()
    quest_label.position=Vector2(16,48)
    quest_label.size=Vector2(258,90)
    quest_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    left.add_child(quest_label)

    var accept:=Button.new()
    accept.text="ACCEPT NEXT QUEST"
    accept.position=Vector2(16,150)
    accept.size=Vector2(258,34)
    accept.pressed.connect(_accept_next_quest)
    left.add_child(accept)

    var complete:=Button.new()
    complete.text="TURN IN QUEST"
    complete.position=Vector2(16,190)
    complete.size=Vector2(258,34)
    complete.pressed.connect(_turn_in_quest)
    left.add_child(complete)

    var shop:=Button.new()
    shop.text="MARKET: BUY 1 RED POTION"
    shop.position=Vector2(16,236)
    shop.size=Vector2(258,34)
    shop.pressed.connect(_buy_potion)
    left.add_child(shop)

    var storage:=Button.new()
    storage.text="STORAGE: DEPOSIT ZENY"
    storage.position=Vector2(16,276)
    storage.size=Vector2(258,34)
    storage.pressed.connect(_deposit_zeny)
    left.add_child(storage)

    var craft:=Button.new()
    craft.text="CRAFT: HUNTER SUPPLY"
    craft.position=Vector2(16,316)
    craft.size=Vector2(258,34)
    craft.pressed.connect(_craft_supply)
    left.add_child(craft)

    var guild:=Button.new()
    guild.text="GUILD: CREATE / + EXP"
    guild.position=Vector2(16,356)
    guild.size=Vector2(258,34)
    guild.pressed.connect(_guild_action)
    left.add_child(guild)

    party_label=Label.new()
    party_label.position=Vector2(16,400)
    party_label.size=Vector2(258,56)
    party_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    left.add_child(party_label)

    var invite:=Button.new()
    invite.text="PARTY: ADD BOT MEMBER"
    invite.position=Vector2(16,470)
    invite.size=Vector2(258,34)
    invite.pressed.connect(_add_party_member)
    left.add_child(invite)

    guild_label=Label.new()
    guild_label.position=Vector2(16,512)
    guild_label.size=Vector2(258,64)
    guild_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    left.add_child(guild_label)

    var right:=Panel.new()
    right.position=Vector2(1505,100)
    right.size=Vector2(397,520)
    right.add_theme_stylebox_override("panel",_panel_style(Color("#0b121cd9")))
    root.add_child(right)

    var stats:=Label.new()
    stats.name="WorldStats"
    stats.position=Vector2(16,12)
    stats.size=Vector2(365,85)
    stats.add_theme_color_override("font_color",Color("#efe8d7"))
    right.add_child(stats)
    status=stats

    var warp_title:=Label.new()
    warp_title.text="COORDINATE WARP"
    warp_title.position=Vector2(16,110)
    warp_title.add_theme_color_override("font_color",Color("#e1bd63"))
    right.add_child(warp_title)
    warp_edit=LineEdit.new()
    warp_edit.position=Vector2(16,140)
    warp_edit.size=Vector2(260,36)
    warp_edit.placeholder_text="@go 0 230:220"
    warp_edit.text_submitted.connect(_execute_warp)
    right.add_child(warp_edit)
    var warp_btn:=Button.new()
    warp_btn.text="WARP"
    warp_btn.position=Vector2(286,140)
    warp_btn.size=Vector2(95,36)
    warp_btn.pressed.connect(func(): _execute_warp(warp_edit.text))
    right.add_child(warp_btn)

    var map_y:float=195.0
    for map_id in [0,1,2,3,4,5,6]:
        var button:=Button.new()
        button.text=str(WARP_POINTS[map_id]["name"])
        button.position=Vector2(16+(int(map_id)%2)*185,map_y+float(int(map_id)/2)*42.0)
        button.size=Vector2(170,34)
        button.pressed.connect(func(id:int=map_id): _warp_to(id,Vector2.ZERO))
        right.add_child(button)

    activity_label=RichTextLabel.new()
    activity_label.position=Vector2(16,360)
    activity_label.size=Vector2(365,140)
    activity_label.bbcode_enabled=true
    right.add_child(activity_label)
    _refresh_ui()

func _refresh_ui()->void:
    if status==null or hero.is_empty():
        return
    var map_name:String=str(WARP_POINTS.get(int(hero.get("map_id",0)),{"name":"Unknown"})["name"])
    status.text="[b]LIVE WORLD[/b]\nLv %d / 250   Zeny %d\nMap: %s   Age %d\nDungeon clears: %d" % [int(hero.get("level",1)),int(hero.get("zeny",0)),map_name,int(hero.get("age",1)),(hero.get("dungeon_record",{}) as Dictionary).size()]
    if active_quest.is_empty():
        quest_label.text="Quest board: no active mission.\nAccept a hunt to begin the RPG loop."
    else:
        quest_label.text="[Quest] %s\nProgress %d / %d\nReward: %d Zeny + %d XP" % [str(active_quest["name"]),quest_progress,int(active_quest["target"]),int(active_quest["reward"]),int(active_quest["xp"])]
    party_label.text="Party: %d / 4\n%s" % [party.size()+1,", ".join(party) if not party.is_empty() else "Solo adventure"]
    var g:Dictionary=hero.get("guild",{})
    guild_label.text="Guild: %s\nLevel %d • EXP %d • Members %d" % [str(g.get("name","No Guild")) if not str(g.get("name","")).is_empty() else "No Guild",int(g.get("level",1)),int(g.get("exp",0)),int(g.get("members",1))]

func _accept_next_quest()->void:
    if not active_quest.is_empty():
        _activity("[Quest] Finish the active mission before accepting another.")
        return
    var completed:Array=hero["quest_board"].get("completed",[])
    for definition in QUESTS:
        if not completed.has(definition["id"]):
            active_quest=definition.duplicate(true)
            quest_progress=0
            hero["quest_board"]["active"]=str(definition["id"])
            hero["quest_board"]["progress"]=0
            _activity("[Quest] Accepted: %s." % str(definition["name"]))
            _save()
            return
    hero["quest_board"]["completed"]=[]
    _activity("[Quest] Board rotated. New hunt chain is available.")

func _turn_in_quest()->void:
    if active_quest.is_empty():
        _activity("[Quest] No active mission.")
        return
    if quest_progress<int(active_quest["target"]):
        _activity("[Quest] Not complete: %d / %d." % [quest_progress,int(active_quest["target"])])
        return
    hero["zeny"]=int(hero.get("zeny",0))+int(active_quest["reward"])
    hero["quest_board"]["completed"].append(active_quest["id"])
    hero["quest_board"]["active"]=""
    hero["quest_board"]["progress"]=0
    _activity("[Quest] Completed %s. Reward +%d Zeny / +%d XP." % [active_quest["name"],int(active_quest["reward"]),int(active_quest["xp"])])
    active_quest={}
    quest_progress=0
    _save()

func _refresh_quest_from_combat()->void:
    if active_quest.is_empty():
        return
    var monsters_value:Variant=legacy.get("monsters")
    if not monsters_value is Array:
        return
    var alive_signature:Array[String]=[]
    for monster in monsters_value:
        if monster is Dictionary:
            alive_signature.append(str(monster.get("id",""))+":"+str(monster.get("hp",0)))
    var signature:String="|".join(alive_signature)
    if last_kill_signature.is_empty():
        last_kill_signature=signature
        return
    if signature==last_kill_signature:
        return
    var old_parts:Array[String]=last_kill_signature.split("|")
    var new_parts:Array[String]=signature.split("|")
    if new_parts.size()<old_parts.size():
        quest_progress=min(int(active_quest["target"]),quest_progress+1)
        hero["quest_board"]["progress"]=quest_progress
        _activity("[Quest] Hunt progress: %d / %d." % [quest_progress,int(active_quest["target"])])
    last_kill_signature=signature

func _buy_potion()->void:
    var price:int=85
    var age:int=int(hero.get("age",1))
    price=max(20,price-age*2)
    if int(hero.get("zeny",0))<price:
        _activity("[Market] Need %d Zeny." % price)
        return
    hero["zeny"]=int(hero["zeny"])-price
    var inv:Dictionary=hero.get("inventory",{})
    inv["Red Potion"]=int(inv.get("Red Potion",0))+1
    hero["inventory"]=inv
    _activity("[Market] Bought Red Potion for %d Zeny." % price)
    _save()

func _deposit_zeny()->void:
    var amount:int=min(500,int(hero.get("zeny",0)))
    if amount<=0:
        _activity("[Storage] No Zeny available.")
        return
    hero["zeny"]=int(hero["zeny"])-amount
    hero["storage"]["zeny"]=int(hero["storage"].get("zeny",0))+amount
    _activity("[Storage] Deposited %d Zeny. Stored: %d." % [amount,int(hero["storage"]["zeny"])])
    _save()

func _craft_supply()->void:
    var mats:Dictionary=hero.get("materials",{})
    var wood:int=int(mats.get("Wood",0))
    var phra:int=int(mats.get("Phracon",0))
    if wood<3 and phra<1:
        _activity("[Craft] Need 3 Wood or 1 Phracon.")
        return
    if wood>=3:
        mats["Wood"]=wood-3
    else:
        mats["Phracon"]=phra-1
    var inv:Dictionary=hero.get("inventory",{})
    inv["Hunter Supply Crate"]=int(inv.get("Hunter Supply Crate",0))+1
    hero["inventory"]=inv
    hero["materials"]=mats
    _activity("[Craft] Created Hunter Supply Crate.")
    _save()

func _guild_action()->void:
    var guild:Dictionary=hero["guild"]
    if str(guild.get("name","")).is_empty():
        guild["name"]="Honour Guard"
        guild["level"]=1
        guild["exp"]=0
        guild["members"]=1
        hero["guild"]=guild
        guild_name="Honour Guard"
        _activity("[Guild] Founded Honour Guard.")
    else:
        guild["exp"]=int(guild.get("exp",0))+100
        if int(guild["exp"])>=500:
            guild["exp"]=int(guild["exp"])-500
            guild["level"]=int(guild.get("level",1))+1
            _activity("[Guild] Honour Guard reached level %d." % int(guild["level"]))
        else:
            _activity("[Guild] Guild contribution +100 EXP.")
        hero["guild"]=guild
    _save()

func _add_party_member()->void:
    if party.size()>=3:
        _activity("[Party] Maximum 4 members reached.")
        return
    var names:Array[String]=["Aeris", "Bran", "Cira"]
    var member:String=names[party.size()]
    party.append(member)
    hero["party"]=party
    _activity("[Party] %s joined the party. Formation %d / 4." % [member,party.size()+1])
    _save()

func _execute_warp(command:String)->void:
    var parsed:Variant=TELEPORT.parse_go(command)
    if parsed is Dictionary and bool(parsed.get("ok",false)):
        _warp_to(int(parsed.get("map_id",0)),Vector2(float(parsed.get("x",0)),float(parsed.get("y",0))))
        return
    _activity("[Warp] Invalid command. Use @go <map> <x>:<y>.")

func _warp_to(map_id:int,_coords:Vector2)->void:
    if not WARP_POINTS.has(map_id):
        _activity("[Warp] Unknown map %d." % map_id)
        return
    var point:Dictionary=WARP_POINTS[map_id]
    hero["map_id"]=map_id
    hero["pos_x"]=595.0+float(map_id)*18.0
    hero["pos_y"]=340.0+float(map_id)*12.0
    _activity("[Warp] Arrived in %s." % str(point["name"]))
    _save()

func _add_world_hub(center:Vector3)->void:
    _service_building(center+Vector3(-7,0,-7),"Quest Hall",Color("#a77d4d"),Color("#5e3435"))
    _service_building(center+Vector3(7,0,-7),"Market",Color("#6c8c71"),Color("#38564c"))
    _service_building(center+Vector3(-7,0,8),"Blacksmith",Color("#79889a"),Color("#343d4e"))
    _service_building(center+Vector3(7,0,8),"Guild Hall",Color("#8f6b9b"),Color("#4e365c"))

func _add_warp_hub()->void:
    var ring:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=2.6
    mesh.outer_radius=2.72
    mesh.ring_segments=64
    mesh.rings=12
    ring.mesh=mesh
    ring.rotation_degrees.x=90.0
    ring.position=TOWN_CENTER+Vector3(0,0.12,-2.0)
    ring.material_override=_glow_material(Color("#62c9ff"),Color("#1c5f9a"))
    world_root.add_child(ring)
    var label:=Label3D.new()
    label.text="WARP CRYSTAL"
    label.position=ring.position+Vector3(0,1.3,0)
    label.font_size=18
    label.outline_size=5
    label.modulate=Color("#bdeaff")
    label.no_depth_test=true
    world_root.add_child(label)

func _add_dungeon_gates()->void:
    var ids:Array[int]=[2,4,5]
    var positions:Array[Vector3]=[Vector3(31,0,-2),Vector3(-27,0,22),Vector3(28,0,-20)]
    for i in ids.size():
        var gate:=Node3D.new()
        gate.name="DungeonGate_%d" % ids[i]
        world_root.add_child(gate)
        var pos:Vector3=positions[i]
        _box(gate,Vector3(1.1,6.0,1.1),pos+Vector3(-2.2,3.0,0),Color("#4b515e"))
        _box(gate,Vector3(1.1,6.0,1.1),pos+Vector3(2.2,3.0,0),Color("#4b515e"))
        _box(gate,Vector3(5.5,1.0,1.1),pos+Vector3(0,5.5,0),Color("#656d7d"))
        var ring:=_ring_node(Color("#66c7e8"),1.65)
        ring.position=pos+Vector3(0,2.2,0)
        gate.add_child(ring)
        var text:=Label3D.new()
        text.text=str(WARP_POINTS[ids[i]]["name"]).to_upper()
        text.position=pos+Vector3(0,6.4,0)
        text.font_size=18
        text.outline_size=5
        text.no_depth_test=true
        gate.add_child(text)

func _add_arena()->void:
    var arena:=MeshInstance3D.new()
    var mesh:=CylinderMesh.new()
    mesh.top_radius=7.0
    mesh.bottom_radius=7.0
    mesh.height=0.18
    mesh.radial_segments=64
    arena.mesh=mesh
    arena.position=Vector3(-42,0.10,-24)
    arena.material_override=_mat(Color("#6b6256"),0.96,0.0)
    world_root.add_child(arena)
    var ring:=_ring_node(Color("#f1bd58"),6.4)
    ring.position=arena.position+Vector3(0,0.13,0)
    world_root.add_child(ring)
    var label:=Label3D.new()
    label.text="WAR ARENA"
    label.position=arena.position+Vector3(0,2.1,0)
    label.font_size=24
    label.outline_size=7
    label.no_depth_test=true
    world_root.add_child(label)

func _service_building(pos:Vector3,service_name:String,wall:Color,roof:Color)->void:
    var b:=Node3D.new()
    b.name=service_name.replace(" ","")
    actor_services.add_child(b)
    _box(b,Vector3(5.2,3.5,4.2),pos+Vector3(0,1.75,0),wall)
    var roof_node:=MeshInstance3D.new()
    var roof_mesh:=CylinderMesh.new()
    roof_mesh.top_radius=0.0
    roof_mesh.bottom_radius=3.5
    roof_mesh.height=2.1
    roof_mesh.radial_segments=6
    roof_node.mesh=roof_mesh
    roof_node.position=pos+Vector3(0,4.45,0)
    roof_node.material_override=_mat(roof,0.75,0.0)
    b.add_child(roof_node)
    _box(b,Vector3(0.85,1.8,0.08),pos+Vector3(0,0.9,2.15),Color("#30241f"))
    var sign:=Label3D.new()
    sign.text=service_name.to_upper()
    sign.position=pos+Vector3(0,5.8,0)
    sign.font_size=20
    sign.outline_size=6
    sign.no_depth_test=true
    b.add_child(sign)

func _ring_node(color:Color,radius:float)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=TorusMesh.new()
    m.inner_radius=radius
    m.outer_radius=radius+0.12
    m.ring_segments=64
    m.rings=12
    n.mesh=m
    n.rotation_degrees.x=90.0
    n.material_override=_glow_material(color,color.darkened(0.72))
    return n

func _glow_material(color:Color,emission:Color)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=0.28
    m.metallic=0.25
    m.emission_enabled=true
    m.emission=emission
    m.emission_energy_multiplier=1.4
    return m

func _mat(color:Color,roughness:float,metallic:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=roughness
    m.metallic=metallic
    return m

func _box(parent:Node3D,size:Vector3,pos:Vector3,color:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var m:=BoxMesh.new()
    m.size=size
    n.mesh=m
    n.position=pos
    n.material_override=_mat(color,0.76,0.0)
    parent.add_child(n)
    return n

func _panel_style(color:Color)->StyleBoxFlat:
    var style:=StyleBoxFlat.new()
    style.bg_color=color
    style.border_color=Color("#b99b5b")
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    return style

func _activity(message:String)->void:
    if activity_label==null:
        return
    activity_label.append_text(message+"\n")
    if activity_label.get_line_count()>8:
        activity_label.scroll_to_line(activity_label.get_line_count()-1)

func _save()->void:
    if hero.is_empty():
        return
    SAVE.save_game(hero)
