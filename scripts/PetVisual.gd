class_name PetVisual
extends Node2D

var pet:Dictionary={}
var pulse:=0.0
var attack_flash:=0.0
var role_color:=Color("#d8c48b")

func setup(data:Dictionary)->void:
	pet=data.duplicate(true)
	var definition:Dictionary=PetSystem.definition(str(pet.get("owner_class","Warrior")))
	role_color=Color(str(definition.get("color","#d8c48b")))
	queue_redraw()

func trigger_attack()->void:
	attack_flash=0.22

func _process(delta:float)->void:
	pulse+=delta
	attack_flash=max(0.0,attack_flash-delta)
	queue_redraw()

func _draw()->void:
	var level:=int(pet.get("level",1))
	var bob:=sin(pulse*4.0)*2.0
	var center:=Vector2(0,bob)
	var species:=str(pet.get("species","Pet"))
	var scale:=1.0+min(0.25,float(level)/400.0)
	if species=="Royal Falcon":
		draw_circle(center,12.0*scale,role_color)
		draw_colored_polygon(PackedVector2Array([center+Vector2(-8,0),center+Vector2(-25,-7),center+Vector2(-14,7)]),role_color)
		draw_colored_polygon(PackedVector2Array([center+Vector2(8,0),center+Vector2(25,-7),center+Vector2(14,7)]),role_color)
		draw_circle(center+Vector2(5,-3),2.0,Color.WHITE)
	elif species=="Astral Sprite":
		draw_circle(center,13.0*scale,role_color)
		draw_circle(center,20.0*scale,Color(role_color,0.22))
		draw_circle(center+Vector2(-5,-3),2.0,Color.WHITE)
		draw_circle(center+Vector2(5,-3),2.0,Color.WHITE)
	elif species=="Blessed Poring":
		draw_circle(center,15.0*scale,role_color)
		draw_line(center+Vector2(-7,-2),center+Vector2(-3,3),Color("#563d68"),2.0)
		draw_line(center+Vector2(7,-2),center+Vector2(3,3),Color("#563d68"),2.0)
	elif species=="Night Panther" or species=="Dire Wolf":
		draw_circle(center,14.0*scale,role_color)
		draw_colored_polygon(PackedVector2Array([center+Vector2(-10,-8),center+Vector2(-5,-19),center+Vector2(0,-9)]),role_color)
		draw_colored_polygon(PackedVector2Array([center+Vector2(10,-8),center+Vector2(5,-19),center+Vector2(0,-9)]),role_color)
		draw_circle(center+Vector2(-5,-3),2.0,Color.WHITE)
		draw_circle(center+Vector2(5,-3),2.0,Color.WHITE)
	else:
		draw_circle(center,14.0*scale,role_color)
		draw_circle(center+Vector2(-5,-3),2.0,Color.WHITE)
		draw_circle(center+Vector2(5,-3),2.0,Color.WHITE)
	if attack_flash>0.0:
		draw_arc(center,24.0,0.0,TAU,24,Color.WHITE,3.0)
	var hp_ratio:=clamp(float(pet.get("hp",60))/max(1.0,float(pet.get("max_hp",60))),0.0,1.0)
	draw_rect(Rect2(-22,22,44,4),Color("#202020"))
	draw_rect(Rect2(-22,22,44*hp_ratio,4),Color("#68d391"))
	draw_string(ThemeDB.fallback_font,Vector2(-32,38),str(pet.get("name","Pet")),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(-20,-25),"Lv."+str(level),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)
