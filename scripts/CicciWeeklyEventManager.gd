class_name CicciWeeklyEventManager
extends RefCounted

const EVENT=preload("res://scripts/CicciWeeklyEvent.gd")

static func ensure_event(game:Node)->void:
    if game==null: return
    var monsters:Variant=game.get("monsters")
    if not monsters is Array: return
    var now:int=int(Time.get_unix_time_from_system())
    var state:Dictionary=game.get_meta("cicci_weekly_state",{})
    if _has_cicci(monsters):
        _process_cast(game,monsters,now,state)
        game.set_meta("cicci_weekly_state",state)
        return
    var last:int=int(state.get("last_respawn_unix",0))
    if last>0 and not EVENT.is_due(now,last):
        return
    var boss:Dictionary=EVENT.monster_profile()
    boss["pos"]=Vector2(820,270)
    boss["hp"]=4000000
    boss["max"]=4000000
    boss["attack"]=1600
    boss["defense"]=800
    boss["attack_type"]="Ranged"
    boss["ranged"]=true
    boss["event_state"]="active"
    boss["event_spawned_unix"]=now
    monsters.append(boss)
    state["last_respawn_unix"]=now
    state["cast"]={}
    state["event_name"]="Cicci Weekly War"
    game.set_meta("cicci_weekly_state",state)

static func on_cicci_hit(game:Node,now:int)->Dictionary:
    var state:Dictionary=game.get_meta("cicci_weekly_state",{})
    var cast:Dictionary=EVENT.on_hit(now)
    state["cast"]=cast
    game.set_meta("cicci_weekly_state",state)
    return cast

static func _process_cast(game:Node,monsters:Array,now:int,state:Dictionary)->void:
    var cast:Dictionary=state.get("cast",{})
    if cast.is_empty() or bool(state.get("mvp_spawned",false)): return
    var result:Dictionary=EVENT.finish_respawn_cast(now,cast)
    if not bool(result.get("ok",false)): return
    var mvp_name:String=str(result.get("summoned_mvp","Thanatos"))
    var boss:Dictionary={"name":mvp_name,"level":300,"mvp":true,"hp":900000,"max":900000,"attack":1200,"defense":600,"pos":Vector2(870,270),"event_summon":true,"event_boss_partner":CicciWeeklyEvent.BOSS_NAME,"attack_type":"Melee"}
    monsters.append(boss)
    state["mvp_spawned"]=true
    state["cast"]={}

static func _has_cicci(monsters:Array)->bool:
    for monster in monsters:
        if monster is Dictionary and str(monster.get("name",""))==CicciWeeklyEvent.BOSS_NAME and int(monster.get("hp",0))>0:
            return true
    return false
