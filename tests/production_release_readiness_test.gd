extends SceneTree

const EXPECTED_CLASSES=["Warrior","Mage","Archer","Thief","Acolyte","Merchant"]
const TIERS=["Foundation","Specialization","Advanced","Mastery","Transcendence"]
const MONSTERS=["Poring","Goblin","Wolf","Skeleton","Zombie","Orc","Mantis","Golem","Evil_Druid","Dragon","Bloody_Knight"]
const ELEMENTS=["Fire","Water","Earth","Wind","Holy","Shadow","Neutral","Undead","Poison","Ghost"]
const REQUIRED_WORKFLOWS=[
    ".github/workflows/honour-war-full-gameplay-qa.yml",
    ".github/workflows/honour-war-windows-exe-qa.yml",
    ".github/workflows/honour-war-production-release-readiness.yml",
    ".github/workflows/daily-honour-war-upgrade.yml"
]
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
    check(FileAccess.file_exists("res://tests/exported_exe_smoke_test.gd"),"exported EXE gameplay smoke test")
    check(FileAccess.file_exists("res://tests/full_gameplay_runtime_qa.gd"),"full gameplay runtime regression")
    check(FileAccess.file_exists("res://tools/validate_autoload_class_conflicts.py"),"autoload/class conflict gate")
    check(FileAccess.file_exists("res://tools/validate_monster_visual_distinctness.py"),"monster visual uniqueness gate")

    for workflow in REQUIRED_WORKFLOWS:
        check(FileAccess.file_exists("res://"+workflow),"required release workflow "+workflow)

    var teleport:=FileAccess.get_file_as_string("res://scripts/TeleportSystem.gd")
    check(teleport.contains("Prontera") and teleport.contains("Umbala Wilds"),"30-map world registry coverage")
    check(teleport.contains("^[0-9]+:[0-9]+$"),"strict integer X/Y navigation grammar")

    var elements:=FileAccess.get_file_as_string("res://scripts/ElementSystem.gd")
    for element in ELEMENTS:
        check(elements.contains('"%s"'%element),"element system "+element)
    check(not elements.contains("Unknown Material"),"no unknown material dependency")
    check(not elements.contains("Transformer"),"no Transformer material dependency")

    var visual_profile:=FileAccess.get_file_as_string("res://scripts/HWCharacterVisualProfiles.gd")
    check(visual_profile.contains("51"),"51 percent material-driven hero appearance rule")

    check(FileAccess.file_exists("res://assets/3d/generated/ui/item_icons_atlas.svg"),"HD item icon atlas")
    check(FileAccess.file_exists("res://tools/capture_real_game_screenshot.gd"),"real-game screenshot capture")
    check(FileAccess.file_exists("res://tools/blender/honour_war_monster_assets.py"),"Blender monster asset pipeline")

    print("PRODUCTION_RELEASE_READINESS: %s"%("PASS" if failures.is_empty() else "FAIL"))
