class_name SkillSystem
extends RefCounted

const MAX_SKILL_LEVEL := 10
const MAX_SKILL_POINTS := 250

static func trees() -> Dictionary:
	return {
		"Warrior":[s("war_power_slash","Power Slash",1,1,10,1,[],"active",35,8,1.0,"Heavy sword strike."),s("war_berserker","Berserker Heart",1,1,10,10,["war_power_slash"],"passive",12,0,0.0,"Raises physical power as health falls."),s("war_whirlwind","Crimson Whirlwind",2,2,10,25,["war_power_slash"],"active",70,16,3.0,"Spins through nearby enemies."),s("war_guardian_roar","Guardian Roar",2,2,10,30,["war_berserker"],"active",20,14,6.0,"Taunts enemies and strengthens defense."),s("war_earthbreaker","Earthbreaker",3,3,10,50,["war_whirlwind"],"active",130,24,5.0,"Smashes the ground with massive force."),s("war_blood_fury","Blood Fury",3,3,10,70,["war_berserker"],"passive",25,0,0.0,"Converts critical health into greater damage."),s("war_emperors_judgment","Emperor's Judgment",4,4,10,100,["war_earthbreaker"],"active",250,38,10.0,"A devastating royal execution strike."),s("war_immortal_arsenal","Immortal Arsenal",5,5,10,200,["war_emperors_judgment","war_blood_fury"],"ultimate",500,70,30.0,"Ultimate sword technique that shatters enemy defenses.")],
		"Mage":[s("mage_arcane_spark","Arcane Spark",1,1,10,1,[],"active",42,10,1.2,"Fast elemental bolt."),s("mage_mana_mastery","Mana Mastery",1,1,10,10,[],"passive",15,0,0.0,"Increases maximum SP and magic power."),s("mage_comet","Starfall Comet",2,2,10,25,["mage_arcane_spark"],"active",90,22,3.0,"Calls a burning comet onto the target area."),s("mage_frost_prison","Frost Prison",2,2,10,30,["mage_mana_mastery"],"active",65,18,5.0,"Freezes enemies and reduces their movement."),s("mage_void_lance","Void Lance",3,3,10,50,["mage_comet"],"active",150,30,5.0,"Pierces defenses with condensed void energy."),s("mage_meteor_surge","Meteor Surge",3,3,10,70,["mage_comet"],"active",210,42,8.0,"Multiple meteors strike the battlefield."),s("mage_arcane_overload","Arcane Overload",4,4,10,100,["mage_void_lance","mage_meteor_surge"],"active",330,55,12.0,"Overloads the battlefield with raw magic."),s("mage_astral_apocalypse","Astral Apocalypse",5,5,10,200,["mage_arcane_overload"],"ultimate",650,90,35.0,"Ultimate celestial spell that devastates a large area.")],
		"Archer":[s("arch_celestial_arrow","Celestial Arrow",1,1,10,1,[],"active",45,8,1.0,"Precise long-range shot."),s("arch_eagle_eye","Eagle Eye",1,1,10,10,[],"passive",18,0,0.0,"Improves range and critical chance."),s("arch_double_shot","Twin Arrow",2,2,10,25,["arch_celestial_arrow"],"active",82,15,2.5,"Fires two empowered arrows."),s("arch_trap","Thunder Snare",2,2,10,30,["arch_eagle_eye"],"active",70,18,5.0,"Deploys a lightning trap."),s("arch_hawk_storm","Hawk Storm",3,3,10,50,["arch_double_shot"],"active",145,28,5.0,"A storm of arrows rains over enemies."),s("arch_deadeye","Deadeye",3,3,10,70,["arch_eagle_eye"],"passive",30,0,0.0,"Greatly improves critical damage."),s("arch_skybreaker","Skybreaker Shot",4,4,10,100,["arch_hawk_storm","arch_deadeye"],"active",360,52,12.0,"A piercing shot that tears through armor."),s("arch_celestial_barrage","Celestial Barrage",5,5,10,200,["arch_skybreaker"],"ultimate",700,88,35.0,"Ultimate arrow rain guided by the Falcon.")],
		"Thief":[s("thief_shadow_strike","Shadow Strike",1,1,10,1,[],"active",48,8,1.0,"Fast stealth strike."),s("thief_poison_edge","Venom Edge",1,1,10,10,[],"passive",16,0,0.0,"Adds poison pressure and damage over time."),s("thief_blade_flurry","Blade Flurry",2,2,10,25,["thief_shadow_strike"],"active",95,16,2.5,"Rapid multi-hit dagger assault."),s("thief_smoke","Phantom Smoke",2,2,10,30,["thief_poison_edge"],"active",45,18,6.0,"Creates a smoke field and evasion window."),s("thief_execution","Night Execution",3,3,10,50,["thief_blade_flurry"],"active",170,30,5.0,"Deals extreme damage to weakened enemies."),s("thief_assassin_instinct","Assassin Instinct",3,3,10,70,["thief_poison_edge"],"passive",28,0,0.0,"Raises critical rate and burst damage."),s("thief_shadow_requiem","Shadow Requiem",4,4,10,100,["thief_execution","thief_assassin_instinct"],"active",380,55,12.0,"A sequence of lethal shadow strikes."),s("thief_eternal_assassin","Eternal Assassin",5,5,10,200,["thief_shadow_requiem"],"ultimate",760,92,35.0,"Ultimate assassination technique that ignores part of enemy defense.")],
		"Acolyte":[s("aco_holy_pulse","Holy Pulse",1,1,10,1,[],"active",38,9,1.0,"Holy damage against enemies."),s("aco_divine_grace","Divine Grace",1,1,10,10,[],"passive",18,0,0.0,"Improves healing and survivability."),s("aco_sanctuary","Sanctuary",2,2,10,25,["aco_divine_grace"],"active",85,20,4.0,"Creates a healing sanctuary."),s("aco_holy_nova","Holy Nova",2,2,10,30,["aco_holy_pulse"],"active",95,22,3.0,"Explodes holy energy around the hero."),s("aco_seraphic_light","Seraphic Light",3,3,10,50,["aco_sanctuary"],"active",155,30,5.0,"Damages foes and heals allies."),s("aco_blessing","Greater Blessing",3,3,10,70,["aco_divine_grace"],"passive",30,0,0.0,"Improves hero and pet recovery."),s("aco_judgment","Divine Judgment",4,4,10,100,["aco_holy_nova","aco_seraphic_light"],"active",340,52,12.0,"Calls divine judgment onto enemies."),s("aco_heaven_gate","Heaven's Gate",5,5,10,200,["aco_judgment","aco_blessing"],"ultimate",620,86,35.0,"Ultimate holy miracle that damages foes and restores the party.")],
		"Merchant":[s("mer_forge_smash","Forge Smash",1,1,10,1,[],"active",40,9,1.0,"Heavy hammer attack."),s("mer_overcharge","Overcharge",1,1,10,10,[],"passive",15,0,0.0,"Improves economic power and item efficiency."),s("mer_cart_impact","Cart Impact",2,2,10,25,["mer_forge_smash"],"active",88,17,2.5,"Charges with a reinforced cart."),s("mer_fortify","Steel Fortify",2,2,10,30,["mer_overcharge"],"active",25,16,7.0,"Greatly increases defensive strength."),s("mer_magma_forge","Magma Forge",3,3,10,50,["mer_cart_impact"],"active",145,29,5.0,"Superheated hammer strike."),s("mer_master_crafter","Master Crafter",3,3,10,70,["mer_overcharge"],"passive",28,0,0.0,"Improves refinement and crafting effectiveness."),s("mer_titan_cart","Titan Cart",4,4,10,100,["mer_magma_forge","mer_fortify"],"active",350,50,12.0,"Summons a devastating armored cart charge."),s("mer_arsenal_overlord","Arsenal Overlord",5,5,10,200,["mer_titan_cart","mer_master_crafter"],"ultimate",680,84,35.0,"Ultimate forge technique that empowers hero and pet equipment.")]
	}

