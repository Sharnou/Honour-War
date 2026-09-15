class_name OnlineAgeSystem
extends RefCounted

## Persistent online-age progression.
## Each character can have an individual starting age. Existing characters keep
## the legacy default of 18 unless `age_origin` is explicitly set.
const DEFAULT_STARTING_AGE:int = 18
const DAYS_PER_YEAR:float = 3.0

static func starting_age(hero:Dictionary)->int:
	var origin:int = int(hero.get("age_origin", DEFAULT_STARTING_AGE))
	return clamp(origin, 1, 9999)

static func age_from_online_days(days:float, origin:int=DEFAULT_STARTING_AGE)->int:
	return starting_age({"age_origin":origin}) + max(0, int(floor(max(0.0, days) / DAYS_PER_YEAR)))

static func normalize(hero:Dictionary)->void:
	var days:float = max(0.0, float(hero.get("online_days", 0.0)))
	hero["online_days"] = days
	if not hero.has("age_origin"):
		hero["age_origin"] = DEFAULT_STARTING_AGE
	hero["age_origin"] = starting_age(hero)
	hero["age"] = max(starting_age(hero), age_from_online_days(days, starting_age(hero)))

static func years_earned(hero:Dictionary)->int:
	normalize(hero)
	return max(0, int(hero.get("age", starting_age(hero))) - starting_age(hero))

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
		"refine_luck":min(0.20,float(years)*0.002)
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
	return {"age":int(hero["age"]),"starting_age":starting_age(hero),"days":days,"days_into_year":elapsed,"days_remaining":DAYS_PER_YEAR-elapsed,"percent":elapsed/DAYS_PER_YEAR}
