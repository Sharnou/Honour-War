class_name LootSystem
extends RefCounted

const EventInventory = preload("res://scripts/EventInventorySystem.gd")

const DEFAULT_RULES := {"enabled":true,"auto_pick_items":true,"auto_pick_cards":true,"auto_pick_materials":true,"auto_pick_equipment":true,"auto_sell_junk":false,"auto_use_potions":false,"min_rarity":"Common","mvp_only_bonus_loot":true,"pet_picks_up":true}
const MVP_SUPER_CARD_DROP_RATE := 0.10
const MVP_GLOWING_ITEM_DROP_RATE := 0.10
const SUPER_CARDS := ["Super Orc Lord Card","Super Baphomet Card","Super Evil Druid Lord Card","Super Fire Dragon Card","Super Thanatos Card","Super Abyss Emperor Card"]
const GLOWING_MVP_ITEMS := ["Super War Emperor Blade","Super Astral Sovereign Staff","Super Celestial Longbow","Super Eternal Assassin Blade","Super Heaven Gate Mace","Super Arsenal Overlord Hammer","Glowing Aegis of Honour","Glowing War Emperor Armor","Glowing Celestial Wing Mantle","Glowing Celestial Crown"]
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
    if not hero.has("ground_loot") or not hero["ground_loot"] is Array: hero["ground_loot"]=[]
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
    var catalog:=ItemDatabase.all()
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
    ensure_state(hero); var catalog:=CardDatabase.all()
    if card_name=="" or not catalog.has(card_name): return false
    if not bool(hero["loot_rules"].get("auto_pick_cards",true)): return false
    if not accept(hero,str(catalog[card_name].get("rarity","Common"))): return false
    if hero["cards"].has(card_name): return false
    hero["cards"].append(card_name); hero["loot_stats"]["cards"]+=1
    if card_name in SUPER_CARDS: hero["loot_stats"]["super_cards"]+=1
    return true
static func collect_drop(hero:Dictionary,name:String,monster_name:String,rng:RandomNumberGenerator)->bool:
    ensure_state(hero)
    if CardDatabase.all().has(name):
        if is_enabled(hero): return add_card(hero,name)
        queue_ground(hero,name,"card",monster_name); return false
    if ItemDatabase.all().has(name):
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
    gained.append("%d XP" % hero_xp); gained.append("%d Zeny" % int(reward.get("zeny",0)))
    if int(xp_result.get("levels",0))>0: gained.append("Level %d" % int(xp_result.get("level",1)))
    return gained
