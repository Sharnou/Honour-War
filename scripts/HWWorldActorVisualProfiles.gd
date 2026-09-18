class_name HWWorldActorVisualProfiles
extends RefCounted

## Canonical visual roles for non-player world actors.
## Names/jobs determine clothing language, emotion, movement and presentation metadata.
## This is presentation-only: it never changes combat balance or progression.

const PROFILES:Dictionary = {
    "Monster": {
        "emotion":"hostile / predatory",
        "motion":"weight-driven idle, threat turn, attack anticipation and recovery",
        "clothing":["species armor/skin","natural silhouette","visible weak-point accents"],
        "accent":"danger red",
        "vfx":"element/status aura"
    },
    "MVP": {
        "emotion":"dominant / intimidating",
        "motion":"slow authoritative idle, deliberate turn, heavy attack recovery",
        "clothing":["signature boss armor","ornate shoulder silhouette","trophy/head detail"],
        "accent":"mythic gold",
        "vfx":"element/status aura + boss presence"
    },
    "Pet": {
        "emotion":"loyal / expressive",
        "motion":"companion idle, head/ear/tail response, follow bounce and skill anticipation",
        "clothing":["species-specific harness","pet accessory","class-themed accent"],
        "accent":"owner-class accent",
        "vfx":"skill aura"
    },
    "Super Champion (Rental Only)": {
        "emotion":"calm / legendary / vigilant",
        "motion":"controlled champion stance, cape/cloth sway, confident turn and skill wind-up",
        "clothing":["mythic champion armor","ornate shoulder guards","champion mantle","class emblems"],
        "accent":"champion gold / royal blue",
        "vfx":"holy-gold aura"
    },
    "Item Shop": {
        "emotion":"friendly / attentive / commercial",
        "motion":"welcoming idle, hand gesture, merchandise glance and conversational turn",
        "clothing":["merchant vest","apron","utility belt","coin pouch"],
        "accent":"shop gold / warm brown",
        "vfx":"none"
    },
    "Rental Shop": {
        "emotion":"professional / trustworthy",
        "motion":"upright idle, contract gesture, confident greeting and service turn",
        "clothing":["formal merchant coat","blue-gold trim","rental insignia","document pouch"],
        "accent":"rental blue / gold",
        "vfx":"subtle contract sparkle"
    },
    "Equipment Shop": {
        "emotion":"proud / helpful",
        "motion":"inspect gear, present item, hammer/measurement gesture",
        "clothing":["blacksmith apron","leather gloves","utility belt"],
        "accent":"steel / ember"
    },
    "Card Service": {
        "emotion":"focused / knowledgeable",
        "motion":"inspect card, turn toward customer, careful hand presentation",
        "clothing":["collector coat","card case","gloves"],
        "accent":"violet / gold"
    },
    "Innkeeper / Healer": {
        "emotion":"warm / reassuring",
        "motion":"gentle greeting, calm sway, service gesture",
        "clothing":["innkeeper uniform","apron","service pouch"],
        "accent":"cream / green"
    },
    "Quest Master": {
        "emotion":"serious / encouraging",
        "motion":"notice-board glance, beckon, deliberate nod",
        "clothing":["guild coat","quest satchel","badge"],
        "accent":"guild blue"
    },
    "Warp Keeper": {
        "emotion":"calm / mystical",
        "motion":"measured idle, hand channeling, portal-facing turn",
        "clothing":["warp robe","hood","travel sigils"],
        "accent":"arcane cyan"
    }
}

static func profile(role:String)->Dictionary:
    return (PROFILES.get(role,PROFILES["Monster"]) as Dictionary).duplicate(true)

static func monster_profile(monster:Dictionary)->Dictionary:
    var mvp:bool=bool(monster.get("mvp",false))
    var p:Dictionary=profile("MVP" if mvp else "Monster")
    p["name"]=str(monster.get("name","Monster"))
    p["level"]=int(monster.get("level",1))
    p["element"]=str(monster.get("element","Neutral"))
    p["status"]=str(monster.get("status","None"))
    return p

static func pet_profile(pet:Dictionary)->Dictionary:
    var p:Dictionary=profile("Pet")
    p["name"]=str(pet.get("name","Pet"))
    p["species"]=str(pet.get("species",""))
    p["owner_class"]=str(pet.get("owner_class","Warrior"))
    p["level"]=int(pet.get("level",1))
    p["role"]=str(pet.get("role","Companion"))
    return p

static func npc_role(npc_name:String, job:String="")->String:
    var value:String=(npc_name+" "+job).to_lower()
    if value.contains("rent") or value.contains("rental") or value.contains("super champion"):
        return "Rental Shop"
    if value.contains("equipment") or value.contains("blacksmith") or value.contains("forge"):
        return "Equipment Shop"
    if value.contains("card"):
        return "Card Service"
    if value.contains("inn") or value.contains("heal"):
        return "Innkeeper / Healer"
    if value.contains("quest"):
        return "Quest Master"
    if value.contains("warp"):
        return "Warp Keeper"
    if value.contains("merchant") or value.contains("shop") or value.contains("item"):
        return "Item Shop"
    return "Item Shop"

static func npc_profile(npc_name:String,job:String="")->Dictionary:
    var role:String=npc_role(npc_name,job)
    var p:Dictionary=profile(role)
    p["name"]=npc_name
    p["job"]=job
    p["role"]=role
    return p
