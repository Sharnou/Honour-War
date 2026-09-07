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
	hero_motion=lerp(hero_motion,clamp(speed/180.0,0.0,1.0),0.25)
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
			if hp<old: monster_hit[id]=0.30
			monster_seen[id]=hp
	for id in monster_hit.keys(): monster_hit[id]=max(0.0,float(monster_hit[id])-delta)
	queue_redraw()

func trigger_hero_attack()->void:
	hero_action=0.28

func trigger_pet_attack()->void:
	pet_action=0.30

func _draw()->void:
	if game==null or not game.get("hero") is Dictionary: return
	var hero:Dictionary=game.get("hero")
	var hero_pos:Vector2=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	_draw_battle_ground(hero_pos)
	_draw_monsters(game.get("monsters"))
	_draw_pet(hero,hero_pos+Vector2(34,24))
	_draw_hero(hero,hero_pos)

func _draw_battle_ground(center:Vector2)->void:
	# Rich layered arena treatment without external assets.
	var bounds:=Rect2(350,105,775,330)
	draw_rect(bounds,Color("#0b1825"),true)
	for i in range(8):
		var y:float=105.0+float(i)*41.0
		draw_line(Vector2(350,y),Vector2(1125,y),Color(0.18,0.28,0.36,0.20),1.0)
	for i in range(14):
		var x:float=350.0+float(i)*60.0
		draw_line(Vector2(x,105),Vector2(x+45,435),Color(0.12,0.22,0.30,0.16),1.0)
	for i in range(12):
		var a:float=TAU*float(i)/12.0+clock*0.03
		var p:=center+Vector2(cos(a)*300.0,sin(a)*110.0)
		if p.x>355 and p.x<1120 and p.y>110 and p.y<430:
			draw_circle(p,1.2+sin(clock*2.0+i)*0.5,Color(0.55,0.78,0.95,0.28))
	draw_arc(center+Vector2(0,8),105,0,TAU,64,Color(0.35,0.65,0.85,0.10),2.0)

