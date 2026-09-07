class_name WorldSystem
extends RefCounted

const DROP_TABLE := {
	"Poring":[{"item":"Poring Card", "chance":0.02},{"item":"Apple", "chance":0.25}],
	"Goblin":[{"item":"Goblin Card", "chance":0.015},{"item":"Iron Ore", "chance":0.30}],
	"Wolf":[{"item":"Wolf Card", "chance":0.012},{"item":"Wolf Claw", "chance":0.35}],
	"Skeleton":[{"item":"Skeleton Card", "chance":0.01},{"item":"Bone", "chance":0.35}],
	"Zombie":[{"item":"Zombie Card", "chance":0.009},{"item":"Rotten Bone", "chance":0.35}],
	"Orc":[{"item":"Orc Card", "chance":0.008},{"item":"Orc Fang", "chance":0.35}],
	"Mantis":[{"item":"Mantis Card", "chance":0.007},{"item":"Sharp Claw", "chance":0.30}],
	"Golem":[{"item":"Golem Card", "chance":0.006},{"item":"Stone Fragment", "chance":0.40}],
	"Evil Druid":[{"item":"Evil Druid Card", "chance":0.004},{"item":"Dark Branch", "chance":0.25}],
	"Dragon":[{"item":"Dragon Card", "chance":0.002},{"item":"Dragon Scale", "chance":0.50}]
}

static func monster_level_for_zone(zone_level:int, family_index:int) -> int:
	return clamp(zone_level * 10 + family_index * 3, 1, 300)

static func monster_stats(level:int) -> Dictionary:
	return {"max_hp":max(40, level * 35), "attack":max(5, level * 4), "defense":max(1, level * 2), "exp":max(10, level * 12), "zeny_min":max(5, level * 2), "zeny_max":max(10, level * 5)}

static func roll_drops(family:String, rng:RandomNumberGenerator) -> Array:
	var drops:Array=[]
	if not DROP_TABLE.has(family): return drops
	for entry in DROP_TABLE[family]:
		if rng.randf() <= float(entry["chance"]):
			drops.append(entry["item"])
	return drops

static func refinement_chance(age:int, hero_level:int, refine:int) -> float:
	return min(0.92, 0.45 + float(GameData.age_bonus(age)) / 100.0 + float(hero_level) / 1000.0 - float(refine) * 0.035)

static func age_discount(age:int) -> float:
	return min(0.30, float(GameData.age_bonus(age)) / 100.0)
