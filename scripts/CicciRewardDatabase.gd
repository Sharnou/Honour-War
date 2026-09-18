class_name CicciRewardDatabase
extends RefCounted

## Cicci weekly reward pools: 50 unique GAME MASTER equipment + 50 unique cards.
## These are reward pools, not guaranteed drops. LootProgressionSystem clamps
## each kill to at most 2 equipment and 2 cards, and the drop roll may award 0.
const VERSION:String = "1.0.0"
const POOL_SIZE:int = 50
const MAX_DROPS_PER_KILL:int = 2

static func equipment_names()->Array:
    return [
        "GAME MASTER Astral Crown","GAME MASTER Dragon Emperor Armor","GAME MASTER Moonveil Robe","GAME MASTER Storm Sovereign Mantle","GAME MASTER Verdant Worldplate",
        "GAME MASTER Night Reaper Coat","GAME MASTER Ember Phoenix Mail","GAME MASTER Star Oracle Raiment","GAME MASTER Iron Colossus Cuirass","GAME MASTER Sovereign Guardian Plate",
        "GAME MASTER Celestial Warblade","GAME MASTER Void Sovereign Staff","GAME MASTER Thunder Worldbow","GAME MASTER Shadow Emperor Katar","GAME MASTER Divine Saint Mace",
        "GAME MASTER Forge Overlord Hammer","GAME MASTER Dawn Aegis","GAME MASTER Eternal Dragon Shield","GAME MASTER Chronos Guard","GAME MASTER Abyss Bulwark",
        "GAME MASTER Seraphic Crown","GAME MASTER Inferno Helm","GAME MASTER Glacial Circlet","GAME MASTER Thundercrest Helm","GAME MASTER World Tree Crown",
        "GAME MASTER Nightmare Mask","GAME MASTER Phoenix Crown","GAME MASTER Starborn Circlet","GAME MASTER Iron Colossus Helm","GAME MASTER Sovereign Diadem",
        "GAME MASTER Dragonwing Cloak","GAME MASTER Moon World Cape","GAME MASTER Stormrunner Mantle","GAME MASTER Verdant Guardian Shawl","GAME MASTER Nightfall Mantle",
        "GAME MASTER Embertrail Cape","GAME MASTER Starpath Wings","GAME MASTER Ironroot Mantle","GAME MASTER Abyssal Cloak","GAME MASTER Chronos Mantle",
        "GAME MASTER Dawnstrider Greaves","GAME MASTER Dragonstep Boots","GAME MASTER Moonwalker Boots","GAME MASTER Stormrunner Boots","GAME MASTER Verdantstride Shoes",
        "GAME MASTER Nightstep Boots","GAME MASTER Embermarch Greaves","GAME MASTER Starpath Greaves","GAME MASTER Ironbark Greaves","GAME MASTER Eternal Sabatons"
    ]

static func card_names()->Array:
    return [
        "GAME MASTER Dawn Wyrm Card","GAME MASTER Dragon Emperor Card","GAME MASTER Moon Serpent Card","GAME MASTER Storm Titan Card","GAME MASTER Verdant Ancient Card",
        "GAME MASTER Night Reaper Card","GAME MASTER Ember Phoenix Card","GAME MASTER Star Oracle Card","GAME MASTER Iron Colossus Card","GAME MASTER Sovereign Guardian Card",
        "GAME MASTER Celestial Champion Card","GAME MASTER Void Archmage Card","GAME MASTER Wild Falcon Lord Card","GAME MASTER Shadow Assassin Card","GAME MASTER Sacred High Saint Card",
        "GAME MASTER Merchant King Card","GAME MASTER Warrior Emperor Card","GAME MASTER Arcane Grandmaster Card","GAME MASTER Ranger King Card","GAME MASTER Thief Emperor Card",
        "GAME MASTER Aegis High Saint Card","GAME MASTER Forge Grandmaster Card","GAME MASTER World Tree Guardian Card","GAME MASTER Starborn Dragon Card","GAME MASTER Eternal Paladin Card",
        "GAME MASTER Inferno Emperor Card","GAME MASTER Glacial Empress Card","GAME MASTER Thunder Roc King Card","GAME MASTER Ancient Kraken Lord Card","GAME MASTER Chronos Dragon Card",
        "GAME MASTER Dawn Worldboss Card","GAME MASTER Dragon Eternal Card","GAME MASTER Moon World Serpent Card","GAME MASTER Storm World Titan Card","GAME MASTER Verdant World Ancient Card",
        "GAME MASTER Night Eternal Reaper Card","GAME MASTER Ember Eternal Phoenix Card","GAME MASTER Star Eternal Oracle Card","GAME MASTER Iron World Colossus Card","GAME MASTER Sovereign Eternal Guardian Card",
        "GAME MASTER Bloodfang World Wolf Card","GAME MASTER Arcane World Golem Card","GAME MASTER Sky World Mantis Card","GAME MASTER Grave World Knight Card","GAME MASTER Plague World Zombie Card",
        "GAME MASTER Forest World Orc Card","GAME MASTER Crimson World Goblin Card","GAME MASTER Ancient World Druid Card","GAME MASTER Royal World Poring Card","GAME MASTER Abyss World Dragon Card"
    ]

