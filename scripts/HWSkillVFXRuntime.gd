extends Node3D

## Runtime skill-presentation layer for production combat.
## Uses lightweight procedural VFX when an authored skill effect is unavailable.

const ASURA_COLOR:Color = Color("#ffd45a")
const ASURA_DURATION:float = 0.42
var active_effects:Array[Node3D] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func play_skill(skill_name:String,origin:Vector3,target:Vector3) -> void:
    match skill_name:
        "Asura Strike":
            _play_asura(origin,target)
        _:
            _play_generic(origin,target)

func _play_asura(origin:Vector3,target:Vector3) -> void:
    var root:Node3D = Node3D.new()
    root.name = "AsuraStrikeVFX"
    add_child(root)
    root.global_position = origin
    var beam:MeshInstance3D = MeshInstance3D.new()
    var mesh:CylinderMesh = CylinderMesh.new()
    mesh.top_radius = 0.08
    mesh.bottom_radius = 0.34
    mesh.height = maxf(0.2,origin.distance_to(target))
    beam.mesh = mesh
    var material:StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = ASURA_COLOR
    material.emission_enabled = true
    material.emission = ASURA_COLOR
    material.emission_energy_multiplier = 4.0
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.86
    beam.material_override = material
    beam.look_at(target,Vector3.UP)
    beam.rotate_object_local(Vector3.RIGHT,PI * 0.5)
    root.add_child(beam)
    active_effects.append(root)
    _fade_and_free(root,ASURA_DURATION)

func _play_generic(origin:Vector3,target:Vector3) -> void:
    var root:Node3D = Node3D.new()
    root.name = "SkillVFX"
    add_child(root)
    root.global_position = target
    var ring:MeshInstance3D = MeshInstance3D.new()
    var mesh:TorusMesh = TorusMesh.new()
    mesh.inner_radius = 0.22
    mesh.outer_radius = 0.34
    ring.mesh = mesh
    var material:StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = ASURA_COLOR
    material.emission_enabled = true
    material.emission = ASURA_COLOR
    material.emission_energy_multiplier = 2.0
    ring.material_override = material
    root.add_child(ring)
    active_effects.append(root)
    _fade_and_free(root,0.30)

func _fade_and_free(node:Node3D,duration:float) -> void:
    var tween:Tween = create_tween()
    tween.tween_property(node,"scale",Vector3(1.35,1.35,1.35),duration)
    tween.tween_callback(node.queue_free)

func clear_effects() -> void:
    for effect in active_effects:
        if is_instance_valid(effect):
            effect.queue_free()
    active_effects.clear()
