class_name Top100Database
extends RefCounted

## Canonical Honour War Top-100 item/card database.
## default_drop_rate_percent is the base chance before any character-age bonus.
## Character age is intentionally excluded from these stored base rates.

const VERSION:String = "1.0.0"
const TOTAL_BASE_POOL_RATE_PERCENT:float = 5.5
const TOP_100:Array = [
    {"rank":1,"type":"equipment","slot":"weapon","name":"Astral Edge","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.1,"age_bonus_separate":true},
    {"rank":2,"type":"equipment","slot":"weapon","name":"Sunforge Blade","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.099091,"age_bonus_separate":true},
    {"rank":3,"type":"equipment","slot":"weapon","name":"Moonveil Saber","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.098182,"age_bonus_separate":true},
    {"rank":4,"type":"equipment","slot":"weapon","name":"Dragonwake Greatsword","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.097273,"age_bonus_separate":true},
    {"rank":5,"type":"equipment","slot":"weapon","name":"Stormcaller Spear","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.096364,"age_bonus_separate":true},
    {"rank":6,"type":"equipment","slot":"weapon","name":"Verdant Halberd","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.095455,"age_bonus_separate":true},
    {"rank":7,"type":"equipment","slot":"weapon","name":"Nightglass Dagger","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.094545,"age_bonus_separate":true},
    {"rank":8,"type":"equipment","slot":"weapon","name":"Emberwind Bow","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.093636,"age_bonus_separate":true},
    {"rank":9,"type":"equipment","slot":"weapon","name":"Starfall Staff","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.092727,"age_bonus_separate":true},
    {"rank":10,"type":"equipment","slot":"weapon","name":"Runebound Tome","rarity":"Mythic","status":"ATK +10%; skill damage +5%; refinement scaling +1% per refine tier","default_drop_rate_percent":0.091818,"age_bonus_separate":true},
    {"rank":11,"type":"equipment","slot":"armor","name":"Aegis of Dawn","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.090909,"age_bonus_separate":true},
    {"rank":12,"type":"equipment","slot":"armor","name":"Dragonhide Cuirass","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.09,"age_bonus_separate":true},
    {"rank":13,"type":"equipment","slot":"armor","name":"Moonlit Robe","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.089091,"age_bonus_separate":true},
    {"rank":14,"type":"equipment","slot":"armor","name":"Stormguard Plate","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.088182,"age_bonus_separate":true},
    {"rank":15,"type":"equipment","slot":"armor","name":"Verdant Mantle","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.087273,"age_bonus_separate":true},
    {"rank":16,"type":"equipment","slot":"armor","name":"Nightwarden Coat","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.086364,"age_bonus_separate":true},
    {"rank":17,"type":"equipment","slot":"armor","name":"Emberweave Vest","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.085455,"age_bonus_separate":true},
    {"rank":18,"type":"equipment","slot":"armor","name":"Starcaller Raiment","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.084545,"age_bonus_separate":true},
    {"rank":19,"type":"equipment","slot":"armor","name":"Ironbark Armor","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.083636,"age_bonus_separate":true},
    {"rank":20,"type":"equipment","slot":"armor","name":"Sovereign Mail","rarity":"Legendary","status":"DEF +10%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.082727,"age_bonus_separate":true},
    {"rank":21,"type":"equipment","slot":"helmet","name":"Crown of the First Light","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.081818,"age_bonus_separate":true},
    {"rank":22,"type":"equipment","slot":"helmet","name":"Dragoncrest Helm","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.080909,"age_bonus_separate":true},
    {"rank":23,"type":"equipment","slot":"helmet","name":"Moonshade Circlet","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.08,"age_bonus_separate":true},
    {"rank":24,"type":"equipment","slot":"helmet","name":"Stormwatch Helm","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.079091,"age_bonus_separate":true},
    {"rank":25,"type":"equipment","slot":"helmet","name":"Verdant Crown","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.078182,"age_bonus_separate":true},
    {"rank":26,"type":"equipment","slot":"helmet","name":"Nightwarden Hood","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.077273,"age_bonus_separate":true},
    {"rank":27,"type":"equipment","slot":"helmet","name":"Emberglass Circlet","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.076364,"age_bonus_separate":true},
    {"rank":28,"type":"equipment","slot":"helmet","name":"Starforged Crown","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.075455,"age_bonus_separate":true},
    {"rank":29,"type":"equipment","slot":"helmet","name":"Ironbark Helm","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.074545,"age_bonus_separate":true},
    {"rank":30,"type":"equipment","slot":"helmet","name":"Sovereign Visor","rarity":"Epic","status":"HP +5%; SP +5%; status resistance +4%","default_drop_rate_percent":0.073636,"age_bonus_separate":true},
    {"rank":31,"type":"equipment","slot":"garment","name":"Wings of Dawn","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.072727,"age_bonus_separate":true},
    {"rank":32,"type":"equipment","slot":"garment","name":"Dragonwing Cloak","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.071818,"age_bonus_separate":true},
    {"rank":33,"type":"equipment","slot":"garment","name":"Moonveil Cape","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.070909,"age_bonus_separate":true},
    {"rank":34,"type":"equipment","slot":"garment","name":"Stormrunner Mantle","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.07,"age_bonus_separate":true},
    {"rank":35,"type":"equipment","slot":"garment","name":"Verdantwind Shawl","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.069091,"age_bonus_separate":true},
    {"rank":36,"type":"equipment","slot":"garment","name":"Nightfall Cloak","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.068182,"age_bonus_separate":true},
    {"rank":37,"type":"equipment","slot":"garment","name":"Embertrail Cape","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.067273,"age_bonus_separate":true},
    {"rank":38,"type":"equipment","slot":"garment","name":"Starpath Mantle","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.066364,"age_bonus_separate":true},
    {"rank":39,"type":"equipment","slot":"garment","name":"Ironbark Cape","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.065455,"age_bonus_separate":true},
    {"rank":40,"type":"equipment","slot":"garment","name":"Sovereign Mantle","rarity":"Epic","status":"DEF +6%; elemental resistance +6%; movement speed +2%","default_drop_rate_percent":0.064545,"age_bonus_separate":true},
    {"rank":41,"type":"equipment","slot":"footwear","name":"Dawnstrider Greaves","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.063636,"age_bonus_separate":true},
    {"rank":42,"type":"equipment","slot":"footwear","name":"Dragonstep Boots","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.062727,"age_bonus_separate":true},
    {"rank":43,"type":"equipment","slot":"footwear","name":"Moonwalker Boots","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.061818,"age_bonus_separate":true},
    {"rank":44,"type":"equipment","slot":"footwear","name":"Stormrunner Boots","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.060909,"age_bonus_separate":true},
    {"rank":45,"type":"equipment","slot":"footwear","name":"Verdantstride Shoes","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.06,"age_bonus_separate":true},
    {"rank":46,"type":"equipment","slot":"footwear","name":"Nightstep Boots","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.059091,"age_bonus_separate":true},
    {"rank":47,"type":"equipment","slot":"footwear","name":"Embermarch Boots","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.058182,"age_bonus_separate":true},
    {"rank":48,"type":"equipment","slot":"footwear","name":"Starpath Greaves","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.057273,"age_bonus_separate":true},
    {"rank":49,"type":"equipment","slot":"footwear","name":"Ironbark Greaves","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.056364,"age_bonus_separate":true},
    {"rank":50,"type":"equipment","slot":"footwear","name":"Sovereign Sabatons","rarity":"Epic","status":"AGI +5; movement speed +4%; HP +3%","default_drop_rate_percent":0.055455,"age_bonus_separate":true},
    {"rank":51,"type":"equipment","slot":"accessory","name":"Sunheart Ring","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.054545,"age_bonus_separate":true},
    {"rank":52,"type":"equipment","slot":"accessory","name":"Dragoncore Ring","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.053636,"age_bonus_separate":true},
    {"rank":53,"type":"equipment","slot":"accessory","name":"Moonstone Seal","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.052727,"age_bonus_separate":true},
    {"rank":54,"type":"equipment","slot":"accessory","name":"Stormeye Ring","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.051818,"age_bonus_separate":true},
    {"rank":55,"type":"equipment","slot":"accessory","name":"Verdant Signet","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.050909,"age_bonus_separate":true},
    {"rank":56,"type":"equipment","slot":"accessory","name":"Nightglass Ring","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.05,"age_bonus_separate":true},
    {"rank":57,"type":"equipment","slot":"accessory","name":"Emberheart Pendant","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.049091,"age_bonus_separate":true},
    {"rank":58,"type":"equipment","slot":"accessory","name":"Starcall Talisman","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.048182,"age_bonus_separate":true},
    {"rank":59,"type":"equipment","slot":"accessory","name":"Ironbark Charm","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.047273,"age_bonus_separate":true},
    {"rank":60,"type":"equipment","slot":"accessory","name":"Sovereign Seal","rarity":"Epic","status":"ATK/MATK +5%; critical +3%; refine success +1%","default_drop_rate_percent":0.046364,"age_bonus_separate":true},
    {"rank":61,"type":"card","slot":"card","name":"Dawn Wyrm Card","rarity":"Legendary","status":"ATK +8%; elemental skill damage +6%; boss damage +3%","default_drop_rate_percent":0.045455,"age_bonus_separate":true},
    {"rank":62,"type":"card","slot":"card","name":"Dragon Emperor Card","rarity":"Legendary","status":"ATK +8%; elemental skill damage +6%; boss damage +3%","default_drop_rate_percent":0.044545,"age_bonus_separate":true},
    {"rank":63,"type":"card","slot":"card","name":"Moon Serpent Card","rarity":"Legendary","status":"HP +5%; ATK +5%; elemental resistance +3%","default_drop_rate_percent":0.043636,"age_bonus_separate":true},
    {"rank":64,"type":"card","slot":"card","name":"Storm Titan Card","rarity":"Legendary","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.042727,"age_bonus_separate":true},
    {"rank":65,"type":"card","slot":"card","name":"Verdant Ancient Card","rarity":"Legendary","status":"HP +5%; ATK +5%; elemental resistance +3%","default_drop_rate_percent":0.041818,"age_bonus_separate":true},
    {"rank":66,"type":"card","slot":"card","name":"Night Reaper Card","rarity":"Legendary","status":"ASPD +5%; critical +4%; movement speed +3%","default_drop_rate_percent":0.040909,"age_bonus_separate":true},
    {"rank":67,"type":"card","slot":"card","name":"Ember Phoenix Card","rarity":"Legendary","status":"ATK +8%; elemental skill damage +6%; boss damage +3%","default_drop_rate_percent":0.04,"age_bonus_separate":true},
    {"rank":68,"type":"card","slot":"card","name":"Star Oracle Card","rarity":"Legendary","status":"MATK +8%; SP +6%; skill cooldown -3%","default_drop_rate_percent":0.039091,"age_bonus_separate":true},
    {"rank":69,"type":"card","slot":"card","name":"Iron Colossus Card","rarity":"Legendary","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.038182,"age_bonus_separate":true},
    {"rank":70,"type":"card","slot":"card","name":"Sovereign Guardian Card","rarity":"Legendary","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.037273,"age_bonus_separate":true},
    {"rank":71,"type":"card","slot":"card","name":"Bloodfang Wolf Card","rarity":"Legendary","status":"ASPD +5%; critical +4%; movement speed +3%","default_drop_rate_percent":0.036364,"age_bonus_separate":true},
    {"rank":72,"type":"card","slot":"card","name":"Arcane Golem Card","rarity":"Legendary","status":"MATK +8%; SP +6%; skill cooldown -3%","default_drop_rate_percent":0.035455,"age_bonus_separate":true},
    {"rank":73,"type":"card","slot":"card","name":"Sky Mantis Card","rarity":"Legendary","status":"ASPD +5%; critical +4%; movement speed +3%","default_drop_rate_percent":0.034545,"age_bonus_separate":true},
    {"rank":74,"type":"card","slot":"card","name":"Grave Knight Card","rarity":"Legendary","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.033636,"age_bonus_separate":true},
    {"rank":75,"type":"card","slot":"card","name":"Plague Zombie Card","rarity":"Legendary","status":"HP +5%; ATK +5%; elemental resistance +3%","default_drop_rate_percent":0.032727,"age_bonus_separate":true},
    {"rank":76,"type":"card","slot":"card","name":"Forest Orc Card","rarity":"Legendary","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.031818,"age_bonus_separate":true},
    {"rank":77,"type":"card","slot":"card","name":"Crimson Goblin Card","rarity":"Legendary","status":"HP +5%; ATK +5%; elemental resistance +3%","default_drop_rate_percent":0.030909,"age_bonus_separate":true},
    {"rank":78,"type":"card","slot":"card","name":"Ancient Druid Card","rarity":"Legendary","status":"MATK +8%; SP +6%; skill cooldown -3%","default_drop_rate_percent":0.03,"age_bonus_separate":true},
    {"rank":79,"type":"card","slot":"card","name":"Royal Poring Card","rarity":"Legendary","status":"HP +5%; ATK +5%; elemental resistance +3%","default_drop_rate_percent":0.029091,"age_bonus_separate":true},
    {"rank":80,"type":"card","slot":"card","name":"Abyssal Dragon Card","rarity":"Legendary","status":"ATK +8%; elemental skill damage +6%; boss damage +3%","default_drop_rate_percent":0.028182,"age_bonus_separate":true},
    {"rank":81,"type":"card","slot":"card","name":"Celestial Knight Card","rarity":"Epic","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.027273,"age_bonus_separate":true},
    {"rank":82,"type":"card","slot":"card","name":"Void Mage Card","rarity":"Epic","status":"MATK +8%; SP +6%; skill cooldown -3%","default_drop_rate_percent":0.026364,"age_bonus_separate":true},
    {"rank":83,"type":"card","slot":"card","name":"Wild Falcon Card","rarity":"Epic","status":"ASPD +5%; critical +4%; movement speed +3%","default_drop_rate_percent":0.025455,"age_bonus_separate":true},
    {"rank":84,"type":"card","slot":"card","name":"Shadow Thief Card","rarity":"Epic","status":"ASPD +5%; critical +4%; movement speed +3%","default_drop_rate_percent":0.024545,"age_bonus_separate":true},
    {"rank":85,"type":"card","slot":"card","name":"Sacred Acolyte Card","rarity":"Epic","status":"MATK +8%; SP +6%; skill cooldown -3%","default_drop_rate_percent":0.023636,"age_bonus_separate":true},
    {"rank":86,"type":"card","slot":"card","name":"Merchant Prince Card","rarity":"Epic","status":"refine material cost -2%; Zeny gain +5%; carrying capacity +10%","default_drop_rate_percent":0.022727,"age_bonus_separate":true},
    {"rank":87,"type":"card","slot":"card","name":"Warrior Lord Card","rarity":"Epic","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.021818,"age_bonus_separate":true},
    {"rank":88,"type":"card","slot":"card","name":"Arcane Master Card","rarity":"Epic","status":"MATK +8%; SP +6%; skill cooldown -3%","default_drop_rate_percent":0.020909,"age_bonus_separate":true},
    {"rank":89,"type":"card","slot":"card","name":"Ranger Sovereign Card","rarity":"Epic","status":"ASPD +5%; critical +4%; movement speed +3%","default_drop_rate_percent":0.02,"age_bonus_separate":true},
    {"rank":90,"type":"card","slot":"card","name":"Thief King Card","rarity":"Epic","status":"ASPD +5%; critical +4%; movement speed +3%","default_drop_rate_percent":0.019091,"age_bonus_separate":true},
    {"rank":91,"type":"card","slot":"card","name":"Aegis Saint Card","rarity":"Epic","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.018182,"age_bonus_separate":true},
    {"rank":92,"type":"card","slot":"card","name":"Forge Master Card","rarity":"Epic","status":"refine material cost -2%; Zeny gain +5%; carrying capacity +10%","default_drop_rate_percent":0.017273,"age_bonus_separate":true},
    {"rank":93,"type":"card","slot":"card","name":"World Tree Card","rarity":"Epic","status":"HP +5%; ATK +5%; elemental resistance +3%","default_drop_rate_percent":0.016364,"age_bonus_separate":true},
    {"rank":94,"type":"card","slot":"card","name":"Star Dragon Card","rarity":"Epic","status":"ATK +8%; elemental skill damage +6%; boss damage +3%","default_drop_rate_percent":0.015455,"age_bonus_separate":true},
    {"rank":95,"type":"card","slot":"card","name":"Eternal Guardian Card","rarity":"Epic","status":"DEF +7%; HP +8%; damage reduction +2%","default_drop_rate_percent":0.014545,"age_bonus_separate":true},
    {"rank":96,"type":"card","slot":"card","name":"Inferno Lord Card","rarity":"Epic","status":"ATK +8%; elemental skill damage +6%; boss damage +3%","default_drop_rate_percent":0.013636,"age_bonus_separate":true},
    {"rank":97,"type":"card","slot":"card","name":"Glacial Queen Card","rarity":"Epic","status":"MATK +8%; SP +6%; skill cooldown -3%","default_drop_rate_percent":0.012727,"age_bonus_separate":true},
    {"rank":98,"type":"card","slot":"card","name":"Thunder Roc Card","rarity":"Epic","status":"ATK +8%; elemental skill damage +6%; boss damage +3%","default_drop_rate_percent":0.011818,"age_bonus_separate":true},
    {"rank":99,"type":"card","slot":"card","name":"Ancient Kraken Card","rarity":"Epic","status":"ATK +8%; elemental skill damage +6%; boss damage +3%","default_drop_rate_percent":0.010909,"age_bonus_separate":true},
    {"rank":100,"type":"card","slot":"card","name":"Chronos Beast Card","rarity":"Epic","status":"HP +5%; ATK +5%; elemental resistance +3%","default_drop_rate_percent":0.01,"age_bonus_separate":true}
]

static func all()->Array:
    return TOP_100.duplicate(true)

static func get_by_rank(rank:int)->Dictionary:
    if rank < 1 or rank > TOP_100.size():
        return {}
    return TOP_100[rank - 1].duplicate(true)

static func get_by_name(item_name:String)->Dictionary:
    for entry in TOP_100:
        if String(entry.get("name","")) == item_name:
            return entry.duplicate(true)
    return {}

static func default_drop_rate_percent(rank:int)->float:
    var entry:Dictionary = get_by_rank(rank)
    return float(entry.get("default_drop_rate_percent",0.0))

static func count()->int:
    return TOP_100.size()

static func validate()->Dictionary:
    var names:Dictionary = {}
    var total:float = 0.0
    var errors:Array[String] = []
    for entry in TOP_100:
        var rank:int = int(entry.get("rank",0))
        var name:String = String(entry.get("name",""))
        var rate:float = float(entry.get("default_drop_rate_percent",0.0))
        if rank < 1 or rank > 100: errors.append("invalid rank: %s" % rank)
        if names.has(name): errors.append("duplicate name: %s" % name)
        names[name] = true
        if rate <= 0.0: errors.append("non-positive rate: %s" % name)
        total += rate
    if TOP_100.size() != 100: errors.append("expected 100 entries, got %s" % TOP_100.size())
    return {"valid":errors.is_empty(),"count":TOP_100.size(),"total_base_rate_percent":total,"errors":errors}
