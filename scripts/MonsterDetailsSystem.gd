class_name MonsterDetailsSystem
extends RefCounted

## Shared monster codex: combat identity, elemental/status behavior, resistances,
## danger rating and drop families. The same data drives combat, UI and VFX.
static func details(monster:Dictionary)->Dictionary:
	var name:String=str(monster.get("name","Monster"))
	var lower:String=name.to_lower()
	var mvp:bool=bool(monster.get("mvp",false))
	var data:Dictionary={"name":name,"level":int(monster.get("level",1)),"role":"Melee","element":"Neutral","status":"None","status_chance":0.0,"poison_resist":0.0,"danger":2,"weakness":"Neutral","description":"Hostile creature.","bleed_resist":0.0}
	if mvp:
		match name:
			"Orc Lord":
				data["role"]="Brute"; data["element"]="Earth"; data["status"]="Stagger"; data["status_chance"]=0.30; data["poison_resist"]=0.85; data["bleed_resist"]=0.35; data["danger"]=15; data["weakness"]="Wind"; data["description"]="A warlord-class orc who commands crushing earth strikes and brutal stagger attacks."
			"Baphomet":
				data["role"]="Brute"; data["element"]="Dark"; data["status"]="Fear + Bleed"; data["status_chance"]=0.34; data["poison_resist"]=0.90; data["bleed_resist"]=0.25; data["danger"]=15; data["weakness"]="Holy"; data["description"]="A horned abyssal tyrant whose crescent attacks break defensive formations."
			"Evil Druid Lord":
				data["role"]="Caster"; data["element"]="Dark"; data["status"]="Curse + Poison"; data["status_chance"]=0.34; data["poison_resist"]=0.55; data["danger"]=15; data["weakness"]="Holy"; data["description"]="A corrupted druid lord that spreads dark roots, curses and toxic magic."
			"Fire Dragon":
				data["role"]="Caster"; data["element"]="Fire"; data["status"]="Burn"; data["status_chance"]=0.42; data["poison_resist"]=0.60; data["danger"]=15; data["weakness"]="Ice"; data["description"]="An elder fire dragon that saturates the battlefield with burning breath and aerial devastation."
			"Ice Titan":
				data["role"]="Tank"; data["element"]="Ice"; data["status"]="Freeze + Stagger"; data["status_chance"]=0.35; data["poison_resist"]=0.95; data["bleed_resist"]=0.80; data["danger"]=15; data["weakness"]="Fire"; data["description"]="A colossal frozen guardian whose glacial shockwaves slow and stagger attackers."
			"Queen Ant":
				data["role"]="Swarm"; data["element"]="Earth"; data["status"]="Poison"; data["status_chance"]=0.38; data["poison_resist"]=0.70; data["danger"]=15; data["weakness"]="Fire"; data["description"]="A hive queen protected by relentless swarms and venomous command attacks."
			"Ancient Golem":
				data["role"]="Tank"; data["element"]="Earth"; data["status"]="Stagger"; data["status_chance"]=0.36; data["poison_resist"]=1.0; data["bleed_resist"]=0.95; data["danger"]=15; data["weakness"]="Magic"; data["description"]="An ancient stone colossus with extreme physical resistance and crushing seismic force."
			"Thanatos":
				data["role"]="Executioner"; data["element"]="Dark"; data["status"]="Curse + Fear + Bleed"; data["status_chance"]=0.48; data["poison_resist"]=0.95; data["bleed_resist"]=0.80; data["danger"]=15; data["weakness"]="Holy"; data["description"]="The death sovereign, wielding soul-cutting attacks that punish weakened heroes."
			"Moonlight Dragon":
				data["role"]="Caster"; data["element"]="Holy"; data["status"]="Slow + Curse"; data["status_chance"]=0.40; data["poison_resist"]=0.80; data["danger"]=15; data["weakness"]="Dark"; data["description"]="A moonlit elder dragon that bends radiant energy into wide-area control magic."
			"Abyss Emperor":
				data["role"]="Executioner"; data["element"]="Dark"; data["status"]="Curse + Fear + Stagger"; data["status_chance"]=0.52; data["poison_resist"]=1.0; data["bleed_resist"]=0.90; data["danger"]=16; data["weakness"]="Holy"; data["description"]="The final abyssal emperor, combining overwhelming physical force with reality-tearing judgment."
		else:
			pass
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
