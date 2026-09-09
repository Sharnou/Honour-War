class_name MonsterDetailsSystem
extends RefCounted

## Shared monster codex: combat identity, elemental/status behavior, resistances,
## danger rating and drop families. The same data drives combat, UI and VFX.
static func details(monster:Dictionary)->Dictionary:
	var name:String=str(monster.get("name","Monster"))
	var lower:String=name.to_lower()
	var mvp:bool=bool(monster.get("mvp",false))
	var data:Dictionary={"name":name,"level":int(monster.get("level",1)),"role":"Melee","element":"Neutral","status":"None","status_chance":0.0,"poison_resist":0.0,"danger":2,"weakness":"Neutral","description":"Hostile creature.","bleed_resist":0.0}
	if lower.contains("poring"):
		data["element"]="Water"; data["danger"]=1; data["description"]="Small roaming creature with quick recovery."
	elif lower.contains("goblin"):
		data["element"]="Earth"; data["status"]="Bleed"; data["status_chance"]=0.10; data["danger"]=2
	elif lower.contains("wolf"):
		data["role"]="Assassin"; data["element"]="Wind"; data["status"]="Bleed"; data["status_chance"]=0.18; data["danger"]=3
	elif lower.contains("skeleton"):
		data["element"]="Undead"; data["status"]="Bleed"; data["status_chance"]=0.08; data["poison_resist"]=1.0; data["danger"]=3
	elif lower.contains("zombie"):
		data["element"]="Undead"; data["status"]="Poison"; data["status_chance"]=0.22; data["poison_resist"]=0.65; data["danger"]=4
	elif lower.contains("orc"):
		data["role"]="Brute"; data["element"]="Earth"; data["status"]="Stagger"; data["status_chance"]=0.14; data["danger"]=5
	elif lower.contains("mantis"):
		data["role"]="Assassin"; data["element"]="Wind"; data["status"]="Poison"; data["status_chance"]=0.30; data["poison_resist"]=0.25; data["danger"]=5
	elif lower.contains("golem"):
		data["role"]="Tank"; data["element"]="Earth"; data["poison_resist"]=0.90; data["danger"]=6
	elif lower.contains("druid"):
		data["role"]="Caster"; data["element"]="Dark"; data["status"]="Curse"; data["status_chance"]=0.25; data["poison_resist"]=0.35; data["danger"]=7
	elif lower.contains("dragon"):
		data["role"]="Caster"; data["element"]="Fire"; data["status"]="Burn"; data["status_chance"]=0.30; data["poison_resist"]=0.50; data["danger"]=9
	elif lower.contains("bloody knight"):
		data["role"]="Executioner"; data["element"]="Dark"; data["status"]="Bleed + Fear + Poison"; data["status_chance"]=0.45; data["poison_resist"]=0.20; data["bleed_resist"]=0.50; data["danger"]=12; data["weakness"]="Holy"; data["description"]="A cursed executioner in blood-blackened plate. Its greatblade tears armor while a toxic blood mist hangs around the battlefield."
	if mvp:
		data["danger"]=max(int(data["danger"]),15); data["description"]=str(data["description"])+" MVP-class threat."
	return data

static func apply_poison(monster:Dictionary,source_damage:int,duration:float=6.0)->bool:
	var d:Dictionary=details(monster)
	var resistance:float=float(d.get("poison_resist",0.0))
	if resistance>=1.0: return false
	var effective:float=max(0.0,1.0-resistance)
	var now:float=Time.get_ticks_msec()/1000.0
	monster["poison_until"]=max(float(monster.get("poison_until",0.0)),now+duration*effective)
	monster["poison_damage"]=max(1,int(float(source_damage)*0.25*effective))
	monster["poison_source"]="Hero/Pet"
	monster["poison_tick"]=now+1.0
	monster["status"]=str(d.get("status","Poison"))+" • Poisoned"
	return true

static func compact_label(monster:Dictionary)->String:
	var d:Dictionary=details(monster)
	return "%s  Lv.%d  %s  %s  Danger %d" % [d["name"],d["level"],d["element"],d["role"],d["danger"]]
