extends SceneTree

const CARDS=preload("res://scripts/StatScalingCards.gd")
const DATA=preload("res://scripts/GameData.gd")

func _init()->void:
    var ok:=true
    ok = ok and CARDS.validate()
    ok = ok and DATA.class_definitions().size()==6
    var hero:Dictionary=DATA.new_hero()
    hero["base_stats"]={"STR":90,"AGI":72,"VIT":54,"INT":36,"DEX":18,"LUK":108}
    ok = ok and CARDS.scaling_amount(hero,"Ancient Mimic Card")==6
    ok = ok and CARDS.scaling_amount(hero,"Tamruan Card")==6
    ok = ok and CARDS.scaling_amount(hero,"Observation Card")==3
    ok = ok and CARDS.card_effect(hero,"Zerom Card").get("amount",0)==2
    ok = ok and CARDS.lowest_stat_bonus(hero,"Jing Guai Card")==0
    hero["base_stats"]["DEX"]=54
    ok = ok and CARDS.lowest_stat_bonus(hero,"Jing Guai Card")==3
    var names:=DATA.class_definitions().keys()
    for class_id:String in names:
        hero["class"]=class_id
        for level:int in [1,25,50,150,200,250]:
            hero["level"]=level
            if level>=200:
                ok=ok and DATA.class_rank_for_hero(hero)==DATA.fifth_job_class(class_id)
            elif level>=150:
                ok=ok and DATA.class_rank_for_hero(hero)==DATA.fourth_job_class(class_id)
    if not ok:
        push_error("FAIL: character progression/stat scaling contract")
        quit(1)
    print("PASS: character progression and pure-base stat scaling contract")
    quit(0)
