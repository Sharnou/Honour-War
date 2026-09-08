class_name CombatEventBus
extends Node

signal hero_attack_landed(target:Dictionary,damage:int,critical:bool)
signal pet_attack_landed(target:Dictionary,damage:int,special:bool)
signal monster_attack_landed(target_kind:String,damage:int)
signal target_changed(target:Dictionary)
signal finisher_landed(target:Dictionary,damage:int)

var combat:Node
var _connected:=false

func _ready()->void:
    call_deferred("_bind_combat_runtime")

func _bind_combat_runtime()->void:
    if not is_inside_tree():
        return
    var root:=get_parent()
    if root==null:
        return
    var legacy:=root.get_node_or_null("LegacyGame")
    combat=legacy.get_node_or_null("CombatRuntime") if legacy else null
    if combat==null or _connected:
        return
    if combat.has_signal("hero_attack_landed"):
        combat.hero_attack_landed.connect(_on_hero_attack_landed)
    if combat.has_signal("pet_attack_landed"):
        combat.pet_attack_landed.connect(_on_pet_attack_landed)
    if combat.has_signal("monster_attack_landed"):
        combat.monster_attack_landed.connect(_on_monster_attack_landed)
    if combat.has_signal("target_changed"):
        combat.target_changed.connect(_on_target_changed)
    _connected=true
    var current:Variant=combat.get("target")
    if current is Dictionary:
        target_changed.emit(current)

func _on_hero_attack_landed(target:Dictionary,damage:int,critical:bool)->void:
    hero_attack_landed.emit(target,damage,critical)

func _on_pet_attack_landed(target:Dictionary,damage:int,special:bool)->void:
    pet_attack_landed.emit(target,damage,special)

func _on_monster_attack_landed(target_kind:String,damage:int)->void:
    monster_attack_landed.emit(target_kind,damage)

func _on_target_changed(target:Dictionary)->void:
    target_changed.emit(target)

func emit_hero_attack(target:Dictionary,damage:int,critical:bool)->void:
    hero_attack_landed.emit(target,damage,critical)

func emit_pet_attack(target:Dictionary,damage:int,special:bool)->void:
    pet_attack_landed.emit(target,damage,special)

func emit_monster_attack(target_kind:String,damage:int)->void:
    monster_attack_landed.emit(target_kind,damage)

func emit_target_changed(target:Dictionary)->void:
    target_changed.emit(target)

func emit_finisher(target:Dictionary,damage:int)->void:
    finisher_landed.emit(target,damage)
