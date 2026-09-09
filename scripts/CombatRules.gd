class_name CombatRules
extends RefCounted

# Honour War combat distances are authored in world meters and converted to
# the legacy map coordinate system with WORLD_SCALE. This keeps gameplay
# readable in meters while the existing simulation remains deterministic.
const WORLD_SCALE:float = 0.055
const GRID_SIZE:float = 1.0
const ClassFormula=preload("res://scripts/ClassCombatFormula.gd")

const CLASS_RULES:Dictionary = {
    "Warrior": {"label":"Swordsman / Warrior", "engagement_m":2.4, "engagement_map":43.636, "attack_interval":0.72, "target_acquire_m":18.0},
    "Mage": {"label":"Mage", "engagement_m":7.5, "engagement_map":136.364, "attack_interval":0.86, "target_acquire_m":18.0},
    "Archer": {"label":"Archer", "engagement_m":12.0, "engagement_map":218.182, "attack_interval":0.78, "target_acquire_m":22.0},
    "Ranger": {"label":"Ranger", "engagement_m":13.5, "engagement_map":245.455, "attack_interval":0.74, "target_acquire_m":24.0},
    "Thief": {"label":"Thief", "engagement_m":2.2, "engagement_map":40.0, "attack_interval":0.64, "target_acquire_m":16.0},
    "Acolyte": {"label":"Acolyte", "engagement_m":5.0, "engagement_map":90.909, "attack_interval":0.90, "target_acquire_m":16.0},
    "Merchant": {"label":"Merchant", "engagement_m":2.4, "engagement_map":43.636, "attack_interval":0.80, "target_acquire_m":16.0}
}

const PET_RULES:Dictionary = {
    "Falcon": {"role":"Ranged", "attack_distance_m":9.0, "attack_distance_map":163.636, "attack_interval":1.00},
    "Wolf": {"role":"Melee", "attack_distance_m":2.6, "attack_distance_map":47.273, "attack_interval":0.92},
    "Dragon": {"role":"Caster", "attack_distance_m":10.0, "attack_distance_map":181.818, "attack_interval":1.20},
    "Wolf Cub": {"role":"Melee", "attack_distance_m":2.4, "attack_distance_map":43.636, "attack_interval":0.98},
    "Guardian": {"role":"Tank", "attack_distance_m":2.8, "attack_distance_map":50.909, "attack_interval":1.00},
    "Sprite": {"role":"Healer", "attack_distance_m":6.0, "attack_distance_map":109.091, "attack_interval":1.10},
    "Shadowcat": {"role":"Assassin", "attack_distance_m":3.0, "attack_distance_map":54.545, "attack_interval":0.72}
}

const MONSTER_DEFAULT:Dictionary = {"attack_distance_m":2.4, "attack_distance_map":43.636}
const MONSTER_RANGED:Dictionary = {"attack_distance_m":9.0, "attack_distance_map":163.636}
const MONSTER_BOSS:Dictionary = {"attack_distance_m":3.5, "attack_distance_map":63.636}

static func class_rule(hero:Dictionary)->Dictionary:
    var id:String = str(hero.get("class","Warrior"))
    return CLASS_RULES.get(id,CLASS_RULES["Warrior"])

static func class_engagement_map(hero:Dictionary)->float:
    return float(class_rule(hero).get("engagement_map",43.636))

static func class_engagement_m(hero:Dictionary)->float:
    return float(class_rule(hero).get("engagement_m",2.4))

static func class_attack_interval(hero:Dictionary)->float:
    var base:float=float(class_rule(hero).get("attack_interval",0.72))
    return ClassFormula.attack_interval(hero,base)

static func pet_rule(pet:Dictionary)->Dictionary:
    var species:String = str(pet.get("species",pet.get("name","Pet")))
    if PET_RULES.has(species):
        return PET_RULES[species]
    var role:String = str(pet.get("role","Melee"))
    if role=="Ranged" or role=="Caster" or role=="Healer":
        return PET_RULES["Sprite"] if role=="Healer" else PET_RULES["Falcon"]
    if role=="Assassin": return PET_RULES["Shadowcat"]
    if role=="Tank" or role=="Guardian": return PET_RULES["Guardian"]
    return PET_RULES["Wolf"]

static func pet_attack_distance_map(pet:Dictionary)->float:
    return float(pet_rule(pet).get("attack_distance_map",47.273))

static func pet_attack_distance_m(pet:Dictionary)->float:
    return float(pet_rule(pet).get("attack_distance_m",2.6))

static func pet_attack_interval(pet:Dictionary)->float:
    return float(pet_rule(pet).get("attack_interval",0.92))

static func monster_attack_distance(monster:Dictionary)->float:
    if bool(monster.get("mvp",false)):
        return float(MONSTER_BOSS["attack_distance_map"])
    if bool(monster.get("ranged",false)) or str(monster.get("attack_type","Melee"))=="Ranged":
        return float(MONSTER_RANGED["attack_distance_map"])
    return float(MONSTER_DEFAULT["attack_distance_map"])

static func snap_map_point(point:Vector2)->Vector2:
    return Vector2(round(point.x/GRID_SIZE)*GRID_SIZE,round(point.y/GRID_SIZE)*GRID_SIZE)

static func meters_to_map(meters:float)->float:
    return meters/WORLD_SCALE

static func map_to_meters(map_units:float)->float:
    return map_units*WORLD_SCALE
