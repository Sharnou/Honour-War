class_name LootSystem
extends RefCounted

const EventInventory = preload("res://scripts/EventInventorySystem.gd")
const QuestSystem = preload("res://scripts/QuestSystem.gd")

const ItemDatabaseClass = preload("res://scripts/ItemDatabaseClass.gd")
const CardDatabaseClass = preload("res://scripts/CardDatabaseClass.gd")

const DEFAULT_RULES := {"enabled":true,"auto_pick_items":true,"auto_pick_cards":true,"auto_pick_materials":true,"auto_pick_equipment":true,"auto_sell_junk":false,"auto_use_potions":false,"min_rarity":"Common","mvp_only_bonus_loot":true,"pet_picks_up":true}
const MVP_SUPER_CARD_DROP_RATE := 0.10
const MVP_GLOWING_ITEM_DROP_RATE := 0.10
const SUPER_CARDS := ["Super Orc Lord Card","Super Baphomet Card","Super Evil Druid Lord Card","Super Fire Dragon Card","Super Thanatos Card","Super Abyss Emperor Card"]
const GLOWING_MVP_ITEMS := ["Super War Emperor Blade","Super Astral Sovereign Staff","Super Celestial Longbow","Super Eternal Assassin Blade","Super Heaven Gate Mace","Super Arsenal Overlord Hammer","Glowing Aegis of Honour","Glowing War Emperor Armor","Glowing Celestial Wing Mantle","Glowing Celestial Crown"]
const CLASS_ENDGAME_WEAPONS := {
    "Warrior":"Super War Emperor Blade",
    "Mage":"Super Astral Sovereign Staff",
    "Archer":"Super Celestial Longbow",
    "Thief":"Super Eternal Assassin Blade",
    "Acolyte":"Super Heaven Gate Mace",
    "Merchant":"Super Arsenal Overlord Hammer"
}
const CLASS_ENDGAME_CARDS := {
    "Warrior":"Super Baphomet Card",
    "Mage":"Super Evil Druid Lord Card",
    "Archer":"Super Fire Dragon Card",
    "Thief":"Super Thanatos Card",
    "Acolyte":"Super Abyss Emperor Card",
    "Merchant":"Super Orc Lord Card"
}
const ENDGAME_ARMOR := "Glowing War Emperor Armor"

const LootProgression=preload("res://scripts/LootProgressionSystem.gd")
const CharacterProgression=preload("res://scripts/CharacterProgressionSystem.gd")
const PetProgression=preload("res://scripts/PetProgressionSystem.gd")

static func ensure_state(hero:Dictionary)->void:
    if not hero.has("loot_rules") or not hero["loot_rules"] is Dictionary: hero["loot_rules"]=DEFAULT_RULES.duplicate(true)
    else:
        for key in DEFAULT_RULES.keys():
            if not hero["loot_rules"].has(key): hero["loot_rules"][key]=DEFAULT_RULES[key]
    if not hero.has("loot_stats") or not hero["loot_stats"] is Dictionary: hero["loot_stats"]={"items":0,"cards":0,"equipment":0,"materials":0,"zeny":0,"xp":0,"pet_xp":0,"mvp_chests":0,"super_cards":0,"glowing_items":0}
    else:
        for key in ["items","cards","equipment","materials","zeny","xp","pet_xp","mvp_chests","super_cards","glowing_items"]:
            if not hero["loot_stats"].has(key): hero["loot_stats"][key]=0
    if not hero.has("ground_loot") or not hero["ground_loot"] is Array: hero["ground_loot"]=[ ]
    if not hero.has("generated_equipment") or not hero["generated_equipment"] is Array: hero["generated_equipment"]=[]
    if not hero.has("generated_cards") or not hero["generated_cards"] is Array: hero["generated_cards"]=[]
    if not hero.has("zeny"): hero["zeny"]=0
    if not hero.has("cards") or not hero["cards"] is Array: hero["cards"]=[]

