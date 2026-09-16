extends Node3D

## Rental-only SS (SUPER SHAMBION) autonomous combat director.
## Follows the owner, heals itself/owner, and uses Asura Strike on enemies.

const FOLLOW_DISTANCE:float = 1.7
const COMBAT_RANGE:float = 7.5
const HEAL_THRESHOLD:float = 0.72
const COMBAT_INTERVAL:float = 1.15
const HEAL_INTERVAL:float = 2.25
const MAX_LEVEL:int = 250
const ASURA_SKILL:String = "Asura Strike"

var ss_visual:Node3D
var elapsed:float = 0.0
var combat_clock:float = 0.0
var heal_clock:float = 0.0
var last_action:String = "Follow"
var target:Node3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_sync")

func _process(delta:float) -> void:
    elapsed += delta
    combat_clock += delta
    heal_clock += delta
    _sync()

func _sync() -> void:
    var runtime:Node = get_node_or_null("/root/HWRentalService")
    var scene:Node = get_tree().current_scene
    if runtime == null or scene == null:
        return
    var rented:bool = bool(runtime.call("is_rented"))
    if rented and ss_visual == null:
        _spawn_ss(scene)
    elif not rented and ss_visual != null:
        ss_visual.queue_free()
        ss_visual = null
    if not rented or ss_visual == null:
        return
    var legacy:Node = scene.get_node_or_null("LegacyGame")
    if legacy == null:
        return
    var hero_value:Variant = legacy.get("hero")
    if not hero_value is Dictionary:
        return
    var hero:Dictionary = hero_value
    var data:Dictionary = runtime.call("get_ss")
    var behavior:Dictionary = data.get("behavior",{}).duplicate(true)
    var hero_pos:Vector2 = Vector2(float(hero.get("pos_x",595.0)),float(hero.get("pos_y",340.0)))
    var target_pos:Vector3 = _map_to_world(hero_pos) + Vector3(FOLLOW_DISTANCE,0.0,0.8)
    if bool(behavior.get("follow",true)):
        ss_visual.position = ss_visual.position.lerp(target_pos,1.0-exp(-8.0*0.016))
        last_action = "Follow"
    ss_visual.set_meta("behavior",behavior)
    ss_visual.set_meta("skill",ASURA_SKILL)
    ss_visual.set_meta("class","SS (SUPER SHAMBION)")
    ss_visual.set_meta("level",int(data.get("level",0)))
    ss_visual.set_meta("age",int(data.get("age",18)))
    ss_visual.set_meta("ai_action",last_action)
    if bool(behavior.get("heal",true)) and heal_clock >= HEAL_INTERVAL:
        heal_clock = 0.0
        _try_heal(legacy,hero,data)
    if bool(behavior.get("fight",true)) and combat_clock >= COMBAT_INTERVAL:
        combat_clock = 0.0
        _try_fight(scene,data)

func _try_heal(legacy:Node, hero:Dictionary, data:Dictionary) -> void:
    var max_hp:float = maxf(1.0,float(hero.get("max_hp",100.0)))
    var hp:float = float(hero.get("hp",max_hp))
    var ss_max_hp:float = maxf(1.0,float(data.get("max_hp",100.0)))
    var ss_hp:float = float(data.get("hp",ss_max_hp))
    if hp / max_hp < HEAL_THRESHOLD:
        hero["hp"] = mini(int(max_hp),int(hp + max_hp*0.16))
        legacy.set("hero",hero)
        last_action = "Heal Hero"
    elif ss_hp / ss_max_hp < HEAL_THRESHOLD:
        data["hp"] = mini(int(ss_max_hp),int(ss_hp + ss_max_hp*0.20))
        _store_ss(data)
        last_action = "Heal Self"

