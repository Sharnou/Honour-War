extends Node

## Server-authoritative gameplay execution layer.
## Converts accepted network actions into deterministic progression changes.
## Client-side combat remains presentation-only; the server owns rewards/state.

const AuthorityPath:String = "/root/HWOnlineAuthorityRuntime"
const GameplayFormula = preload("res://scripts/GameplayFormula.gd")
const LootSystem = preload("res://scripts/LootSystem.gd")
const CharacterProgression = preload("res://scripts/CharacterProgressionSystem.gd")
const SaveSystem = preload("res://scripts/SaveSystem.gd")
const SkillSystem = preload("res://scripts/SkillSystem.gd")

signal gameplay_result(peer_id:int,result:Dictionary)
signal combat_result(peer_id:int,result:Dictionary)
signal progression_changed(peer_id:int,player:Dictionary)

const SAVE_INTERVAL:float = 15.0
const MAX_MONSTERS_PER_MAP:int = 300
const MIN_MONSTER_LEVEL:int = 1
const MAX_MONSTER_LEVEL:int = 300

var authority:Node
var monster_state:Dictionary = {}
var save_elapsed:float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind")

func _process(delta:float) -> void:
    save_elapsed += delta
    if save_elapsed < SAVE_INTERVAL:
        return
    save_elapsed = 0.0
    _save_authenticated_players()

func _bind() -> void:
    authority = get_node_or_null(AuthorityPath)
    if authority == null:
        call_deferred("_bind")
        return
    if authority.has_signal("authoritative_action_accepted") and not authority.authoritative_action_accepted.is_connected(_on_action):
        authority.authoritative_action_accepted.connect(_on_action)

func _is_server() -> bool:
    return authority != null and is_instance_valid(authority) and authority.is_authority()

func _on_action(event:Dictionary) -> void:
    if not _is_server():
        return
    var peer_id:int = int(event.get("sender",0))
    var action:String = str(event.get("action",""))
    var payload:Dictionary = event.get("payload",{})
    if peer_id <= 0 or not authority.is_peer_authenticated(peer_id):
        return
    var player:Dictionary = authority.player_for_peer(peer_id)
    if player.is_empty():
        return
    var result:Dictionary = {}
    match action:
        "move":
            result = _apply_move(peer_id,player,payload)
        "attack":
            result = _apply_attack(peer_id,player,payload)
        "cast_skill","use_skill":
            result = _apply_skill(peer_id,player,payload)
        "use_item":
            result = _apply_use_item(peer_id,player,payload)
        "buy":
            result = _apply_buy(peer_id,player,payload)
        "sell":
            result = _apply_sell(peer_id,player,payload)
        "refine":
            result = _apply_refine(peer_id,player,payload,false)
        "refine_pet":
            result = _apply_refine(peer_id,player,payload,true)
        "loot":
            result = _apply_loot(peer_id,player,payload)
        "warp":
            result = _apply_warp(peer_id,player,payload)
        _:
            return
    if not result.is_empty():
        authority.set_player_for_peer(peer_id,player)
        gameplay_result.emit(peer_id,result)
        _broadcast_result(peer_id,result)

func _apply_move(peer_id:int,player:Dictionary,payload:Dictionary)->Dictionary:
    if not bool(payload.get("absolute",false)):
        return {"action":"move","ok":true}
    player["pos_x"]=float(payload.get("x",player.get("pos_x",595.0)))
    player["pos_y"]=float(payload.get("y",player.get("pos_y",340.0)))
    return {"action":"move","ok":true,"x":player["pos_x"],"y":player["pos_y"],"map_id":int(player.get("map_id",0))}

func _apply_attack(peer_id:int,player:Dictionary,payload:Dictionary)->Dictionary:
    var target_id:int=int(payload.get("target_id",payload.get("target",0)))
    if target_id<=0:
        return {"action":"attack","ok":false,"reason":"invalid_target"}
    var map_id:int=int(player.get("map_id",0))
    var key:String="%d:%d" % [map_id,target_id]
    var monster:Dictionary=monster_state.get(key,{})
    if monster.is_empty():
        var hero_level:int=clamp(int(player.get("level",1)),1,250)
        var requested_level:int=int(payload.get("target_level",hero_level))
        var level:int=clamp(requested_level,1,300)
        var max_hp:int=max(50,level*70)
        monster={"target_id":target_id,"map_id":map_id,"level":level,"name":str(payload.get("target_name","Monster #%d" % target_id)),"hp":max_hp,"max_hp":max_hp,"mvp":bool(payload.get("mvp",level>=250))}
    var stats:Dictionary=GameplayFormula.hero_stats(int(player.get("level",1)),player)
    var critical:bool=(int(Time.get_ticks_msec())+peer_id+target_id)%17==0
    var damage:int=GameplayFormula.physical_damage(int(stats.get("attack",40)),max(1,int(monster.get("level",1))*2),1.0,critical)
    monster["hp"]=max(0,int(monster.get("hp",0))-damage)
    monster_state[key]=monster
    var result:Dictionary={"action":"attack","ok":true,"target_id":target_id,"damage":damage,"critical":critical,"monster_hp":int(monster["hp"]),"monster_max_hp":int(monster["max_hp"]),"monster_level":int(monster["level"])}
    if int(monster["hp"])<=0:
        var rng:RandomNumberGenerator=RandomNumberGenerator.new()
        rng.seed=hash("%d:%d:%d:%d" % [peer_id,target_id,int(player.get("kills",0)),int(Time.get_unix_time_from_system())])
        var drops:Array[String]=LootSystem.on_monster_defeated(player,monster,rng)
        player["kills"]=int(player.get("kills",0))+1
        result["defeated"]=true
        result["drops"]=drops
        result["xp"]=int(player.get("loot_stats",{}).get("xp",0))
        result["zeny"]=int(player.get("zeny",0))
        monster_state.erase(key)
        progression_changed.emit(peer_id,player.duplicate(true))
    combat_result.emit(peer_id,result)
    return result

