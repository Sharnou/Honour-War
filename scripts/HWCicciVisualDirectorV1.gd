extends Node3D
## Honour War Cicci event-boss visual director.
## Eight deterministic combat-presentation cycles for the live level-400 weekly boss.
## Native Godot geometry/materials only; no GLB/GLTF assets and no gameplay-state ownership.

const CYCLE_NAMES:Array[String] = [
    "IDLE", "CHARGE", "DRAW", "AIM", "RELEASE", "IMPACT", "RESURRECTION", "ROAR"
]
var game:Node3D
var built:Dictionary = {}
var elapsed:float = 0.0

func _ready()->void:
    game=get_parent() as Node3D
    process_priority=918

func _process(delta:float)->void:
    elapsed+=delta
    if game==null: return
    var visuals:Variant=game.get("monster_visuals")
    if not visuals is Dictionary: return
    for id in visuals.keys():
        var node:Variant=visuals[id]
        if not node is Node3D or not is_instance_valid(node): continue
        var root:Node3D=node as Node3D
        if str(root.get_meta("boss_name",""))!="Cicci" and root.name!="Cicci":
            continue
        if not built.has(id):
            _build(root)
            built[id]=root
        _animate(root)

func _build(root:Node3D)->void:
    root.set_meta("boss_name","Cicci")
    root.set_meta("visual_cycle_total",CYCLE_NAMES.size())
    var detail:=Node3D.new()
    detail.name="CicciHDVisual"
    root.add_child(detail)

    var body_mat:=_mat(Color("#6f3d2e"),0.05,0.42)
    var armor_mat:=_mat(Color("#c49b52"),0.72,0.24)
    var dark_mat:=_mat(Color("#251b25"),0.20,0.34)
    var glow_mat:=_mat(Color("#ffd98a"),0.10,0.18,true)

    var lower:=MeshInstance3D.new()
    lower.name="CentaurLowerBody"
    var lower_mesh:=CapsuleMesh.new()
    lower_mesh.radius=0.62
    lower_mesh.height=1.75
    lower_mesh.radial_segments=32
    lower_mesh.rings=12
    lower.mesh=lower_mesh
    lower.position=Vector3(0,0.88,0)
    lower.scale=Vector3(1.25,1.0,1.55)
    lower.material_override=body_mat
    detail.add_child(lower)

    var torso:=MeshInstance3D.new()
    torso.name="CentaurTorso"
    var torso_mesh:=CapsuleMesh.new()
    torso_mesh.radius=0.42
    torso_mesh.height=1.25
    torso_mesh.radial_segments=28
    torso_mesh.rings=10
    torso.mesh=torso_mesh
    torso.position=Vector3(0,2.02,-0.08)
    torso.material_override=armor_mat
    detail.add_child(torso)

    var head:=MeshInstance3D.new()
    head.name="CicciHead"
    var head_mesh:=SphereMesh.new()
    head_mesh.radius=0.34
    head_mesh.height=0.68
    head_mesh.radial_segments=28
    head_mesh.rings=18
    head.mesh=head_mesh
    head.position=Vector3(0,2.95,-0.04)
    head.material_override=body_mat
    detail.add_child(head)

    for side:float in [-1.0,1.0]:
        var eye:=MeshInstance3D.new()
        eye.name="CicciEye"
        var eye_mesh:=SphereMesh.new()
        eye_mesh.radius=0.055
        eye_mesh.height=0.11
        eye_mesh.radial_segments=16
        eye_mesh.rings=8
        eye.mesh=eye_mesh
        eye.position=Vector3(side*0.12,2.98,0.30)
        eye.material_override=glow_mat
        detail.add_child(eye)

        var arm:=MeshInstance3D.new()
        arm.name="CicciArm"
        var arm_mesh:=CapsuleMesh.new()
        arm_mesh.radius=0.11
        arm_mesh.height=0.72
        arm_mesh.radial_segments=16
        arm_mesh.rings=8
        arm.mesh=arm_mesh
        arm.position=Vector3(side*0.48,2.08,0.02)
        arm.rotation_degrees=Vector3(0,0,side*38.0)
        arm.material_override=body_mat
        detail.add_child(arm)

        var leg:=MeshInstance3D.new()
        leg.name="CicciLeg"
        var leg_mesh:=CapsuleMesh.new()
        leg_mesh.radius=0.13
        leg_mesh.height=0.92
        leg_mesh.radial_segments=16
        leg_mesh.rings=8
        leg.mesh=leg_mesh
        leg.position=Vector3(side*0.43,0.72,0.48)
        leg.rotation_degrees=Vector3(8.0,0,side*8.0)
        leg.material_override=body_mat
        detail.add_child(leg)

        var rear_leg:=MeshInstance3D.new()
        rear_leg.name="CicciRearLeg"
        rear_leg.mesh=leg_mesh
        rear_leg.position=Vector3(side*0.43,0.68,-0.50)
        rear_leg.rotation_degrees=Vector3(-8.0,0,side*8.0)
        rear_leg.material_override=body_mat
        detail.add_child(rear_leg)

    var mane:=MeshInstance3D.new()
    mane.name="CicciMane"
    var mane_mesh:=CylinderMesh.new()
    mane_mesh.top_radius=0.20
    mane_mesh.bottom_radius=0.46
    mane_mesh.height=0.95
    mane_mesh.radial_segments=24
    mane.mesh=mane_mesh
    mane.position=Vector3(0,2.45,-0.30)
    mane.material_override=dark_mat
    detail.add_child(mane)

    var bow:=MeshInstance3D.new()
    bow.name="CicciBow"
    var bow_mesh:=TorusMesh.new()
    bow_mesh.inner_radius=0.34
    bow_mesh.outer_radius=0.38
    bow_mesh.rings=24
    bow_mesh.ring_segments=10
    bow.mesh=bow_mesh
    bow.position=Vector3(0.68,2.02,0.28)
    bow.rotation_degrees=Vector3(90,0,18)
    bow.material_override=armor_mat
    detail.add_child(bow)

    var string_mesh:=BoxMesh.new()
    string_mesh.size=Vector3(0.03,0.75,0.03)
    var string:=MeshInstance3D.new()
    string.name="CicciBowString"
    string.mesh=string_mesh
    string.position=Vector3(0.68,2.02,0.30)
    string.material_override=glow_mat
    detail.add_child(string)

    var crown:=MeshInstance3D.new()
    crown.name="CicciCrown"
    var crown_mesh:=PrismMesh.new()
    crown_mesh.size=Vector3(0.46,0.20,0.32)
    crown.mesh=crown_mesh
    crown.position=Vector3(0,3.30,0)
    crown.material_override=armor_mat
    detail.add_child(crown)

    var aura:=MeshInstance3D.new()
    aura.name="CicciAura"
    var aura_mesh:=TorusMesh.new()
    aura_mesh.inner_radius=1.0
    aura_mesh.outer_radius=1.08
    aura_mesh.rings=32
    aura_mesh.ring_segments=12
    aura.mesh=aura_mesh
    aura.position=Vector3(0,0.08,0)
    aura.material_override=glow_mat
    detail.add_child(aura)

