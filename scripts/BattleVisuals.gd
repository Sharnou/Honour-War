class_name BattleVisuals
extends Node2D

# Procedural 2D character/monster presentation layer. It is intentionally asset-free
# so the prototype remains portable, while providing sprite-like animation states.
const CLASS_COLORS := {
	"Warrior":Color("#e8a34b"), "Mage":Color("#b88cff"), "Archer":Color("#8fe08f"),
	"Thief":Color("#ff7eb6"), "Acolyte":Color("#fff0a3"), "Merchant":Color("#7ed7ff")
}
const MONSTER_COLORS := {
	"Poring":Color("#f38ba8"), "Goblin":Color("#78c850"), "Wolf":Color("#8b95a5"),
	"Skeleton":Color("#ddd6c8"), "Zombie":Color("#6f8c6a"), "Orc":Color("#6e9d3d"),
	"Mantis":Color("#79bd58"), "Golem":Color("#a78f74"), "Evil Druid":Color("#8d6bc2"), "Dragon":Color("#d45c4a"
	)
}

var game:Node
var clock:=0.0
var last_hero_pos:=Vector2.ZERO
var hero_motion:=0.0
var hero_action:=0.0
var pet_action:=0.0
var monster_state:Dictionary={}
var monster_seen:Dictionary={}

func _ready()->void:
	game=get_parent()
	z_index=8
	set_process(true)
	queue_redraw()

func _process(delta:float)->void:
	clock+=delta
	if game==null or not game.get("hero") is Dictionary: return
	var hero:Dictionary=game.get("hero")
	var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	hero_motion=lerp(hero_motion,clamp(last_hero_pos.distance_to(hero_pos)/max(delta,0.001),0.0,180.0)/180.0,0.35)
	if last_hero_pos.distance_to(hero_pos)>2.0: hero_action=max(hero_action,0.10)
	last_hero_pos=hero_pos
	hero_action=max(0.0,hero_action-delta)
	pet_action=max(0.0,pet_action-delta)
	track_monsters(game.get("monsters"))
	queue_redraw()

func track_monsters(monsters)->void:
	if not monsters is Array: return
	for monster in monsters:
		if not monster is Dictionary: continue
		if not monster.has("visual_id"): monster["visual_id"]=str(randi())+"_"+str(clock)
		var id:=str(monster["visual_id"])
		var hp:=int(monster.get("hp",0))
		var previous:=int(monster_seen.get(id,hp))
		if hp<previous: monster_state[id]={"hit":0.22,"attack":0.16}
		monster_seen[id]=hp
		var state:Dictionary=monster_state.get(id,{"hit":0.0,"attack":0.0})
		state["hit"]=max(0.0,float(state.get("hit",0.0))-0.016)
		state["attack"]=max(0.0,float(state.get("attack",0.0))-0.016)
		monster_state[id]=state

func trigger_hero_attack()->void:
	hero_action=0.22

func trigger_pet_attack()->void:
	pet_action=0.24

func _draw()->void:
	if game==null or not game.get("hero") is Dictionary: return
	var hero:Dictionary=game.get("hero")
	var hero_pos:=Vector2(float(hero.get("pos_x",0.0)),float(hero.get("pos_y",0.0)))
	_draw_monsters(game.get("monsters"))
	_draw_pet(hero,hero_pos+Vector2(34,24))
	_draw_hero(hero,hero_pos)

