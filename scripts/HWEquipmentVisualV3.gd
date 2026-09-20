extends Node3D
## Honour War HD Equipment + Character Cycle Visual Layer V3.
## Runtime-native presentation only: no GLB/GLTF assets.
## 60 authored visual cycles = 6 classes x 10 appearance/animation cycles.
## Equipment is represented from the live equipment dictionary, including refine/card state.

const CLASSES := ["Warrior","Mage","Archer","Thief","Acolyte","Merchant"]
const CYCLES_PER_CLASS := 10
const SLOT_ORDER := ["head_upper","head_middle","head_lower","armor","weapon","shield","garment","shoes","accessory_1","accessory_2"]
var game:Node3D
var hero:Node3D
var root:Node3D
var last_key:String=""
var elapsed:float=0.0
var cycle:int=0

func _ready()->void:
    game=get_parent() as Node3D
    process_priority=925

func _process(delta:float)->void:
    elapsed += delta
    if game==null: return
    var h:Variant=game.get("hero_visual")
    if h is Node3D and is_instance_valid(h):
        hero=h
        var legacy:=game.get_node_or_null("LegacyGame")
        var data:Dictionary={}
        if legacy!=null:
            var v:Variant=legacy.get("hero")
            if v is Dictionary: data=v
        var cls:String=str(hero.get_meta("class","Warrior"))
        cycle=_cycle_for(data,cls)
        var key=str(hero.get_instance_id())+":"+cls+":"+str(cycle)+":"+str(data.get("equipment",{}).hash())
        if key!=last_key:
            last_key=key
            _rebuild(data,cls,cycle)
        _animate()
    else:
        hero=null

func _cycle_for(data:Dictionary,cls:String)->int:
    var class_index:int=max(0,CLASSES.find(cls))
    var age:int=int(data.get("age",18))
    var level:int=int(data.get("level",1))
    return class_index*CYCLES_PER_CLASS + int((age+level)%CYCLES_PER_CLASS)

func _rebuild(data:Dictionary,cls:String,cycle_id:int)->void:
    if root!=null and is_instance_valid(root): root.queue_free()
    root=Node3D.new()
    root.name="HWEquipmentVisualV3_Cycle_%02d"%cycle_id
    root.set_meta("visual_cycle_id",cycle_id)
    root.set_meta("visual_cycle_total",60)
    hero.add_child(root)
    var p:=_palette(cls,cycle_id)
    _silhouette(root,p,cycle_id)
    var equipment:Variant=data.get("equipment",{})
    if equipment is Dictionary:
        for slot in SLOT_ORDER:
            var item:Variant=equipment.get(slot)
            if item is Dictionary: _slot(root,slot,item,p)
    _refine_aura(root,data)

func _palette(cls:String,id:int)->Dictionary:
    var hue:float=fposmod(float(id)*0.071,1.0)
    var accent:=Color.from_hsv(hue,0.55,0.95)
    match cls:
        "Mage": return {"accent":accent,"metal":Color("#a9b9d6"),"dark":Color("#29233f")}
        "Archer": return {"accent":accent,"metal":Color("#b9a36d"),"dark":Color("#253a30")}
        "Thief": return {"accent":accent,"metal":Color("#b29ac2"),"dark":Color("#261d31")}
        "Acolyte": return {"accent":accent,"metal":Color("#dfd4b4"),"dark":Color("#665f52")}
        "Merchant": return {"accent":accent,"metal":Color("#c7aa70"),"dark":Color("#493025")}
        _: return {"accent":accent,"metal":Color("#c9ced8"),"dark":Color("#302027")}

func _silhouette(r:Node3D,p:Dictionary,id:int)->void:
    var shoulder:=MeshInstance3D.new()
    shoulder.name="CycleShoulderTrim"
    var sm:=BoxMesh.new(); sm.size=Vector3(1.05,0.12,0.50); shoulder.mesh=sm
    shoulder.position=Vector3(0,1.68,-0.01)
    shoulder.material_override=_mat(p.metal,0.65,0.25); r.add_child(shoulder)
    for i in range(3):
        var plate:=MeshInstance3D.new(); plate.name="CyclePlate%d"%i
        var pm:=BoxMesh.new(); pm.size=Vector3(0.72-float(i)*0.08,0.045,0.05); plate.mesh=pm
        plate.position=Vector3(0,1.28+float(i)*0.16,0.36)
        plate.material_override=_mat(p.accent,0.35,0.30); r.add_child(plate)
    var crest:=MeshInstance3D.new(); crest.name="CycleCrest"
    var cm:=SphereMesh.new(); cm.radius=0.10; cm.height=0.20; cm.radial_segments=20; cm.rings=12; crest.mesh=cm
    crest.position=Vector3(0,2.72,0.12); crest.material_override=_mat(p.accent,0.10,0.18); r.add_child(crest)
    if id%2==0:
        var mantle:=MeshInstance3D.new(); mantle.name="CycleMantle"
        var mm:=CylinderMesh.new(); mm.top_radius=0.28; mm.bottom_radius=0.62; mm.height=0.85; mm.radial_segments=20; mantle.mesh=mm
        mantle.position=Vector3(0,1.42,-0.34); mantle.material_override=_mat(p.dark,0.05,0.72); r.add_child(mantle)

