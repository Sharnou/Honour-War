class_name OnlineAgeSystem
extends RefCounted

## Persistent online-age progression.
## A new character starts at age 18. Every 3 accumulated online days grants
## one permanent character year. Age is gameplay state, never a floating label.
const DEFAULT_STARTING_AGE:int = 18
const DAYS_PER_YEAR:float = 3.0
const STAT_GROWTH_PER_YEAR:float = 0.005
const REFINE_SUCCESS_PER_YEAR:float = 0.01
const TOP_100_DROP_PER_YEAR:float = 0.001

static func starting_age(hero:Dictionary)->int:
	var origin:int = int(hero.get("age_origin", DEFAULT_STARTING_AGE))
	return max(DEFAULT_STARTING_AGE, origin)

static func age_from_online_days(days:float, origin:int=DEFAULT_STARTING_AGE)->int:
	return starting_age({"age_origin":origin}) + max(0, int(floor(max(0.0, days) / DAYS_PER_YEAR)))

static func normalize(hero:Dictionary)->void:
	var days:float = max(0.0, float(hero.get("online_days", 0.0)))
	hero["online_days"] = days
	if not hero.has("age_origin"):
		hero["age_origin"] = DEFAULT_STARTING_AGE
	var origin:int = starting_age(hero)
	hero["age_origin"] = origin
	# Recalculate on every call so persistent characters age as their online
	# time advances, not only during first-time save migration.
	hero["age"] = max(origin, age_from_online_days(days, origin))

static func years_earned(hero:Dictionary)->int:
	normalize(hero)
	return max(0, int(hero.get("age", starting_age(hero))) - starting_age(hero))

static func stat_growth_multiplier(hero:Dictionary)->float:
	return 1.0 + float(years_earned(hero)) * STAT_GROWTH_PER_YEAR

static func stat_growth_percent(hero:Dictionary)->float:
	return float(years_earned(hero)) * STAT_GROWTH_PER_YEAR * 100.0

static func refine_success_bonus(hero:Dictionary)->float:
	return float(years_earned(hero)) * REFINE_SUCCESS_PER_YEAR

static func refine_success_bonus_percent(hero:Dictionary)->float:
	return refine_success_bonus(hero) * 100.0

static func top_100_drop_bonus(hero:Dictionary)->float:
	return float(years_earned(hero)) * TOP_100_DROP_PER_YEAR

static func top_100_drop_bonus_percent(hero:Dictionary)->float:
	return top_100_drop_bonus(hero) * 100.0

static func strength_bonus(hero:Dictionary)->Dictionary:
	var years:int = years_earned(hero)
	return {
		"atk":years*2,
		"matk":years*2,
		"def":years,
		"mdef":years,
		"hp":years*18,
		"sp":years*4,
		"crit":years/10,
		"flee":years/8,
		"hit":years/8,
		"healing":years/5,
		"refine_luck":refine_success_bonus(hero)
	}

static func title(age:int)->String:
	if age<25: return "Young Hero"
	if age<50: return "Seasoned Hero"
	if age<100: return "Veteran Hero"
	if age<250: return "Ancient Hero"
	if age<500: return "Eternal Hero"
	return "Immortal Legend"

static func progress_to_next_year(hero:Dictionary)->Dictionary:
	normalize(hero)
	var days:float=float(hero.get("online_days",0.0))
	var elapsed:float=fmod(days,DAYS_PER_YEAR)
	return {
		"age":int(hero["age"]),
		"starting_age":starting_age(hero),
		"days":days,
		"days_into_year":elapsed,
		"days_remaining":DAYS_PER_YEAR-elapsed,
		"percent":elapsed/DAYS_PER_YEAR,
		"stat_growth_percent":stat_growth_percent(hero),
		"refine_success_bonus_percent":refine_success_bonus_percent(hero),
		"top_100_drop_bonus_percent":top_100_drop_bonus_percent(hero)
	}
