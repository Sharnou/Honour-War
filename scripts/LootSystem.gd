class_name LootSystem
extends RefCounted

const DEFAULT_RULES := {
	"enabled":true,
	"auto_pick_items":true,
	"auto_pick_cards":true,
	"auto_pick_materials":true,
	"auto_pick_equipment":true,
	"auto_sell_junk":false,
	"auto_use_potions":false,
	"min_rarity":"Common",
	"mvp_only_bonus_loot":true,
	"pet_picks_up":true
}

static func ensure_state(hero:Dictionary)->void:
	if not hero.has("loot_rules") or not hero["loot_rules"] is Dictionary: hero["loot_rules"]=DEFAULT_RULES.duplicate(true)
	else:
		for key in DEFAULT_RULES.keys():
			if not hero["loot_rules"].has(key): hero["loot_rules"][key]=DEFAULT_RULES[key]
	if not hero.has("loot_stats"): hero["loot_stats"]={"items":0,"cards":0,"equipment":0,"materials":0,"zeny":0,"mvp_chests":0}
	if not hero.has("ground_loot") or not hero["ground_loot"] is Array: hero["ground_loot"]=[]

static func is_enabled(hero:Dictionary)->bool:
	ensure_state(hero)
	return bool(hero["loot_rules"].get("enabled",true))

static func set_enabled(hero:Dictionary,enabled:bool)->void:
	ensure_state(hero)
	hero["loot_rules"]["enabled"]=enabled

static func toggle(hero:Dictionary)->bool:
	set_enabled(hero,not is_enabled(hero))
	return is_enabled(hero)

static func rarity_rank(rarity:String)->int:
	match rarity:
		"Common": return 1
		"Uncommon": return 2
		"Rare": return 3
		"Epic": return 4
		"Legendary": return 5
		"MVP": return 6
	return 0

static func accept(hero:Dictionary,rarity:String)->bool:
	ensure_state(hero)
	return rarity_rank(rarity)>=rarity_rank(str(hero["loot_rules"].get("min_rarity","Common")))

static func queue_ground(hero:Dictionary,name:String,kind:String,monster_name:String)->void:
	ensure_state(hero)
	hero["ground_loot"].append({"name":name,"kind":kind,"monster":monster_name,"time":Time.get_ticks_msec()})

static func add_item(hero:Dictionary,item_name:String,amount:int=1)->bool:
	ensure_state(hero)
	var catalog:=ItemDatabase.all()
	if amount<=0 or not catalog.has(item_name): return false
	var data:Dictionary=catalog[item_name]
	var type:=str(data.get("type",""))
	var rarity:=str(data.get("rarity","Common"))
	if type in ["Weapon","Armor","Accessory"] and not bool(hero["loot_rules"].get("auto_pick_equipment",true)): return false
	if type=="Crafting" and not bool(hero["loot_rules"].get("auto_pick_materials",true)): return false
	if type not in ["Weapon","Armor","Accessory","Crafting"] and not bool(hero["loot_rules"].get("auto_pick_items",true)): return false
	if not accept(hero,rarity): return false
	var inv:Dictionary=hero.get("inventory",{})
	inv[item_name]=int(inv.get(item_name,0))+amount
	hero["inventory"]=inv
	hero["loot_stats"]["items"]+=amount
	if type in ["Weapon","Armor","Accessory"]: hero["loot_stats"]["equipment"]+=amount
	if item_name=="MVP Treasure Chest": hero["loot_stats"]["mvp_chests"]+=amount
	return true

static func add_material(hero:Dictionary,item_name:String,amount:int=1)->bool:
	return add_item(hero,item_name,amount)