func _draw_hero(hero:Dictionary,pos:Vector2)->void:
	var class_id:String=str(hero.get("class","Warrior"))
	var c:Color=Color(str(CLASS_COLORS.get(class_id,"#ffffff")))
	var breathe:float=sin(clock*3.0)*1.4
	var stride:float=sin(clock*10.0)*3.5*hero_motion
	var attack_t:float=clamp(hero_action/0.28,0.0,1.0)
	var recoil:float=-7.0*sin(attack_t*PI) if hero_action>0.0 else 0.0
	var p:Vector2=pos+Vector2(recoil,breathe)
	var scale_factor:float=1.08
	_draw_shadow(p+Vector2(0,25),22.0,7.0)
	# Ground aura and animated spirit motes.
	var aura:float=0.45+0.18*sin(clock*4.0)
	draw_arc(p+Vector2(0,4),31+aura*4.0,clock,clock+4.7,40,Color(c.r,c.g,c.b,0.18),2.0)
	for i in range(6):
		var a:float=clock*0.8+float(i)*TAU/6.0
		var orbit:=p+Vector2(cos(a)*26.0,sin(a)*13.0-4.0)
		draw_circle(orbit,1.4+0.5*sin(clock*3.0+i),Color(c.r,c.g,c.b,0.65))
	# Legs with boots and animated stride.
	var left_foot:=p+Vector2(-7+stride,26)
	var right_foot:=p+Vector2(7-stride,26)
	draw_line(p+Vector2(-6,11),left_foot,Color("#30394a"),6.0)
	draw_line(p+Vector2(6,11),right_foot,Color("#30394a"),6.0)
	draw_line(left_foot,left_foot+Vector2(5,1),Color("#151b26"),5.0)
	draw_line(right_foot,right_foot+Vector2(5,1),Color("#151b26"),5.0)
	# Cape/back silhouette and shoulders.
	draw_colored_polygon(PackedVector2Array([p+Vector2(-11,-8),p+Vector2(-18,18),p+Vector2(-4,14),p+Vector2(8,18),p+Vector2(13,-8)]),Color(c.r,c.g,c.b,0.34))
	# Torso armor, belt and shoulder plates.
	draw_colored_polygon(PackedVector2Array([p+Vector2(-11,-9),p+Vector2(-14,10),p+Vector2(-7,16),p+Vector2(8,16),p+Vector2(14,10),p+Vector2(10,-9)]),Color(c.r,c.g,c.b,0.96))
	draw_line(p+Vector2(-10,3),p+Vector2(10,3),Color(0.08,0.10,0.14,0.75),2.0)
	draw_circle(p+Vector2(0,4),3.0,Color(0.95,0.78,0.35,0.85))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-13,-7),p+Vector2(-19,-4),p+Vector2(-14,3),p+Vector2(-9,-3)]),Color(c.r,c.g,c.b,0.92))
	draw_colored_polygon(PackedVector2Array([p+Vector2(13,-7),p+Vector2(19,-4),p+Vector2(14,3),p+Vector2(9,-3)]),Color(c.r,c.g,c.b,0.92))
	# Head, hair, face and highlights.
	draw_circle(p+Vector2(0,-20),11.2,Color("#f1c7a5"))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-10,-20),p+Vector2(-8,-30),p+Vector2(0,-34),p+Vector2(9,-30),p+Vector2(11,-19),p+Vector2(5,-23),p+Vector2(-4,-24)]),Color("#3b2c35"))
	draw_circle(p+Vector2(-4,-20),1.4,Color("#201b2b"))
	draw_circle(p+Vector2(4,-20),1.4,Color("#201b2b"))
	draw_line(p+Vector2(-3,-14),p+Vector2(3,-14),Color(0.55,0.25,0.25,0.65),1.0)
	# Class-specific weapon/action pose.
	var hand:Vector2=p+Vector2(12,-1)
	var weapon_end:Vector2=hand+Vector2(25,-9)
	if hero_action>0.0: weapon_end=hand+Vector2(34,-25)
	match class_id:
		"Warrior": _draw_sword(hand,weapon_end,c)
		"Mage": _draw_staff(hand,weapon_end,c)
		"Archer": _draw_bow(hand,weapon_end,c)
		"Thief": _draw_dagger(hand,weapon_end,c)
		"Acolyte": _draw_mace(hand,weapon_end,c)
		"Merchant": _draw_hammer(hand,weapon_end,c)
	# Weapon swing trail.
	if hero_action>0.0:
		draw_arc(p+Vector2(8,-3),39,-1.8,0.5,28,Color(c.r,c.g,c.b,0.65),3.0)

func _draw_sword(hand:Vector2,end:Vector2,c:Color)->void:
	draw_line(hand,end,Color("#cfd9e6"),6.0)
	draw_line(hand,end,Color("#ffffff"),2.0)
	draw_line(hand+Vector2(-4,-4),hand+Vector2(4,4),Color("#c99a54"),4.0)
	draw_colored_polygon(PackedVector2Array([end,end+Vector2(-5,-3),end+Vector2(-2,4)]),Color("#f3f7ff"))

func _draw_staff(hand:Vector2,end:Vector2,c:Color)->void:
	draw_line(hand,end,Color("#9b7049"),4.0)
	draw_circle(end,6.0,Color("#9fe8ff"))
	draw_circle(end,12.0,Color(c.r,c.g,c.b,0.15))
	draw_arc(end,14,clock,clock+4.0,24,Color(0.55,0.85,1.0,0.6),2.0)

func _draw_bow(hand:Vector2,end:Vector2,c:Color)->void:
	var center:=hand+Vector2(4,-3)
	draw_arc(center,18,-1.15,1.15,22,c,3.0)
	draw_line(center+Vector2(0,-17),center+Vector2(0,17),Color("#e8d4a0"),2.0)
	draw_line(center+Vector2(0,0),end,Color("#f1d79b"),2.0)
	draw_colored_polygon(PackedVector2Array([end,end+Vector2(-8,-3),end+Vector2(-8,3)]),Color("#dce8f5"))

func _draw_dagger(hand:Vector2,end:Vector2,c:Color)->void:
	draw_line(hand,end,Color("#dce8f5"),4.0)
	draw_line(hand+Vector2(-2,-4),hand+Vector2(5,3),Color("#c99a54"),3.0)
	draw_colored_polygon(PackedVector2Array([end,end+Vector2(-9,-4),end+Vector2(-8,3)]),Color("#ffffff"))

