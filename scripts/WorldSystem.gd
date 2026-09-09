class_name WorldSystem
extends RefCounted

const DROP_TABLE := {
	"Poring":[{"item":"Apple","chance":0.25},{"item":"Poring Card","chance":0.01},{"item":"Phracon","chance":0.08}],
	"Goblin":[{"item":"Iron Ore","chance":0.30},{"item":"Goblin Ear","chance":0.35},{"item":"Goblin Card","chance":0.006},{"item":"Phracon","chance":0.08}],
	"Wolf":[{"item":"Wolf Claw","chance":0.35},{"item":"Beast Fang","chance":0.20},{"item":"Wolf Card","chance":0.005},{"item":"Phracon","chance":0.08}],
	"Skeleton":[{"item":"Skeleton Bone","chance":0.35},{"item":"Bone","chance":0.25},{"item":"Skeleton Card","chance":0.004},{"item":"Phracon","chance":0.08}],
	"Zombie":[{"item":"Zombie Heart","chance":0.35},{"item":"Rotten Bone","chance":0.25},{"item":"Zombie Card","chance":0.0035},{"item":"Phracon","chance":0.08}],
	"Orc":[{"item":"Orc Tusk","chance":0.35},{"item":"Orc Fang","chance":0.25},{"item":"Orc Card","chance":0.003},{"item":"Emveretarcon","chance":0.025}],
	"Mantis":[{"item":"Mantis Shell","chance":0.30},{"item":"Sharp Claw","chance":0.25},{"item":"Mantis Card","chance":0.0025},{"item":"Emveretarcon","chance":0.025}],
	"Golem":[{"item":"Golem Core","chance":0.40},{"item":"Stone Fragment","chance":0.35},{"item":"Golem Card","chance":0.002},{"item":"Oridecon","chance":0.012}],
	"Evil Druid":[{"item":"Druid Relic","chance":0.25},{"item":"Dark Branch","chance":0.30},{"item":"Evil Druid Card","chance":0.0015},{"item":"Oridecon","chance":0.012}],
	"Dragon":[{"item":"Dragon Scale","chance":0.50},{"item":"Ancient Dragon Heart","chance":0.02},{"item":"Dragon Card","chance":0.001},{"item":"Oridecon","chance":0.018}],
	"Bloody Knight":[{"item":"Bloody Knight Card","chance":0.003},{"item":"Blood Shard","chance":0.20},{"item":"Cursed Armor Fragment","chance":0.16},{"item":"Oridecon","chance":0.05}]
}

static func monster_level_for_zone(zone_level:int,family_index:int)->int:
	return clamp(zone_level*10+family_index*3,1,300)

static func monster_stats(level:int)->Dictionary:
	return {"max_hp":max(40,level*35),"attack":max(5,level*4),"defense":max(1,level*2),"exp":max(10,level*12),"zeny_min":max(5,level*2),"zeny_max":max(10,level*5)}

static func roll_drops(family:String,rng:RandomNumberGenerator)->Array:
	var drops:Array=[]
	if not DROP_TABLE.has(family): return drops
	for entry in DROP_TABLE[family]:
		if rng.randf()<=float(entry["chance"]): drops.append(entry["item"])
	return drops

static func refinement_chance(age:int,hero_level:int,refine:int)->float:
	return min(0.92,0.45+float(GameData.age_bonus(age))/100.0+float(hero_level)/1000.0-float(refine)*0.035)

static func age_discount(age:int)->float:
	return min(0.30,float(GameData.age_bonus(age))/100.0)
