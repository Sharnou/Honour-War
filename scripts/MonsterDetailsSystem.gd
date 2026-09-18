class_name MonsterDetailsSystem
extends RefCounted

## Shared monster codex: combat identity, elemental/status behavior, resistances,
## danger rating and drop families. The same data drives combat, UI and VFX.

static func _mvp_data() -> Dictionary:
	return {
		"Orc Lord": {"role":"Brute","element":"Earth","status":"Stagger","status_chance":0.30,"poison_resist":0.85,"bleed_resist":0.35,"danger":15,"weakness":"Wind","description":"A warlord-class orc who commands crushing earth strikes and brutal stagger attacks."},
		"Baphomet": {"role":"Brute","element":"Dark","status":"Fear + Bleed","status_chance":0.34,"poison_resist":0.90,"bleed_resist":0.25,"danger":15,"weakness":"Holy","description":"A horned abyssal tyrant whose crescent attacks break defensive formations."},
		"Evil Druid Lord": {"role":"Caster","element":"Dark","status":"Curse + Poison","status_chance":0.34,"poison_resist":0.55,"danger":15,"weakness":"Holy","description":"A corrupted druid lord that spreads dark roots, curses and toxic magic."},
		"Fire Dragon": {"role":"Caster","element":"Fire","status":"Burn","status_chance":0.42,"poison_resist":0.60,"danger":15,"weakness":"Ice","description":"An elder fire dragon that saturates the battlefield with burning breath and aerial devastation."},
		"Ice Titan": {"role":"Tank","element":"Ice","status":"Freeze + Stagger","status_chance":0.35,"poison_resist":0.95,"bleed_resist":0.80,"danger":15,"weakness":"Fire","description":"A colossal frozen guardian whose glacial shockwaves slow and stagger attackers."},
		"Queen Ant": {"role":"Swarm","element":"Earth","status":"Poison","status_chance":0.38,"poison_resist":0.70,"danger":15,"weakness":"Fire","description":"A hive queen protected by relentless swarms and venomous command attacks."},
		"Ancient Golem": {"role":"Tank","element":"Earth","status":"Stagger","status_chance":0.36,"poison_resist":1.0,"bleed_resist":0.95,"danger":15,"weakness":"Magic","description":"An ancient stone colossus with extreme physical resistance and crushing seismic force."},
		"Thanatos": {"role":"Executioner","element":"Dark","status":"Curse + Fear + Bleed","status_chance":0.48,"poison_resist":0.95,"bleed_resist":0.80,"danger":15,"weakness":"Holy","description":"The death sovereign, wielding soul-cutting attacks that punish weakened heroes."},
		"Moonlight Dragon": {"role":"Caster","element":"Holy","status":"Slow + Curse","status_chance":0.40,"poison_resist":0.80,"danger":15,"weakness":"Dark","description":"A moonlit elder dragon that bends radiant energy into wide-area control magic."},
		"Abyss Emperor": {"role":"Executioner","element":"Dark","status":"Curse + Fear + Stagger","status_chance":0.52,"poison_resist":1.0,"bleed_resist":0.90,"danger":16,"weakness":"Holy","description":"The final abyssal emperor, combining overwhelming physical force with reality-tearing judgment."}
	}