func _try_fight(scene:Node, data:Dictionary) -> void:
    target = _find_nearest_enemy(scene)
    if target == null:
        return
    if ss_visual.global_position.distance_to(target.global_position) > COMBAT_RANGE:
        return
    var level:int = clampi(int(data.get("level",0)),0,MAX_LEVEL)
    var strength:int = int(data.get("status_points",{}).get("STR",0))
    var damage:int = maxi(25,80 + level*6 + strength*4)
    var target_hp:float = float(target.get_meta("hp",target.get_meta("max_hp",1000)))
    target_hp = maxf(0.0,target_hp-float(damage))
    target.set_meta("hp",target_hp)
    target.set_meta("last_hit_skill",ASURA_SKILL)
    target.set_meta("last_hit_by","SS (SUPER SHAMBION)")
    if target_hp <= 0.0:
        target.set_meta("defeated_by","SS (SUPER SHAMBION)")
        _grant_ss_progress(data,target)
    last_action = ASURA_SKILL

func _grant_ss_progress(data:Dictionary, enemy:Node3D) -> void:
    var level:int = clampi(int(data.get("level",0)),0,MAX_LEVEL)
    var xp:int = int(data.get("xp",0)) + maxi(1,int(enemy.get_meta("xp_reward",100)))
    var needed:int = 100 + level*50
    while level < MAX_LEVEL and xp >= needed:
        xp -= needed
        level += 1
        needed = 100 + level*50
    data["level"] = level
    data["xp"] = xp
    _store_ss(data)

func _store_ss(data:Dictionary) -> void:
    var runtime:Node = get_node_or_null("/root/HWRentalService")
    if runtime != null and bool(runtime.call("is_rented")):
        runtime.set("ss",data.duplicate(true))

func _find_nearest_enemy(scene:Node) -> Node3D:
    var nearest:Node3D = null
    var nearest_distance:float = INF
    for node in get_tree().get_nodes_in_group("monsters"):
        if not node is Node3D or not is_instance_valid(node):
            continue
        var candidate:Node3D = node
        var hp:float = float(candidate.get_meta("hp",candidate.get_meta("max_hp",1)))
        if hp <= 0.0:
            continue
        var distance:float = ss_visual.global_position.distance_to(candidate.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = candidate
    if nearest != null:
        return nearest
    for node in scene.get_children():
        if not node is Node3D or not node.name.to_lower().contains("monster"):
            continue
        var candidate:Node3D = node
        var distance:float = ss_visual.global_position.distance_to(candidate.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = candidate
    return nearest

func _spawn_ss(scene:Node) -> void:
    ss_visual = Node3D.new()
    ss_visual.name = "SSSuperShambion"
    ss_visual.add_to_group("ss_companion")
    ss_visual.set_meta("class","SS (SUPER SHAMBION)")
    ss_visual.set_meta("level",0)
    scene.add_child(ss_visual)
    var body:MeshInstance3D = MeshInstance3D.new()
    var capsule:CapsuleMesh = CapsuleMesh.new()
    capsule.radius = 0.62
    capsule.height = 2.15
    body.mesh = capsule
    body.position.y = 1.08
    var material:StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color("#7b1e35")
    material.metallic = 0.25
    material.roughness = 0.45
    body.material_override = material
    ss_visual.add_child(body)
    var head:MeshInstance3D = MeshInstance3D.new()
    var sphere:SphereMesh = SphereMesh.new()
    sphere.radius = 0.48
    sphere.height = 0.96
    head.mesh = sphere
    head.position.y = 2.45
    head.material_override = material
    ss_visual.add_child(head)
    var label:Label3D = Label3D.new()
    label.text = "SS\nSUPER SHAMBION\nAsura Strike"
    label.position = Vector3(0.0,3.25,0.0)
    label.pixel_size = 0.0032
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.modulate = Color("#ffd66b")
    ss_visual.add_child(label)

func _map_to_world(pos:Vector2) -> Vector3:
    return Vector3(pos.x*0.055,0.0,pos.y*0.055)
