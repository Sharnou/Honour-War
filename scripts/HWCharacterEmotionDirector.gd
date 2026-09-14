extends Node

## Honour War character emotion + visual identity memory.
## Health, combat and social-state cues drive facial/body-language changes.
## A small persistent memory keeps the hero's visual baseline and recent
## emotion history across sessions without changing gameplay statistics.

const MEMORY_PATH := "user://honour_war_character_visual_memory.json"
const SAMPLE_INTERVAL := 0.18

var scene:Node
var hero_node:Node3D
var previous_hp:float = -1.0
var previous_target:String = ""
var emotion:String = "idle"
var sample_timer:float = 0.0
var time_alive:float = 0.0
var identity:Dictionary = {}
var tracked_visual:Node3D

func _ready() -> void:
    _load_identity()
    call_deferred("_bind")

func _process(delta:float) -> void:
    sample_timer += delta
    time_alive += delta
    if sample_timer < SAMPLE_INTERVAL:
        _animate_visual(delta)
        return
    sample_timer = 0.0
    _bind()
    _sample_state()
    _animate_visual(delta)

func _bind() -> void:
    var current := get_tree().current_scene
    if current == null:
        return
    scene = current
    var candidate:Node3D = current.get("hero_visual") as Node3D
    if candidate == null or not is_instance_valid(candidate):
        candidate = current.get_node_or_null("Actors3D/Hero") as Node3D
    if candidate == null or not is_instance_valid(candidate):
        candidate = current.get_node_or_null("Hero") as Node3D
    if candidate != null and candidate != hero_node:
        hero_node = candidate
        tracked_visual = _get_visual_root(hero_node)

func _sample_state() -> void:
    if hero_node == null or not is_instance_valid(hero_node):
        return
    var legacy := scene.get_node_or_null("LegacyGame")
    if legacy == null:
        return
    var value:Variant = legacy.get("hero")
    if not value is Dictionary:
        return
    var hero:Dictionary = value
    var hp := float(hero.get("hp",0.0))
    var target_value:Variant = hero.get("target_id", hero.get("target", ""))
    var target := str(target_value)
    if previous_hp >= 0.0:
        if hp < previous_hp - 0.5:
            _set_emotion("pain")
        elif hp > previous_hp + 0.5:
            _set_emotion("relief")
    previous_hp = hp
    if hp <= 0.0:
        _set_emotion("defeated")
        return
    var hp_reference := max(max(previous_hp,hp),1.0)
    if hp < 0.28 * hp_reference:
        _set_emotion("strained")
    elif target != "" and target != "null":
        if target != previous_target:
            _set_emotion("alert")
        elif emotion == "idle" or emotion == "relief":
            _set_emotion("focused")
    else:
        if emotion in ["pain", "relief", "alert", "focused", "strained"]:
            _set_emotion("idle")
    previous_target = target

func _set_emotion(value:String) -> void:
    if value == emotion:
        return
    emotion = value
    identity["last_emotion"] = emotion
    var history:Array = identity.get("emotion_history", [])
    history.append({"emotion":emotion,"time":Time.get_unix_time_from_system()})
    while history.size() > 12:
        history.pop_front()
    identity["emotion_history"] = history
    _save_identity()

func _animate_visual(_delta:float) -> void:
    if tracked_visual == null or not is_instance_valid(tracked_visual):
        if hero_node != null and is_instance_valid(hero_node):
            tracked_visual = _get_visual_root(hero_node)
        return
    var breath := sin(time_alive * 2.4) * 0.012
    tracked_visual.scale = Vector3.ONE + Vector3(0.0,breath,0.0)
    var visual_rotation := Vector3.ZERO
    match emotion:
        "pain":
            visual_rotation.x = deg_to_rad(-4.0)
            visual_rotation.z = deg_to_rad(sin(time_alive*14.0)*1.3)
        "strained":
            visual_rotation.x = deg_to_rad(-3.0)
        "alert", "focused":
            visual_rotation.x = deg_to_rad(2.0)
            visual_rotation.y = deg_to_rad(sin(time_alive*5.0)*1.5)
        "relief":
            visual_rotation.x = deg_to_rad(1.0)
            visual_rotation.z = deg_to_rad(sin(time_alive*3.0)*0.8)
        "defeated":
            visual_rotation.x = deg_to_rad(-14.0)
        _:
            visual_rotation.z = deg_to_rad(sin(time_alive*1.7)*0.35)
    tracked_visual.rotation = visual_rotation
    _animate_face_parts(tracked_visual)

func _animate_face_parts(root:Node) -> void:
    var stack:Array[Node] = [root]
    while not stack.is_empty():
        var node:Node = stack.pop_back()
        var name_lower := node.name.to_lower()
        if node is Node3D:
            var n3d := node as Node3D
            if name_lower.contains("eye") or name_lower.contains("iris"):
                var openness := 1.0
                if emotion == "pain" or emotion == "strained":
                    openness = 0.68
                elif emotion == "surprised":
                    openness = 1.24
                elif emotion == "defeated":
                    openness = 0.52
                n3d.scale.y = openness
            elif name_lower.contains("mouth") or name_lower.contains("jaw"):
                if emotion == "pain":
                    n3d.scale.x = 1.18
                    n3d.rotation.z = deg_to_rad(3.0)
                elif emotion == "relief":
                    n3d.scale.x = 0.92
                    n3d.rotation.z = 0.0
                elif emotion == "defeated":
                    n3d.scale.x = 0.78
                    n3d.rotation.z = deg_to_rad(-2.0)
                else:
                    n3d.rotation.z = 0.0
            elif name_lower.contains("head") or name_lower.contains("face"):
                if emotion == "focused" or emotion == "alert":
                    n3d.rotation.x = deg_to_rad(-2.5)
                elif emotion == "relief":
                    n3d.rotation.x = deg_to_rad(1.5)
                elif emotion == "defeated":
                    n3d.rotation.x = deg_to_rad(-10.0)
                else:
                    n3d.rotation.x = 0.0
        for child in node.get_children():
            stack.append(child)

func _get_visual_root(actor:Node3D) -> Node3D:
    var generated := actor.get_node_or_null("HW_GeneratedGLB") as Node3D
    if generated != null:
        return generated
    var fallback := actor.get_node_or_null("HW_VisualFallback") as Node3D
    if fallback != null:
        return fallback
    return actor

func _load_identity() -> void:
    identity = {"appearance_seed":randi(),"last_emotion":"idle","emotion_history":[]}
    if not FileAccess.file_exists(MEMORY_PATH):
        _save_identity()
        return
    var file := FileAccess.open(MEMORY_PATH,FileAccess.READ)
    if file == null:
        return
    var text := file.get_as_text()
    file.close()
    var parsed:Variant = JSON.parse_string(text)
    if parsed is Dictionary:
        identity = parsed
    if not identity.has("appearance_seed"):
        identity["appearance_seed"] = randi()
    if not identity.has("emotion_history"):
        identity["emotion_history"] = []

func _save_identity() -> void:
    var file := FileAccess.open(MEMORY_PATH,FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(identity))
    file.close()