func _draw_hero(hero:Dictionary,pos:Vector2)->void:
	var class_id:=str(hero.get("class","Warrior"))
	var c:Color=CLASS_COLORS.get(class_id,Color.WHITE)
	var walk:=sin(clock*10.0)*3.0*hero_motion
	var breathe:=sin(clock*3.0)*1.4
	var recoil:=-10.0 if hero_action>0.0 else 0.0
	var body:=pos+Vector2(recoil,breathe)
	# Shadow and grounded feet.
	draw_ellipse(body+Vector2(0,20),Vector2(19,6),Color(0,0,0,0.30))
	# Cape/back silhouette.
	draw_colored_polygon(PackedVector2Array([body+Vector2(-12,-8),body+Vector2(-17,18),body+Vector2(2,13),body+Vector2(10,-8)]),Color(c,0.48))
	# Torso, head and hair/helmet.
	draw_rect(Rect2(body+Vector2(-10,-10),Vector2(20,25)),Color(c,0.95),true)
	draw_circle(body+Vector2(0,-20),10.5,Color("#f1c7a5"))
	draw_arc(body+Vector2(0,-20),10.5,3.35,6.05,18,Color(c,0.95),5.0)
	# Eyes and face highlight.
	draw_circle(body+Vector2(-4,-21),1.2,Color("#201b2b")); draw_circle(body+Vector2(4,-21),1.2,Color("#201b2b"))
	# Legs animate with a grounded stride.
	var leg_a:=body+Vector2(-6,14)
	var leg_b:=body+Vector2(6,14)
	draw_line(leg_a,leg_a+Vector2(walk,11),Color("#242b3a"),5.0)
	draw_line(leg_b,leg_b+Vector2(-walk,11),Color("#242b3a"),5.0)
	# Weapon pose changes by class.
	var hand:=body+Vector2(10,-2)
	var weapon_end:=hand+Vector2(23,-10)
	if hero_action>0.0: weapon_end=hand+Vector2(32,-25)
	match class_id:
		"Mage":
			draw_line(hand,weapon_end,Color("#d7b27c"),3.0); draw_circle(weapon_end,5.0,Color("#9fe8ff")); draw_circle(weapon_end,10.0,Color(0.55,0.75,1.0,0.12))
		"Archer":
			draw_arc(hand+Vector2(4,-3),15.0,-1.1,1.1,16,c,2.0); draw_line(hand+Vector2(4,-3),weapon_end,Color("#e8d4a0"),2.0)
		"Thief": draw_line(hand,weapon_end,Color("#d8e5ef"),3.0)
		"Acolyte": draw_line(hand,weapon_end,Color("#e8d4a0"),4.0); draw_circle(weapon_end,4.0,Color("#fff1a8"))
		"Merchant": draw_line(hand,weapon_end,Color("#9b7954"),6.0)
		_: draw_line(hand,weapon_end,Color("#dce6ef"),5.0)
	# Living aura/spirit particles.
	var aura:=0.5+0.5*sin(clock*4.0)
	draw_arc(body,25.0+aura*3.0,clock,clock+2.5,28,Color(c,0.18),1.5)
	for i in range(3):
		var p:=body+Vector2(cos(clock*2.0+i*2.1),sin(clock*2.0+i*2.1))*Vector2(23,16)
		draw_circle(p,1.5,Color(c,0.55))

func _draw_pet(hero:Dictionary,pos:Vector2)->void:
	var pet:Dictionary=hero.get("pet",{})
	if pet.is_empty(): return
	var species:=str(pet.get("species","Pet"))
	var c:=Color("#d8c48b")
	match species:
		"Royal Falcon": c=Color("#cda85d")
		"Astral Sprite": c=Color("#78dfff")
		"Blessed Poring": c=Color("#ff9fc8")
		"Night Panther": c=Color("#7d78a8")
		"Dire Wolf": c=Color("#a5acbb")
	var bob:=sin(clock*5.0)*3.0
	var lunge:=14.0 if pet_action>0.0 else 0.0
	var p:=pos+Vector2(lunge,bob)
	draw_ellipse(p+Vector2(0,14),Vector2(17,5),Color(0,0,0,0.24))
	if species=="Royal Falcon":
		draw_ellipse(p,Vector2(9,15),c); draw_colored_polygon(PackedVector2Array([p+Vector2(-5,-2),p+Vector2(-29,-10),p+Vector2(-16,6)]),c); draw_colored_polygon(PackedVector2Array([p+Vector2(5,-2),p+Vector2(29,-10),p+Vector2(16,6)]),c)
	elif species=="Astral Sprite":
		draw_circle(p,10,c); draw_arc(p,18.0,clock,clock+4.5,24,Color(c,0.55),2.0); draw_circle(p+Vector2(-4,-2),2,Color.WHITE); draw_circle(p+Vector2(4,-2),2,Color.WHITE)
	elif species=="Blessed Poring":
		draw_circle(p,13,c); draw_circle(p+Vector2(-5,-2),2,Color("#5c3e67")); draw_circle(p+Vector2(5,-2),2,Color("#5c3e67")); draw_arc(p,17,clock,clock+4.0,20,Color("#fff0a3",0.7),2.0)
	else:
		draw_ellipse(p,Vector2(18,10),c); draw_circle(p+Vector2(14,-7),8,c); draw_colored_polygon(PackedVector2Array([p+Vector2(8,-12),p+Vector2(11,-23),p+Vector2(17,-13)]),c); draw_colored_polygon(PackedVector2Array([p+Vector2(20,-12),p+Vector2(24,-23),p+Vector2(28,-10)]),c); draw_circle(p+Vector2(17,-9),1.5,Color.WHITE)
	if pet_action>0.0:
		draw_arc(p,25.0,clock*2.0,clock*2.0+4.5,24,Color(0.7,0.9,1.0,0.8),3.0)

