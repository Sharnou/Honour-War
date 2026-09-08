class_name CombatVFX
extends Node2D

var effects:Array[Dictionary]=[]
var game:Node
var elapsed:float=0.0

const CLASS_COLORS:Dictionary={
	"Warrior":Color("#e8a34b"),"Mage":Color("#b88cff"),"Archer":Color("#8fe08f"),
	"Thief":Color("#ff7eb6"),"Acolyte":Color("#fff0a3"),"Merchant":Color("#7ed7ff")
}

func setup(owner:Node)->void:
	game=owner
	z_index=20
	set_process(true)
	queue_redraw()

func _process(delta:float)->void:
	elapsed+=delta
	for i in range(effects.size()-1,-1,-1):
		effects[i]["age"]=float(effects[i].get("age",0.0))+delta
		if float(effects[i]["age"])>=float(effects[i].get("duration",0.4)):
			effects.remove_at(i)
	queue_redraw()

func emit_effect(kind:String,position:Vector2,duration:float=0.45,scale:float=1.0,text:String="")->void:
	effects.append({"kind":kind,"pos":position,"age":0.0,"duration":duration,"scale":scale,"text":text})
	queue_redraw()

func hero_attack(position:Vector2)->void:
	emit_effect("hero_attack",position,0.26,1.05)
func pet_attack(position:Vector2,role:String="")->void:
	emit_effect("pet_attack",position,0.34,1.0,role)
func skill_cast(position:Vector2,skill_name:String,ultimate:bool=false)->void:
	emit_effect("ultimate" if ultimate else "skill",position,0.95 if ultimate else 0.52,1.45 if ultimate else 1.05,skill_name)
func hit(position:Vector2,damage:int,critical:bool=false)->void:
	emit_effect("critical" if critical else "hit",position,0.55,1.0,str(damage))
func monster_death(position:Vector2)->void:
	emit_effect("death",position,0.95,1.25)
func heal(position:Vector2,amount:int)->void:
	emit_effect("heal",position,0.75,1.0,str(amount))

func _draw()->void:
	if game!=null and game.get("hero") is Dictionary:
		var hero:Dictionary=game.get("hero")
		var hero_pos:Vector2=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
		var class_id:String=str(hero.get("class","Warrior"))
		var class_color:Color=CLASS_COLORS.get(class_id,Color.WHITE)
		_draw_aura(hero_pos,class_color)
		if hero.get("pet",{}) is Dictionary: _draw_pet_link(hero_pos,class_color)
	for effect in effects: _draw_effect(effect)

func _draw_aura(pos:Vector2,color:Color)->void:
	var pulse:float=0.5+0.5*sin(elapsed*3.5)
	draw_arc(pos,25.0+3.0*pulse,0.0,TAU,48,Color(color,0.12+0.08*pulse),2.0)
	draw_arc(pos,32.0+3.0*pulse,elapsed,elapsed+1.8,32,Color(color,0.22),1.0)
	for i in range(8):
		var a:float=elapsed*0.7+float(i)*TAU/8.0
		var mote:Vector2=pos+Vector2(cos(a)*28.0,sin(a)*14.0-8.0)
		draw_circle(mote,1.5+0.8*sin(elapsed*4.0+float(i)),Color(color,0.55))

func _draw_pet_link(hero_pos:Vector2,color:Color)->void:
	var pet_pos:Vector2=hero_pos+Vector2(34.0,24.0)
	if game.has_method("get_pet_visual_position"): pet_pos=game.call("get_pet_visual_position")
	draw_dashed_line(hero_pos+Vector2(0,-4),pet_pos,Color(color,0.16),1.0,5.0)
	draw_circle(pet_pos,4.0+sin(elapsed*5.0),Color(color,0.18))

