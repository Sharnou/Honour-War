class_name OnlineAgeSystem
extends RefCounted

## Unlimited online-age progression. Age is never capped. Every 3 accumulated
## online days grants one year; each year permanently increases character power.
const STARTING_AGE:int = 18
const DAYS_PER_YEAR:float = 3.0

static func age_from_online_days(days:float)->int:
	return STARTING_AGE + max(0,int(floor(max(0.0,days)/DAYS_PER_YEAR)))

static func normalize(hero:Dictionary)->void:
	var days:float=max(0.0,float(hero.get("online_days",0.0)))
	hero["online_days"]=days
	hero["age"]=max(STARTING_AGE,age_from_online_days(days))

static func years_earned(hero:Dictionary)->int:
	normalize(hero)
	return max(0,int(hero.get("age",STARTING_AGE))-STARTING_AGE)

static func strength_bonus(hero:Dictionary)->Dictionary:
	var years:int=years_earned(hero)
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
	return {"age":int(hero["age"]),"days":days,"days_into_year":elapsed,"days_remaining":DAYS_PER_YEAR-elapsed,"percent":elapsed/DAYS_PER_YEAR}
