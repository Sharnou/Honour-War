class_name HWCharacterVisualProfiles
extends RefCounted

const GameDataClass = preload("res://scripts/GameData.gd")

## Canonical six-class clothing, emotion and motion profiles.
## The profile follows GameDataClass.class_rank_for_hero(), so every job promotion
## changes the displayed title, clothing emphasis, silhouette and motion language.

const PROFILES:Dictionary={
    "Warrior":{"emotion":"fierce/courageous","clothing":["segmented plate armor","pauldrons","gauntlets","tassets","cape","greatsword"],"motion":"firm stance, strong shoulder drive, decisive weapon recovery","accent":"steel/gold","signature":["Greatsword","SegmentedPauldron","Tasset","Cape"]},
    "Mage":{"emotion":"aloof/concentrated","clothing":["wizard hat","layered robe","sash","staff","arcane orb","magic circle"],"motion":"measured robe sway, focused casting pose, controlled staff movement","accent":"arcane violet","signature":["WizardHat","LayeredRobe","MageSash","ArcaneOrb","MagicCircle"]},
    "Archer":{"emotion":"alert/natural","clothing":["tunic","leather chest guard","bracers","quiver","arrows","detailed bow"],"motion":"light footwork, alert torso scan, natural bow draw/release recovery","accent":"forest green","signature":["ArcherTunic","LeatherChestGuard","Bracer","Quiver","Bow"]},
    "Thief":{"emotion":"focused/calculating","clothing":["mask","tactical harness","wraps","sheaths","dual daggers","shadow effect"],"motion":"low center of gravity, quick hand shifts, evasive shadow sway","accent":"shadow crimson","signature":["ShadowMask","TacticalHarness","Wrap","Sheath","DualDagger"]},
    "Acolyte":{"emotion":"serene/benevolent","clothing":["white robe","blue stole","gold cross","halo","staff","divine aura"],"motion":"calm robe sway, open posture, gentle staff and aura movement","accent":"white/blue/gold","signature":["WhiteRobe","BlueStole","GoldCrossV","GoldCrossH","DivineHalo"]},
    "Merchant":{"emotion":"confident/opportunistic","clothing":["detailed vest","suspenders","belt","coin pouch","scale","cart","potions"],"motion":"confident weight shift, purposeful arm gesture, lively trade motion","accent":"merchant blue/gold","signature":["MerchantVest","Suspender","CoinPouch","TradeScale","CartHandle","Potion"]}
}