func _draw_effect(e:Dictionary)->void:
	var pos:Vector2=e["pos"]
	var age:float=float(e["age"])
	var duration:float=max(0.01,float(e["duration"]))
	var t:float=clamp(age/duration,0.0,1.0)
	var s:float=float(e.get("scale",1.0))
	var kind:String=str(e["kind"])
	var alpha:float=1.0-t
	var class_id:String="Warrior"
	if game!=null and game.get("hero") is Dictionary:
		class_id=str(game.get("hero").get("class","Warrior"))
	var class_color:Color=CLASS_COLORS.get(class_id,Color.WHITE)
	if kind=="hero_attack":
		_draw_slash(pos,t,alpha,s,Color("#ffd36b"))
	elif kind=="pet_attack":
		for j in range(8):
			var a:float=float(j)*TAU/8.0+t*3.0
			var inner:float=8.0+12.0*t
			var outer:float=inner+30.0*(1.0-t)*s
			draw_line(pos+Vector2(cos(a),sin(a))*inner,pos+Vector2(cos(a),sin(a))*outer,Color(0.65,0.9,1.0,alpha),3.0)
		_draw_ring(pos,20.0+30.0*t,alpha,Color("#8fe8ff"),2.0)
	elif kind=="skill":
		_draw_class_skill(pos,class_id,class_color,t,alpha,s,str(e.get("text","SKILL")))
	elif kind=="ultimate":
		_draw_magic_circle(pos,t,alpha,s,Color("#ffd35c"))
		_draw_ring(pos,35.0+125.0*t*s,alpha,Color("#fff0a3"),5.0)
		for j in range(12):
			var a:float=elapsed*1.2+float(j)*TAU/12.0
			var p:Vector2=pos+Vector2(cos(a),sin(a))*((35.0+105.0*t)*s)
			draw_circle(p,3.0*(1.0-t),Color(0.7,0.85,1.0,alpha))
		_draw_label(pos+Vector2(-72,-62-24*t),str(e.get("text","ULTIMATE")),alpha)
	elif kind=="hit" or kind=="critical":
		var rays:int=12 if kind=="critical" else 7
		for j in range(rays):
			var a:float=float(j)*TAU/float(rays)+t*2.0
			var inner:float=7.0+12.0*t
			var outer:float=inner+30.0*(1.0-t)*s
			draw_line(pos+Vector2(cos(a),sin(a))*inner,pos+Vector2(cos(a),sin(a))*outer,Color(1.0,0.72,0.28,alpha),4.0 if kind=="critical" else 2.0)
		_draw_ring(pos,12.0+22.0*t,alpha,Color("#ffb347"),2.0)
		_draw_label(pos+Vector2(-15,-34-18*t),str(e.get("text","0")),alpha)
	elif kind=="death":
		_draw_ring(pos,20.0+58.0*t,alpha,Color("#ffe08a"),3.0)
		for j in range(12):
			var a:float=float(j)*TAU/12.0+elapsed
			var p:Vector2=pos+Vector2(cos(a),sin(a))*(12.0+52.0*t)
			draw_circle(p,4.0*(1.0-t),Color(1.0,0.85,0.4,alpha))
	elif kind=="heal":
		_draw_ring(pos,20.0+38.0*t,alpha,Color("#8dffb1"),2.0)
		for j in range(5):
			var p:Vector2=pos+Vector2(-20.0+j*10.0,-18.0-48.0*t-float(j)*5.0)
			draw_circle(p,4.0*(1.0-t),Color(0.55,1.0,0.72,alpha))
		_draw_label(pos+Vector2(-18,-34-20*t),"+"+str(e.get("text","0")),alpha)

func _draw_slash(pos:Vector2,t:float,alpha:float,s:float,color:Color)->void:
	var start:float=-2.3+t*2.8
	var finish:float=start+1.8
	draw_arc(pos,25.0+34.0*t*s,start,finish,32,Color(color,alpha),6.0)
	draw_arc(pos,30.0+34.0*t*s,start,finish,32,Color(1.0,1.0,1.0,alpha*0.8),2.0)