func _draw_monsters(monsters)->void:
	if not monsters is Array: return
	for monster in monsters:
		if not monster is Dictionary: continue
		var pos:Vector2=monster.get("pos",Vector2.ZERO)
		var id:=str(monster.get("visual_id",""))
		var state:Dictionary=monster_state.get(id,{})
		var hit_t:=float(state.get("hit",0.0))
		var recoil:=(-7.0 if fmod(float(monster.get("level",1)),2.0)==0.0 else 7.0)*min(1.0,hit_t*5.0)
		var c:Color=MONSTER_COLORS.get(str(monster.get("name","")),Color("#d45c5c"))
		var scale:=1.35 if bool(monster.get("mvp",false)) else 1.0
		var breathe:=sin(clock*3.0+float(monster.get("level",1)))*2.0
		var p:=pos+Vector2(recoil,breathe)
		if bool(monster.get("mvp",false)):
			draw_arc(p,30.0+sin(clock*4.0)*3.0,clock,clock+5.0,36,Color("#f5c85b",0.65),2.5)
			draw_circle(p,35.0,Color(0.45,0.05,0.1,0.08))
		# Species silhouettes.
		var name:=str(monster.get("name","Monster"))
		if name=="Poring":
			draw_circle(p,14.0*scale,c)
		elif name=="Wolf":
			draw_ellipse(p,Vector2(18,10)*scale,c); draw_circle(p+Vector2(15,-6)*scale,8*scale,c); draw_colored_polygon(PackedVector2Array([p+Vector2(10,-11)*scale,p+Vector2(12,-23)*scale,p+Vector2(18,-11)*scale]),c)
		elif name=="Skeleton" or name=="Zombie":
			draw_circle(p+Vector2(0,-10)*scale,10*scale,c); draw_rect(Rect2(p+Vector2(-8,0)*scale,Vector2(16,22)*scale),c,true)
		elif name=="Dragon":
			draw_ellipse(p,Vector2(25,13)*scale,c); draw_colored_polygon(PackedVector2Array([p+Vector2(-10,-4)*scale,p+Vector2(-35,-22)*scale,p+Vector2(-22,5)*scale]),c); draw_colored_polygon(PackedVector2Array([p+Vector2(10,-4)*scale,p+Vector2(35,-22)*scale,p+Vector2(22,5)*scale]),c); draw_circle(p+Vector2(19,-7)*scale,7*scale,c)
		else:
			draw_ellipse(p,Vector2(19,12)*scale,c); draw_circle(p+Vector2(0,-9)*scale,10*scale,c); draw_colored_polygon(PackedVector2Array([p+Vector2(-9,-14)*scale,p+Vector2(-6,-26)*scale,p+Vector2(-1,-15)*scale]),c); draw_colored_polygon(PackedVector2Array([p+Vector2(9,-14)*scale,p+Vector2(6,-26)*scale,p+Vector2(1,-15)*scale]),c)
		# Eyes, HP and MVP badge.
		draw_circle(p+Vector2(-4,-10)*scale,1.7*scale,Color("#ff5c63")); draw_circle(p+Vector2(4,-10)*scale,1.7*scale,Color("#ff5c63"))
		var ratio:=clamp(float(monster.get("hp",0))/max(1.0,float(monster.get("max",1))),0.0,1.0)
		var bar_w:=38.0*scale
		draw_rect(Rect2(p+Vector2(-bar_w/2,22),Vector2(bar_w,4)),Color(0,0,0,0.7),true)
		draw_rect(Rect2(p+Vector2(-bar_w/2,22),Vector2(bar_w*ratio,4)),Color("#e85d75") if not monster.get("mvp",false) else Color("#f5c85b"),true)
		if monster.get("mvp",false):
			draw_string(ThemeDB.fallback_font,p+Vector2(-25,-35),"MVP",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f5c85b"))
			draw_string(ThemeDB.fallback_font,p+Vector2(-30,38),"Lv."+str(monster.get("level",1)),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)

func draw_ellipse(center:Vector2,radii:Vector2,color:Color)->void:
	var points:=PackedVector2Array()
	for i in range(32):
		var a:=TAU*float(i)/32.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
