extends Node

## Honour War gameplay math singleton. Registered as GameplayFormula autoload.
const HERO_MAX_LEVEL:int = 250
const PET_MAX_LEVEL:int = 250
const MONSTER_MAX_LEVEL:int = 300
const BASE_HP:int = 120
const BASE_SP:int = 40
const XP_GROWTH:float = 1.18
const XP_BASE:int = 100
const STAT_POINTS_PER_LEVEL:int = 3

static func xp_to_next_level(level:int)->int:
    var lv:int = clampi(level,1,HERO_MAX_LEVEL-1)
    return maxi(XP_BASE,roundi(float(XP_BASE)*pow(float(lv),XP_GROWTH)))

static func level_from_xp(xp:int)->int:
    var level:int = 1
    var remaining:int = maxi(0,xp)
    while level < HERO_MAX_LEVEL:
        var needed:int = xp_to_next_level(level)
        if remaining < needed: break
        remaining -= needed
        level += 1
    return level

static func stat_points(level:int)->int:
    return maxi(0,clampi(level,1,HERO_MAX_LEVEL)-1)*STAT_POINTS_PER_LEVEL

static func hero_stats(level:int,base_stats:Dictionary)->Dictionary:
    var lv:int = clampi(level,1,HERO_MAX_LEVEL)
    var str_stat:int = int(base_stats.get("str",10))
    var agi:int = int(base_stats.get("agi",10))
    var vit:int = int(base_stats.get("vit",10))
    var int_stat:int = int(base_stats.get("int",10))
    var dex:int = int(base_stats.get("dex",10))
    var luk:int = int(base_stats.get("luk",10))
    return {"str":str_stat,"agi":agi,"vit":vit,"int":int_stat,"dex":dex,"luk":luk,"max_hp":BASE_HP + vit*18 + lv*12,"max_sp":BASE_SP + int_stat*7 + lv*4,"attack":40 + str_stat*4 + dex + lv*3,"magic_attack":25 + int_stat*5 + dex + lv*2,"defense":10 + vit*3 + agi + lv,"magic_defense":5 + int_stat*2 + vit + lv,"hit":80 + dex*2 + lv,"flee":60 + agi*2 + lv,"crit":luk/3.0}

static func pet_stats(level:int,role:String)->Dictionary:
    var lv:int = clampi(level,1,PET_MAX_LEVEL)
    var role_bonus:Dictionary = {"Melee":{"attack":8,"defense":5,"hp":20},"Ranged":{"attack":11,"defense":2,"hp":14},"Caster":{"attack":12,"defense":2,"hp":13},"Tank":{"attack":5,"defense":9,"hp":30},"Healer":{"attack":5,"defense":5,"hp":18},"Assassin":{"attack":13,"defense":3,"hp":15}}
    var b:Dictionary = role_bonus.get(role,role_bonus["Melee"])
    return {"max_hp":80 + lv*int(b.hp),"attack":12 + lv*int(b.attack),"defense":5 + lv*int(b.defense),"skill_power":10 + lv*2,"evasion":10 + lv}

static func physical_damage(attack:int,defense:int,skill_multiplier:float=1.0,critical:bool=false)->int:
    var raw:float = max(1.0,float(attack)*max(0.1,skill_multiplier)-float(defense)*0.45)
    if critical: raw *= 1.75
    return maxi(1,roundi(raw))

static func magical_damage(magic_attack:int,magic_defense:int,skill_multiplier:float=1.0)->int:
    return maxi(1,roundi(max(1.0,float(magic_attack)*max(0.1,skill_multiplier)-float(magic_defense)*0.30)))

static func refine_success_rate(refine_level:int)->float:
    var lv:int = clampi(refine_level,0,15)
    return clampf(0.95-float(lv)*0.055,0.08,0.95)

static func refine_power(refine_level:int)->float:
    return 1.0 + clampi(refine_level,0,15)*0.035

static func drop_multiplier(monster_level:int,hero_level:int)->float:
    var gap:int = abs(monster_level-hero_level)
    return clampf(1.0-float(gap)*0.012,0.55,1.15)
