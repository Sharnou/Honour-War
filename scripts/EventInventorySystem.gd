class_name EventInventorySystem
extends RefCounted

## Event rewards and inventory presentation. Inventory remains compatible with
## the existing LootSystem integer stacks; event metadata lives separately.
static func event_catalog()->Array:
	return [
		{"id":"daily_hunt","name":"Daily Hunt","duration_hours":24,"objective":"Defeat 20 monsters","target":20,"reward":"Event Token x5 + XP","repeatable":true},
		{"id":"blood_moon","name":"Blood Moon","duration_hours":3,"objective":"Defeat Bloody Knights","target":10,"reward":"Blood Shard + rare loot","repeatable":false},
		{"id":"mvp_hour","name":"MVP Hour","duration_hours":1,"objective":"Defeat an MVP","target":1,"reward":"MVP Token + bonus loot","repeatable":false},
		{"id":"pet_bond","name":"Pet Bond Festival","duration_hours":6,"objective":"Fight beside your bonded pet","target":25,"reward":"Pet Skill Item + Bond XP","repeatable":false},
		{"id":"forge_festival","name":"Forge Festival","duration_hours":4,"objective":"Refine or craft equipment","target":1,"reward":"Refine materials + Zeny","repeatable":false},
		{"id":"ancient_night","name":"Ancient Night","duration_hours":2,"objective":"Survive an elite monster wave","target":1,"reward":"Ancient Relic + XP","repeatable":false}
	]

static func ensure_inventory(hero:Dictionary)->void:
	if not hero.has("inventory") or not hero["inventory"] is Dictionary: hero["inventory"]={}
	if not hero.has("event_inventory") or not hero["event_inventory"] is Dictionary: hero["event_inventory"]={}
	if not hero.has("event_progress") or not hero["event_progress"] is Dictionary: hero["event_progress"]={}
	if not hero.has("event_claimed") or not hero["event_claimed"] is Dictionary: hero["event_claimed"]={}
	if not hero.has("monster_codex") or not hero["monster_codex"] is Dictionary: hero["monster_codex"]={}

static func add_item(hero:Dictionary,item_id:String,amount:int=1,rarity:String="Common")->void:
	ensure_inventory(hero)
	if amount<=0: return
	hero["inventory"][item_id]=int(hero["inventory"].get(item_id,0))+amount
	hero["event_inventory"][item_id]={"rarity":rarity,"last_source":"event"}

static func remove_item(hero:Dictionary,item_id:String,amount:int=1)->bool:
	ensure_inventory(hero)
	var current:int=int(hero["inventory"].get(item_id,0))
	if current<amount: return false
	var left:int=current-amount
	if left<=0: hero["inventory"].erase(item_id)
	else: hero["inventory"][item_id]=left
	return true

static func inventory_list(hero:Dictionary)->Array:
	ensure_inventory(hero)
	var list:Array=[]
	for id in hero["inventory"].keys():
		var value:Variant=hero["inventory"][id]
		var amount:int=int(value.get("amount",0)) if value is Dictionary else int(value)
		var event_meta:Dictionary=hero["event_inventory"].get(str(id),{}) if hero["event_inventory"].get(str(id),{}) is Dictionary else {}
		var rarity:String=str(event_meta.get("rarity","Common"))
		list.append({"id":str(id),"amount":amount,"rarity":rarity})
	list.sort_custom(func(a,b): return str(a["id"])<str(b["id"]))
	return list

static func record_monster(hero:Dictionary,monster:Dictionary)->void:
	ensure_inventory(hero)
	var id:String=str(monster.get("name","Monster"))
	var entry:Dictionary=hero["monster_codex"].get(id,{"kills":0,"highest_level":0})
	entry["kills"]=int(entry.get("kills",0))+1
	entry["highest_level"]=max(int(entry.get("highest_level",0)),int(monster.get("level",1)))
	hero["monster_codex"][id]=entry

static func record_event_progress(hero:Dictionary,event_id:String,amount:int=1)->void:
	ensure_inventory(hero)
	var progress:int=int(hero["event_progress"].get(event_id,0))+amount
	hero["event_progress"][event_id]=progress
	var claimed:int=int(hero["event_claimed"].get(event_id,0))
	var target:int=0
	for event in event_catalog():
		if str(event["id"])==event_id:
			target=int(event.get("target",1))
			break
	if target<=0 or progress<target or progress<claimed+target: return
	_claim_reward(hero,event_id)
	hero["event_claimed"][event_id]=claimed+target

static func _claim_reward(hero:Dictionary,event_id:String)->void:
	ensure_inventory(hero)
	match event_id:
		"daily_hunt":
			add_item(hero,"Event Token",5,"Rare")
			add_item(hero,"Red Potion",3,"Common")
		"blood_moon": add_item(hero,"Blood Shard",1,"Legendary")
		"mvp_hour": add_item(hero,"MVP Bounty Token",1,"MVP")
		"pet_bond": add_item(hero,"Pet Skill Item",1,"Epic")
		"forge_festival": add_item(hero,"Oridecon",1,"Epic")
		"ancient_night": add_item(hero,"Abyssal Relic",1,"MVP")