func _animate(root:Node3D)->void:
    var detail:=root.get_node_or_null("CicciHDVisual") as Node3D
    if detail==null: return
    var cycle_index:int=int(floor(elapsed/1.2))%CYCLE_NAMES.size()
    root.set_meta("cicci_visual_cycle",cycle_index)
    root.set_meta("cicci_visual_cycle_name",CYCLE_NAMES[cycle_index])
    var phase:float=fposmod(elapsed,1.2)/1.2
    var wave:float=sin(phase*TAU)
    detail.position.y=0.035*wave
    detail.rotation.y=0.035*sin(elapsed*1.4)
    var aura:=detail.get_node_or_null("CicciAura") as Node3D
    if aura!=null:
        var pulse:float=1.0+0.08*sin(elapsed*5.0)
        aura.scale=Vector3.ONE*pulse
    var bow:=detail.get_node_or_null("CicciBow") as Node3D
    if bow!=null:
        match cycle_index:
            1,2: bow.rotation_degrees.z=18.0+28.0*phase
            3: bow.rotation_degrees.z=46.0-8.0*phase
            4,5: bow.rotation_degrees.z=38.0-35.0*phase
            6: bow.rotation_degrees.z=18.0
            7: bow.rotation_degrees.z=18.0+10.0*wave
            _: bow.rotation_degrees.z=18.0+4.0*wave
    var crown:=detail.get_node_or_null("CicciCrown") as Node3D
    if crown!=null:
        crown.scale=Vector3.ONE*(1.0+0.06*max(0.0,wave) if cycle_index==7 else 1.0)

func _mat(color:Color,metallic:float,roughness:float,emission:bool=false)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metallic
    material.roughness=roughness
    if emission:
        material.emission_enabled=true
        material.emission=color
        material.emission_energy_multiplier=2.2
    return material