func _draw_magic_circle(pos:Vector2,t:float,alpha:float,s:float,color:Color)->void:
	_draw_ring(pos,18.0+62.0*t*s,alpha,color,3.0)
	draw_arc(pos,30.0+42.0*t*s,-elapsed*1.5,TAU-elapsed*1.5,64,Color(color,alpha*0.8),2.0)
	for j in range(6):
		var a:float=elapsed+float(j)*TAU/6.0
		var p:Vector2=pos+Vector2(cos(a),sin(a))*((18.0+42.0*t)*s)
		draw_circle(p,2.5*(1.0-t),Color(color,alpha))

func _draw_class_skill(pos:Vector2,class_id:String,color:Color,t:float,alpha:float,s:float,label:String)->void:
	var radius:float=18.0+62.0*t*s
	match class_id:
		"Warrior":
			draw_arc(pos,radius,-1.5,0.25,36,Color(1.0,0.55,0.20,alpha),5.0)
			draw_arc(pos,radius*0.62,-0.7,0.9,28,Color(1.0,0.84,0.36,alpha*0.7),3.0)
		"Mage":
			draw_circle(pos,radius*0.7,Color(0.45,0.35,1.0,alpha*0.12))
			draw_arc(pos,radius,elapsed*2.0,elapsed*2.0+4.8,48,Color(0.72,0.70,1.0,alpha),3.0)
			for j in range(8):
				var a:float=elapsed*2.4+float(j)*TAU/8.0
				draw_circle(pos+Vector2(cos(a),sin(a))*radius,2.5,Color(0.75,0.9,1.0,alpha))
		"Archer":
			for j in range(3):
				var offset:float=(float(j)-1.0)*9.0
				var start:Vector2=pos+Vector2(-radius*0.55,offset)
				var finish:Vector2=pos+Vector2(radius*0.95,offset)
				draw_line(start,finish,Color(0.70,1.0,0.78,alpha*(1.0-float(j)*0.18)),3.0)
		"Thief":
			draw_arc(pos,radius,-2.2,0.2,32,Color(1.0,0.35,0.66,alpha),4.0)
			draw_arc(pos,radius*0.72,1.0,3.1,28,Color(0.45,0.12,0.30,alpha*0.8),3.0)
		"Acolyte":
			draw_circle(pos,radius*0.74,Color(1.0,0.92,0.40,alpha*0.12))
			draw_arc(pos,radius*0.86,0.0,TAU,40,Color(1.0,0.96,0.60,alpha),3.0)
			draw_line(pos+Vector2(-radius*0.45,0.0),pos+Vector2(radius*0.45,0.0),Color(1.0,1.0,0.85,alpha),2.0)
			draw_line(pos+Vector2(0,-radius*0.45),pos+Vector2(0,radius*0.45),Color(1.0,1.0,0.85,alpha),2.0)
		"Merchant":
			draw_arc(pos,radius,-0.9,1.1,28,Color(0.35,0.85,1.0,alpha),5.0)
			for j in range(5):
				var box_pos:Vector2=pos+Vector2(-radius*0.5+float(j)*radius*0.25,10.0*sin(t*4.0+float(j)))
				draw_rect(Rect2(box_pos-Vector2(3,3),Vector2(6,6)),Color(0.55,0.9,1.0,alpha*0.85),true)
		_:
			draw_arc(pos,radius,elapsed,elapsed+4.7,40,Color(color.r,color.g,color.b,alpha),3.0)
	if t<0.82:
		_draw_label(pos+Vector2(-48,-34*t),label,alpha)

func _draw_ring(pos:Vector2,radius:float,alpha:float,color:Color,width:float)->void:
	draw_arc(pos,radius,0.0,TAU,64,Color(color,alpha),width)

func _draw_label(pos:Vector2,text:String,alpha:float)->void:
	draw_string(ThemeDB.fallback_font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(1.0,1.0,1.0,alpha))
