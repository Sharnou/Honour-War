class_name CombatEventBus
extends Node

signal hero_attack_landed(target:Dictionary,damage:int,critical:bool)
signal pet_attack_landed(target:Dictionary,damage:int,special:bool)
signal monster_attack_landed(target_kind:String,damage:int)
signal target_changed(target:Dictionary)
signal finisher_landed(target:Dictionary,damage:int)

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
