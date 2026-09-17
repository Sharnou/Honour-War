extends Node

## Final-pass production coordinator. Keeps gameplay authoritative while making
## the HD presentation stack self-checking and ready for authored GLB assets.
const REQUIRED_ZONES := ["HDTownDistrict", "HDFieldDistrict", "HDDungeonDistrict"]
const REQUIRED_PRESENTATION := ["HWHDContent", "HWHDCombatVFX"]
const REQUIRED_MONSTERS := ["Poring", "Goblin", "Wolf", "Skeleton", "Zombie", "Orc", "Mantis", "Golem", "Druid", "Dragon", "Bloody"]

var report:Dictionary = {}

func _ready() -> void:
    call_deferred("audit")

func audit() -> Dictionary:
    var scene := get_tree().current_scene
    report = {
        "scene_loaded": scene != null,
        "godot_target": "4.7.x",
        "renderer": "Forward+",
        "zones": {},
        "monster_families": {},
        "combat_vfx": false,
        "equipment_presentation": false,
        "mmorpg_only": true,
        "strategy_systems": false
    }
    if scene == null:
        return report
    var content := scene.get_node_or_null("HWHDContent") as Node3D
    if content != null:
        for zone in REQUIRED_ZONES:
            report["zones"][zone] = content.get_node_or_null(zone) != null
    var vfx := scene.get_node_or_null("HWHDCombatVFX") as Node3D
    report["combat_vfx"] = vfx != null
    var hero := _find_hero(scene)
    report["equipment_presentation"] = hero != null and hero.get_node_or_null("HDWeaponSilhouette") != null
    var visuals:Variant = scene.get("monster_visuals")
    if visuals is Dictionary:
        for family in REQUIRED_MONSTERS:
            var found := false
            for key in visuals.keys():
                if str(key).to_lower().contains(family.to_lower()):
                    found = true
                    break
            report["monster_families"][family] = found
    return report

func _find_hero(scene:Node) -> Node3D:
    var direct := scene.get_node_or_null("Hero") as Node3D
    if direct != null:
        return direct
    for node in scene.get_children():
        if node is Node3D and str(node.name).to_lower().contains("hero"):
            return node as Node3D
    return null