static func is_enabled(hero:Dictionary)->bool:
    ensure_state(hero); return bool(hero["loot_rules"].get("enabled",true))
static func set_enabled(hero:Dictionary,enabled:bool)->void:
    ensure_state(hero); hero["loot_rules"]["enabled"]=enabled
static func toggle(hero:Dictionary)->bool:
    set_enabled(hero,not is_enabled(hero)); return is_enabled(hero)
static func rarity_rank(rarity:String)->int:
    match rarity:
        "Common": return 1
        "Uncommon": return 2
        "Rare": return 3
        "Epic": return 4
        "Legendary": return 5
        "MVP": return 6
    return 0
static func accept(hero:Dictionary,rarity:String)->bool:
    ensure_state(hero); return rarity_rank(rarity)>=rarity_rank(str(hero["loot_rules"].get("min_rarity","Common")))
static func queue_ground(hero:Dictionary,name:String,kind:String,monster_name:String)->void:
    ensure_state(hero); hero["ground_loot"].append({"name":name,"kind":kind,"monster":monster_name,"time":Time.get_ticks_msec()})
static func add_item(hero:Dictionary,item_name:String,amount:int=1)->bool:
    ensure_state(hero)
    var catalog:=ItemDatabaseClass.all()
    if amount<=0 or not catalog.has(item_name): return false
    var data:Dictionary=catalog[item_name]; var item_type:String=str(data.get("type","")); var rarity:String=str(data.get("rarity","Common"))
    if item_type in ["Weapon","Armor","Accessory"] and not bool(hero["loot_rules"].get("auto_pick_equipment",true)): return false
    if item_type=="Crafting" and not bool(hero["loot_rules"].get("auto_pick_materials",true)): return false
    if item_type not in ["Weapon","Armor","Accessory","Crafting"] and not bool(hero["loot_rules"].get("auto_pick_items",true)): return false
    if not accept(hero,rarity): return false
    var inv:Dictionary=hero.get("inventory",{}); inv[item_name]=int(inv.get(item_name,0))+amount; hero["inventory"]=inv
    hero["loot_stats"]["items"]+=amount
    if item_type in ["Weapon","Armor","Accessory"]: hero["loot_stats"]["equipment"]+=amount
    if item_type=="Crafting": hero["loot_stats"]["materials"]+=amount
    if item_name=="MVP Treasure Chest": hero["loot_stats"]["mvp_chests"]+=amount
    if item_name in GLOWING_MVP_ITEMS: hero["loot_stats"]["glowing_items"]+=amount
    return true
static func add_material(hero:Dictionary,item_name:String,amount:int=1)->bool: return add_item(hero,item_name,amount)
static func add_card(hero:Dictionary,card_name:String)->bool:
    ensure_state(hero); var catalog:=CardDatabaseClass.all()
    if card_name=="" or not catalog.has(card_name): return false
    if not bool(hero["loot_rules"].get("auto_pick_cards",true)): return false
    if not accept(hero,str(catalog[card_name].get("rarity","Common"))): return false
    if hero["cards"].has(card_name): return false
    hero["cards"].append(card_name); hero["loot_stats"]["cards"]+=1
    if card_name in SUPER_CARDS: hero["loot_stats"]["super_cards"]+=1
    return true
static func collect_drop(hero:Dictionary,name:String,monster_name:String,rng:RandomNumberGenerator)->bool:
    ensure_state(hero)
    if CardDatabaseClass.all().has(name):
        if is_enabled(hero): return add_card(hero,name)
        queue_ground(hero,name,"card",monster_name); return false
    if ItemDatabaseClass.all().has(name):
        if is_enabled(hero): return add_item(hero,name,1)
        queue_ground(hero,name,"item",monster_name); return false
    return false