static func s(id:String,name:String,tier:int,cost:int,max_level:int,required_level:int,requires:Array,kind:String,power:int,sp_cost:int,cooldown:float,description:String)->Dictionary:
	return {"id":id,"name":name,"tier":tier,"cost":cost,"max_level":max_level,"required_level":required_level,"requires":requires,"kind":kind,"power":power,"sp_cost":sp_cost,"cooldown":cooldown,"description":description}
static func all_skills(class_id:String)->Array: return trees().get(class_id,trees()["Warrior"])
static func skill_map(class_id:String)->Dictionary:
	var result:Dictionary={}
	for skill in all_skills(class_id): result[skill["id"]]=skill
	return result
static func ensure_state(hero:Dictionary)->void:
	if not hero.has("skill_levels"): hero["skill_levels"]={}
	if not hero.has("skill_points"): hero["skill_points"]=max(0,int(hero.get("level",1))-1)
	if not hero.has("skill_cooldowns"): hero["skill_cooldowns"]={}
	var valid:=skill_map(str(hero.get("class","Warrior")))
	for id in valid.keys():
		if not hero["skill_levels"].has(id): hero["skill_levels"][id]=0
	var basic_id:=str(valid.keys()[0])
	if int(hero["skill_levels"].get(basic_id,0))<1: hero["skill_levels"][basic_id]=1
