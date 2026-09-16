class_name Top100Database
extends RefCounted

## Honour War has two independent Top-100 pools: 100 items and 100 cards.
## Rank 1 = 0.100000%; rank 100 = 0.010000% in each pool.
## Character age is excluded from stored base rates and applied separately.

const VERSION:String = "2.0.0"
const ENTRIES_PER_POOL:int = 100
const POOL_BASE_RATE_PERCENT:float = 5.5
const COMBINED_BASE_RATE_PERCENT:float = 11.0

const ITEM_NAMES:Array = [
"Astral Edge","Sunforge Blade","Moonveil Saber","Dragonwake Greatsword","Stormcaller Spear","Verdant Halberd","Nightglass Dagger","Emberwind Bow","Starfall Staff","Runebound Tome",
"Aegis of Dawn","Dragonhide Cuirass","Moonlit Robe","Stormguard Plate","Verdant Mantle","Nightwarden Coat","Emberweave Vest","Starcaller Raiment","Ironbark Armor","Sovereign Mail",
"Crown of the First Light","Dragoncrest Helm","Moonshade Circlet","Stormwatch Helm","Verdant Crown","Nightwarden Hood","Emberglass Circlet","Starforged Crown","Ironbark Helm","Sovereign Visor",
"Wings of Dawn","Dragonwing Cloak","Moonveil Cape","Stormrunner Mantle","Verdantwind Shawl","Nightfall Cloak","Embertrail Cape","Starpath Mantle","Ironbark Cape","Sovereign Mantle",
"Dawnstrider Greaves","Dragonstep Boots","Moonwalker Boots","Stormrunner Boots","Verdantstride Shoes","Nightstep Boots","Embermarch Boots","Starpath Greaves","Ironbark Greaves","Sovereign Sabatons",
"Sunheart Ring","Dragoncore Ring","Moonstone Seal","Stormeye Ring","Verdant Signet","Nightglass Ring","Emberheart Pendant","Starcall Talisman","Ironbark Charm","Sovereign Seal",
"Dawnpiercer","Dragonfire Greatblade","Moonshadow Katar","Stormbreak Lance","Verdant Reaper","Nightfall Kris","Emberstorm Crossbow","Starbound Grimoire","Ironroot Hammer","Sovereign Waraxe",
"Dawnplate Armor","Dragonlord Cuirass","Moonshadow Vestment","Stormbreaker Plate","Verdant Guardian Armor","Nightreaper Mail","Emberlord Armor","Starforged Cuirass","Ironroot Bulwark","Sovereign Aegis",
"Dawnwatch Crown","Dragonlord Helm","Moonshadow Hood","Stormbreaker Helm","Verdant Guardian Helm","Nightreaper Mask","Emberlord Crown","Starforged Circlet","Ironroot Crown","Sovereign Diadem",
"Dawnwind Cloak","Dragonlord Mantle","Moonshadow Cape","Stormbreaker Cloak","Verdant Guardian Shawl","Nightreaper Mantle","Emberlord Cape","Starforged Wings","Ironroot Mantle","Sovereign Cloak"
]

const CARD_NAMES:Array = [
"Dawn Wyrm Card","Dragon Emperor Card","Moon Serpent Card","Storm Titan Card","Verdant Ancient Card","Night Reaper Card","Ember Phoenix Card","Star Oracle Card","Iron Colossus Card","Sovereign Guardian Card",
"Bloodfang Wolf Card","Arcane Golem Card","Sky Mantis Card","Grave Knight Card","Plague Zombie Card","Forest Orc Card","Crimson Goblin Card","Ancient Druid Card","Royal Poring Card","Abyssal Dragon Card",
"Celestial Knight Card","Void Mage Card","Wild Falcon Card","Shadow Thief Card","Sacred Acolyte Card","Merchant Prince Card","Warrior Lord Card","Arcane Master Card","Ranger Sovereign Card","Thief King Card",
"Aegis Saint Card","Forge Master Card","World Tree Card","Star Dragon Card","Eternal Guardian Card","Inferno Lord Card","Glacial Queen Card","Thunder Roc Card","Ancient Kraken Card","Chronos Beast Card",
"Dawn Seraph Card","Dragon Tyrant Card","Moon Empress Card","Storm Leviathan Card","Verdant Treant Card","Nightmare Reaper Card","Ember Phoenix Lord Card","Star Seer Card","Iron Behemoth Card","Sovereign Paladin Card",
"Bloodfang Alpha Card","Arcane Titan Card","Skybreaker Mantis Card","Grave Emperor Card","Plague Lord Card","Forest Elder Card","Crimson Goblin King Card","Ancient Archdruid Card","Royal Poring King Card","Abyssal Wyrm Card",
"Celestial Champion Card","Void Archmage Card","Wild Falcon Lord Card","Shadow Assassin Card","Sacred High Priest Card","Merchant King Card","Warrior Emperor Card","Arcane Grandmaster Card","Ranger King Card","Thief Emperor Card",
"Aegis High Saint Card","Forge Grandmaster Card","World Tree Guardian Card","Starborn Dragon Card","Eternal Paladin Card","Inferno Emperor Card","Glacial Empress Card","Thunder Roc King Card","Ancient Kraken Lord Card","Chronos Dragon Card",
"Dawn Worldboss Card","Dragon Eternal Card","Moon World Serpent Card","Storm World Titan Card","Verdant World Ancient Card","Night Eternal Reaper Card","Ember Eternal Phoenix Card","Star Eternal Oracle Card","Iron World Colossus Card","Sovereign Eternal Guardian Card",
"Bloodfang World Wolf Card","Arcane World Golem Card","Sky World Mantis Card","Grave World Knight Card","Plague World Zombie Card","Forest World Orc Card","Crimson World Goblin Card","Ancient World Druid Card","Royal World Poring Card","Abyss World Dragon Card"
]