static func collect_ground(hero:Dictionary)->Array[String]:
    ensure_state(hero); var gained:Array[String]=[]; if not is_enabled(hero): return gained
    var remaining:Array=[]
    for drop in hero["ground_loot"]:
        if not drop is Dictionary: continue
        var drop_name:String=str(drop.get("name","")); var kind:String=str(drop.get("kind","item")); var ok:bool=add_card(hero,drop_name) if kind=="card" else add_item(hero,drop_name,1)
        if ok: gained.append(drop_name)
        else: remaining.append(drop)
    hero["ground_loot"]=remaining; return gained

static func _drop_rate_for_rarity(rarity:String, mvp:bool, equipment:bool)->float:
    match rarity:
        "Common": return 0.080 if equipment else 0.050
        "Uncommon": return 0.040 if equipment else 0.025
        "Rare": return 0.020 if equipment else 0.012
        "Epic": return 0.010 if equipment else 0.006
        "Legendary": return 0.004 if equipment else 0.002
        "MVP": return 0.001 if equipment else 0.0008
    return 0.0

static func _catalog_names_for_rarity(catalog:Dictionary, rarity:String, equipment:bool)->Array[String]:
    var names:Array[String]=[]
    for key:Variant in catalog.keys():
        var data:Dictionary=catalog[key]
        if str(data.get("rarity","Common")) != rarity:
            continue
        var item_type:String=str(data.get("type",""))
        var is_equipment:bool=item_type in ["Weapon","Armor","Accessory"]
        if is_equipment == equipment:
            names.append(str(key))
    return names

static func _random_catalog_name(catalog:Dictionary, rarity:String, equipment:bool, rng:RandomNumberGenerator)->String:
    var names:Array[String]=_catalog_names_for_rarity(catalog,rarity,equipment)
    if names.is_empty():
        return ""
    return names[rng.randi_range(0,names.size()-1)]

static func _add_generated_entry(hero:Dictionary, entry:Dictionary, kind:String)->bool:
    ensure_state(hero)
    if entry.is_empty():
        return false
    var name:String=str(entry.get("name",""))
    var rarity:String=str(entry.get("rarity","Rare"))
    if name.is_empty():
        return false
    if rarity != "GAME MASTER" and not accept(hero,rarity):
        return false
    if kind=="equipment":
        if not bool(hero["loot_rules"].get("auto_pick_equipment",true)):
            queue_ground(hero,name,"equipment",str(entry.get("source","Monster")))
            return false
        if not hero.has("generated_equipment") or not hero["generated_equipment"] is Array:
            hero["generated_equipment"]=[]
        hero["generated_equipment"].append(entry.duplicate(true))
        hero["loot_stats"]["items"]+=1
        hero["loot_stats"]["equipment"]+=1
        return true
    if not bool(hero["loot_rules"].get("auto_pick_cards",true)):
        queue_ground(hero,name,"card",str(entry.get("source","Monster")))
        return false
    if not hero.has("generated_cards") or not hero["generated_cards"] is Array:
        hero["generated_cards"]=[]
    hero["generated_cards"].append(entry.duplicate(true))
    hero["loot_stats"]["cards"]+=1
    return true

static func _roll_standard_drops(hero:Dictionary, monster:Dictionary, rng:RandomNumberGenerator, gained:Array[String])->void:
    var rarity:String=LootProgression.roll_rarity(int(monster.get("level",1)),bool(monster.get("mvp",false)),rng.randf())
    var equipment_catalog:Dictionary=ItemDatabaseClass.all()
    var card_catalog:Dictionary=CardDatabaseClass.all()
    var equipment_count:int=0
    var card_count:int=0
    var rate:float=LootProgression.effective_drop_rate_percent(_drop_rate_for_rarity(rarity,bool(monster.get("mvp",false)),true),hero)
    if rng.randf() < min(rate/100.0,1.0):
        var item_name:String=_random_catalog_name(equipment_catalog,rarity,true,rng)
        if not item_name.is_empty() and add_item(hero,item_name,1):
            gained.append(item_name)
            equipment_count+=1
    if equipment_count < LootProgression.MAX_EQUIPMENT_DROPS_PER_KILL and rng.randf() < min(rate/100.0,1.0):
        var second_name:String=_random_catalog_name(equipment_catalog,rarity,true,rng)
        if not second_name.is_empty() and add_item(hero,second_name,1):
            gained.append(second_name)
    var card_rate:float=LootProgression.effective_drop_rate_percent(_drop_rate_for_rarity(rarity,bool(monster.get("mvp",false)),false),hero)
    if rng.randf() < min(card_rate/100.0,1.0):
        var card_name:String=_random_catalog_name(card_catalog,rarity,false,rng)
        if not card_name.is_empty() and add_card(hero,card_name):
            gained.append(card_name)
            card_count+=1
    if card_count < LootProgression.MAX_CARD_DROPS_PER_KILL and rng.randf() < min(card_rate/100.0,1.0):
        var second_card:String=_random_catalog_name(card_catalog,rarity,false,rng)
        if not second_card.is_empty() and add_card(hero,second_card):
            gained.append(second_card)

