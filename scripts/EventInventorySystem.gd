class_name EventInventorySystem
extends RefCounted

## Event rewards and a structured inventory list. Stacks are dictionaries so UI,
## saving and future online synchronization all use the same representation.
static func event_catalog()->Array:
	return [
		{"id":"daily_hunt","name":"Daily Hunt","duration_hours":24,"objective":"Defeat 20 monsters","reward":"Event Token x5 + XP","repeatable":true},
		{"id":"blood_moon","name":"Blood Moon","duration_hours":3,"objective":"Defeat Blood Moon monsters","reward":"Blood Shard + rare loot","repeatable":false},
		{"id":"mvp_hour","name":"MVP Hour","duration_hours":1,"objective":"Defeat an MVP","reward":"MVP Token + bonus loot","repeatable":false},
		{"id":"pet_bond","name":"Pet Bond Festival","duration_hours":6,"objective":"Fight beside your bonded pet","reward":"Pet Skill Item + Bond XP","repeatable":false},
		{"id":"forge_festival","name":"Forge Festival","duration_hours":4,"objective":"Refine or craft equipment","reward":"Refine materials + Zeny","repeatable":false},
		{"id":"ancient_night","name":"Ancient Night","duration_hours":2,"objective":"Survive an elite monster wave","reward":"Ancient Relic + XP","repeatable":false}
	]

static func ensure_inventory(hero:Dictionary)->void:
	if not hero.has("inventory") or not hero["inventory"] is Dictionary: hero["inventory"]={}
	if not hero.has("event_inventory") or not hero["event_inventory"] is Dictionary: hero["event_inventory"]={}
	if not hero.has("event_progress") or not hero["event_progress"] is Dictionary: hero["event_progress"]={}
	if not hero.has("monster_codex") or not hero["monster_codex"] is Dictionary: hero["monster_codex"]={}

static func add_item(hero:Dictionary,item_id:String,amount:int=1,rarity:String="Common")->void:
	ensure_inventory(hero)
	if amount<=0: return
	var current:Variant=hero["inventory"].get(item_id,{"amount":0,"rarity":rarity})
	if not current is Dictionary: current={"amount":0,"rarity":rarity}
	var stack:Dictionary=current
	stack["amount"]=int(stack.get("amount",0))+amount
	stack["rarity"]=rarity if rarity!="" else str(stack.get("rarity","Common"))
	hero["inventory"][item_id]=stack

static func remove_item(hero:Dictionary,item_id:String,amount:int=1)->bool:
	ensure_inventory(hero)
	var stack:Variant=hero["inventory"].get(item_id)
	if not stack is Dictionary or int(stack.get("amount",0))<amount: return false
	var left:int=int(stack.get("amount",0))-amount
	if left<=0: hero["inventory"].erase(item_id)
	else: stack["amount"]=left
	return true

static func inventory_list(hero:Dictionary)->Array:
	ensure_inventory(hero)
	var list:Array=[]
	for id in hero["inventory"].keys():
		var stack:Dictionary=hero["inventory"][id]
		list.append({"id":str(id),"amount":int(stack.get("amount",0)),"rarity":str(stack.get("rarity","Common"))})
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
	hero["event_progress"][event_id]=int(hero["event_progress"].get(event_id,0))+amount
