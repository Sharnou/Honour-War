class_name CardDatabase
extends RefCounted

static func all() -> Dictionary:
	return {
		"Poring Card":{"monster":"Poring","rarity":"Common","slot":"Accessory","bonus":"+2% item drop rate","power":2,"item_drop_percent":2.0},
		"Goblin Card":{"monster":"Goblin","rarity":"Common","slot":"Weapon","bonus":"+4% damage to Goblin family","power":4,"family_damage":"Goblin","family_damage_percent":4.0},
		"Wolf Card":{"monster":"Wolf","rarity":"Common","slot":"Armor","bonus":"+40 HP, +2% movement speed","power":4,"hp":40,"move_percent":2.0},
		"Skeleton Card":{"monster":"Skeleton","rarity":"Common","slot":"Weapon","bonus":"+3% critical damage","power":5,"crit_damage_percent":3.0},
		"Zombie Card":{"monster":"Zombie","rarity":"Common","slot":"Armor","bonus":"+5 poison resistance","power":5,"poison_resist":5},
		"Orc Card":{"monster":"Orc","rarity":"Uncommon","slot":"Armor","bonus":"+6 defense vs brute","power":8,"family_defense":"Orc","family_defense_value":6},
		"Mantis Card":{"monster":"Mantis","rarity":"Uncommon","slot":"Weapon","bonus":"+5% attack speed","power":7,"attack_speed_percent":5.0},
		"Golem Card":{"monster":"Golem","rarity":"Rare","slot":"Armor","bonus":"+12 defense","power":12,"defense":12},
		"Evil Druid Card":{"monster":"Evil Druid","rarity":"Rare","slot":"Armor","bonus":"+8% magic resistance","power":14,"magic_resist_percent":8.0},
		"Dragon Card":{"monster":"Dragon","rarity":"Epic","slot":"Weapon","bonus":"+12% damage to bosses","power":20,"boss_damage_percent":12.0},
		"Bloody Knight Card":{"monster":"Bloody Knight","rarity":"Legendary","slot":"Armor","bonus":"+20% bleed resistance, +40 defense, +8% damage to dark monsters","power":70,"defense":40,"bleed_resist":20.0,"dark_damage_percent":8.0},
		"Orc Lord Card":{"monster":"Orc Lord","rarity":"MVP","slot":"Armor","bonus":"+15% HP and +10 defense","power":35,"hp_percent":15.0,"defense":10},
		"Baphomet Card":{"monster":"Baphomet","rarity":"MVP","slot":"Weapon","bonus":"+18% physical damage","power":42,"damage_percent":18.0},
		"Evil Druid Lord Card":{"monster":"Evil Druid Lord","rarity":"MVP","slot":"Accessory","bonus":"+18% magic damage","power":42,"magic_damage_percent":18.0},
		"Fire Dragon Card":{"monster":"Fire Dragon","rarity":"MVP","slot":"Weapon","bonus":"+20% fire damage","power":48,"fire_percent":20.0},
		"Ice Titan Card":{"monster":"Ice Titan","rarity":"MVP","slot":"Armor","bonus":"+20% ice resistance","power":48,"ice_resist_percent":20.0},
		"Queen Ant Card":{"monster":"Queen Ant","rarity":"MVP","slot":"Accessory","bonus":"+12% item quantity","power":45,"item_quantity_percent":12.0},
		"Ancient Golem Card":{"monster":"Ancient Golem","rarity":"MVP","slot":"Armor","bonus":"+25 defense and stagger resistance","power":55,"defense":25,"stagger_resist":25},
		"Thanatos Card":{"monster":"Thanatos","rarity":"MVP","slot":"Weapon","bonus":"+25% boss damage","power":65,"boss_damage_percent":25.0},
		"Moonlight Dragon Card":{"monster":"Moonlight Dragon","rarity":"MVP","slot":"Accessory","bonus":"+20% XP and +10% movement","power":60,"xp_percent":20.0,"move_percent":10.0},
		"Abyss Emperor Card":{"monster":"Abyss Emperor","rarity":"MVP","slot":"Weapon","bonus":"+30% all damage","power":80,"damage_percent":30.0,"boss_damage_percent":30.0,"all_rewards_percent":5.0},
		"Super Orc Lord Card":{"monster":"Orc Lord","rarity":"MVP","slot":"Armor","bonus":"+25% HP, +35 defense, +10% boss damage","power":100,"hp_percent":25.0,"defense":35,"boss_damage_percent":10.0,"super_card":true},
		"Super Baphomet Card":{"monster":"Baphomet","rarity":"MVP","slot":"Weapon","bonus":"+35% physical damage, +15% boss damage","power":110,"damage_percent":35.0,"boss_damage_percent":15.0,"super_card":true},
		"Super Evil Druid Lord Card":{"monster":"Evil Druid Lord","rarity":"MVP","slot":"Accessory","bonus":"+35% magic damage, +15% dark damage","power":110,"magic_damage_percent":35.0,"dark_percent":15.0,"super_card":true},
		"Super Fire Dragon Card":{"monster":"Fire Dragon","rarity":"MVP","slot":"Weapon","bonus":"+40% fire damage, +15% boss damage","power":120,"fire_percent":40.0,"boss_damage_percent":15.0,"super_card":true},
		"Super Thanatos Card":{"monster":"Thanatos","rarity":"MVP","slot":"Weapon","bonus":"+45% boss damage, +20% all damage","power":140,"boss_damage_percent":45.0,"damage_percent":20.0,"super_card":true},
		"Super Abyss Emperor Card":{"monster":"Abyss Emperor","rarity":"MVP","slot":"Weapon","bonus":"+55% all damage, +30% boss damage, +10% rewards","power":180,"damage_percent":55.0,"boss_damage_percent":30.0,"all_rewards_percent":10.0,"super_card":true}
	}

static func for_monster(monster_name:String)->String:
	var needle:=monster_name.strip_edges()
	var catalog:=all()
	for card_name in catalog.keys():
		if str(catalog[card_name].get("monster",""))==needle: return str(card_name)
	return ""

static func rarity_weight(rarity:String)->float:
	match rarity:
		"Common": return 0.010
		"Uncommon": return 0.006
		"Rare": return 0.003
		"Epic": return 0.0015
		"Legendary": return 0.0008
		"MVP": return 0.08
	return 0.001

static func apply_effect(result:Dictionary,card_name:String,hero:Dictionary,slot:String)->void:
	var data:Dictionary=all().get(card_name,{})
	result["hp"]+=int(data.get("hp",0))
	result["defense"]+=int(data.get("defense",0))
	result["crit"]+=int(data.get("crit",0))
	result["item_drop_percent"]+=float(data.get("item_drop_percent",0.0))+float(data.get("item_quantity_percent",0.0))
	result["damage_percent"]+=float(data.get("damage_percent",0.0))
	result["boss_damage_percent"]+=float(data.get("boss_damage_percent",0.0))
	result["xp_percent"]+=float(data.get("xp_percent",0.0))
	result["move_percent"]+=float(data.get("move_percent",0.0))
	result["fire_percent"]+=float(data.get("fire_percent",0.0))
	result["ice_resist_percent"]+=float(data.get("ice_resist_percent",0.0))
	result["dark_percent"]+=float(data.get("dark_percent",0.0))+float(data.get("dark_damage_percent",0.0))
	result["all_rewards_percent"]+=float(data.get("all_rewards_percent",0.0))
	result["poison_resist"]+=int(data.get("poison_resist",0))
	result["power_bonus"] = int(result.get("power_bonus",0))+int(data.get("power",0))
