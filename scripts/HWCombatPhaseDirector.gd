extends Node

## Visual-only combat phase director.
## It consumes CombatRuntime signals but never applies damage, movement or state.
const CLASS_COLORS := {
    "Warrior":Color("#4f9cff"),
    "Mage":Color("#8f70ff"),
    "Archer":Color("#63c77b"),
    "Thief":Color("#c767ff"),
    "Acolyte":Color("#f4d46d"),
    "Merchant":Color("#d57a3f")
}

var scene_root:Node
var sequences:Array[Dictionary] = []
var runtime:Node

func _ready() -> void:
    process_priority = 840
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")

func _bind() -> void:
    scene_root = get_tree().current_scene
    if scene_root == null:
        return
    var legacy:Node = scene_root.get_node_or_null("LegacyGame")
    runtime = legacy.get_node_or_null("CombatRuntime") if legacy != null else null
    if runtime == null:
        runtime = scene_root.get_node_or_null("CombatRuntime")
    if runtime == null:
        return
    if runtime.has_signal("hero_attack_landed") and not runtime.hero_attack_landed.is_connected(_on_hero_attack):
        runtime.hero_attack_landed.connect(_on_hero_attack)
    if runtime.has_signal("pet_attack_landed") and not runtime.pet_attack_landed.is_connected(_on_pet_attack):
        runtime.pet_attack_landed.connect(_on_pet_attack)
    if runtime.has_signal("monster_attack_landed") and not runtime.monster_attack_landed.is_connected(_on_monster_attack):
        runtime.monster_attack_landed.connect(_on_monster_attack)

func _process(_delta:float) -> void:
    if scene_root == null or not is_instance_valid(scene_root):
        _bind()
        if scene_root == null:
            return
    var now:float = Time.get_ticks_msec()/1000.0
    for i in range(sequences.size()-1,-1,-1):
        var seq:Dictionary = sequences[i]
        var actor_value:Variant = seq.get("actor",null)
        if not is_instance_valid(actor_value) or not actor_value is Node3D:
            sequences.remove_at(i)
            continue
        var actor:Node3D = actor_value as Node3D
        if actor == null or not is_instance_valid(actor):
            sequences.remove_at(i)
            continue
        var elapsed:float = now - float(seq.get("started",now))
        var anticipation:float = float(seq.get("anticipation",0.10))
        var contact:float = float(seq.get("contact",0.07))
        var recovery:float = float(seq.get("recovery",0.22))
        var total:float = anticipation + contact + recovery
        var base_scale:Vector3 = seq.get("base_scale",actor.scale)
        if elapsed < anticipation:
            var t:float = clampf(elapsed/maxf(anticipation,0.001),0.0,1.0)
            actor.scale = base_scale.lerp(base_scale*Vector3(1.045,0.965,1.045),t)
        elif elapsed < anticipation + contact:
            if not bool(seq.get("contact_done",false)):
                seq["contact_done"] = true
                _emit_contact(seq)
                sequences[i] = seq
            actor.scale = base_scale*Vector3(1.045,0.965,1.045)
        elif elapsed < total:
            var t:float = clampf((elapsed-anticipation-contact)/maxf(recovery,0.001),0.0,1.0)
            actor.scale = (base_scale*Vector3(1.045,0.965,1.045)).lerp(base_scale,t)
        else:
            actor.scale = base_scale
            sequences.remove_at(i)

func _on_hero_attack(target:Dictionary,_damage:int,critical:bool) -> void:
    _start_sequence(_find_hero(),critical,"hero",target)

func _on_pet_attack(target:Dictionary,_damage:int,special:bool) -> void:
    _start_sequence(_find_pet(),special,"pet",target)

func _on_monster_attack(target_kind:String,_damage:int) -> void:
    if target_kind == "hero":
        _start_sequence(_find_hero(),false,"monster",{})