func _draw_mace(hand:Vector2,end:Vector2,c:Color)->void:
	draw_line(hand,end,Color("#d0a66c"),5.0)
	draw_circle(end,7.0,Color("#f2e4c1"))
	for i in range(6):
		var a:float=TAU*float(i)/6.0
		draw_line(end,end+Vector2(cos(a),sin(a))*9.0,Color("#fff3bd"),2.0)

func _draw_hammer(hand:Vector2,end:Vector2,c:Color)->void:
	draw_line(hand,end,Color("#8b6244"),6.0)
	draw_rect(Rect2(end-Vector2(9,5),Vector2(18,10)),Color("#aeb9c7"),true)
	draw_line(end-Vector2(7,3),end+Vector2(7,-3),Color("#e2edf5"),2.0)

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
	var bob:float=sin(clock*5.0)*3.0
	var lunge:float=12.0 if pet_action>0.0 else 0.0
	var p:Vector2=pos+Vector2(lunge,bob)
	_draw_shadow(p+Vector2(0,15),18.0,5.0)
	# Bond line and pet aura.
	draw_line(p+Vector2(-18,-5),p+Vector2(-35,-4),Color(c.r,c.g,c.b,0.22),2.0)
	draw_arc(p,25,clock*1.5,clock*1.5+4.8,28,Color(c.r,c.g,c.b,0.35),2.0)
	if species=="Royal Falcon":
		draw_ellipse(p,Vector2(10,15),c)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-5,-2),p+Vector2(-31,-13),p+Vector2(-17,7),p+Vector2(-4,7)]),c)
		draw_colored_polygon(PackedVector2Array([p+Vector2(5,-2),p+Vector2(31,-13),p+Vector2(17,7),p+Vector2(4,7)]),c)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-3,-14),p+Vector2(0,-22),p+Vector2(3,-14)]),Color("#e6d1a2"))
		draw_circle(p+Vector2(4,-5),2.2,Color("#f6e16d"))
		draw_colored_polygon(PackedVector2Array([p+Vector2(9,-2),p+Vector2(17,1),p+Vector2(9,4)]),Color("#e5b75f"))
	elif species=="Astral Sprite":
		draw_circle(p,11,c)
		draw_circle(p,7,Color(0.65,0.9,1.0,0.35))
		for i in range(4):
			var a:float=clock*1.8+i*TAU/4.0
			draw_circle(p+Vector2(cos(a)*18.0,sin(a)*18.0),2.0,Color(c.r,c.g,c.b,0.7))
		draw_circle(p+Vector2(-4,-2),2.0,Color.WHITE); draw_circle(p+Vector2(4,-2),2.0,Color.WHITE)
		draw_circle(p+Vector2(-4,-2),0.8,Color("#2b4260")); draw_circle(p+Vector2(4,-2),0.8,Color("#2b4260"))
	elif species=="Blessed Poring":
		draw_circle(p,14,c)
		draw_arc(p,16,PI,TAU,24,Color("#fff0a3"),3.0)
		draw_circle(p+Vector2(-5,-2),2.0,Color("#5c3e67")); draw_circle(p+Vector2(5,-2),2.0,Color("#5c3e67"))
		draw_arc(p+Vector2(0,1),6,0.2,2.9,14,Color("#7b4765"),1.5)
	else:
		draw_ellipse(p,Vector2(20,10),c)
		draw_circle(p+Vector2(15,-7),9,c)
		draw_colored_polygon(PackedVector2Array([p+Vector2(8,-12),p+Vector2(10,-25),p+Vector2(16,-14)]),c)
		draw_colored_polygon(PackedVector2Array([p+Vector2(20,-12),p+Vector2(25,-24),p+Vector2(29,-10)]),c)
		draw_circle(p+Vector2(17,-9),2.0,Color("#f3d66b"))
		draw_line(p+Vector2(-15,5),p+Vector2(-26,0),c,3.0)
	if pet_action>0.0:
		draw_arc(p,30,clock*2.0,clock*2.0+5.0,30,Color(0.75,0.92,1.0,0.8),3.0)
		for i in range(5):
			var a:float=clock*3.0+float(i)
			draw_circle(p+Vector2(cos(a)*24.0,sin(a)*15.0),1.8,Color(0.75,0.92,1.0,0.8))