static func details(monster:Dictionary) -> Dictionary:
	var name:String = str(monster.get("name", "Monster"))
	var lower:String = name.to_lower()
	var mvp:bool = bool(monster.get("mvp", false))
	var data:Dictionary = {
		"name":name,
		"level":int(monster.get("level", 1)),
		"role":"Melee",
		"element":"Neutral",
		"status":"None",
		"status_chance":0.0,
		"poison_resist":0.0,
		"danger":2,
		"weakness":"Neutral",
		"description":"Hostile creature.",
		"bleed_resist":0.0
	}
	if lower.contains("poring"):
		data["element"] = "Water"
		data["danger"] = 1
		data["description"] = "Small roaming creature with quick recovery."
	elif lower.contains("goblin"):
		data["element"] = "Earth"
		data["status"] = "Bleed"
		data["status_chance"] = 0.10
		data["danger"] = 2
	elif lower.contains("wolf"):
		data["role"] = "Assassin"
		data["element"] = "Wind"
		data["status"] = "Bleed"
		data["status_chance"] = 0.18
		data["danger"] = 3
	elif lower.contains("skeleton"):
		data["element"] = "Undead"
		data["status"] = "Bleed"
		data["status_chance"] = 0.08
		data["poison_resist"] = 1.0
		data["danger"] = 3
	elif lower.contains("zombie"):
		data["element"] = "Undead"
		data["status"] = "Poison"
		data["status_chance"] = 0.22
		data["poison_resist"] = 0.65
		data["danger"] = 4
	elif lower.contains("orc"):
		data["role"] = "Brute"
		data["element"] = "Earth"
		data["status"] = "Stagger"
		data["status_chance"] = 0.14
		data["danger"] = 5
	elif lower.contains("mantis"):
		data["role"] = "Assassin"
		data["element"] = "Wind"
		data["status"] = "Poison"
		data["status_chance"] = 0.30
		data["poison_resist"] = 0.25
		data["danger"] = 5
	elif lower.contains("golem"):
		data["role"] = "Tank"
		data["element"] = "Earth"
		data["poison_resist"] = 0.90
		data["danger"] = 6
	elif lower.contains("druid"):
		data["role"] = "Caster"
		data["element"] = "Dark"
		data["status"] = "Curse"
		data["status_chance"] = 0.25
		data["poison_resist"] = 0.35
		data["danger"] = 7
	elif lower.contains("dragon"):
		data["role"] = "Caster"
		data["element"] = "Fire"
		data["status"] = "Burn"
		data["status_chance"] = 0.30
		data["poison_resist"] = 0.50
		data["danger"] = 9
	elif lower.contains("bloody knight"):
		data["role"] = "Executioner"
		data["element"] = "Dark"
		data["status"] = "Bleed + Fear + Poison"
		data["status_chance"] = 0.45
		data["poison_resist"] = 0.20
		data["bleed_resist"] = 0.50
		data["danger"] = 12
		data["weakness"] = "Holy"
		data["description"] = "A cursed executioner in blood-blackened plate. Its greatblade tears armor while a toxic blood mist hangs around the battlefield."

	if mvp:
		var overrides:Dictionary = _mvp_data().get(name, {})
		for key in overrides.keys():
			data[key] = overrides[key]
		data["danger"] = max(int(data.get("danger", 0)), 15)
		data["description"] = str(data.get("description", "Hostile creature.")) + " MVP-class threat."

	return data

static func skill_element(class_id:String, skill_id:String) -> String:
	var skill:String = skill_id.to_lower()
	if class_id == "Mage":
		if skill.contains("frost"):
			return "Ice"
		if skill.contains("meteor") or skill.contains("comet"):
			return "Fire"
		if skill.contains("void"):
			return "Dark"
		return "Magic"
	if class_id == "Archer":
		if skill.contains("trap"):
			return "Lightning"
		return "Wind"
	if class_id == "Thief":
		return "Dark"
	if class_id == "Acolyte":
		return "Holy"
	if class_id == "Merchant":
		if skill.contains("magma"):
			return "Fire"
		return "Neutral"
	return "Neutral"

static func skill_damage_multiplier(class_id:String, skill_id:String, monster:Dictionary) -> float:
	var monster_data:Dictionary = details(monster)
	var attack_element:String = skill_element(class_id, skill_id)
	var weakness:String = str(monster_data.get("weakness", "Neutral"))
	var defense_element:String = str(monster_data.get("element", "Neutral"))
	if weakness == "Magic" and attack_element == "Magic":
		return 1.25
	if weakness == attack_element and weakness != "Neutral":
		return 1.25
	if attack_element == defense_element and attack_element != "Neutral":
		return 0.88
	return 1.0

static func apply_poison(monster:Dictionary, source_damage:int, duration:float = 6.0) -> bool:
	var d:Dictionary = details(monster)
	var resistance:float = float(d.get("poison_resist", 0.0))
	if resistance >= 1.0:
		return false
	var effective:float = max(0.0, 1.0 - resistance)
	var now:float = float(Time.get_ticks_msec()) / 1000.0
	monster["poison_until"] = max(float(monster.get("poison_until", 0.0)), now + duration * effective)
	monster["poison_damage"] = max(1, int(float(source_damage) * 0.25 * effective))
	monster["poison_source"] = "Hero/Pet"
	monster["poison_tick"] = now + 1.0
	monster["status"] = str(d.get("status", "Poison")) + " - Poisoned"
	return true

static func compact_label(monster:Dictionary) -> String:
	var d:Dictionary = details(monster)
	return "%s  Lv.%d  %s  %s  Danger %d" % [d["name"], d["level"], d["element"], d["role"], d["danger"]]