static func can_learn(hero:Dictionary,skill_id:String)->bool:
	ensure_state(hero); var skills:=skill_map(str(hero.get("class","Warrior")))
	if not skills.has(skill_id): return false
	var skill:Dictionary=skills[skill_id]; var current:=int(hero["skill_levels"].get(skill_id,0))
	if current>=int(skill["max_level"]) or int(hero.get("level",1))<int(skill["required_level"]) or int(hero.get("skill_points",0))<int(skill["cost"]): return false
	for req in skill["requires"]:
		if int(hero["skill_levels"].get(req,0))<1: return false
	return true
static func learn(hero:Dictionary,skill_id:String)->bool:
	if not can_learn(hero,skill_id): return false
	var skill:=skill_map(str(hero.get("class","Warrior")))[skill_id]
	hero["skill_points"]-=int(skill["cost"]); hero["skill_levels"][skill_id]=int(hero["skill_levels"].get(skill_id,0))+1
	return true
static func skill_level(hero:Dictionary,skill_id:String)->int:
	ensure_state(hero); return int(hero["skill_levels"].get(skill_id,0))
static func power(hero:Dictionary,skill_id:String)->int:
	var skills:=skill_map(str(hero.get("class","Warrior")))
	if not skills.has(skill_id): return 0
	var skill:Dictionary=skills[skill_id]; var level:=skill_level(hero,skill_id)
	return int(skill["power"])+max(0,level-1)*int(skill["power"])/3
static func sp_cost(hero:Dictionary,skill_id:String)->int:
	var skills:=skill_map(str(hero.get("class","Warrior")))
	if not skills.has(skill_id): return 0
	return int(skills[skill_id]["sp_cost"])+max(0,skill_level(hero,skill_id)-1)*2
static func is_ready(hero:Dictionary,skill_id:String,now:float)->bool: return float(hero.get("skill_cooldowns",{}).get(skill_id,0.0))<=now
static func use(hero:Dictionary,skill_id:String,now:float)->Dictionary:
	ensure_state(hero); var skills:=skill_map(str(hero.get("class","Warrior")))
	if not skills.has(skill_id) or skill_level(hero,skill_id)<=0: return {"ok":false,"reason":"locked"}
	if not is_ready(hero,skill_id,now): return {"ok":false,"reason":"cooldown"}
	var cost:=sp_cost(hero,skill_id)
	if int(hero.get("sp",0))<cost: return {"ok":false,"reason":"sp"}
	hero["sp"]-=cost; hero["skill_cooldowns"][skill_id]=now+float(skills[skill_id]["cooldown"])
	return {"ok":true,"skill":skills[skill_id],"level":skill_level(hero,skill_id),"power":power(hero,skill_id),"sp_cost":cost}
static func passive_power_bonus(hero:Dictionary)->int:
	var total:=0
	for skill in all_skills(str(hero.get("class","Warrior"))):
		if skill["kind"]=="passive": total+=skill_level(hero,skill["id"])*int(skill["power"])/5
	return total