static func _roll_top100_and_fifth_job(hero:Dictionary, monster:Dictionary, rng:RandomNumberGenerator, gained:Array[String])->void:
    var monster_level:int=int(monster.get("level",0))
    var eligible:bool=(monster_level >= 200) or bool(monster.get("mvp",false))
    if not eligible:
        return
    if rng.randf() < min(LootProgression.effective_drop_rate_percent(0.05,hero)/100.0,1.0):
        var rank:int=rng.randi_range(1,100)
        var entry:Dictionary=LootProgression.top_100_item_entry(rank)
        if _add_generated_entry(hero,entry,"equipment"):
            gained.append(str(entry.get("name","")))
    if rng.randf() < min(LootProgression.effective_drop_rate_percent(0.03,hero)/100.0,1.0):
        var rank_card:int=rng.randi_range(1,100)
        var card:Dictionary=LootProgression.top_100_card_entry(rank_card)
        if _add_generated_entry(hero,card,"card"):
            gained.append(str(card.get("name","")))
    var class_id:String=str(hero.get("class","Warrior"))
    var fifth:Dictionary=LootProgression.fifth_job_drop_table(monster,class_id)
    if bool(fifth.get("eligible",false)):
        for item:Dictionary in fifth.get("items",[]):
            if rng.randf() < min(LootProgression.effective_drop_rate_percent(float(item.get("drop_rate_percent",0.0)),hero)/100.0,1.0):
                if _add_generated_entry(hero,item,"equipment"):
                    gained.append(str(item.get("name","")))
                    break
        for card:Dictionary in fifth.get("cards",[]):
            if rng.randf() < min(LootProgression.effective_drop_rate_percent(float(card.get("drop_rate_percent",0.0)),hero)/100.0,1.0):
                if _add_generated_entry(hero,card,"card"):
                    gained.append(str(card.get("name","")))
                    break

static func _roll_cicci_rewards(hero:Dictionary, monster:Dictionary, rng:RandomNumberGenerator, gained:Array[String])->void:
    if str(monster.get("name","")) != "Cicci":
        return
    var equipment_drops:int=0
    for rank:int in range(1,51):
        if equipment_drops >= LootProgression.MAX_EQUIPMENT_DROPS_PER_KILL:
            break
        var roll:Dictionary=LootProgression.roll_cicci_equipment(rank,hero,rng.randf())
        if bool(roll.get("dropped",false)) and _add_generated_entry(hero,roll.get("entry",{}),"equipment"):
            gained.append(str(roll.get("entry",{}).get("name","")))
            equipment_drops+=1
    var card_drops:int=0
    for rank:int in range(1,51):
        if card_drops >= LootProgression.MAX_CARD_DROPS_PER_KILL:
            break
        var roll:Dictionary=LootProgression.roll_cicci_card(rank,hero,rng.randf())
        if bool(roll.get("dropped",false)) and _add_generated_entry(hero,roll.get("entry",{}),"card"):
            gained.append(str(roll.get("entry",{}).get("name","")))
            card_drops+=1

