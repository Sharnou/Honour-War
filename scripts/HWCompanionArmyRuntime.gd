extends Node
class_name HWCompanionArmyRuntime

## Unified companion/pet + soldier runtime contract for Honour War.
## Pets are permanently bound to the hero; soldiers are produced by bases/cities.

const MAX_PET_LEVEL:int = 250
const MAX_SOLDIER_LEVEL:int = 50
const SOLDIERS_PER_RESPAWN_BATCH:int = 5
const SOLDIER_AUTO_SKILLS:int = 2

var pet:Dictionary = {}
var soldier_reserve:int = 0
var active_soldiers:Array[Dictionary] = []
var bank_assignments:Dictionary = {}

func initialize_pet(hero_class:String="Adventurer", pet_name:String="Companion") -> Dictionary:
    if pet.is_empty():
        pet = {"name":pet_name,"class":hero_class,"level":1,"xp":0,"skills":["Bond Strike","Guardian Instinct"],"refine":0,"alive":true}
    return pet.duplicate(true)

func gain_pet_xp(amount:int) -> Dictionary:
    initialize_pet()
    pet.xp += maxi(0,amount)
    while pet.level < MAX_PET_LEVEL and pet.xp >= _pet_xp_to_next(pet.level):
        pet.xp -= _pet_xp_to_next(pet.level)
        pet.level += 1
    return pet.duplicate(true)

func refine_pet(level:int) -> Dictionary:
    initialize_pet()
    pet.refine = clampi(level,0,15)
    return pet.duplicate(true)

func produce_soldiers(count:int, soldier_type:String="Guard") -> int:
    var produced:int = maxi(0,count)
    soldier_reserve += produced
    return produced

func deploy_soldiers(count:int, bank_id:String="") -> int:
    var amount:int = mini(maxi(0,count),soldier_reserve)
    soldier_reserve -= amount
    for i in range(amount):
        active_soldiers.append({"level":1,"type":bank_id if bank_id != "" else "Guard","auto_skills":SOLDIER_AUTO_SKILLS,"alive":true})
    if bank_id != "":
        bank_assignments[bank_id] = int(bank_assignments.get(bank_id,0)) + amount
    return amount

func soldier_death(count:int=1) -> Dictionary:
    var deaths:int = maxi(0,count)
    var respawned:int = (deaths / SOLDIERS_PER_RESPAWN_BATCH) * SOLDIERS_PER_RESPAWN_BATCH
    var survivors_to_remove:int = mini(deaths,active_soldiers.size())
    for i in range(survivors_to_remove):
        active_soldiers.pop_back()
    if respawned > 0:
        soldier_reserve += respawned
    return {"deaths":deaths,"respawn_batch":respawned,"city_production_return":respawned,"active":active_soldiers.size()}

func assign_bank(bank_id:String, count:int) -> int:
    var deployed:int = deploy_soldiers(count,bank_id)
    return deployed

func clear_bank(bank_id:String) -> int:
    var count:int = int(bank_assignments.get(bank_id,0))
    bank_assignments.erase(bank_id)
    return count

func _pet_xp_to_next(level:int) -> int:
    return maxi(50,roundi(80.0*pow(float(clampi(level,1,MAX_PET_LEVEL)),1.16)))