const BRANCH_VISUALS:Dictionary={
    "Warlord":{"emotion":"commanding/unyielding","clothing":["reinforced war mantle","rank insignia","battle sash"],"style":"command-warrior"},
    "Guardian":{"emotion":"calm/vigilant","clothing":["tower shield harness","fortress pauldrons","protective tabard"],"style":"fortress-warrior"},
    "Berserker":{"emotion":"fierce/raging","clothing":["scarred plate","red battle wraps","exposed trophy straps"],"style":"berserker-warrior"},
    "Dragoon":{"emotion":"proud/decisive","clothing":["long cavalry coat","lance harness","high boots"],"style":"dragoon-warrior"},
    "Elementalist":{"emotion":"curious/commanding","clothing":["elemental mantle","rune sash","crystal clasps"],"style":"elemental-mage"},
    "Voidcaller":{"emotion":"intense/secretive","clothing":["void-lined robe","dark hood","void sigils"],"style":"void-mage"},
    "Astral Sage":{"emotion":"wise/serene","clothing":["star mantle","astral collar","constellation trim"],"style":"astral-mage"},
    "Chronomancer":{"emotion":"precise/composed","clothing":["clockwork robe trim","timepiece sash","chrono seals"],"style":"chrono-mage"},
    "Sniper":{"emotion":"focused/cold","clothing":["precision cloak","long-range harness","scope bracer"],"style":"sniper-archer"},
    "Falconer":{"emotion":"alert/connected","clothing":["falcon mantle","feather clasp","companion harness"],"style":"falconer-archer"},
    "Trapper":{"emotion":"cautious/calculating","clothing":["utility mantle","trap belt","field pouches"],"style":"trapper-archer"},
    "Ballista":{"emotion":"confident/forceful","clothing":["heavy bow harness","reinforced bracers","siege quiver"],"style":"ballista-archer"},
    "Assassin":{"emotion":"cold/lethal","clothing":["assassin hood","precision harness","silent sheaths"],"style":"assassin-thief"},
    "Phantom":{"emotion":"elusive/quiet","clothing":["mist cloak","soft mask","ghost wraps"],"style":"phantom-thief"},
    "Venomblade":{"emotion":"cunning/menacing","clothing":["venom vials","toxin sash","scaled wraps"],"style":"venomblade-thief"},
    "Shadow Dancer":{"emotion":"playful/dangerous","clothing":["flowing shadow scarf","dance wraps","lightweight sheaths"],"style":"shadow-dancer-thief"},
    "Priest":{"emotion":"compassionate/steady","clothing":["healing stole","ceremonial mantle","prayer cord"],"style":"priest-acolyte"},
    "Saint":{"emotion":"radiant/merciful","clothing":["saintly mantle","radiant stole","blessing ribbons"],"style":"saint-acolyte"},
    "Exorcist":{"emotion":"stern/purifying","clothing":["exorcist seals","warded robe","holy talisman belt"],"style":"exorcist-acolyte"},
    "Oracle":{"emotion":"visionary/serene","clothing":["oracle veil","prophecy sash","luminous sigils"],"style":"oracle-acolyte"},
    "Blacksmith":{"emotion":"proud/industrious","clothing":["forge apron","reinforced vest","smith gloves"],"style":"blacksmith-merchant"},
    "Alchemist":{"emotion":"curious/calculating","clothing":["alchemy apron","potion harness","chemical satchel"],"style":"alchemist-merchant"},
    "Arsenal Lord":{"emotion":"commanding/confident","clothing":["arsenal coat","equipment harness","metal shoulder guard"],"style":"arsenal-merchant"},
    "Tactician":{"emotion":"strategic/alert","clothing":["command vest","map sash","utility belt"],"style":"tactician-merchant"}
}

static func branch_visual(branch:String)->Dictionary:
    return (BRANCH_VISUALS.get(branch,{}) as Dictionary).duplicate(true)

static func branch_snapshot(hero:Dictionary)->Dictionary:
    var class_id:String=str(hero.get("class","Warrior"))
    var branch:String=str(hero.get("class_branch",""))
    var base:Dictionary=snapshot(hero)
    var branch_data:Dictionary=branch_visual(branch)
    base["class_branch"]=branch
    base["branch_visual_style"]=str(branch_data.get("style",""))
    base["branch_emotion"]=str(branch_data.get("emotion",base.get("emotion","")))
    base["branch_clothing"]=branch_data.get("clothing",[]).duplicate(true) if branch_data.has("clothing") else []
    base["branch_visual_identity_locked"]=branch != "" and branch in BRANCH_VISUALS
    return base

static func profile(class_id:String)->Dictionary:
    return (PROFILES.get(class_id,PROFILES["Warrior"]) as Dictionary).duplicate(true)

static func snapshot(hero:Dictionary)->Dictionary:
    var class_id:String=str(hero.get("class","Warrior"))
    var level:int=int(hero.get("level",1))
    var p:Dictionary=profile(class_id)
    p["class"]=class_id
    p["level"]=level
    p["rank"]=GameDataClass.class_rank_for_hero(hero)
    p["tier"]=GameDataClass.class_tier_for_level(level)
    p["stage"]=["Foundation","Specialization","Advanced","Mastery","Transcendence"][clampi(p["tier"],0,4)]
    return p
