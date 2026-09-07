class_name CardDatabase
extends RefCounted

static func all() -> Dictionary:
	return {
		"Poring Card":{"monster":"Poring","rarity":"Common","slot":"Accessory","bonus":"+2% item drop rate","power":2},
		"Goblin Card":{"monster":"Goblin","rarity":"Common","slot":"Weapon","bonus":"+4% damage to Goblin family","power":4},
		"Wolf Card":{"monster":"Wolf","rarity":"Common","slot":"Armor","bonus":"+40 HP, +2% movement speed","power":4},
		"Skeleton Card":{"monster":"Skeleton","rarity":"Common","slot":"Weapon","bonus":"+3% critical damage","power":5},
		"Zombie Card":{"monster":"Zombie","rarity":"Common","slot":"Armor","bonus":"+5 poison resistance","power":5},
		"Orc Card":{"monster":"Orc","rarity":"Uncommon","slot":"Armor","bonus":"+6 defense vs brute","power":8},
		"Mantis Card":{"monster":"Mantis","rarity":"Uncommon","slot":"Weapon","bonus":"+5% attack speed","power":7},
		"Golem Card":{"monster":"Golem","rarity":"Rare","slot":"Armor","bonus":"+12 defense","power":12},
		"Evil Druid Card":{"monster":"Evil Druid","rarity":"Rare","slot":"Armor","bonus":"+8% magic resistance","power":14},
		"Dragon Card":{"monster":"Dragon","rarity":"Epic","slot":"Weapon","bonus":"+12% damage to bosses","power":20},
		"Orc Lord Card":{"monster":"Orc Lord","rarity":"MVP","slot":"Armor","bonus":"+15% HP and +10 defense","power":35},
		"Baphomet Card":{"monster":"Baphomet","rarity":"MVP","slot":"Weapon","bonus":"+18% physical damage","power":42},
		"Evil Druid Lord Card":{"monster":"Evil Druid Lord","rarity":"MVP","slot":"Accessory","bonus":"+18% magic damage","power":42},
		"Fire Dragon Card":{"monster":"Fire Dragon","rarity":"MVP","slot":"Weapon","bonus":"+20% fire damage","power":48},
		"Ice Titan Card":{"monster":"Ice Titan","rarity":"MVP","slot":"Armor","bonus":"+20% ice resistance","power":48},
		"Queen Ant Card":{"monster":"Queen Ant","rarity":"MVP","slot":"Accessory","bonus":"+12% item quantity","power":45},
		"Ancient Golem Card":{"monster":"Ancient Golem","rarity":"MVP","slot":"Armor","bonus":"+25 defense and stagger resistance","power":55},
		"Thanatos Card":{"monster":"Thanatos","rarity":"MVP","slot":"Weapon","bonus":"+25% boss damage","power":65},
		"Moonlight Dragon Card":{"monster":"Moonlight Dragon","rarity":"MVP","slot":"Accessory","bonus":"+20% XP and +10% movement","power":60},
		"Abyss Emperor Card":{"monster":"Abyss Emperor","rarity":"MVP","slot":"Weapon","bonus":"+30% all damage","power":80}
	}

static func for_monster(monster_name:String)->String:
	var needle:=monster_name.strip_edges()
	var catalog:=all()
	for card_name in catalog.keys():
		if str(catalog[card_name].get("monster",""))==needle:
			return str(card_name)
	return ""

static func rarity_weight(rarity:String)->float:
	match rarity:
		"Common": return 0.010
		"Uncommon": return 0.006
		"Rare": return 0.003
		"Epic": return 0.0015
		"MVP": return 0.08
	return 0.001
