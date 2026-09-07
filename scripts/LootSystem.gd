class_name LootSystem
extends RefCounted

const DEFAULT_RULES := {
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
	if not hero.has("loot_rules"):
		hero["loot_rules"]=DEFAULT_RULES.duplicate(true)
	if not hero.has("loot_stats"):
		hero["loot_stats"]={"items":0,"cards":0,"equipment":0,"materials":0,"zeny":0,"mvp_chests":0}

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
	var rules:Dictionary=hero["loot_rules"]
	return rarity_rank(rarity)>=rarity_rank(str(rules.get("min_rarity","Common")))

static func add_item(hero:Dictionary,item_name:String,amount:int=1)->void:
	ensure_state(hero)
	var catalog:=ItemDatabase.all()
	if amount<=0 or not catalog.has(item_name): return
	var rarity:=str(catalog[item_name].get("rarity","Common"))
	if not accept(hero,rarity): return
	var inv:Dictionary=hero.get("inventory",{})
	inv[item_name]=int(inv.get(item_name,0))+amount
	hero["inventory"]=inv
	hero["loot_stats"]["items"]+=amount
	if str(catalog[item_name].get("type","")) in ["Weapon","Armor","Accessory"]:
		hero["loot_stats"]["equipment"]+=amount
	if item_name=="MVP Treasure Chest": hero["loot_stats"]["mvp_chests"]+=amount

static func add_material(hero:Dictionary,item_name:String,amount:int=1)->void:
	ensure_state(hero)
	var mats:Dictionary=hero.get("materials",{})
	mats[item_name]=int(mats.get(item_name,0))+amount
	hero["materials"]=mats
	hero["loot_stats"]["materials"]+=amount

static func add_card(hero:Dictionary,card_name:String)->void:
	ensure_state(hero)
	if not bool(hero["loot_rules"].get("auto_pick_cards",true)): return
	var catalog:=CardDatabase.all()
	if card_name=="" or not catalog.has(card_name): return
	if not hero["cards"].has(card_name):
		hero["cards"].append(card_name)
		hero["loot_stats"]["cards"]+=1

static func apply_mvp_loot(hero:Dictionary,monster:Dictionary,rng:RandomNumberGenerator)->Array[String]:
	ensure_state(hero)
	var gained:Array[String]=[]
	if not bool(monster.get("mvp",false)): return gained
	var card_name:=str(monster.get("mvp_card",""))
	if CardDatabase.all().has(card_name):
		add_card(hero,card_name)
		if hero["cards"].has(card_name): gained.append(card_name)
	for item_name in monster.get("mvp_loot",[]):
		if rng.randf()<0.78:
			add_item(hero,str(item_name),1)
			gained.append(str(item_name))
	if rng.randf()<0.35:
		add_item(hero,"MVP Bounty Token",rng.randi_range(1,3))
		gained.append("MVP Bounty Token")
	return gained

static func apply_bonus_loot(hero:Dictionary,monster:Dictionary,rng:RandomNumberGenerator)->Array[String]:
	ensure_state(hero)
	var gained:Array[String]=[]
	var name:=str(monster.get("name",""))
	var card_name:=CardDatabase.for_monster(name)
	if card_name!="":
		var rarity:=str(CardDatabase.all()[card_name].get("rarity","Common"))
		if rng.randf()<CardDatabase.rarity_weight(rarity):
			add_card(hero,card_name)
			if hero["cards"].has(card_name): gained.append(card_name)
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
	if rng.randf()<0.55:
		add_item(hero,reagent,rng.randi_range(1,3)); gained.append(reagent)
	if rng.randf()<0.035:
		add_item(hero,"Pet Skill Item",1); gained.append("Pet Skill Item")
	if rng.randf()<0.06:
		add_item(hero,"Pet Refine Item",1); gained.append("Pet Refine Item")
	return gained

static func on_monster_defeated(hero:Dictionary,monster:Dictionary,rng:RandomNumberGenerator)->Array[String]:
	var gained:=apply_bonus_loot(hero,monster,rng)
	var mvp:=apply_mvp_loot(hero,monster,rng)
	for entry in mvp: gained.append(entry)
	return gained
