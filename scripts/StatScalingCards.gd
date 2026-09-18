class_name StatScalingCards
extends RefCounted

## Honour War stat-scaling card rules.
## These cards use PURE BASE STATS only: manually invested base stats.
## Job levels, temporary buffs, equipment bonuses and other derived bonuses
## are intentionally excluded from the source-stat calculation.
const RATIO:int=18

const CARDS:Array = [
    {"name":"Ancient Mimic Card","bonus_stat":"AGI","source_stat":"LUK","ratio":18,"slot":"armor"},
    {"name":"Clock Card","bonus_stat":"INT","source_stat":"LUK","ratio":18,"slot":"armor"},
    {"name":"Tamruan Card","bonus_stat":"STR","source_stat":"LUK","ratio":18,"slot":"armor"},
    {"name":"Alicel Card","bonus_stat":"FLEE","source_stat":"LUK","ratio":18,"slot":"armor"},
    {"name":"Aliza Card","bonus_stat":"MDEF","source_stat":"LUK","ratio":18,"slot":"armor"},
    {"name":"Wild Rose Card","bonus_stat":"PERFECT_DODGE","source_stat":"LUK","ratio":18,"slot":"armor"},
    {"name":"Garm Pup Card","bonus_stat":"VIT","source_stat":"LUK","ratio":18,"slot":"armor"},
    {"name":"Observation Card","bonus_stat":"DEX","source_stat":"VIT","ratio":18,"slot":"armor"},
    {"name":"Lady Solace Card","bonus_stat":"INT","source_stat":"VIT","ratio":18,"slot":"armor"},
    {"name":"Mistress Card","bonus_stat":"LUK","source_stat":"VIT","ratio":18,"slot":"armor"}
]

const FLAT_CARDS:Array = [
    {"name":"Zerom Card","bonus_stat":"DEX","amount":2,"slot":"accessory"},
    {"name":"Tarou Card","bonus_stat":"STR","amount":2,"slot":"accessory"}
]

const LOWEST_STAT_CARDS:Array = [
    {"name":"Jing Guai Card","rule":"For every 10 points in the lowest pure base stat, grant +1 to all stats when the lowest pure base stat is at least 50.","slot":"armor"}
]

static func pure_base_stats(hero:Dictionary)->Dictionary:
    var source:Dictionary=hero.get("base_stats",{})
    var result:Dictionary={}
    for stat in ["STR","AGI","VIT","INT","DEX","LUK"]:
        result[stat]=max(0,int(source.get(stat,0)))
    return result

static func scaling_amount(hero:Dictionary,card_name:String)->int:
    var stats:=pure_base_stats(hero)
    for card:Dictionary in CARDS:
        if str(card.get("name",""))==card_name:
            return int(stats.get(str(card.get("source_stat","")),0))/RATIO
    return 0

static func lowest_stat_bonus(hero:Dictionary,card_name:String)->int:
    if card_name!="Jing Guai Card": return 0
    var stats:=pure_base_stats(hero)
    var lowest:int=999999
    for stat:String in stats.keys(): lowest=min(lowest,int(stats[stat]))
    if lowest<50: return 0
    return lowest/10

static func card_effect(hero:Dictionary,card_name:String)->Dictionary:
    for card:Dictionary in CARDS:
        if str(card.get("name",""))==card_name:
            return {"name":card_name,"slot":"armor","bonus_stat":str(card["bonus_stat"]),"amount":scaling_amount(hero,card_name),"source_stat":str(card["source_stat"]),"ratio":RATIO,"pure_base_only":true}
    for card:Dictionary in FLAT_CARDS:
        if str(card.get("name",""))==card_name:
            return {"name":card_name,"slot":"accessory","bonus_stat":str(card["bonus_stat"]),"amount":int(card["amount"]),"flat":true}
    for card:Dictionary in LOWEST_STAT_CARDS:
        if str(card.get("name",""))==card_name:
            return {"name":card_name,"slot":"armor","bonus_all_stats":lowest_stat_bonus(hero,card_name),"lowest_stat_rule":str(card["rule"]),"pure_base_only":true}
    return {}

static func all()->Array:
    return CARDS+FLAT_CARDS+LOWEST_STAT_CARDS

static func validate()->bool:
    if CARDS.size()!=10: return false
    for card:Dictionary in CARDS:
        if int(card.get("ratio",0))!=18 or str(card.get("slot",""))!="armor": return false
    return true
