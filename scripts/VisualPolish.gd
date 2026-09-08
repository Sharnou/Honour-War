class_name VisualPolish
extends Node2D

var game:Node
var time:float=0.0
var previous_hero_hp:int=-1
var hit_flash:float=0.0
var danger_pulse:float=0.0
var last_position:Vector2=Vector2.ZERO
var movement_energy:float=0.0

func _ready()->void:
	game=get_parent()
	z_index=30
	set_process(true)
	set_process_input(true)

func _process(delta:float)->void:
	time+=delta
	if game==null:
		return
	var hero:Variant=game.get("hero")
	if hero is Dictionary:
		var hp:int=int(hero.get("hp",0))
		if previous_hero_hp>=0 and hp<previous_hero_hp:
			hit_flash=1.0
		previous_hero_hp=hp
		var position_now:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
		var distance:float=last_position.distance_to(position_now)
		movement_energy=lerp(movement_energy,clamp(distance/8.0,0.0,1.0),0.2)
		last_position=position_now
		if hp>0 and hp<float(hero.get("max_hp",1))*0.25:
			danger_pulse=min(1.0,danger_pulse+delta*1.5)
		else:
			danger_pulse=max(0.0,danger_pulse-delta*2.0)
	hit_flash=max(0.0,hit_flash-delta*4.0)
	queue_redraw()

func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F10:
			visible=not visible

func _draw()->void:
	if game==null:
		return
	var viewport_size:=get_viewport_rect().size
	# Subtle cinematic letterbox bars; F10 toggles this polish layer.
	draw_rect(Rect2(0,0,viewport_size.x,22),Color(0.015,0.025,0.045,0.72),true)
	draw_rect(Rect2(0,viewport_size.y-22,viewport_size.x,22),Color(0.015,0.025,0.045,0.72),true)
	# Soft edge vignette made from translucent bands, compatible with OpenGL 3.3.
	for i in range(8):
		var alpha:float=0.035*(8-i)
		draw_rect(Rect2(float(i)*12.0,22.0,12.0,viewport_size.y-44.0),Color(0.01,0.025,0.05,alpha),true)
		draw_rect(Rect2(viewport_size.x-float(i+1)*12.0,22.0,12.0,viewport_size.y-44.0),Color(0.01,0.025,0.05,alpha),true)
	# Movement speed lines make movement feel deliberate rather than sliding.
	if movement_energy>0.12 and game.get("hero") is Dictionary:
		var hero:Dictionary=game.get("hero")
		var p:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
		for i in range(4):
			var y:float=p.y+8.0+float(i)*4.0
			draw_line(p+Vector2(-18.0-float(i)*5.0,y-p.y),p+Vector2(-5.0,y-p.y),Color(0.55,0.8,1.0,0.12*movement_energy),1.0)
	# Damage reaction flash.
	if hit_flash>0.0:
		draw_rect(Rect2(0,0,viewport_size.x,viewport_size.y),Color(1.0,0.16,0.10,0.12*hit_flash),true)
	# Low-health red edge pulse.
	if danger_pulse>0.0:
		var pulse:float=0.05+0.04*sin(time*8.0)
		draw_rect(Rect2(0,22,viewport_size.x,5),Color(0.95,0.08,0.08,pulse*danger_pulse),true)
		draw_rect(Rect2(0,viewport_size.y-27,viewport_size.x,5),Color(0.95,0.08,0.08,pulse*danger_pulse),true)
