extends SceneTree

const ElementSystem=preload("res://scripts/ElementSystem.gd")

func _init()->void:
	var expected:Array[String]=["Neutral","Fire","Water","Earth","Wind","Holy","Shadow","Undead","Poison","Ghost"]
	for element in expected:
		assert(ElementSystem.is_valid(element), "Missing element: %s" % element)
	assert(ElementSystem.weakness("Fire")=="Water")
	assert(ElementSystem.weakness("Water")=="Wind")
	assert(ElementSystem.weakness("Earth")=="Fire")
	assert(ElementSystem.weakness("Wind")=="Earth")
	assert(ElementSystem.weakness("Holy")=="Shadow")
	assert(ElementSystem.weakness("Shadow")=="Holy")
	assert(ElementSystem.weakness("Undead")=="Holy")
	assert(ElementSystem.weakness("Poison")=="Fire")
	assert(ElementSystem.attack_multiplier("Water","Fire")>1.0)
	assert(ElementSystem.attack_multiplier("Fire","Fire")<1.0)
	assert(ElementSystem.attack_multiplier("Holy","Undead")>=1.40)
	assert(ElementSystem.attack_multiplier("Neutral","Ghost")==0.0)
	var materials:Dictionary=ElementSystem.material_catalogue()
	for element in ["Fire","Water","Earth","Wind","Holy","Shadow"]:
		assert(materials.has(element), "Missing material contract: %s" % element)
		assert(str(materials[element].get("catalyst",""))!="", "Missing catalyst: %s" % element)
		assert(str(materials[element].get("converter",""))!="", "Missing converter: %s" % element)
	assert(not ElementSystem.validate_material("Unknown Material"))
	var hero:Dictionary={"class":"Warrior","inventory":{"Flame Heart":1}}
	var crafted:Dictionary=ElementSystem.craft_converter(hero,"Fire",1)
	assert(bool(crafted.get("ok",false)), "Fire converter crafting failed")
	assert(int(hero["inventory"].get("Flame Heart",0))==0)
	assert(int(hero["inventory"].get("Fire Converter",0))==1)
	var applied:Dictionary=ElementSystem.apply_converter(hero,"Fire")
	assert(bool(applied.get("ok",false)), "Fire converter application failed")
	assert(ElementSystem.active_weapon_element(hero)=="Fire")
	print("ELEMENT_SYSTEM_QA: PASS")
	quit(0)
