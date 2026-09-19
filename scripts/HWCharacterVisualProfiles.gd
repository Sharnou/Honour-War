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
