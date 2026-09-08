class_name Combat3DBridge
extends Node

var numbers:DamageNumbers3D

func _ready()->void:
	numbers=DamageNumbers3D.new()
	numbers.name="DamageNumbers3D"
	var game:=get_parent().get_parent()
	game.add_child(numbers)

func show_number(map_position:Vector2,amount:int,critical:bool=false,source:String="enemy")->void:
	if numbers==null:
		return
	var legacy:=get_parent()
	if source=="enemy" and legacy!=null:
		var hero_value:Variant=legacy.get("hero")
		if hero_value is Dictionary:
			var hero:Dictionary=hero_value
			var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
			if hero_pos.distance_to(map_position)<28.0:
				source="hero"
	var game:=get_parent().get_parent()
	var world_position:=Vector3((map_position.x-365.0)*0.055,0.0,(map_position.y-120.0)*0.055)
	numbers.show_damage(game.to_global(world_position),amount,critical,source)
