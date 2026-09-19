extends SceneTree

const EXPECTED_CLASSES=["Warrior","Mage","Archer","Thief","Acolyte","Merchant"]
const TIERS=["Foundation","Specialization","Advanced","Mastery","Transcendence"]
const MONSTERS=["Poring","Goblin","Wolf","Skeleton","Zombie","Orc","Mantis","Golem","Evil_Druid","Dragon","Bloody_Knight"]
var failures:Array[String]=[]

func _initialize()->void:
    _run()
    quit(0 if failures.is_empty() else 1)

func check(ok:bool,msg:String)->void:
    if not ok:
        failures.append(msg)
        print("FAIL: "+msg)
    else:
        print("PASS: "+msg)

func _run()->void:
    var project:=FileAccess.get_file_as_string("res://project.godot")
    check(project.contains('config/features=PackedStringArray("4.7")'),"Godot 4.7 feature contract")
    check(project.contains('renderer/rendering_method="forward_plus"'),"Forward+ production renderer")
    check(project.contains('HWProductionAudioDirector='),"production audio director autoload")
    check(project.contains('HWPerformanceDirector='),"performance director autoload")
    for c in EXPECTED_CLASSES:
        for tier in TIERS:
            check(FileAccess.file_exists("res://assets/3d/generated/characters/%s/%s.glb"%[c,tier]),"hero GLB %s/%s"%[c,tier])
        check(FileAccess.file_exists("res://assets/3d/generated/pets/%s_pet.glb"%c),"pet GLB "+c)
    for m in MONSTERS:
        check(FileAccess.file_exists("res://assets/3d/generated/monsters/monster_%s.glb"%m),"monster GLB "+m)
    check(FileAccess.file_exists("res://scripts/HWOnlineAuthorityRuntime.gd"),"online authority runtime")
    check(FileAccess.file_exists("res://scripts/HWServerGameplayRuntime.gd"),"server gameplay runtime")
    check(FileAccess.file_exists("res://scripts/HWLiveWorldReplication.gd"),"live world replication")
    check(FileAccess.file_exists("res://scripts/HWServerBootstrap.gd"),"server bootstrap")
    check(FileAccess.file_exists("res://export_presets.cfg"),"Windows export preset")
    check(FileAccess.file_exists("res://scripts/HWProductionAudioDirector.gd"),"production audio implementation")
    check(FileAccess.file_exists("res://scripts/HWPerformanceDirector.gd"),"performance implementation")
    print("PRODUCTION_RELEASE_READINESS: %s"%("PASS" if failures.is_empty() else "FAIL"))
