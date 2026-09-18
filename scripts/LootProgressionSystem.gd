class_name LootProgressionSystem
extends RefCounted

const Age=preload("res://scripts/OnlineAgeSystem.gd")
const Top100=preload("res://scripts/Top100Database.gd")
const FifthJobs=preload("res://scripts/FifthJobDatabase.gd")

static func rarity_weight(level:int,mvp:bool=false)->Dictionary:
    var l:int=clamp(level,1,300); var scale:float=float(l)/300.0
    if mvp: return {"Common":5.0,"Uncommon":18.0,"Rare":35.0,"Epic":28.0,"Legendary":12.0,"MVP":2.0+scale*8.0}
    return {"Common":58.0,"Uncommon":28.0,"Rare":10.0+scale*6.0,"Epic":3.0+scale*3.0,"Legendary":0.5+scale*1.5,"MVP":0.0}

static func xp(monster_level:int,hero_level:int,base_xp:int)->int:
    var gap:int=monster_level-hero_level; var multiplier:float=1.0
    if gap>=10: multiplier=1.30
    elif gap>=5: multiplier=1.15
    elif gap<=-15: multiplier=0.35
    elif gap<=-8: multiplier=0.60
    elif gap<=-3: multiplier=0.80
    return max(1,int(round(base_xp*multiplier)))

static func money(monster_level:int,mvp:bool=false)->int:
    return (8+monster_level*3)*(8 if mvp else 1)

static func roll_rarity(level:int,mvp:bool,roll:float)->String:
    var weights:Dictionary=rarity_weight(level,mvp); var total:float=0.0
    for value in weights.values(): total+=float(value)
    var cursor:float=clamp(roll,0.0,0.999999)*total
    for rarity in ["Common","Uncommon","Rare","Epic","Legendary","MVP"]:
        cursor-=float(weights.get(rarity,0.0))
        if cursor<=0.0: return rarity
    return "Common"

static func top_100_drop_bonus(hero:Dictionary)->float:
    return Age.top_100_drop_bonus(hero)

static func top_100_drop_bonus_percent(hero:Dictionary)->float:
    return Age.top_100_drop_bonus_percent(hero)

static func top_100_item_entries()->Array:
    return Top100.items()

static func top_100_card_entries()->Array:
    return Top100.cards()

static func top_100_item_entry(rank:int)->Dictionary:
    return Top100.get_item_by_rank(rank)

static func top_100_card_entry(rank:int)->Dictionary:
    return Top100.get_card_by_rank(rank)

static func top_100_item_default_drop_rate_percent(rank:int)->float:
    return Top100.default_drop_rate_percent(rank)

static func top_100_card_default_drop_rate_percent(rank:int)->float:
    return Top100.default_drop_rate_percent(rank)

## Backward-compatible item-pool aliases.
static func top_100_default_drop_rate_percent(rank:int)->float:
    return top_100_item_default_drop_rate_percent(rank)

static func top_100_entry(rank:int)->Dictionary:
    return top_100_item_entry(rank)

static func top_100_entries()->Array:
    return Top100.all()

static func top_100_item_pool_rate_percent()->float:
    return Top100.item_pool_rate_percent()

static func top_100_card_pool_rate_percent()->float:
    return Top100.card_pool_rate_percent()

static func top_100_combined_pool_rate_percent()->float:
    return Top100.combined_pool_rate_percent()

static func top_100_drop_chance(base_chance:float,hero:Dictionary)->float:
    return clampf(base_chance+top_100_drop_bonus(hero),0.0,1.0)

static func resolve_top_100_item(rank:int,hero:Dictionary)->Dictionary:
    return _resolve_entry(Top100.get_item_by_rank(rank),rank,hero,"item")

static func resolve_top_100_card(rank:int,hero:Dictionary)->Dictionary:
    return _resolve_entry(Top100.get_card_by_rank(rank),rank,hero,"card")

static func _resolve_entry(entry:Dictionary,rank:int,hero:Dictionary,pool_type:String)->Dictionary:
    if entry.is_empty(): return {}
    var base_percent:float=float(entry.get("default_drop_rate_percent",0.0))
    var age_bonus_percent:float=top_100_drop_bonus_percent(hero)
    return {"rank":rank,"name":entry.get("name",""),"type":pool_type,"slot":entry.get("slot",""),"rarity":entry.get("rarity",""),"status":entry.get("status",""),"default_drop_rate_percent":base_percent,"age_bonus_percent":age_bonus_percent,"final_drop_rate_percent":base_percent+age_bonus_percent}

static func resolve_top_100(rank:int,hero:Dictionary)->Dictionary:
    return resolve_top_100_item(rank,hero)

static func fifth_job_drop_table(monster:Dictionary,class_id:String)->Dictionary:
    return FifthJobs.drop_table(monster,class_id)

static func fifth_job_drop_rate_percent(monster:Dictionary,class_id:String,item_name:String)->float:
    var table:Dictionary=FifthJobs.drop_table(monster,class_id)
    if not bool(table.get("eligible",false)): return 0.0
    for item in table.get("items",[]):
        if str(item.get("name",""))==item_name: return float(item.get("drop_rate_percent",0.0))
    for card in table.get("cards",[]):
        if str(card.get("name",""))==item_name: return float(card.get("drop_rate_percent",0.0))
    return 0.0

static func resolve(monster:Dictionary,hero:Dictionary,roll:float=0.5)->Dictionary:
    var ml:int=int(monster.get("level",1)); var hl:int=int(hero.get("level",1)); var is_mvp:bool=bool(monster.get("mvp",false))
    var base_xp:int=int(monster.get("xp",max(10,ml*12)))
    var rarity:String=roll_rarity(ml,is_mvp,roll)
    var top_bonus:float=top_100_drop_bonus(hero)
    return {"xp":xp(ml,hl,base_xp),"zeny":money(ml,is_mvp),"rarity":rarity,"mvp":is_mvp,"level":ml,"top_100_drop_bonus":top_bonus,"top_100_drop_bonus_percent":top_bonus*100.0,"top_100_item_count":Top100.item_count(),"top_100_card_count":Top100.card_count(),"top_100_count":Top100.count()}