static func _rate(rank:int)->float:
    return 0.1 - (float(rank - 1) * 0.09 / 99.0)

static func _item_slot(rank:int)->String:
    if rank <= 10 or rank >= 61 and rank <= 70: return "weapon"
    if rank <= 20 or rank >= 71 and rank <= 80: return "armor"
    if rank <= 30 or rank >= 81 and rank <= 90: return "helmet"
    if rank <= 40 or rank >= 91 and rank <= 100: return "garment"
    if rank <= 50: return "footwear"
    return "accessory"

static func _item_status(slot:String)->String:
    match slot:
        "weapon": return "ATK +10%; skill damage +5%; refinement scaling +1% per refine tier"
        "armor": return "DEF +10%; HP +8%; damage reduction +2%"
        "helmet": return "HP +5%; SP +5%; status resistance +4%"
        "garment": return "DEF +6%; elemental resistance +6%; movement speed +2%"
        "footwear": return "AGI +5; movement speed +4%; HP +3%"
        _: return "ATK/MATK +5%; critical +3%; refine success +1%"

static func _card_status(rank:int)->String:
    if rank % 5 == 1: return "ATK +8%; elemental skill damage +6%; boss damage +3%"
    if rank % 5 == 2: return "MATK +8%; SP +6%; skill cooldown -3%"
    if rank % 5 == 3: return "ASPD +5%; critical +4%; movement speed +3%"
    if rank % 5 == 4: return "DEF +7%; HP +8%; damage reduction +2%"
    return "HP +5%; ATK +5%; elemental resistance +3%"

static func _item(rank:int)->Dictionary:
    var slot:String = _item_slot(rank)
    return {"rank":rank,"type":"equipment","slot":slot,"name":ITEM_NAMES[rank - 1],"rarity":"Mythic" if rank <= 10 else ("Legendary" if rank <= 20 else "Epic"),"status":_item_status(slot),"default_drop_rate_percent":_rate(rank),"age_bonus_separate":true,"drop_pool":"Top-100 Items"}

static func _card(rank:int)->Dictionary:
    return {"rank":rank,"type":"card","slot":"card","name":CARD_NAMES[rank - 1],"rarity":"Legendary" if rank <= 80 else "Epic","status":_card_status(rank),"default_drop_rate_percent":_rate(rank),"age_bonus_separate":true,"drop_pool":"Top-100 Cards"}

static func items()->Array:
    var result:Array = []
    for rank in range(1, ENTRIES_PER_POOL + 1): result.append(_item(rank))
    return result

static func cards()->Array:
    var result:Array = []
    for rank in range(1, ENTRIES_PER_POOL + 1): result.append(_card(rank))
    return result

static func all()->Array:
    return items() + cards()

static func get_item_by_rank(rank:int)->Dictionary:
    if rank < 1 or rank > ENTRIES_PER_POOL: return {}
    return _item(rank)

static func get_card_by_rank(rank:int)->Dictionary:
    if rank < 1 or rank > ENTRIES_PER_POOL: return {}
    return _card(rank)

static func get_by_rank(rank:int)->Dictionary:
    return get_item_by_rank(rank)

static func get_item_by_name(item_name:String)->Dictionary:
    for entry in items():
        if entry["name"] == item_name: return entry
    return {}

static func get_card_by_name(card_name:String)->Dictionary:
    for entry in cards():
        if entry["name"] == card_name: return entry
    return {}

static func default_drop_rate_percent(rank:int)->float:
    return _rate(rank) if rank >= 1 and rank <= ENTRIES_PER_POOL else 0.0

static func count()->int:
    return ENTRIES_PER_POOL * 2

static func item_count()->int:
    return ENTRIES_PER_POOL

static func card_count()->int:
    return ENTRIES_PER_POOL

static func item_pool_rate_percent()->float:
    return POOL_BASE_RATE_PERCENT

static func card_pool_rate_percent()->float:
    return POOL_BASE_RATE_PERCENT

static func combined_pool_rate_percent()->float:
    return COMBINED_BASE_RATE_PERCENT

static func validate()->bool:
    if ITEM_NAMES.size() != ENTRIES_PER_POOL or CARD_NAMES.size() != ENTRIES_PER_POOL: return false
    var names:Dictionary = {}
    var item_total:float = 0.0
    var card_total:float = 0.0
    for rank in range(1, ENTRIES_PER_POOL + 1):
        var item:Dictionary = _item(rank)
        var card:Dictionary = _card(rank)
        if names.has(item["name"]) or names.has(card["name"]): return false
        names[item["name"]] = true
        names[card["name"]] = true
        item_total += float(item["default_drop_rate_percent"])
        card_total += float(card["default_drop_rate_percent"])
    return abs(item_total - POOL_BASE_RATE_PERCENT) < 0.00001 and abs(card_total - POOL_BASE_RATE_PERCENT) < 0.00001
