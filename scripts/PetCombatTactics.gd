class_name PetCombatTactics
extends RefCounted

static func nearby_targets(monsters:Array,origin:Vector2,radius:float)->Array:
    var result:Array=[]
    for monster in monsters:
        if not monster is Dictionary or int(monster.get("hp",0))<=0: continue
        var pos:Vector2=monster.get("pos",origin)
        if origin.distance_to(pos)<=radius: result.append(monster)
    return result

static func count_cluster(monsters:Array,target:Dictionary,radius:float)->int:
    return nearby_targets(monsters,target.get("pos",Vector2.ZERO),radius).size()

static func best_target(monsters:Array,hero_pos:Vector2,current:Dictionary,role:String)->Dictionary:
    var candidates:Array=[]
    for monster in monsters:
        if monster is Dictionary and int(monster.get("hp",0))>0:
            var distance:float=hero_pos.distance_to(monster.get("pos",hero_pos))
            if distance<=260.0: candidates.append(monster)
    if candidates.is_empty(): return current if current is Dictionary else {}
    var best:Dictionary=candidates[0]
    var best_score:float=-INF
    for monster in candidates:
        var score:float=0.0
        var distance:float=hero_pos.distance_to(monster.get("pos",hero_pos))
        score-=distance*0.015
        score+=float(monster.get("pet_threat",0))*0.02
        if bool(monster.get("mvp",false)): score+=5.0
        var hp:float=float(monster.get("hp",1))/float(max(1,int(monster.get("max",monster.get("hp",1)))))
        if role=="DPS" or role=="Ranged": score+=(1.0-hp)*5.0
        if role=="Guardian": score+=float(monster.get("pet_threat",0))*0.04
        if monster==current: score+=3.0
        if score>best_score:
            best_score=score
            best=monster
    return best

static func should_use_aoe(skill:Dictionary,cluster_size:int,role:String)->bool:
    var kind:String=str(skill.get("kind",""))
    var tier:int=int(skill.get("tier",1))
    if kind=="ultimate": return cluster_size>=3 or role=="Guardian"
    if tier>=4: return cluster_size>=3
    if tier>=2: return cluster_size>=2
    return false

static func target_priority(monster:Dictionary,hero_pos:Vector2,role:String)->float:
    var score:float=0.0
    var distance:float=hero_pos.distance_to(monster.get("pos",hero_pos))
    score-=distance*0.02
    if bool(monster.get("mvp",false)): score+=8.0
    score+=float(monster.get("pet_threat",0))*0.05
    if role=="Guardian" and bool(monster.get("target_pet_until",0.0)): score+=4.0
    var hp:float=float(monster.get("hp",1))/float(max(1,int(monster.get("max",monster.get("hp",1)))))
    if role=="DPS" or role=="Ranged": score+=(1.0-hp)*6.0
    return score