func _start_sequence(actor:Node3D,critical:bool,kind:String,target:Dictionary) -> void:
    if actor == null or not is_instance_valid(actor):
        return
    var seq:Dictionary = {
        "actor":actor,
        "started":Time.get_ticks_msec()/1000.0,
        "anticipation":0.12 if critical else 0.10,
        "contact":0.09 if critical else 0.07,
        "recovery":0.28 if critical else 0.22,
        "base_scale":actor.scale,
        "critical":critical,
        "kind":kind,
        "target":target,
        "contact_done":false
    }
    sequences.append(seq)

func _emit_contact(seq:Dictionary) -> void:
    var root:Node3D = scene_root.get_node_or_null("HWHDCombatVFX") as Node3D
    if root == null:
        root = Node3D.new()
        root.name = "HWHDCombatVFX"
        scene_root.add_child(root)
    var actor_value:Variant = seq.get("actor",null)
    var actor:Node3D = actor_value as Node3D if is_instance_valid(actor_value) and actor_value is Node3D else null
    var pos:Vector3 = actor.global_position if actor != null else Vector3.ZERO
    var target:Dictionary = seq.get("target",{})
    if target is Dictionary and target.has("id"):
        var visuals:Variant = scene_root.get("monster_visuals")
        if visuals is Dictionary and visuals.has(str(target["id"])):
            var target_value:Variant = visuals[str(target["id"])]
            if is_instance_valid(target_value) and target_value is Node3D:
                var target_node:Node3D = target_value as Node3D
                pos = target_node.global_position
    var color:Color = CLASS_COLORS.get(str(_hero_class()),Color("#ffffff"))
    if str(seq.get("kind","")) == "pet":
        color = Color("#8de5ff")
    elif str(seq.get("kind","")) == "monster":
        color = Color("#ff786e")
    _spawn_flash(root,pos,color,bool(seq.get("critical",false)))

func _spawn_flash(root:Node3D,pos:Vector3,color:Color,critical:bool) -> void:
    var fx:=Node3D.new()
    fx.name="CombatContactCritical" if critical else "CombatContact"
    fx.position=pos
    var ring:=MeshInstance3D.new()
    var mesh:=TorusMesh.new()
    mesh.inner_radius=0.18
    mesh.outer_radius=0.30 if critical else 0.25
    mesh.rings=32
    mesh.ring_segments=10
    ring.mesh=mesh
    ring.rotation_degrees.x=90.0
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.emission_enabled=true
    mat.emission=color
    mat.emission_energy_multiplier=2.2 if critical else 1.45
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color.a=0.92
    ring.material_override=mat
    fx.add_child(ring)
    root.add_child(fx)
    var tween:=create_tween()
    tween.tween_property(fx,"scale",Vector3.ONE*(1.9 if critical else 1.5),0.18)
    tween.tween_callback(fx.queue_free)

func _find_hero() -> Node3D:
    if scene_root == null:
        return null
    var value:Variant = scene_root.get("hero_visual")
    if value is Node3D:
        return value as Node3D
    var direct:=scene_root.get_node_or_null("Actors3D/Hero") as Node3D
    if direct != null:
        return direct
    return scene_root.get_node_or_null("Hero") as Node3D

func _find_pet() -> Node3D:
    if scene_root == null:
        return null
    var value:Variant = scene_root.get("pet_visual")
    if value is Node3D:
        return value as Node3D
    var direct:=scene_root.get_node_or_null("Actors3D/Pet") as Node3D
    if direct != null:
        return direct
    return scene_root.get_node_or_null("Pet") as Node3D

func _hero_class() -> String:
    var hero_value:Variant = scene_root.get("hero") if scene_root != null else null
    if not hero_value is Dictionary:
        var legacy:Node = scene_root.get_node_or_null("LegacyGame") if scene_root != null else null
        hero_value = legacy.get("hero") if legacy != null else null
    return str((hero_value as Dictionary).get("class","Warrior")) if hero_value is Dictionary else "Warrior"
