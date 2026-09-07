class_name BattleVisuals
extends Node2D

const CLASS_COLORS={"Warrior":"#e8a34b","Mage":"#b88cff","Archer":"#8fe08f","Thief":"#ff7eb6","Acolyte":"#fff0a3","Merchant":"#7ed7ff"}
const MONSTER_COLORS={"Poring":"#f38ba8","Goblin":"#78c850","Wolf":"#8b95a5","Skeleton":"#ddd6c8","Zombie":"#6f8c6a","Orc":"#6e9d3d","Mantis":"#79bd58","Golem":"#a78f74","Evil Druid":"#8d6bc2","Dragon":"#d45c4a"}

var game:Node
var clock:float=0.0
var last_hero_pos:Vector2=Vector2.ZERO
var hero_motion:float=0.0
var hero_action:float=0.0
var pet_action:float=0.0
var monster_seen:Dictionary={}
var monster_hit:Dictionary={}

func _ready()->void:
	game=get_parent()
	z_index=8
	set_process(true)

func _process(delta:float)->void:
	clock+=delta
	if game==null or not game.get("hero") is Dictionary: return
	var hero:Dictionary=game.get("hero")
	var pos:Vector2=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	var speed:float=last_hero_pos.distance_to(pos)/max(delta,0.001)
	hero_motion=lerp(hero_motion,clamp(speed/180.0,0.0,1.0),0.30)
	if speed>8.0: hero_action=max(hero_action,0.10)
	last_hero_pos=pos
	hero_action=max(0.0,hero_action-delta)
	pet_action=max(0.0,pet_action-delta)
	var monsters:Variant=game.get("monsters")
	if monsters is Array:
		for monster in monsters:
			if not monster is Dictionary: continue
			if not monster.has("visual_id"): monster["visual_id"]=str(randi())+str(Time.get_ticks_msec())
			var id:String=str(monster["visual_id"])
			var hp:int=int(monster.get("hp",0))
			var old:int=int(monster_seen.get(id,hp))
			if hp<old: monster_hit[id]=0.24
			monster_seen[id]=hp
	for id in monster_hit.keys(): monster_hit[id]=max(0.0,float(monster_hit[id])-delta)
	queue_redraw()

func trigger_hero_attack()->void:
	hero_action=0.22

func trigger_pet_attack()->void:
	pet_action=0.24

func _draw()->void:
	if game==null or not game.get("hero") is Dictionary: return
	var hero:Dictionary=game.get("hero")
	var hero_pos:Vector2=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	_draw_monsters(game.get("monsters"))
	_draw_pet(hero,hero_pos+Vector2(34,24))
	_draw_hero(hero,hero_pos)

func _draw_hero(hero:Dictionary,pos:Vector2)->void:
	var class_id:String=str(hero.get("class","Warrior"))
	var c:Color=Color(str(CLASS_COLORS.get(class_id,"#ffffff")))
	var breathe:float=sin(clock*3.0)*1.5
	var stride:float=sin(clock*10.0)*3.0*hero_motion
	var recoil:float=-9.0 if hero_action>0.0 else 0.0
	var p:Vector2=pos+Vector2(recoil,breathe)
	draw_ellipse(p+Vector2(0,20),Vector2(20,6),Color(0,0,0,0.30))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-12,-8),p+Vector2(-18,18),p+Vector2(3,14),p+Vector2(11,-8)]),Color(c.r,c.g,c.b,0.45))
	draw_rect(Rect2(p+Vector2(-10,-10),Vector2(20,25)),Color(c.r,c.g,c.b,0.95),true)
	draw_circle(p+Vector2(0,-20),10.5,Color("#f1c7a5"))
	draw_arc(p+Vector2(0,-20),10.5,3.35,6.05,18,c,5.0)
	draw_circle(p+Vector2(-4,-21),1.2,Color("#201b2b")); draw_circle(p+Vector2(4,-21),1.2,Color("#201b2b"))
	draw_line(p+Vector2(-6,14),p+Vector2(-6+stride,25),Color("#242b3a"),5.0)
	draw_line(p+Vector2(6,14),p+Vector2(6-stride,25),Color("#242b3a"),5.0)
	var hand:Vector2=p+Vector2(10,-2)
	var end:Vector2=hand+Vector2(25,-10)
	if hero_action>0.0: end=hand+Vector2(34,-24)
	match class_id:
		"Mage":
			draw_line(hand,end,Color("#d7b27c"),3.0); draw_circle(end,5,Color("#9fe8ff")); draw_circle(end,10,Color(0.55,0.75,1.0,0.12))
		"Archer":
			draw_arc(hand+Vector2(4,-3),15,-1.1,1.1,16,c,2); draw_line(hand+Vector2(4,-3),end,Color("#e8d4a0"),2)
		"Thief": draw_line(hand,end,Color("#d8e5ef"),3)
		"Acolyte": draw_line(hand,end,Color("#e8d4a0"),4); draw_circle(end,4,Color("#fff1a8"))
		"Merchant": draw_line(hand,end,Color("#9b7954"),6)
		_: draw_line(hand,end,Color("#dce6ef"),5)
	var pulse:float=0.5+0.5*sin(clock*4.0)
	draw_arc(p,25+pulse*3,clock,clock+2.5,28,Color(c.r,c.g,c.b,0.20),1.5)
	for i in range(3):
		var sp:Vector2=p+Vector2(cos(clock*2+i*2.1)*23,sin(clock*2+i*2.1)*16)
		draw_circle(sp,1.5,Color(c.r,c.g,c.b,0.60))

