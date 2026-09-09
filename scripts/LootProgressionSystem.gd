class_name LootProgressionSystem
extends RefCounted

## Deterministic loot resolver. Monster data remains authoritative for the
## source pool; this layer handles level scaling, rarity and MVP guarantees.

static func rarity_weight(level:int,mvp:bool=false)->Dictionary:
    var l:int = clamp(level,1,300)
    var scale:float = float(l)/300.0
    if mvp:
        return {"Common":5.0,"Uncommon":18.0,"Rare":35.0,"Epic":28.0,"Legendary":12.0,"MVP":2.0+scale*8.0}
    return {"Common":58.0,"Uncommon":28.0,"Rare":10.0+scale*6.0,"Epic":3.0+scale*3.0,"Legendary":0.5+scale*1.5,"MVP":0.0}

static func xp(monster_level:int,hero_level:int,base_xp:int)->int:
    var gap:int = monster_level-hero_level
    var multiplier:float = 1.0
    if gap >= 10: multiplier = 1.30
    elif gap >= 5: multiplier = 1.15
    elif gap <= -15: multiplier = 0.35
    elif gap <= -8: multiplier = 0.60
    elif gap <= -3: multiplier = 0.80
    return max(1,int(round(base_xp*multiplier)))

static func money(monster_level:int,mvp:bool=false)->int:
    var base:int = 8 + monster_level * 3
    return base * (8 if mvp else 1)

static func roll_rarity(level:int,mvp:bool,roll:float)->String:
    var weights:Dictionary = rarity_weight(level,mvp)
    var total:float = 0.0
    for value in weights.values(): total += float(value)
    var cursor:float = clamp(roll,0.0,0.999999)*total
    for rarity in ["Common","Uncommon","Rare","Epic","Legendary","MVP"]:
        cursor -= float(weights.get(rarity,0.0))
        if cursor <= 0.0: return rarity
    return "Common"

static func resolve(monster:Dictionary,hero:Dictionary,roll:float=0.5)->Dictionary:
    var ml:int = int(monster.get("level",1))
    var hl:int = int(hero.get("level",1))
    var is_mvp:bool = bool(monster.get("mvp",false))
    var base_xp:int = int(monster.get("xp",max(10,ml*12)))
    var rarity:String = roll_rarity(ml,is_mvp,roll)
    return {"xp":xp(ml,hl,base_xp),"zeny":money(ml,is_mvp),"rarity":rarity,"mvp":is_mvp,"level":ml}