func _slot(r:Node3D,slot:String,item:Dictionary,p:Dictionary)->void:
    var refine:int=clamp(int(item.get("refine",0)),0,15)
    var name:String=str(item.get("name",slot)).strip_edges()
    var seed:int=abs(name.hash())
    var accent:Color=p.accent.lightened(min(0.20,float(refine)*0.012))
    if refine>=7: accent=accent.lightened(0.08)
    var anchor:=_anchor(slot)
    var node:=MeshInstance3D.new()
    node.name="Equip_"+slot
    var mesh:=BoxMesh.new()
    var dims:Vector3=Vector3(0.20,0.20,0.20)
    if slot=="weapon": dims=Vector3(0.12,1.10,0.16)
    elif slot=="armor": dims=Vector3(0.78,0.48,0.10)
    elif slot.begins_with("head"): dims=Vector3(0.55,0.16,0.40)
    elif slot=="shield": dims=Vector3(0.55,0.70,0.12)
    elif slot=="garment": dims=Vector3(0.72,0.88,0.08)
    elif slot=="shoes": dims=Vector3(0.60,0.18,0.34)
    elif slot.begins_with("accessory"): dims=Vector3(0.16,0.16,0.16)
    mesh.size=dims; node.mesh=mesh; node.position=anchor
    node.material_override=_mat(accent,0.60 if refine>=10 else 0.30,0.24 if refine>=7 else 0.40)
    r.add_child(node)
    if refine>0:
        var badge:=Label3D.new()
        badge.name="Refine_"+slot
        badge.text="+"+str(refine)
        badge.font_size=22
        badge.outline_size=6
        badge.position=anchor+Vector3(0,0.20,0)
        badge.modulate=Color("#fff0a0") if refine<10 else Color("#b8f5ff")
        r.add_child(badge)
    var cards:Variant=item.get("cards",[])
    if cards is Array:
        for i in range(min(4,cards.size())):
            var gem:=MeshInstance3D.new(); gem.name="Card_%s_%d"%[slot,i]
            var gm:=SphereMesh.new(); gm.radius=0.035+float(i)*0.005; gm.height=gm.radius*2.0; gm.radial_segments=12; gm.rings=8; gem.mesh=gm
            gem.position=anchor+Vector3(-0.12+float(i)*0.08,0.05,0.10)
            gem.material_override=_mat(Color.from_hsv(fposmod(float(seed+i)*0.013,1.0),0.70,0.95),0.15,0.18)
            r.add_child(gem)

func _refine_aura(r:Node3D,data:Dictionary)->void:
    var equipment:Variant=data.get("equipment",{})
    var best:int=0
    if equipment is Dictionary:
        for value in equipment.values():
            if value is Dictionary: best=max(best,int(value.get("refine",0)))
    if best<7: return
    var light:=OmniLight3D.new()
    light.name="RefinementAura"
    light.position=Vector3(0,1.35,0.15)
    light.omni_range=2.8+float(best)*0.08
    light.light_energy=0.45+float(best)*0.06
    light.light_color=Color("#8fe8ff") if best>=10 else Color("#fff0a0")
    r.add_child(light)

func _animate()->void:
    if root==null: return
    var phase:float=elapsed*2.0
    root.position.y=sin(phase)*0.012
    root.rotation.y=sin(phase*0.55)*0.018
    var crest:=root.get_node_or_null("CycleCrest") as Node3D
    if crest!=null: crest.scale=Vector3.ONE*(1.0+sin(elapsed*3.5)*0.08)

func _anchor(slot:String)->Vector3:
    match slot:
        "head_upper": return Vector3(0,2.75,-0.02)
        "head_middle": return Vector3(0,2.48,0.37)
        "head_lower": return Vector3(0,2.27,0.38)
        "armor": return Vector3(0,1.48,0.39)
        "weapon": return Vector3(0.72,1.70,0.12)
        "shield": return Vector3(-0.68,1.40,0.12)
        "garment": return Vector3(0,1.38,-0.45)
        "shoes": return Vector3(0,0.13,0.15)
        "accessory_1": return Vector3(0.62,1.05,0.28)
        "accessory_2": return Vector3(-0.62,1.05,0.28)
        _: return Vector3.ZERO

func _mat(c:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new(); m.albedo_color=c; m.metallic=metal; m.roughness=rough; return m