func _draw_pet(hero:Dictionary,pos:Vector2)->void:
	var pet:Dictionary=hero.get("pet",{})
	if pet.is_empty(): return
	var species:String=str(pet.get("species","Pet"))
	var c:Color=Color("#d8c48b")
	match species:
		"Royal Falcon": c=Color("#cda85d")
		"Astral Sprite": c=Color("#78dfff")
		"Blessed Poring": c=Color("#ff9fc8")
		"Night Panther": c=Color("#7d78a8")
		"Dire Wolf": c=Color("#a5acbb")
	var p:Vector2=pos+Vector2(14 if pet_action>0 else 0,sin(clock*5)*3)
	draw_ellipse(p+Vector2(0,14),Vector2(17,5),Color(0,0,0,0.24))
	if species=="Royal Falcon":
		draw_ellipse(p,Vector2(9,15),c); draw_colored_polygon(PackedVector2Array([p+Vector2(-5,-2),p+Vector2(-29,-10),p+Vector2(-16,6)]),c); draw_colored_polygon(PackedVector2Array([p+Vector2(5,-2),p+Vector2(29,-10),p+Vector2(16,6)]),c)
	elif species=="Astral Sprite":
		draw_circle(p,10,c); draw_arc(p,18,clock,clock+4.5,24,Color(c.r,c.g,c.b,0.55),2); draw_circle(p+Vector2(-4,-2),2,Color.WHITE); draw_circle(p+Vector2(4,-2),2,Color.WHITE)
	elif species=="Blessed Poring":
		draw_circle(p,13,c); draw_circle(p+Vector2(-5,-2),2,Color("#5c3e67")); draw_circle(p+Vector2(5,-2),2,Color("#5c3e67")); draw_arc(p,17,clock,clock+4,20,Color("#fff0a3",0.7),2)
	else:
		draw_ellipse(p,Vector2(18,10),c); draw_circle(p+Vector2(14,-7),8,c); draw_colored_polygon(PackedVector2Array([p+Vector2(8,-12),p+Vector2(11,-23),p+Vector2(17,-13)]),c); draw_colored_polygon(PackedVector2Array([p+Vector2(20,-12),p+Vector2(24,-23),p+Vector2(28,-10)]),c)
	if pet_action>0: draw_arc(p,25,clock*2,clock*2+4.5,24,Color(0.7,0.9,1,0.8),3)

func _draw_monsters(monsters:Variant)->void:
	if not monsters is Array: return
	for monster in monsters:
		if not monster is Dictionary: continue
		var pos:Vector2=monster.get("pos",Vector2.ZERO)
		var name:String=str(monster.get("name","Monster"))
		var c:Color=Color(str(MONSTER_COLORS.get(name,"#d45c5c")))
		var id:String=str(monster.get("visual_id",""))
		var hit:float=float(monster_hit.get(id,0.0))
		var recoil:float=(-8.0 if int(monster.get("level",1))%2==0 else 8.0)*min(1.0,hit*5.0)
		var s:float=1.35 if bool(monster.get("mvp",false)) else 1.0
		var p:Vector2=pos+Vector2(recoil,sin(clock*3+int(monster.get("level",1)))*2)
		if monster.get("mvp",false):
			draw_arc(p,31+sin(clock*4)*3,clock,clock+5,36,Color("#f5c85b",0.65),2.5); draw_circle(p,35,Color(0.45,0.05,0.1,0.08))
		if name=="Poring": draw_circle(p,14*s,c)
		elif name=="Wolf": draw_ellipse(p,Vector2(18,10)*s,c); draw_circle(p+Vector2(15,-6)*s,8*s,c)
		elif name=="Dragon": draw_ellipse(p,Vector2(25,13)*s,c); draw_colored_polygon(PackedVector2Array([p+Vector2(-10,-4)*s,p+Vector2(-35,-22)*s,p+Vector2(-22,5)*s]),c); draw_colored_polygon(PackedVector2Array([p+Vector2(10,-4)*s,p+Vector2(35,-22)*s,p+Vector2(22,5)*s]),c)
		else: draw_ellipse(p,Vector2(19,12)*s,c); draw_circle(p+Vector2(0,-9)*s,10*s,c); draw_colored_polygon(PackedVector2Array([p+Vector2(-9,-14)*s,p+Vector2(-6,-26)*s,p+Vector2(-1,-15)*s]),c); draw_colored_polygon(PackedVector2Array([p+Vector2(9,-14)*s,p+Vector2(6,-26)*s,p+Vector2(1,-15)*s]),c)
		draw_circle(p+Vector2(-4,-10)*s,1.7*s,Color("#ff5c63")); draw_circle(p+Vector2(4,-10)*s,1.7*s,Color("#ff5c63"))
		var ratio:float=clamp(float(monster.get("hp",0))/max(1.0,float(monster.get("max",1))),0.0,1.0)
		var w:float=38.0*s
		draw_rect(Rect2(p+Vector2(-w/2,22),Vector2(w,4)),Color(0,0,0,0.7),true)
		draw_rect(Rect2(p+Vector2(-w/2,22),Vector2(w*ratio,4)),Color("#f5c85b") if monster.get("mvp",false) else Color("#e85d75"),true)
		if monster.get("mvp",false): draw_string(ThemeDB.fallback_font,p+Vector2(-25,-35),"MVP",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f5c85b"))
		draw_string(ThemeDB.fallback_font,p+Vector2(-30,38),"Lv."+str(monster.get("level",1)),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)

func draw_ellipse(center:Vector2,radii:Vector2,color:Color)->void:
	var points:PackedVector2Array=PackedVector2Array()
	for i in range(32):
		var a:float=TAU*float(i)/32.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
