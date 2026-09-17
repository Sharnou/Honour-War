extends SceneTree

## Headless regression suite for persistent quest progression and rewards.

const GAME_DATA = preload("res://scripts/GameData.gd")
const QUESTS = preload("res://scripts/QuestSystem.gd")
const LOOT = preload("res://scripts/LootSystem.gd")

var failures:int = 0

func _initialize() -> void:
    call_deferred("_run_quest_test")

func _run_quest_test() -> void:
    var hero:Dictionary = GAME_DATA.new_hero()
    QUESTS.ensure_state(hero)

    _check("starter quest is available",QUESTS.can_accept(hero,"first_hunt"))
    _check("level-gated wolf quest is locked at level 1",not QUESTS.can_accept(hero,"wolf_scout"))
    _check("accept starter quest",QUESTS.accept_quest(hero,"first_hunt"))
    _check("starter quest becomes active",QUESTS.active_quests(hero).has("first_hunt"))

    for i in range(4):
        QUESTS.record_kill(hero,{"name":"Poring","level":1})
    _check("starter quest stays incomplete at four kills",not QUESTS.is_complete(hero,"first_hunt"))
    _check("starter quest shows four of five",int(QUESTS.progress_summary(hero,"first_hunt")["objectives"][0]["current"])==4)

    var loot_rng:RandomNumberGenerator=RandomNumberGenerator.new()
    loot_rng.seed=12345
    LOOT.on_monster_defeated(hero,{"name":"Poring","level":1,"hp":0,"loot_processed":false},loot_rng)
    _check("loot defeat advances quest to five kills",QUESTS.is_complete(hero,"first_hunt"))
    _check("completed quest is still unclaimed",not hero["quests_completed"].has("first_hunt"))

    var zeny_before:int=int(hero.get("zeny",0))
    var claim:Dictionary=QUESTS.claim_quest(hero,"first_hunt")
    _check("completed quest can be claimed",bool(claim.get("ok",false)))
    _check("claim records quest completion",hero["quests_completed"].has("first_hunt"))
    _check("claim grants zeny",int(hero.get("zeny",0))>zeny_before)
    _check("claim grants guaranteed reward item",int(hero.get("inventory",{}).get("Red Potion",0))>=5)
    _check("claimed quest leaves active list",not QUESTS.active_quests(hero).has("first_hunt"))
    _check("claimed quest cannot be claimed twice",not bool(QUESTS.claim_quest(hero,"first_hunt").get("ok",false)))

    hero["level"]=10
    _check("wolf quest unlocks at level 10",QUESTS.can_accept(hero,"wolf_scout"))
    _check("accept wolf quest",QUESTS.accept_quest(hero,"wolf_scout"))
    hero["level"]=20
    _check("goblin quest unlocks at level 20",QUESTS.can_accept(hero,"goblin_threat"))
    _check("accept goblin quest",QUESTS.accept_quest(hero,"goblin_threat"))
    hero["level"]=35
    _check("accept undead quest as third active",QUESTS.accept_quest(hero,"undead_purge"))
    hero["level"]=50
    _check("fourth active quest is blocked",not QUESTS.can_accept(hero,"orc_breakthrough"))
    _check("abandoning an active quest works",QUESTS.abandon_quest(hero,"goblin_threat"))
    _check("abandoned quest is no longer active",not QUESTS.active_quests(hero).has("goblin_threat"))

    if failures==0:
        print("PASS: Honour War quest system regression suite")
        quit(0)
        return
    print("FAIL: Honour War quest system regression suite: %d failure(s)" % failures)
    quit(1)

func _check(label:String,condition:bool)->void:
    if condition:
        print("PASS: ",label)
    else:
        failures+=1
        print("FAIL: ",label)