func _draw_monsters(monsters:Variant)->void:
	if not monsters is Array: return
	for monster in monsters:
		if not monster is Dictionary: continue
		var pos:Vector2=monster.get("pos",Vector2.ZERO)
		var name:String=str(monster.get("name","Monster"))
		var c:Color=Color(str(MONSTER_COLORS.get(name,"#d45c5c")))
		var id:String=str(monster.get("visual_id",""))
		var hit:float=float(monster_hit.get(id,0.0))
		var recoil:float=(-9.0 if int(monster.get("level",1))%2==0 else 9.0)*min(1.0,hit*5.0)
		var elite:bool=bool(monster.get("mvp",false))
		var s:float=1.42 if elite else 1.08
		var p:Vector2=pos+Vector2(recoil,sin(clock*3.0+int(monster.get("level",1)))*2.0)
		_draw_shadow(p+Vector2(0,22*s),22.0*s,7.0*s)
		if elite:
			var pulse:float=sin(clock*3.5)*3.0
			draw_circle(p,38*s+ pulse,Color(0.65,0.05,0.10,0.08))
			draw_arc(p,34*s+pulse,clock,clock+5.0,42,Color("#f5c85b",0.75),3.0)
			draw_arc(p,27*s-pulse,clock+2.0,clock+5.5,36,Color(0.95,0.35,0.2,0.55),2.0)
		if name=="Poring":
			draw_circle(p,16*s,c)
			draw_colored_polygon(PackedVector2Array([p+Vector2(-10,3)*s,p+Vector2(-5,16)*s,p+Vector2(0,7)*s]),Color(c.r,c.g,c.b,0.85))
			draw_colored_polygon(PackedVector2Array([p+Vector2(10,3)*s,p+Vector2(5,16)*s,p+Vector2(0,7)*s]),Color(c.r,c.g,c.b,0.85))
		elif name=="Wolf":
			_draw_wolf(p,c,s)
		elif name=="Dragon":
			_draw_dragon(p,c,s)
		elif name=="Skeleton" or name=="Zombie":
			_draw_undead(p,c,s)
		elif name=="Golem":
			_draw_golem(p,c,s)
		elif name=="Mantis":
			_draw_mantis(p,c,s)
		else:
			_draw_humanoid_monster(p,c,s)
		# Eyes and combat readability.
		if name!="Poring":
			draw_circle(p+Vector2(-5,-11)*s,2.0*s,Color("#ff5c63"))
			draw_circle(p+Vector2(5,-11)*s,2.0*s,Color("#ff5c63"))
		var ratio:float=clamp(float(monster.get("hp",0))/max(1.0,float(monster.get("max",1))),0.0,1.0)
		var w:float=44.0*s
		draw_rect(Rect2(p+Vector2(-w/2,25*s),Vector2(w,5)),Color(0.02,0.03,0.05,0.85),true)
		draw_rect(Rect2(p+Vector2(-w/2,25*s),Vector2(w*ratio,5)),Color("#f5c85b") if elite else Color("#e85d75"),true)
		if elite:
			draw_string(ThemeDB.fallback_font,p+Vector2(-28,-43*s),"MVP",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#f5c85b"))
		draw_string(ThemeDB.fallback_font,p+Vector2(-25,42*s),"Lv."+str(monster.get("level",1)),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)

func _draw_wolf(p:Vector2,c:Color,s:float)->void:
	draw_ellipse(p,Vector2(21,12)*s,c)
	draw_circle(p+Vector2(16,-7)*s,10*s,c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(9,-12)*s,p+Vector2(11,-27)*s,p+Vector2(18,-14)*s]),c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(21,-12)*s,p+Vector2(26,-26)*s,p+Vector2(31,-10)*s]),c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-18,-3)*s,p+Vector2(-32,-13)*s,p+Vector2(-25,3)*s]),Color(c.r,c.g,c.b,0.9))
	draw_line(p+Vector2(-8,8)*s,p+Vector2(-11,20)*s,Color("#59606e"),4*s)
	draw_line(p+Vector2(9,8)*s,p+Vector2(12,20)*s,Color("#59606e"),4*s)

