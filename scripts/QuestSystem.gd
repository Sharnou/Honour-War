class_name QuestSystem
extends RefCounted

## Persistent PvE quest system for Honour War.
## Quest state lives on the player and is safe to process from either offline
## gameplay or the server-authoritative action layer.

const MAX_ACTIVE_QUESTS:int = 3
const ITEM_CATALOG = preload("res://scripts/ItemDatabase.gd")
const CARD_CATALOG = preload("res://scripts/CardDatabase.gd")
const PROGRESSION = preload("res://scripts/CharacterProgressionSystem.gd")

const QUESTS:Dictionary = {
    "first_hunt": {
        "name":"First Hunt",
        "level_req":1,
        "description":"Defeat the Poring family threatening the starter roads.",
        "objectives":{"Poring":5},
        "reward_xp":250,
        "reward_zeny":500,
        "items":{"Red Potion":5},
        "cards":["Poring Card"]
    },
    "wolf_scout": {
        "name":"Wolf Scout",
        "level_req":10,
        "description":"Push back the wolves and secure the field approaches.",
        "objectives":{"Wolf":8},
        "reward_xp":900,
        "reward_zeny":1800,
        "items":{"Orange Potion":4,"Wolf Claw":4},
        "cards":["Wolf Card"]
    },
    "goblin_threat": {
        "name":"Goblin Threat",
        "level_req":20,
        "description":"Break the goblin assault before it reaches the towns.",
        "objectives":{"Goblin":10},
        "reward_xp":1800,
        "reward_zeny":3500,
        "items":{"Iron Ore":8,"Phracon":3},
        "cards":["Goblin Card"]
    },
    "undead_purge": {
        "name":"Undead Purge",
        "level_req":35,
        "description":"Cleanse the undead infestation from the dungeon approaches.",
        "objectives":{"Skeleton":8,"Zombie":8},
        "reward_xp":4200,
        "reward_zeny":8000,
        "items":{"Skeleton Bone":8,"Rotten Bone":8,"Emveretarcon":2},
        "cards":["Skeleton Card","Zombie Card"]
    },
    "orc_breakthrough": {
        "name":"Orc Breakthrough",
        "level_req":50,
        "description":"Defeat the brutal Orc and Golem guard line.",
        "objectives":{"Orc":8,"Golem":3},
        "reward_xp":8500,
        "reward_zeny":16000,
        "items":{"Orc Tusk":8,"Golem Core":3,"Oridecon":1},
        "cards":["Orc Card","Golem Card"]
    },
    "dungeon_clearing": {
        "name":"Deep Dungeon Clearing",
        "level_req":80,
        "description":"Clear the Mantis and Evil Druid packs from the deep dungeon.",
        "objectives":{"Mantis":10,"Evil Druid":5},
        "reward_xp":18000,
        "reward_zeny":32000,
        "items":{"Mantis Shell":10,"Druid Relic":5,"Emveretarcon":3,"Oridecon":1},
        "cards":["Mantis Card","Evil Druid Card"]
    },
    "dragon_vanguard": {
        "name":"Dragon Vanguard",
        "level_req":120,
        "description":"Break the dragon vanguard and collect its scales.",
        "objectives":{"Dragon":3},
        "reward_xp":42000,
        "reward_zeny":80000,
        "items":{"Dragon Scale":6,"Oridecon":3},
        "cards":["Dragon Card"]
    },
    "blood_knight_bounty": {
        "name":"Blood Knight Bounty",
        "level_req":180,
        "description":"Hunt the Bloody Knight and recover blood-forged relics.",
        "objectives":{"Bloody Knight":3},
        "reward_xp":90000,
        "reward_zeny":180000,
        "items":{"Blood Shard":6,"Cursed Armor Fragment":3,"Oridecon":5},
        "cards":["Bloody Knight Card"]
    },
    "endgame_mvp_hunt": {
        "name":"Endgame MVP Hunt",
        "level_req":200,
        "description":"Prove yourself against the highest-tier field bosses.",
        "objectives":{"Dragon":5,"Bloody Knight":5},
        "reward_xp":150000,
        "reward_zeny":300000,
        "items":{"MVP Treasure Chest":1,"Boss Soul Shard":2,"Ancient Dragon Heart":1,"Oridecon":8},
        "cards":["Dragon Card","Bloody Knight Card"]
    }
}

