class_name HWGenderPolicy
extends RefCounted

## Honour War account gender policy.
## Gender is selected exactly once at registration and is immutable for that account.
## Character gender must always match the account gender.

const MALE:String = "M"
const FEMALE:String = "F"
const UNKNOWN:String = "U"

static func normalize_gender(value:String) -> String:
    var gender:String = value.strip_edges().to_upper()
    if gender in [MALE,FEMALE]:
        return gender
    return UNKNOWN

static func gender_from_username(username:String) -> String:
    var value:String = username.strip_edges().to_upper()
    if value.ends_with("_M"):
        return MALE
    if value.ends_with("_F"):
        return FEMALE
    return UNKNOWN

static func registration_gender(username:String) -> String:
    return gender_from_username(username)

static func is_registration_gender_valid(username:String) -> bool:
    return registration_gender(username) != UNKNOWN

static func can_use_character_gender(account_gender:String, character_gender:String) -> bool:
    var account:String = normalize_gender(account_gender)
    var character:String = normalize_gender(character_gender)
    return account in [MALE,FEMALE] and account == character

static func lock_player_gender(player:Dictionary, account_gender:String) -> Dictionary:
    var locked:Dictionary = player.duplicate(true)
    var gender:String = normalize_gender(account_gender)
    if gender in [MALE,FEMALE]:
        locked["gender"] = gender
        locked["gender_locked"] = true
    return locked

static func validate_player_gender(player:Dictionary, account_gender:String) -> bool:
    if not player is Dictionary:
        return false
    return can_use_character_gender(account_gender,str(player.get("gender",UNKNOWN)))
