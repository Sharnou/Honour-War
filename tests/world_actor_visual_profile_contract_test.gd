extends SceneTree

const Profiles=preload("res://scripts/HWWorldActorVisualProfiles.gd")

func _initialize()->void:
    var failures:Array[String]=[]
    var monster:Dictionary=Profiles.monster_profile({"name":"Orc","level":120,"element":"Earth","status":"Stagger"})
    _check(failures,str(monster.get("emotion","")).contains("hostile"),"monster emotion")
    _check(failures,str(monster.get("motion","")).contains("threat"),"monster movement role")
    var mvp:Dictionary=Profiles.monster_profile({"name":"Baphomet","level":250,"mvp":true})
    _check(failures,str(mvp.get("emotion","")).contains("dominant"),"MVP emotion")
    _check(failures,str(mvp.get("clothing","")).contains("boss armor"),"MVP clothing")
    var pet:Dictionary=Profiles.pet_profile({"name":"Falcon","species":"Royal Falcon","owner_class":"Archer","level":250,"role":"Ranged Striker"})
    _check(failures,str(pet.get("emotion","")).contains("loyal"),"pet emotion")
    _check(failures,str(pet.get("motion","")).contains("companion"),"pet movement role")
    var item:Dictionary=Profiles.npc_profile("Item Shop","Merchant")
    _check(failures,str(item.get("role",""))=="Item Shop","item shop role")
    _check(failures,str(item.get("clothing","")).contains("merchant vest"),"item shop clothing")
    var rental:Dictionary=Profiles.npc_profile("Rent","Super Champion (Rental Only)")
    _check(failures,str(rental.get("role",""))=="Rental Shop","rental shop role")
    _check(failures,str(rental.get("motion","")).contains("contract"),"rental movement role")
    _check(failures,str(rental.get("clothing","")).contains("formal merchant coat"),"rental clothing")
    if failures.is_empty():
        print("PASS: world actor visual profiles")
        quit(0)
    for failure in failures:
        push_error("FAIL: "+failure)
    quit(1)

func _check(failures:Array[String],condition:bool,label:String)->void:
    if not condition:
        failures.append(label)