static func ensure_state(hero:Dictionary)->void:
    if not hero.has("quest_progress") or not hero["quest_progress"] is Dictionary:
        hero["quest_progress"]={}
    if not hero.has("quests_completed") or not hero["quests_completed"] is Array:
        hero["quests_completed"]=[]
    for quest_id:String in hero["quest_progress"].keys():
        var state:Variant=hero["quest_progress"][quest_id]
        if not state is Dictionary:
            hero["quest_progress"].erase(quest_id)
            continue
        var definition:Dictionary=QUESTS.get(quest_id,{})
        if definition.is_empty():
            hero["quest_progress"].erase(quest_id)
            continue
        _normalize_progress_state(state,definition)

static func _normalize_progress_state(state:Dictionary,definition:Dictionary)->void:
    if not state.has("accepted"): state["accepted"]=true
    if not state.has("claimed"): state["claimed"]=false
    if not state.has("progress") or not state["progress"] is Dictionary: state["progress"]={}
    var objectives:Dictionary=definition.get("objectives",{})
    for target:String in objectives.keys():
        state["progress"][target]=clampi(int(state["progress"].get(target,0)),0,int(objectives[target]))

static func definition(quest_id:String)->Dictionary:
    var data:Variant=QUESTS.get(quest_id,{})
    return data.duplicate(true) if data is Dictionary else {}

static func all_quests()->Array[Dictionary]:
    var result:Array[Dictionary]=[]
    for quest_id:String in QUESTS.keys():
        var item:Dictionary=definition(quest_id)
        item["id"]=quest_id
        result.append(item)
    return result

static func active_quests(hero:Dictionary)->Array[String]:
    ensure_state(hero)
    var result:Array[String]=[]
    for quest_id:String in hero["quest_progress"].keys():
        var state:Dictionary=hero["quest_progress"][quest_id]
        if bool(state.get("accepted",false)) and not bool(state.get("claimed",false)):
            result.append(quest_id)
    return result

static func available_quests(hero:Dictionary)->Array[Dictionary]:
    ensure_state(hero)
    var level:int=int(hero.get("level",1))
    var active:int=active_quests(hero).size()
    var result:Array[Dictionary]=[]
    for quest_id:String in QUESTS.keys():
        if hero["quests_completed"].has(quest_id):
            continue
        if hero["quest_progress"].has(quest_id):
            continue
        var item:Dictionary=definition(quest_id)
        var row:Dictionary={"id":quest_id,"name":str(item.get("name",quest_id)),"level_req":int(item.get("level_req",1)),"description":str(item.get("description","")),"available":level>=int(item.get("level_req",1)) and active<MAX_ACTIVE_QUESTS}
        result.append(row)
    return result

static func can_accept(hero:Dictionary,quest_id:String)->bool:
    ensure_state(hero)
    if not QUESTS.has(quest_id): return false
    if hero["quests_completed"].has(quest_id): return false
    if hero["quest_progress"].has(quest_id): return false
    if active_quests(hero).size()>=MAX_ACTIVE_QUESTS: return false
    return int(hero.get("level",1))>=int(QUESTS[quest_id].get("level_req",1))

static func accept_quest(hero:Dictionary,quest_id:String)->bool:
    if not can_accept(hero,quest_id): return false
    var definition_data:Dictionary=QUESTS[quest_id]
    var progress:Dictionary={}
    for target:String in definition_data.get("objectives",{}).keys():
        progress[target]=0
    hero["quest_progress"][quest_id]={"accepted":true,"claimed":false,"progress":progress,"accepted_level":int(hero.get("level",1)),"accepted_at":Time.get_unix_time_from_system()}
    return true

static func record_kill(hero:Dictionary,monster:Dictionary)->Array[String]:
    ensure_state(hero)
    var monster_name:String=str(monster.get("name",""))
    if monster_name.is_empty(): return []
    var changed:Array[String]=[]
    for quest_id:String in active_quests(hero):
        var state:Dictionary=hero["quest_progress"][quest_id]
        var definition_data:Dictionary=QUESTS[quest_id]
        var objectives:Dictionary=definition_data.get("objectives",{})
        if not objectives.has(monster_name):
            continue
        var before:int=int(state["progress"].get(monster_name,0))
        var after:int=min(int(objectives[monster_name]),before+1)
        if after!=before:
            state["progress"][monster_name]=after
            changed.append(quest_id)
        if _is_complete_state(state,definition_data):
            state["completed_at"]=Time.get_unix_time_from_system()
    return changed