static func _grant_level_300_rewards(hero:Dictionary,gained:Array[String],rng:RandomNumberGenerator)->void:
    # A level-300 monster is the explicit endgame bridge: every such kill
    # awards a class-matched Super weapon, top-tier glowing armor, and a
    # Super card when autoloot is enabled. Duplicates are still allowed for
    # equipment but cards remain unique through add_card().
    var class_id:String=str(hero.get("class","Warrior"))
    var weapon:String=str(CLASS_ENDGAME_WEAPONS.get(class_id,CLASS_ENDGAME_WEAPONS["Warrior"]))
    var card:String=str(CLASS_ENDGAME_CARDS.get(class_id,CLASS_ENDGAME_CARDS["Warrior"]))
    var weapon_roll:Dictionary=LootProgression.roll_drop(0.10,hero,rng.randf())
    if bool(weapon_roll.get("dropped",false)) and add_item(hero,weapon,1): gained.append(weapon)
    var armor_roll:Dictionary=LootProgression.roll_drop(0.10,hero,rng.randf())
    if bool(armor_roll.get("dropped",false)) and add_item(hero,ENDGAME_ARMOR,1): gained.append(ENDGAME_ARMOR)
    var card_roll:Dictionary=LootProgression.roll_drop(0.10,hero,rng.randf())
    if bool(card_roll.get("dropped",false)) and add_card(hero,card): gained.append(card)

static func on_monster_defeated(hero:Dictionary,monster:Dictionary,rng:RandomNumberGenerator)->Array[String]:
    ensure_state(hero)
    if bool(monster.get("loot_processed",false)): return []
    monster["loot_processed"]=true
    var gained:Array[String]=[]
    var reward:Dictionary=LootProgression.resolve(monster,hero,rng.randf())
    var hero_xp:int=int(reward.get("xp",0)); var pet_xp:int=int(round(float(hero_xp)*0.75))
    var xp_result:Dictionary=CharacterProgression.grant_xp(hero,hero_xp)
    hero["zeny"]=int(hero.get("zeny",0))+int(reward.get("zeny",0)); hero["loot_stats"]["xp"]+=hero_xp; hero["loot_stats"]["zeny"]+=int(reward.get("zeny",0))
    if hero.get("pet",{}) is Dictionary:
        var pet:Dictionary=hero["pet"]; PetProgression.grant_xp(pet,pet_xp); hero["pet"]=pet; hero["loot_stats"]["pet_xp"]+=pet_xp
        pet["bond_xp"]=int(pet.get("bond_xp",0))+pet_xp; pet["loyalty"]=min(100,int(pet.get("loyalty",100))+1); EventInventory.record_event_progress(hero,"pet_bond",1)
    if bool(monster.get("mvp",false)): EventInventory.record_event_progress(hero,"mvp_hour",1)
    if str(monster.get("name",""))=="Bloody Knight": EventInventory.record_event_progress(hero,"blood_moon",1)
    var quest_changes:Array[String]=QuestSystem.record_kill(hero,monster)
    for quest_id:String in quest_changes:
        var summary:Dictionary=QuestSystem.progress_summary(hero,quest_id)
        var quest_name:String=str(summary.get("name",quest_id))
        gained.append("Quest progress: %s" % quest_name)
        if bool(summary.get("complete",false)):
            gained.append("Quest complete: %s" % quest_name)
    gained.append("%d XP" % hero_xp); gained.append("%d Zeny" % int(reward.get("zeny",0)))
    if int(xp_result.get("levels",0))>0: gained.append("Level %d" % int(xp_result.get("level",1)))
    _roll_standard_drops(hero,monster,rng,gained)
    _roll_top100_and_fifth_job(hero,monster,rng,gained)
    _roll_cicci_rewards(hero,monster,rng,gained)
    if int(monster.get("level",0))>=300:
        _grant_level_300_rewards(hero,gained,rng)
    return gained
