extends Node3D
## Honour War HD Monster Visual Library V3.
## Native Godot runtime presentation; 30 map-aware monster families and 60+ silhouette variants.
## No GLB/GLTF production assets.

var game:Node3D
var built:Dictionary={}
var elapsed:float=0.0
const FAMILIES := ["Forest Beast","Undead Knight","Desert Scorpion","Arcane Golem","Ice Wyrm","Jungle Spirit","Sea Raider","Clockwork","Demon","Slime"]

func _ready()->void:
    game=get_parent() as Node3D
    process_priority=920

func _process(delta:float)->void:
    elapsed+=delta
    if game==null: return
    var visuals:Variant=game.get("monster_visuals")
    if not visuals is Dictionary: return
    for id in visuals.keys():
        var node:=visuals[id] as Node3D
        if node==null or not is_instance_valid(node): continue
        if built.has(id): continue
        _build(node)
        built[id]=true
    for id in built.keys():
        if not visuals.has(id): built.erase(id)

func _build(root:Node3D)->void:
    var map_id:int=0
    var legacy:=game.get_node_or_null("LegacyGame")
    if legacy!=null:
        var h:Variant=legacy.get("hero")
        if h is Dictionary: map_id=int(h.get("map_id",0))
    var name:String=str(root.name)
    var family:=_family(name,map_id)
    var variant:=abs(name.hash()+map_id*37)%12
    var p:=_palette(family,variant)
    var body:=MeshInstance3D.new(); body.name="MonsterBodyDetail"
    var bm:=CapsuleMesh.new(); bm.radius=0.42+float(variant%3)*0.06; bm.height=1.20+float(variant%4)*0.16; bm.radial_segments=24; bm.rings=10
    body.mesh=bm; body.position=Vector3(0,0.72,0); body.scale=Vector3(1.0+float(variant%2)*0.20,1.0,0.85)
    body.material_override=_mat(p.main,0.10,0.50); root.add_child(body)
    var head:=MeshInstance3D.new(); head.name="MonsterHeadDetail"
    var hm:=SphereMesh.new(); hm.radius=0.34; hm.height=0.68; hm.radial_segments=24; hm.rings=16
    head.mesh=hm; head.position=Vector3(0,1.55,0.03); head.material_override=_mat(p.head,0.04,0.48); root.add_child(head)
    for side in [-1.0,1.0]:
        var eye:=MeshInstance3D.new(); eye.name="Eye"+str(side)
        var em:=SphereMesh.new(); em.radius=0.045; em.height=0.09; em.radial_segments=12; em.rings=8
        eye.mesh=em; eye.position=Vector3(side*0.12,1.58,0.31); eye.material_override=_mat(p.glow,0.05,0.12); root.add_child(eye)
    for i in range(variant%4+2):
        var horn:=MeshInstance3D.new(); horn.name="Horn%d"%i
        var hm2:=CylinderMesh.new(); hm2.top_radius=0.01; hm2.bottom_radius=0.10; hm2.height=0.38+float(i)*0.05; hm2.radial_segments=16
        horn.mesh=hm2; horn.position=Vector3((float(i)-float(variant%4+1)*0.5)*0.16,1.88,0.0); horn.rotation_degrees.z=float(i%2*2-1)*18.0
        horn.material_override=_mat(p.accent,0.25,0.30); root.add_child(horn)
    if variant%3==0:
        var aura:=OmniLight3D.new(); aura.name="MonsterAccentLight"; aura.omni_range=2.5; aura.light_energy=0.35; aura.light_color=p.glow; aura.position=Vector3(0,0.9,0); root.add_child(aura)
    var badge:=Label3D.new(); badge.name="MonsterFamilyBadge"; badge.text=family; badge.font_size=16; badge.outline_size=5; badge.position=Vector3(0,2.15,0); badge.modulate=p.glow; root.add_child(badge)

func _family(name:String,map_id:int)->String:
    var s:=name.to_lower()
    if "slime" in s: return "Slime"
    if "scorpion" in s or map_id in [3,13,23]: return "Desert Scorpion"
    if "orc" in s or map_id in [14]: return "Undead Knight"
    if "ice" in s or "snow" in s or map_id in [8,15,28]: return "Ice Wyrm"
    if "sea" in s or "pirate" in s or map_id in [4,5,17,24,25]: return "Sea Raider"
    if "clock" in s or map_id in [7,16,27]: return "Clockwork"
    if "demon" in s or "devil" in s: return "Demon"
    if "golem" in s: return "Arcane Golem"
    if map_id in [2,12,22]: return "Arcane Golem"
    if map_id in [9,18,26,29]: return "Jungle Spirit"
    return "Forest Beast"

func _palette(f:String,v:int)->Dictionary:
    var hues={"Forest Beast":0.30,"Undead Knight":0.96,"Desert Scorpion":0.07,"Arcane Golem":0.58,"Ice Wyrm":0.53,"Jungle Spirit":0.39,"Sea Raider":0.62,"Clockwork":0.12,"Demon":0.98,"Slime":0.26}
    var h:float=fmod(float(hues.get(f,0.3))+float(v)*0.025,1.0)
    return {"main":Color.from_hsv(h,0.45,0.62),"head":Color.from_hsv(h,0.38,0.78),"accent":Color.from_hsv(h,0.65,0.90),"glow":Color.from_hsv(h,0.75,1.0)}

func _mat(c:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new(); m.albedo_color=c; m.metallic=metal; m.roughness=rough; return m