func _apply_skill(peer_id:int,player:Dictionary,payload:Dictionary)->Dictionary:
    var skill:String=str(payload.get("skill","")).strip_edges()
    if skill.is_empty():
        return {"action":"skill","ok":false,"reason":"skill_required"}
    var now:float=Time.get_ticks_msec()/1000.0
    var used:Dictionary=SkillSystem.use(player,skill,now)
    if not bool(used.get("ok",false)):
        return {"action":"skill","ok":false,"reason":str(used.get("reason","skill_rejected")),"skill":skill,"sp":int(player.get("sp",0))}
    return {"action":"skill","ok":true,"skill":skill,"power":int(used.get("power",0)),"sp":int(player.get("sp",0)),"sp_cost":int(used.get("sp_cost",0)),"cooldown":float(used.get("skill",{}).get("cooldown",0.0))}

func _apply_use_item(peer_id:int,player:Dictionary,payload:Dictionary)->Dictionary:
    var item:String=str(payload.get("item","")).strip_edges()
    var inventory:Dictionary=player.get("inventory",{})
    var count:int=int(inventory.get(item,0))
    if item.is_empty() or count<=0:
        return {"action":"use_item","ok":false,"reason":"item_unavailable"}
    inventory[item]=count-1
    player["inventory"]=inventory
    player["hp"]=min(int(player.get("max_hp",100)),int(player.get("hp",100))+50)
    return {"action":"use_item","ok":true,"item":item,"hp":int(player["hp"])}

func _apply_buy(peer_id:int,player:Dictionary,payload:Dictionary)->Dictionary:
    var item:String=str(payload.get("item","")).strip_edges()
    var price:int=clamp(int(payload.get("price",0)),0,1000000000)
    if item.is_empty() or price<=0 or int(player.get("zeny",0))<price:
        return {"action":"buy","ok":false,"reason":"insufficient_zeny_or_invalid_item"}
    var inventory:Dictionary=player.get("inventory",{})
    inventory[item]=int(inventory.get(item,0))+1
    player["inventory"]=inventory
    player["zeny"]=int(player.get("zeny",0))-price
    return {"action":"buy","ok":true,"item":item,"price":price,"zeny":int(player["zeny"])}

func _apply_sell(peer_id:int,player:Dictionary,payload:Dictionary)->Dictionary:
    var item:String=str(payload.get("item","")).strip_edges()
    var inventory:Dictionary=player.get("inventory",{})
    var count:int=int(inventory.get(item,0))
    var price:int=clamp(int(payload.get("price",0)),1,1000000000)
    if item.is_empty() or count<=0:
        return {"action":"sell","ok":false,"reason":"item_unavailable"}
    inventory[item]=count-1
    player["inventory"]=inventory
    player["zeny"]=int(player.get("zeny",0))+price
    return {"action":"sell","ok":true,"item":item,"price":price,"zeny":int(player["zeny"])}

func _apply_refine(peer_id:int,player:Dictionary,payload:Dictionary,is_pet:bool)->Dictionary:
    var slot:String=str(payload.get("slot","weapon")).strip_edges()
    var equipment:Dictionary=player.get("equipment",{})
    var item_name:String=str(equipment.get(slot,""))
    if item_name.is_empty():
        return {"action":"refine","ok":false,"reason":"equipment_unavailable"}
    var current:int=clamp(int(payload.get("refine",player.get("refine",0))),0,15)
    if current>=15:
        return {"action":"refine","ok":false,"reason":"max_refine","pet":is_pet,"slot":slot,"refine":15}
    var age:int=int(player.get("age",18))
    var chance:float=GameplayFormula.refine_success_rate(current,age)
    var roll:float=clampf(float(payload.get("roll",0.5)),0.0,0.999999)
    var success:bool=roll<chance
    var next_refine:int=current
    if success:
        next_refine=current+1
        equipment[slot]=item_name+" +%d" % next_refine
        player["equipment"]=equipment
    return {"action":"refine","ok":true,"pet":is_pet,"slot":slot,"success":success,"chance":chance,"refine":next_refine}

func _apply_loot(peer_id:int,player:Dictionary,payload:Dictionary)->Dictionary:
    var gained:Array[String]=LootSystem.collect_ground(player)
    return {"action":"loot","ok":true,"gained":gained}

func _apply_warp(peer_id:int,player:Dictionary,payload:Dictionary)->Dictionary:
    player["map_id"]=max(0,int(payload.get("map_id",0)))
    player["pos_x"]=float(payload.get("x",595.0))
    player["pos_y"]=float(payload.get("y",340.0))
    return {"action":"warp","ok":true,"map_id":int(player["map_id"]),"x":float(player["pos_x"]),"y":float(player["pos_y"])}

func _broadcast_result(peer_id:int,result:Dictionary)->void:
    if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
        return
    if peer_id>0 and multiplayer.get_peers().has(peer_id):
        _client_gameplay_result.rpc_id(peer_id,result)

@rpc("authority","reliable")
func _client_gameplay_result(result:Dictionary)->void:
    gameplay_result.emit(multiplayer.get_unique_id(),result)

func _save_authenticated_players()->void:
    if not _is_server():
        return
    for peer_value:Variant in authority._authenticated_peers.keys():
        var peer_id:int=int(peer_value)
        var player:Dictionary=authority.player_for_peer(peer_id)
        if not player.is_empty():
            authority.save_player_for_peer(peer_id,player)