static func _equipment_slot(rank:int)->String:
    if rank <= 10: return "armor"
    if rank <= 20: return "weapon"
    if rank <= 30: return "head_upper"
    if rank <= 40: return "garment"
    return "shoes"

static func _equipment(rank:int)->Dictionary:
    var power:int = 500 - (rank - 1) * 6
    var atk:int = 40 - int((rank - 1) / 5)
    var matk:int = 40 - int((rank - 1) / 6)
    var hp:int = 45 - int((rank - 1) / 5)
    var defense:int = 30 - int((rank - 1) / 6)
    var boss:float = 25.0 - float(rank - 1) * 0.25
    var element:float = 25.0 - float(rank - 1) * 0.20
    var crit:float = 12.0 - float(rank - 1) * 0.12
    var aspd:float = 12.0 - float(rank - 1) * 0.10
    var reduction:float = 8.0 - float(rank - 1) * 0.08
    var rewards:float = 10.0 - float(rank - 1) * 0.12
    var refine:float = 2.0 + float(50 - rank) * 0.04
    return {
        "rank":rank,"name":equipment_names()[rank - 1],"type":"equipment","rarity":"GAME MASTER",
        "slot":_equipment_slot(rank),"power":power,"atk_percent":roundf(atk*10.0)/10.0,
        "matk_percent":roundf(matk*10.0)/10.0,"hp_percent":roundf(hp*10.0)/10.0,
        "defense":defense,"boss_damage_percent":roundf(boss*100.0)/100.0,
        "elemental_damage_percent":roundf(element*100.0)/100.0,"critical_percent":roundf(crit*100.0)/100.0,
        "aspd_percent":roundf(aspd*100.0)/100.0,"damage_reduction_percent":roundf(reduction*100.0)/100.0,
        "rewards_percent":roundf(rewards*100.0)/100.0,"refine_bonus_percent":roundf(refine*100.0)/100.0,
        "card_slots":4,"max_refine":15,"drop_rate_percent":0.20 - float(rank - 1) * 0.003
    }

static func _card(rank:int)->Dictionary:
    var power:int = 400 - (rank - 1) * 5
    var damage:float = 35.0 - float(rank - 1) * 0.30
    var boss:float = 30.0 - float(rank - 1) * 0.30
    var rewards:float = 10.0 - float(rank - 1) * 0.12
    var hp:float = 35.0 - float(rank - 1) * 0.25
    var matk:float = 35.0 - float(rank - 1) * 0.25
    var crit:float = 12.0 - float(rank - 1) * 0.12
    var aspd:float = 8.0 - float(rank - 1) * 0.10
    var reduction:float = 8.0 - float(rank - 1) * 0.08
    var cooldown:float = 10.0 - float(rank - 1) * 0.08
    return {
        "rank":rank,"name":card_names()[rank - 1],"type":"card","slot":"card","rarity":"GAME MASTER",
        "power":power,"damage_percent":roundf(damage*100.0)/100.0,"boss_damage_percent":roundf(boss*100.0)/100.0,
        "rewards_percent":roundf(rewards*100.0)/100.0,"hp_percent":roundf(hp*100.0)/100.0,
        "matk_percent":roundf(matk*100.0)/100.0,"critical_percent":roundf(crit*100.0)/100.0,
        "aspd_percent":roundf(aspd*100.0)/100.0,"damage_reduction_percent":roundf(reduction*100.0)/100.0,
        "skill_cooldown_reduction_percent":roundf(cooldown*100.0)/100.0,
        "elemental_damage_percent":roundf((28.0 - float(rank - 1) * 0.25)*100.0)/100.0,
        "drop_rate_percent":0.20 - float(rank - 1) * 0.003
    }

static func equipment()->Array:
    var result:Array = []
    for rank in range(1,POOL_SIZE+1): result.append(_equipment(rank))
    return result

static func cards()->Array:
    var result:Array = []
    for rank in range(1,POOL_SIZE+1): result.append(_card(rank))
    return result

static func get_equipment(rank:int)->Dictionary:
    if rank < 1 or rank > POOL_SIZE: return {}
    return _equipment(rank)

static func get_card(rank:int)->Dictionary:
    if rank < 1 or rank > POOL_SIZE: return {}
    return _card(rank)

static func validate()->bool:
    return equipment_names().size() == POOL_SIZE and card_names().size() == POOL_SIZE