static func is_complete(hero:Dictionary,quest_id:String)->bool:
    ensure_state(hero)
    if not hero["quest_progress"].has(quest_id): return false
    var state:Dictionary=hero["quest_progress"][quest_id]
    var definition_data:Dictionary=QUESTS.get(quest_id,{})
    if definition_data.is_empty(): return false
    return _is_complete_state(state,definition_data)

static func _is_complete_state(state:Dictionary,definition_data:Dictionary)->bool:
    var objectives:Dictionary=definition_data.get("objectives",{})
    for target:String in objectives.keys():
        if int(state.get("progress",{}).get(target,0))<int(objectives[target]):
            return false
    return true

static func progress_summary(hero:Dictionary,quest_id:String)->Dictionary:
    ensure_state(hero)
    var definition_data:Dictionary=QUESTS.get(quest_id,{})
    var state:Dictionary=hero["quest_progress"].get(quest_id,{})
    if definition_data.is_empty(): return {}
    var objectives:Array[Dictionary]=[]
    for target:String in definition_data.get("objectives",{}).keys():
        objectives.append({"target":target,"current":int(state.get("progress",{}).get(target,0)),"required":int(definition_data["objectives"][target])})
    return {"id":quest_id,"name":str(definition_data.get("name",quest_id)),"description":str(definition_data.get("description","")),"level_req":int(definition_data.get("level_req",1)),"objectives":objectives,"complete":_is_complete_state(state,definition_data),"claimed":bool(state.get("claimed",false))}

static func claim_quest(hero:Dictionary,quest_id:String)->Dictionary:
    ensure_state(hero)
    if not is_complete(hero,quest_id): return {"ok":false,"reason":"not_complete","quest_id":quest_id}
    if hero["quests_completed"].has(quest_id): return {"ok":false,"reason":"already_claimed","quest_id":quest_id}
    var definition_data:Dictionary=QUESTS.get(quest_id,{})
    if definition_data.is_empty(): return {"ok":false,"reason":"quest_not_found","quest_id":quest_id}

    var awarded:Array[String]=[]
    var reward_xp:int=int(definition_data.get("reward_xp",0))
    var reward_zeny:int=int(definition_data.get("reward_zeny",0))
    if reward_xp>0:
        var xp_result:Dictionary=PROGRESSION.grant_xp(hero,reward_xp)
        awarded.append("%d XP" % reward_xp)
        if int(xp_result.get("levels",0))>0:
            awarded.append("Level %d" % int(xp_result.get("level",hero.get("level",1))))
    hero["zeny"]=int(hero.get("zeny",0))+reward_zeny
    if reward_zeny>0: awarded.append("%d Zeny" % reward_zeny)

    var items:Array=definition_data.get("items",{}).keys()
    for item_name:String in items:
        var amount:int=int(definition_data["items"][item_name])
        if _add_item_direct(hero,item_name,amount):
            awarded.append("%s x%d" % [item_name,amount])
    for card_name:String in definition_data.get("cards",[]):
        if _add_card_direct(hero,card_name):
            awarded.append(card_name)

    var state:Dictionary=hero["quest_progress"][quest_id]
    state["claimed"]=true
    state["claimed_at"]=Time.get_unix_time_from_system()
    hero["quest_progress"][quest_id]=state
    hero["quests_completed"].append(quest_id)
    return {"ok":true,"reason":"claimed","quest_id":quest_id,"name":str(definition_data.get("name",quest_id)),"rewards":awarded}

static func abandon_quest(hero:Dictionary,quest_id:String)->bool:
    ensure_state(hero)
    if not hero["quest_progress"].has(quest_id): return false
    if hero["quests_completed"].has(quest_id): return false
    hero["quest_progress"].erase(quest_id)
    return true

static func _add_item_direct(hero:Dictionary,item_name:String,amount:int)->bool:
    if amount<=0 or not ITEM_CATALOG.all().has(item_name): return false
    if not hero.has("inventory") or not hero["inventory"] is Dictionary: hero["inventory"]={}
    hero["inventory"][item_name]=int(hero["inventory"].get(item_name,0))+amount
    return true

static func _add_card_direct(hero:Dictionary,card_name:String)->bool:
    if card_name.is_empty() or not CARD_CATALOG.all().has(card_name): return false
    if not hero.has("cards") or not hero["cards"] is Array: hero["cards"]=[]
    if hero["cards"].has(card_name): return false
    hero["cards"].append(card_name)
    return true