func _draw_dragon(p:Vector2,c:Color,s:float)->void:
	draw_ellipse(p,Vector2(27,15)*s,c)
	draw_circle(p+Vector2(18,-9)*s,12*s,c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-8,-5)*s,p+Vector2(-43,-28)*s,p+Vector2(-29,8)*s,p+Vector2(-10,7)*s]),Color(c.r,c.g,c.b,0.92))
	draw_colored_polygon(PackedVector2Array([p+Vector2(8,-5)*s,p+Vector2(43,-28)*s,p+Vector2(29,8)*s,p+Vector2(10,7)*s]),Color(c.r,c.g,c.b,0.92))
	draw_colored_polygon(PackedVector2Array([p+Vector2(21,-18)*s,p+Vector2(27,-31)*s,p+Vector2(31,-18)*s]),Color("#e7b95d"))
	draw_arc(p+Vector2(30,-1)*s,10*s,-0.8,0.8,12,Color("#ffb45d"),2.0)

func _draw_undead(p:Vector2,c:Color,s:float)->void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(-15,15)*s,p+Vector2(-13,-11)*s,p+Vector2(-8,-22)*s,p+Vector2(8,-22)*s,p+Vector2(14,-11)*s,p+Vector2(16,15)*s]),Color(c.r,c.g,c.b,0.96))
	draw_circle(p+Vector2(0,-14)*s,11*s,c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-8,-22)*s,p+Vector2(-5,-31)*s,p+Vector2(-1,-23)*s]),c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(8,-22)*s,p+Vector2(5,-31)*s,p+Vector2(1,-23)*s]),c)
	draw_line(p+Vector2(-6,-12)*s,p+Vector2(6,-12)*s,Color(0.2,0.16,0.15,0.8),2*s)

func _draw_golem(p:Vector2,c:Color,s:float)->void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(-21,17)*s,p+Vector2(-24,-10)*s,p+Vector2(-14,-23)*s,p+Vector2(14,-23)*s,p+Vector2(24,-9)*s,p+Vector2(20,17)*s]),c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-26,-8)*s,p+Vector2(-38,3)*s,p+Vector2(-25,8)*s]),Color(c.r,c.g,c.b,0.95))
	draw_colored_polygon(PackedVector2Array([p+Vector2(26,-8)*s,p+Vector2(38,3)*s,p+Vector2(25,8)*s]),Color(c.r,c.g,c.b,0.95))
	draw_line(p+Vector2(-10,0)*s,p+Vector2(10,0)*s,Color(0.25,0.20,0.16,0.5),3*s)
	draw_circle(p+Vector2(0,6)*s,4*s,Color("#d5b35e"))

func _draw_mantis(p:Vector2,c:Color,s:float)->void:
	draw_ellipse(p,Vector2(12,22)*s,c)
	draw_circle(p+Vector2(0,-18)*s,8*s,c)
	draw_line(p+Vector2(-7,-7)*s,p+Vector2(-30,-28)*s,c,4*s)
	draw_line(p+Vector2(7,-7)*s,p+Vector2(30,-28)*s,c,4*s)
	draw_line(p+Vector2(-7,8)*s,p+Vector2(-25,22)*s,c,3*s)
	draw_line(p+Vector2(7,8)*s,p+Vector2(25,22)*s,c,3*s)

func _draw_humanoid_monster(p:Vector2,c:Color,s:float)->void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(-17,17)*s,p+Vector2(-18,-8)*s,p+Vector2(-10,-22)*s,p+Vector2(10,-22)*s,p+Vector2(18,-8)*s,p+Vector2(17,17)*s]),c)
	draw_circle(p+Vector2(0,-17)*s,11*s,c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-9,-23)*s,p+Vector2(-13,-35)*s,p+Vector2(-4,-27)*s]),c)
	draw_colored_polygon(PackedVector2Array([p+Vector2(9,-23)*s,p+Vector2(13,-35)*s,p+Vector2(4,-27)*s]),c)
	draw_line(p+Vector2(-17,-1)*s,p+Vector2(-29,12)*s,c,5*s)
	draw_line(p+Vector2(17,-1)*s,p+Vector2(29,12)*s,c,5*s)

func _draw_shadow(center:Vector2,width:float,height:float)->void:
	draw_ellipse(center,Vector2(width,height),Color(0.0,0.0,0.0,0.32))

func draw_ellipse(center:Vector2,radii:Vector2,color:Color)->void:
	var points:PackedVector2Array=PackedVector2Array()
	for i in range(40):
		var a:float=TAU*float(i)/40.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
