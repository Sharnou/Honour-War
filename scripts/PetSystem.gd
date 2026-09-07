class_name PetSystem
extends RefCounted

const MAX_PET_LEVEL := 100
const PETS := {
	"Warrior": {"name":"War Wolf", "role":"Tank", "species":"Dire Wolf", "base_power":14, "skill":"Howl of Courage", "skill_power":22, "color":"#c8a27a"},
	"Mage": {"name":"Arcane Sprite", "role":"Support Caster", "species":"Astral Sprite", "base_power":12, "skill":"Mana Burst", "skill_power":28, "color":"#c29cff"},
	"Archer": {"name":"Falcon", "role":"Ranged Striker", "species":"Royal Falcon", "base_power":16, "skill":"Falcon Assault", "skill_power":30, "color":"#d8c48b"},
	"Thief": {"name":"Shadow Cat", "role":"Assassin", "species":"Night Panther", "base_power":17, "skill":"Shadow Pounce", "skill_power":32, "color":"#9b7abf"},
	"Acolyte": {"name":"Holy Poring", "role":"Healer", "species":"Blessed Poring", "base_power":10, "skill":"Holy Mend", "skill_power":20, "color":"#f6e7a4"},
	"Merchant": {"name":"Iron Beetle", "role":"Guardian", "species":"Iron Beetle", "base_power":15, "skill":"Iron Charge", "skill_power":27, "color":"#82b7c9"}
}

static func definition(class_name:String) -> Dictionary:
	return PETS.get(class_name, PETS["Warrior"])

static func new_pet(class_name:String) -> Dictionary:
	var d:Dictionary=definition(class_name)
	return {
		"name":d["name"], "role":d["role"], "species":d["species"], "level":1, "exp":0,
		"hp":60, "max_hp":60, "sp":30, "max_sp":30, "skills":[d["skill"]], "skill_points":0,
		"skill_level":1, "skill_uses":0, "refine":0, "inventory":{},
		"materials":{"Phracon":3,"Emveretarcon":1,"Oridecon":0},
		"equipment":{"weapon":d["species"]+" Claw", "armor":"Pet Guard Harness"},
		"kills":0
	}

static func exp_to_next(level:int) -> int:
	return max(80, level * 90)

static func power(pet:Dictionary)->int:
	var d:Dictionary=definition(str(pet.get("owner_class","Warrior")))
	return int(d["base_power"])+int(pet.get("level",1))*2+int(pet.get("refine",0))*2

static func skill_power(pet:Dictionary)->int:
	var d:Dictionary=definition(str(pet.get("owner_class","Warrior")))
	return int(d["skill_power"])+int(pet.get("level",1))*2+int(pet.get("skill_level",1))*5+int(pet.get("refine",0))*2

static func heal_power(pet:Dictionary)->int:
	return 10+int(pet.get("level",1))*2+int(pet.get("skill_level",1))*4

static func add_exp(pet:Dictionary, amount:int)->bool:
	var leveled:=false
	if int(pet.get("level",1))>=MAX_PET_LEVEL:
		pet["exp"]=0
		return false
	pet["exp"]+=amount
	while int(pet["level"])<MAX_PET_LEVEL and int(pet["exp"])>=exp_to_next(int(pet["level"])):
		pet["exp"]-=exp_to_next(int(pet["level"]))
		pet["level"]+=1
		pet["max_hp"]+=7
		pet["hp"]=pet["max_hp"]
		pet["max_sp"]+=3
		pet["sp"]=pet["max_sp"]
		pet["skill_points"]+=1
		if int(pet["level"])%10==0:
			pet["skill_level"]+=1
		leveled=true
	return leveled

static func role_description(role:String)->String:
	match role:
		"Tank": return "Absorbs pressure and protects the hero."
		"Support Caster": return "Adds magical damage and utility."
		"Ranged Striker": return "Attacks from range and excels at finishing targets."
		"Assassin": return "High burst damage with critical-style attacks."
		"Healer": return "Automatically restores the hero during combat."
		"Guardian": return "Steady damage with defensive utility."
	return "Fights beside the hero automatically."

static func refine_material(level:int)->String:
	if level<4: return "Phracon"
	if level<8: return "Emveretarcon"
	return "Oridecon"
