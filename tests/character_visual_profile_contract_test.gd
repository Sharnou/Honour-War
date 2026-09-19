extends SceneTree

const PROFILE=preload("res://scripts/HWCharacterVisualProfiles.gd")
const GAME_DATA=preload("res://scripts/GameData.gd")

func _init()->void:
    var expected={
        "Warrior":["segmented plate armor","pauldrons","gauntlets","tassets","cape","greatsword"],
        "Mage":["wizard hat","layered robe","sash","staff","arcane orb","magic circle"],
        "Archer":["tunic","leather chest guard","bracers","quiver","arrows","detailed bow"],
        "Thief":["mask","tactical harness","wraps","sheaths","dual daggers","shadow effect"],
        "Acolyte":["white robe","blue stole","gold cross","halo","staff","divine aura"],
        "Merchant":["detailed vest","suspenders","belt","coin pouch","scale","cart","potions"]
    }
    for class_id in expected.keys():
        var p:Dictionary=PROFILE.profile(str(class_id))
        if str(p.get("emotion",""))=="" or str(p.get("motion",""))=="":
            push_error("FAIL: missing emotion/motion profile for "+str(class_id))
        var clothing:Array=p.get("clothing",[])
        for item in expected[class_id]:
            if item not in clothing:
                push_error("FAIL: missing clothing profile "+str(class_id)+" / "+str(item))
    for class_id in expected.keys():
        for level in [1,25,50,150,200,250]:
            var hero:Dictionary=GAME_DATA.new_hero()
            hero["class"]=str(class_id)
            hero["level"]=level
            var snap:Dictionary=PROFILE.snapshot(hero)
            if str(snap.get("rank",""))!=GAME_DATA.class_rank_for_hero(hero):
                push_error("FAIL: progression rank mismatch "+str(class_id)+" Lv"+str(level))
            if int(snap.get("tier",-1))!=GAME_DATA.class_tier_for_level(level):
                push_error("FAIL: progression tier mismatch "+str(class_id)+" Lv"+str(level))
    print("PASS: six-class clothing, emotion, motion, and progression visual profiles")
    quit()
