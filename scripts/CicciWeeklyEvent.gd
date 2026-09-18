class_name CicciWeeklyEvent
extends RefCounted

## Weekly endgame event boss. Cicci is a special event monster and may exceed
## the normal monster level cap without changing ordinary monster progression.
const BOSS_NAME:String = "Cicci"
const BOSS_LEVEL:int = 400
const WEEKLY_INTERVAL_SECONDS:int = 7 * 24 * 60 * 60
const MVP_RESPAWN_CAST_SECONDS:int = 120
const BOW_LEVEL:int = 1
const DROP_ITEM_COUNT:int = 50
const DROP_CARD_COUNT:int = 50
const DROP_CATEGORY:String = "GAME MASTER"

const MVP_POOL:Array[String] = [
    "Thanatos", "Ifrit", "Storm Empress", "Ancient Dragon", "Demon King",
    "Moon Tyrant", "Abyss Lord", "Celestial Guardian", "World Devourer"
]

static func monster_profile()->Dictionary:
    return {
        "name":BOSS_NAME,
        "level":BOSS_LEVEL,
        "power_level":400,
        "mvp":true,
        "event_boss":true,
        "weekly":true,
        "body_type":"Centaur",
        "body_geometry":"Four-legged equine lower body, humanoid torso and arms, exactly centaur anatomy",
        "weapon":{"name":"Cicci Bow","visual_level":BOW_LEVEL,"display_level":1},
        "combat_power":"Level 400",
        "normal_monster_level_cap_exempt":true,
        "respawn_skill":{"name":"MVP Resurrection","cast_time_seconds":MVP_RESPAWN_CAST_SECONDS,"summons_mvp":true}
    }

static func weekly_schedule(anchor_unix:int)->Dictionary:
    return {"interval_seconds":WEEKLY_INTERVAL_SECONDS,"anchor_unix":anchor_unix,"next_respawn_unix":anchor_unix + WEEKLY_INTERVAL_SECONDS,"event":"Cicci Weekly War"}

static func is_due(now_unix:int,last_respawn_unix:int)->bool:
    return now_unix >= last_respawn_unix + WEEKLY_INTERVAL_SECONDS

static func start_respawn_cast(now_unix:int)->Dictionary:
    return {"ok":true,"boss":BOSS_NAME,"skill":"MVP Resurrection","started_unix":now_unix,"cast_time_seconds":MVP_RESPAWN_CAST_SECONDS,"ready_unix":now_unix + MVP_RESPAWN_CAST_SECONDS}

static func finish_respawn_cast(now_unix:int,cast:Dictionary)->Dictionary:
    var ready_unix:int=int(cast.get("ready_unix",0))
    if now_unix < ready_unix:
        return {"ok":false,"remaining_seconds":ready_unix-now_unix,"boss":BOSS_NAME}
    var mvp:String=MVP_POOL[abs(now_unix) % MVP_POOL.size()]
    return {"ok":true,"boss":BOSS_NAME,"summoned_mvp":mvp,"spawned":true,"cast_time_seconds":MVP_RESPAWN_CAST_SECONDS}

static func drops()->Dictionary:
    var items:Array=[]
    var cards:Array=[]
    for i in range(DROP_ITEM_COUNT):
        items.append({"name":"GAME MASTER Equipment %02d" % (i+1),"category":DROP_CATEGORY,"slot":"Endgame","rarity":"GAME MASTER","drop_source":BOSS_NAME})
    for i in range(DROP_CARD_COUNT):
        cards.append({"name":"GAME MASTER Card %02d" % (i+1),"category":DROP_CATEGORY,"rarity":"GAME MASTER","drop_source":BOSS_NAME})
    return {"item_count":items.size(),"card_count":cards.size(),"items":items,"cards":cards,"category":DROP_CATEGORY,"boss":BOSS_NAME}

static func on_hit(now_unix:int)->Dictionary:
    return start_respawn_cast(now_unix)
