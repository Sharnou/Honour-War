class_name HWAccountDatabase
extends RefCounted

## Persistent server account database.
## Passwords are never stored directly. A per-account salt and password verifier
## are stored; challenge responses are derived from the verifier.
## Account gender is selected once at registration and is immutable thereafter.

const HWGenderPolicyClass = preload("res://scripts/HWGenderPolicy.gd")
const SCHEMA_VERSION:int = 1
const DEFAULT_PATH:String = "user://honour_war_accounts.json"
const MAX_ACCOUNTS:int = 100000
const MIN_USERNAME_LENGTH:int = 3
const MAX_USERNAME_LENGTH:int = 24
var path:String=DEFAULT_PATH
var accounts:Dictionary={}

func _init(storage_path:String=DEFAULT_PATH)->void:
    path=storage_path;load_database()
func load_database()->bool:
    accounts.clear()
    if not FileAccess.file_exists(path):return true
    var file:=FileAccess.open(path,FileAccess.READ)
    if file==null:return false
    var parsed:Variant=JSON.parse_string(file.get_as_text());file.close()
    if not parsed is Dictionary:return false
    var root:Dictionary=parsed
    if int(root.get("schema",0))!=SCHEMA_VERSION:return false
    var raw:Variant=root.get("accounts",{})
    if not raw is Dictionary:return false
    accounts=raw.duplicate(true);return true
func flush()->bool:
    if accounts.size()>MAX_ACCOUNTS:return false
    var file:=FileAccess.open(path,FileAccess.WRITE)
    if file==null:return false
    file.store_string(JSON.stringify({"schema":SCHEMA_VERSION,"accounts":accounts}));file.close();return true
func account_exists(username:String)->bool:return accounts.has(_normalize_username(username))
func account_gender(username:String)->String:
    var record:Variant=accounts.get(_normalize_username(username),{})
    if not record is Dictionary:return HWGenderPolicyClass.UNKNOWN
    var gender:=HWGenderPolicyClass.normalize_gender(str(record.get("gender",HWGenderPolicyClass.UNKNOWN)))
    return gender if gender in [HWGenderPolicyClass.MALE,HWGenderPolicyClass.FEMALE] else HWGenderPolicyClass.UNKNOWN
func can_use_character_gender(username:String,character_gender:String)->bool:return HWGenderPolicyClass.can_use_character_gender(account_gender(username),character_gender)
func create_account(username:String,salt:String,verifier:String,player:Dictionary)->bool:
    var normalized:=_normalize_username(username)
    if not validate_username(normalized):return false
    if salt.strip_edges().length()<16 or verifier.strip_edges().length()!=64:return false
    if accounts.has(normalized) or accounts.size()>=MAX_ACCOUNTS:return false
    var gender:=HWGenderPolicyClass.normalize_gender(str(player.get("gender",HWGenderPolicyClass.UNKNOWN)))
    if gender==HWGenderPolicyClass.UNKNOWN:gender=HWGenderPolicyClass.registration_gender(normalized)
    if gender==HWGenderPolicyClass.UNKNOWN:gender=HWGenderPolicyClass.MALE
    var locked_player:=HWGenderPolicyClass.lock_player_gender(player,gender)
    accounts[normalized]={"username":normalized,"salt":salt,"verifier":verifier,"gender":gender,"gender_locked":true,"created_at":Time.get_unix_time_from_system(),"last_login":0,"updated_at":Time.get_unix_time_from_system(),"player":locked_player}
    return flush()
func get_auth_record(username:String)->Dictionary:
    var value:Variant=accounts.get(_normalize_username(username),{})
    return value.duplicate(true) if value is Dictionary else {}
func authenticate_challenge(username:String,response:String,nonce:String)->bool:
    var record:=get_auth_record(username)
    if record.is_empty():return false
    return _constant_time_equal(challenge_digest(str(record.get("verifier","")),nonce),response.strip_edges())
func mark_login(username:String)->void:
    var normalized:=_normalize_username(username)
    if not accounts.has(normalized):return
    accounts[normalized]["last_login"]=Time.get_unix_time_from_system();accounts[normalized]["updated_at"]=Time.get_unix_time_from_system();flush()
func load_player(username:String,default_player:Dictionary)->Dictionary:
    var record:=get_auth_record(username)
    if record.is_empty():return default_player.duplicate(true)
    var gender:=account_gender(username)
    var stored:Variant=record.get("player",{})
    if stored is Dictionary and not stored.is_empty() and gender in [HWGenderPolicyClass.MALE,HWGenderPolicyClass.FEMALE]:return HWGenderPolicyClass.lock_player_gender(stored,gender)
    return HWGenderPolicyClass.lock_player_gender(default_player,gender) if gender in [HWGenderPolicyClass.MALE,HWGenderPolicyClass.FEMALE] else default_player.duplicate(true)
func save_player(username:String,player:Dictionary)->bool:
    var normalized:=_normalize_username(username)
    if not accounts.has(normalized) or not player is Dictionary:return false
    var gender:=account_gender(normalized)
    var locked:=HWGenderPolicyClass.lock_player_gender(player,gender)
    accounts[normalized]["player"]=locked;accounts[normalized]["updated_at"]=Time.get_unix_time_from_system();return flush()
static func validate_username(username:String)->bool:
    var value:=username.strip_edges()
    if value.length()<MIN_USERNAME_LENGTH or value.length()>MAX_USERNAME_LENGTH:return false
    for character in value:
        var code:=character.unicode_at(0)
        if not ((code>=48 and code<=57) or (code>=65 and code<=90) or (code>=97 and code<=122) or code==95 or code==45):return false
    return true
static func password_verifier(password:String,salt:String)->String:return (password+":"+salt).sha256_text()
static func challenge_digest(verifier:String,nonce:String)->String:return (verifier+":"+nonce).sha256_text()
static func _constant_time_equal(a:String,b:String)->bool:
    if a.length()!=b.length():return false
    var different:=0
    for i in a.length():different|=a.unicode_at(i)^b.unicode_at(i)
    return different==0
func _normalize_username(username:String)->String:return username.strip_edges().to_lower()
