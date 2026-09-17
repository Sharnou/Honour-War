extends Node

## Open-world encounter director for Honour War.
## Towns remain service/social hubs; fields and dungeons are populated with
## combat encounters. This director feeds the existing LegacyGame combat data
## so movement, targeting, loot, quests and HD monster presentation keep one
## authoritative gameplay source.

const GameDataClass = preload("res://scripts/GameData.gd")
const TeleportSystemClass = preload("res://scripts/TeleportSystem.gd")
const WorldSystemClass = preload("res://scripts/WorldSystem.gd")

const MAX_WORLD_ENCOUNTERS:int = 10
const MIN_WORLD_ENCOUNTERS:int = 6
const SPAWN_INTERVAL:float = 2.5
const SPAWN_MARGIN:float = 90.0

const FIELD_FAMILIES:Dictionary = {
    20:["Poring","Wolf","Goblin"],
    21:["Wolf","Mantis","Skeleton"],
    22:["Goblin","Golem","Evil Druid"],
    23:["Mantis","Orc","Golem"],
    24:["Poring","Wolf","Mantis"],
    25:["Poring","Wolf","Orc"],
    26:["Mantis","Wolf","Golem"],
    27:["Golem","Evil Druid","Wolf"],
    28:["Wolf","Zombie","Golem"],
    29:["Mantis","Evil Druid","Golem"]
}

const DUNGEON_FAMILIES:Dictionary = {
    10:["Skeleton","Zombie","Bloody Knight"],
    11:["Wolf","Skeleton","Zombie"],
    12:["Goblin","Evil Druid","Golem"],
    13:["Mantis","Golem","Evil Druid"],
    14:["Orc","Golem","Bloody Knight"],
    15:["Wolf","Zombie","Golem"],
    16:["Golem","Evil Druid","Bloody Knight"],
    17:["Skeleton","Zombie","Mantis"],
    18:["Mantis","Evil Druid","Golem"],
    19:["Skeleton","Zombie","Bloody Knight"]
}

var game:Node3D
var legacy:Node
var rng:RandomNumberGenerator = RandomNumberGenerator.new()
var timer:float = 0.0
var encounter_serial:int = 0

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    rng.randomize()
    call_deferred("_bind")

func _bind()->void:
    game = get_tree().current_scene as Node3D
    if game == null:
        return
    legacy = game.get_node_or_null("LegacyGame")
    _ensure_population()

func _process(delta:float)->void:
    if game == null or not is_instance_valid(game):
        game = get_tree().current_scene as Node3D
        legacy = game.get_node_or_null("LegacyGame") if game != null else null
    if legacy == null or not is_instance_valid(legacy):
        return
    timer += delta
    if timer >= SPAWN_INTERVAL:
        timer = 0.0
        _ensure_population()
    _ensure_visual_ids()

func _ensure_population()->void:
    if legacy == null:
        return
    var hero_value:Variant = legacy.get("hero")
    var monsters_value:Variant = legacy.get("monsters")
    if not hero_value is Dictionary or not monsters_value is Array:
        return
    var hero:Dictionary = hero_value
    var monsters:Array = monsters_value
    var map_id:int = int(hero.get("map_id",0))
    var target_count:int = MAX_WORLD_ENCOUNTERS
    if not TeleportSystemClass.MAPS.has(map_id):
        return
    var map_type:String = str(TeleportSystemClass.MAPS[map_id].get("type","town"))
    if map_type == "town":
        # Never spawn hostile encounters inside city service hubs.
        if not monsters.is_empty():
            monsters.clear()
        return
    if monsters.size() >= MIN_WORLD_ENCOUNTERS:
        return
    var families:Array = _families_for_map(map_id,map_type)
    if families.is_empty():
        return
    while monsters.size() < target_count:
        monsters.append(_make_monster(hero,map_id,families))

func _families_for_map(map_id:int,map_type:String)->Array:
    if map_type == "field":
        var field_value:Variant = FIELD_FAMILIES.get(map_id,[])
        return field_value.duplicate() if field_value is Array else []
    var dungeon_value:Variant = DUNGEON_FAMILIES.get(map_id,[])
    return dungeon_value.duplicate() if dungeon_value is Array else []

func _make_monster(hero:Dictionary,map_id:int,families:Array)->Dictionary:
    encounter_serial += 1
    var family:String = str(families[rng.randi_range(0,families.size()-1)])
    var hero_level:int = clampi(int(hero.get("level",1)),1,GameDataClass.MAX_HERO_LEVEL)
    var zone:int = maxi(1,int(float(hero_level + 9) / 10.0))
    if TeleportSystemClass.is_dungeon(map_id):
        zone += 2
    var level:int = WorldSystemClass.monster_level_for_zone(zone,rng.randi_range(0,GameDataClass.monster_families().size()-1))
    level = clampi(level,1,GameDataClass.MAX_MONSTER_LEVEL)
    var stats:Dictionary = WorldSystemClass.monster_stats(level)
    var map_data:Dictionary = TeleportSystemClass.MAPS[map_id]
    var width:float = float(map_data.get("width",1200))
    var height:float = float(map_data.get("height",700))
    var x:float = SPAWN_MARGIN + rng.randf_range(0.0,maxf(1.0,width - SPAWN_MARGIN * 2.0))
    var y:float = SPAWN_MARGIN + rng.randf_range(0.0,maxf(1.0,height - SPAWN_MARGIN * 2.0))
    var mvp:bool = family == "Bloody Knight" and level >= 180 and rng.randf() < 0.18
    if mvp:
        level = mini(GameDataClass.MAX_MONSTER_LEVEL,maxi(level,200 + rng.randi_range(0,100)))
        stats = WorldSystemClass.monster_stats(level)
    return {
        "visual_id":"encounter_%d_%d" % [map_id,encounter_serial],
        "name":family,
        "kind":"MVP" if mvp else "Monster",
        "mvp":mvp,
        "level":level,
        "pos":Vector2(365.0 + x,120.0 + y),
        "hp":int(stats.get("max_hp",100)),
        "max":int(stats.get("max_hp",100)),
        "max_hp":int(stats.get("max_hp",100)),
        "attack":int(stats.get("attack",10)),
        "defense":int(stats.get("defense",5)),
        "exp":int(stats.get("exp",50)),
        "zmin":int(stats.get("zeny_min",10)),
        "zmax":int(stats.get("zeny_max",30))
    }

func _ensure_visual_ids()->void:
    if legacy == null:
        return
    var monsters_value:Variant = legacy.get("monsters")
    if not monsters_value is Array:
        return
    var monsters:Array = monsters_value
    for monster_value in monsters:
        if not monster_value is Dictionary:
            continue
        var monster:Dictionary = monster_value
        if str(monster.get("visual_id","")).is_empty():
            encounter_serial += 1
            monster["visual_id"] = "legacy_encounter_%d" % encounter_serial
        if not monster.has("max_hp"):
            monster["max_hp"] = int(monster.get("max",monster.get("hp",1)))
        if not monster.has("kind"):
            monster["kind"] = "MVP" if bool(monster.get("mvp",false)) else "Monster"