static func add_card(hero:Dictionary,card_name:String)->bool:
	ensure_state(hero)
	var catalog:=CardDatabase.all()
	if card_name=="" or not catalog.has(card_name): return false
	if not bool(hero["loot_rules"].get("auto_pick_cards",true): return false
	if not accept(hero,str(catalog[card_name].get("rarity","Common"))): return false
	if hero["cards"].has(card_name): return false
	hero["cards"].append(card_name)
	hero["loot_stats"]["cards"]+=1
	return true

static func collect_drop(hero:Dictionary,name:String,monster_name:String,rng:RandomNumberGenerator)->bool:
	ensure_state(hero)
	if CardDatabase.all().has(name):
		if is_enabled(hero): return add_card(hero,name)
		queue_ground(hero,name,"card",monster_name)
		return false
	if ItemDatabase.all().has(name):
		if is_enabled(hero): return add_item(hero,name,1)
		queue_ground(hero,name,"item",monster_name)
		return false
	return false

static func collect_ground(hero:Dictionary)->Array[String]:
	ensure_state(hero)
	var gained:Array[String]=[]
	if not is_enabled(hero): return gained
	var remaining:Array=[]
	for drop in hero["ground_loot"]:
		if not drop is Dictionary: continue
		var name:=str(drop.get("name",""))
		var kind:=str(drop.get("kind","item"))
		var ok:=add_card(hero,name) if kind=="card" else add_item(hero,name,1)
		if ok: gained.append(name)
		else: remaining.append(drop)
	hero["ground_loot"]=remaining
	return gained

static func apply_bonus_loot(hero:Dictionary,monster:Dictionary,rng:RandomNumberGenerator)->Array[String]:
	ensure_state(hero)
	var gained:Array[String]=[]
	var name:=str(monster.get("name",""))
	var reagent:="Monster Essence"
	match name:
		"Wolf": reagent="Wolf Claw"
		"Goblin": reagent="Goblin Ear"
		"Orc": reagent="Orc Tusk"
		"Mantis": reagent="Mantis Shell"
		"Skeleton": reagent="Skeleton Bone"
		"Zombie": reagent="Zombie Heart"
		"Golem": reagent="Golem Core"
		"Evil Druid": reagent="Druid Relic"
		"Dragon": reagent="Dragon Scale"
	if rng.randf()<0.55 and collect_drop(hero,reagent,name,rng): gained.append(reagent)
	if rng.randf()<0.035 and collect_drop(hero,"Pet Skill Item",name,rng): gained.append("Pet Skill Item")
	if rng.randf()<0.06 and collect_drop(hero,"Pet Refine Item",name,rng): gained.append("Pet Refine Item")
	return gained

static func apply_mvp_loot(hero:Dictionary,monster:Dictionary,rng:RandomNumberGenerator)->Array[String]:
	ensure_state(hero)
	var gained:Array[String]=[]
	if not bool(monster.get("mvp",false)): return gained
	var monster_name:=str(monster.get("name","MVP"))
	var card_name:=str(monster.get("mvp_card",""))
	if card_name!="" and collect_drop(hero,card_name,monster_name,rng): gained.append(card_name)
	for item_name in monster.get("mvp_loot",[]):
		if rng.randf()<0.78 and collect_drop(hero,str(item_name),monster_name,rng): gained.append(str(item_name))
	if rng.randf()<0.35 and collect_drop(hero,"MVP Bounty Token",monster_name,rng): gained.append("MVP Bounty Token")
	if collect_drop(hero,"MVP Treasure Chest",monster_name,rng): gained.append("MVP Treasure Chest")
	return gained

static func on_monster_defeated(hero:Dictionary,monster:Dictionary,rng:RandomNumberGenerator)->Array[String]:
	ensure_state(hero)
	if bool(monster.get("loot_processed",false)): return []
	monster["loot_processed"]=true
	var gained:Array[String]=[]
	for drop in WorldSystem.roll_drops(str(monster.get("name","")),rng):
		if collect_drop(hero,str(drop),str(monster.get("name","Monster")),rng): gained.append(str(drop))
	for entry in apply_bonus_loot(hero,monster,rng): gained.append(entry)
	for entry in apply_mvp_loot(hero,monster,rng): gained.append(entry)
	return gained
