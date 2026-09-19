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
    var branches={
        "Warrior":["Warlord","Guardian","Berserker","Dragoon"],
        "Mage":["Elementalist","Voidcaller","Astral Sage","Chronomancer"],
        "Archer":["Sniper","Falconer","Trapper","Ballista"],
        "Thief":["Assassin","Phantom","Venomblade","Shadow Dancer"],
        "Acolyte":["Priest","Saint","Exorcist","Oracle"],
        "Merchant":["Blacksmith","Alchemist","Arsenal Lord","Tactician"]
    }
    for class_id in branches.keys():
        for branch in branches[class_id]:
            var branch_visual:Dictionary=PROFILE.branch_visual(str(branch))
            if str(branch_visual.get("style",""))=="":
                push_error("FAIL: missing branch clothing style "+str(class_id)+" / "+str(branch))
            if str(branch_visual.get("emotion",""))=="":
                push_error("FAIL: missing branch clothing emotion "+str(class_id)+" / "+str(branch))
            if branch_visual.get("clothing",[]).is_empty():
                push_error("FAIL: missing branch clothing set "+str(class_id)+" / "+str(branch))
            var hero:Dictionary=GAME_DATA.new_hero()
            hero["class"]=str(class_id)
            hero["class_branch"]=str(branch)
            hero["level"]=25
            var branch_snapshot:Dictionary=PROFILE.branch_snapshot(hero)
            if not bool(branch_snapshot.get("branch_visual_identity_locked",false)):
                push_error("FAIL: branch visual identity not locked "+str(class_id)+" / "+str(branch))
            if str(branch_snapshot.get("class_branch",""))!=str(branch):
                push_error("FAIL: branch visual branch mismatch "+str(class_id)+" / "+str(branch))

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
