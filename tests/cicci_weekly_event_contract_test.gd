extends SceneTree

const CICCI=preload("res://scripts/CicciWeeklyEvent.gd")

func check(label:String,condition:bool)->void:
    if not condition:
        push_error("FAIL: "+label)
        quit(1)

func _initialize()->void:
    var p:Dictionary=CICCI.monster_profile()
    check("Cicci name",p["name"]=="Cicci")
    check("Cicci Level 400 power",int(p["level"])==400 and int(p["power_level"])==400)
    check("Cicci special MVP",bool(p["mvp"]) and bool(p["event_boss"]) and bool(p["weekly"]))
    check("Cicci centaur body",str(p["body_type"])=="Centaur")
    check("Cicci Level 1 bow",int(p["weapon"]["display_level"])==1)
    check("MVP resurrection cast is 2 minutes",int(p["respawn_skill"]["cast_time_seconds"])==120)
    var schedule:Dictionary=CICCI.weekly_schedule(1000)
    check("weekly respawn interval",int(schedule["interval_seconds"])==604800)
    check("weekly due check",CICCI.is_due(604800,0))
    var cast:Dictionary=CICCI.on_hit(1000)
    check("hit triggers cast",bool(cast["ok"]) and int(cast["cast_time_seconds"])==120)
    var waiting:Dictionary=CICCI.finish_respawn_cast(1119,cast)
    check("MVP cast still charging",not bool(waiting["ok"]) and int(waiting["remaining_seconds"])==1)
    var ready:Dictionary=CICCI.finish_respawn_cast(1120,cast)
    check("MVP respawns after cast",bool(ready["ok"]) and bool(ready["spawned"]) and str(ready["summoned_mvp"])!="")
    var loot:Dictionary=CICCI.drops()
    check("50 GAME MASTER equipment",int(loot["item_count"])==50)
    check("50 GAME MASTER cards",int(loot["card_count"])==50)
    check("GAME MASTER category",str(loot["category"])=="GAME MASTER")
    check("all equipment marked GAME MASTER",loot["items"].all(func(x): return str(x["category"])=="GAME MASTER"))
    check("all cards marked GAME MASTER",loot["cards"].all(func(x): return str(x["category"])=="GAME MASTER"))
    print("Cicci weekly event QA: PASS")
    quit(0)
