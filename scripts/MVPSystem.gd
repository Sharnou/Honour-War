class_name MVPSystem
extends RefCounted

static func definitions() -> Dictionary:
	return {
		"Orc Lord":{"level":250,"hp_mult":12.0,"attack_mult":3.0,"defense_mult":2.5,"title":"MVP • Orc Lord","card":"Orc Lord Card","loot":["MVP Treasure Chest","Orc Tusk","Boss Soul Shard"],"skill":"Earthshaker"},
		"Baphomet":{"level":255,"hp_mult":14.0,"attack_mult":3.4,"defense_mult":2.4,"title":"MVP • Baphomet","card":"Baphomet Card","loot":["MVP Treasure Chest","Boss Soul Shard","Golden Crown"],"skill":"Dark Crescent"},
		"Evil Druid Lord":{"level":260,"hp_mult":13.0,"attack_mult":3.5,"defense_mult":2.8,"title":"MVP • Evil Druid Lord","card":"Evil Druid Lord Card","loot":["MVP Treasure Chest","Druid Relic","Moon Crystal"],"skill":"Grave Bloom"},
		"Fire Dragon":{"level":270,"hp_mult":18.0,"attack_mult":4.0,"defense_mult":3.0,"title":"MVP • Fire Dragon","card":"Fire Dragon Card","loot":["MVP Treasure Chest","Dragon Scale","Ancient Dragon Heart"],"skill":"Inferno Breath"},
		"Ice Titan":{"level":275,"hp_mult":18.0,"attack_mult":3.8,"defense_mult":3.4,"title":"MVP • Ice Titan","card":"Ice Titan Card","loot":["MVP Treasure Chest","Moon Crystal","Boss Soul Shard"],"skill":"Glacial Rupture"},
		"Queen Ant":{"level":280,"hp_mult":16.0,"attack_mult":3.6,"defense_mult":2.6,"title":"MVP • Queen Ant","card":"Queen Ant Card","loot":["MVP Treasure Chest","Boss Soul Shard","MVP Bounty Token"],"skill":"Royal Swarm"},
		"Ancient Golem":{"level":290,"hp_mult":22.0,"attack_mult":3.2,"defense_mult":4.2,"title":"MVP • Ancient Golem","card":"Ancient Golem Card","loot":["MVP Treasure Chest","Golem Core","Ancient Dragon Heart"],"skill":"Titan Slam"},
		"Thanatos":{"level":300,"hp_mult":25.0,"attack_mult":4.5,"defense_mult":3.8,"title":"MVP • Thanatos","card":"Thanatos Card","loot":["MVP Treasure Chest","Thanatos Fragment","Abyssal Relic"],"skill":"Soul Requiem"},
		"Moonlight Dragon":{"level":300,"hp_mult":24.0,"attack_mult":4.3,"defense_mult":3.5,"title":"MVP • Moonlight Dragon","card":"Moonlight Dragon Card","loot":["MVP Treasure Chest","Moon Crystal","Ancient Dragon Heart"],"skill":"Lunar Cataclysm"},
		"Abyss Emperor":{"level":300,"hp_mult":30.0,"attack_mult":5.0,"defense_mult":4.0,"title":"MVP • Abyss Emperor","card":"Abyss Emperor Card","loot":["MVP Treasure Chest","Abyssal Relic","Thanatos Fragment"],"skill":"Abyssal Judgment"}
	}

static func roll_name(rng:RandomNumberGenerator)->String:
	var names:Array=definitions().keys()
	return str(names[rng.randi_range(0,names.size()-1)])

static func decorate(monster:Dictionary,rng:RandomNumberGenerator,hero_level:int)->Dictionary:
	if monster.get("mvp_checked",false): return monster
	monster["mvp_checked"]=true
	var chance:=0.018 if hero_level<150 else 0.035
	if rng.randf()>chance:
		monster["mvp"]=false
		return monster
	var name:=roll_name(rng)
	var d:Dictionary=definitions()[name]
	monster["mvp"]=true
	monster["name"]=name
	monster["title"]=d["title"]
	monster["level"]=min(GameData.MAX_MONSTER_LEVEL,int(d["level"]))
	monster["hp"]=max(1,int(float(monster.get("hp",100))*float(d["hp_mult"])))
	monster["max"]=monster["hp"]
	monster["attack"]=max(1,int(float(monster.get("attack",20))*float(d["attack_mult"])))
	monster["defense"]=max(1,int(float(monster.get("defense",10))*float(d["defense_mult"])))
	monster["exp"]=int(float(monster.get("exp",100))*float(d["hp_mult"])*1.6)
	monster["zmin"]=int(float(monster.get("zmin",10))*4.0)
	monster["zmax"]=int(float(monster.get("zmax",20))*7.0)
	monster["mvp_skill"]=d["skill"]
	monster["mvp_card"]=d["card"]
	monster["mvp_loot"]=d["loot"]
	return monster
