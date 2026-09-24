#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "HonourWarTypes.h"
#include "HonourWarCombatComponent.generated.h"

class AHonourWarMonster;
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FHonourWarSkillEvent, int32, SkillIndex, float, Damage);

UCLASS(ClassGroup=(HonourWar), meta=(BlueprintSpawnableComponent))
class HONOURWAR_API UHonourWarCombatComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    UHonourWarCombatComponent();

    UPROPERTY(BlueprintAssignable) FHonourWarSkillEvent OnSkillUsed;

    bool UseSkill(int32 SkillIndex);
    void ReceiveDamage(float Damage);
    void ReceiveMonsterAttack(float Damage,int32 AttackerLevel);
    void RestoreVitals();

    float GetHealthPercent() const { return MaxHealth > 0.0f ? CurrentHealth / MaxHealth : 0.0f; }
    float GetSpPercent() const { return MaxSp > 0.0f ? CurrentSp / MaxSp : 0.0f; }
    float GetXpPercent() const { return XpToNextLevel > 0 ? static_cast<float>(Experience) / XpToNextLevel : 0.0f; }
    float GetCurrentHealth() const { return CurrentHealth; }
    float GetMaxHealth() const { return MaxHealth; }
    float GetCurrentSp() const { return CurrentSp; }
    float GetMaxSp() const { return MaxSp; }
    int32 GetLevel() const { return Level; }
    int32 GetExperience() const { return Experience; }
    int32 GetAgeDays() const { return AgeDays; }
    int64 GetZeny() const { return Zeny; }
    int32 GetEquipmentRefineLevel() const { return EquipmentRefineLevel; }
    int32 GetPhracon() const { return Phracon; }
    int32 GetEmveretarcon() const { return Emveretarcon; }
    int32 GetOridecon() const { return Oridecon; }
    float GetRefineSuccessPercent() const;
    int64 GetRefineZenyCost() const;
    int32 GetHonours() const { return Honours; }
    FString GetLastLootMessage() const { return LastLootMessage; }
    const TArray<FString>& GetInventoryItems() const { return InventoryItems; }
    const TArray<FString>& GetCards() const { return Cards; }
    float GetEngagementRange() const { return SkillRangeForClass(); }
    int32 GetHitRating() const;
    int32 GetFleeRating() const;
    int32 GetCriticalRate() const;
    int32 GetLuck() const;
    int32 GetStatusPoints() const { return StatusPoints; }
    int32 GetStrength() const { return Strength; }
    int32 GetAgility() const { return Agility; }
    int32 GetVitality() const { return Vitality; }
    int32 GetIntelligence() const { return Intelligence; }
    int32 GetDexterity() const { return Dexterity; }
    int32 GetLuckStat() const { return LuckStat; }
    int32 GetSkillPoints() const { return SkillPoints; }
    int32 GetSkillLevel(int32 SkillIndex) const { return SkillLevels.IsValidIndex(SkillIndex) ? SkillLevels[SkillIndex] : 0; }
    const TArray<int32>& GetSkillLevels() const { return SkillLevels; }
    float GetSkillImpactMultiplierForSpecies(int32 SkillIndex,const FString& SpeciesName) const;
    bool SpendSkillPoint(int32 SkillIndex,int32 Amount=1);
    bool TryResetSkills();
    void SetSkillState(int32 InSkillPoints,const TArray<int32>& InSkillLevels);
    int32 GetStatusPointCost(EHonourWarStatusStat Stat) const;
    bool SpendStatusPoint(EHonourWarStatusStat Stat,int32 Amount=1);
    void SetStatusState(int32 InStatusPoints,int32 InStrength,int32 InAgility,int32 InVitality,int32 InIntelligence,int32 InDexterity,int32 InLuck);
    float GetDamageReductionPercent() const;
    float GetSkillCooldownMultiplier() const;

    void SetClassId(EHonourWarClass NewClass);
    void SetLevel(int32 NewLevel);
    void SetExperience(int32 NewExperience);
    void SetAgeDays(int32 NewAgeDays);
    void SetZeny(int64 NewZeny);
    void AddZeny(int64 Amount);
    void AddHonours(int32 Amount);
    void AddQuestItem(const FString& ItemName);
    void SetQuestMessage(const FString& Message);
    void SetEquipmentRefineLevel(int32 NewRefine);
    void SetPhracon(int32 Value);
    void SetEmveretarcon(int32 Value);
    void SetOridecon(int32 Value);
    void SetBasicSkillLevel(int32 Value);
    bool TryRefineEquipment();
    int32 GetBasicSkillLevel() const { return BasicSkillLevel; }
    bool TryMixCards();
    bool TryUpgradeBasicSkill();
    void SetHonours(int32 NewHonours);
    void SetInventoryItems(const TArray<FString>& NewItems);
    void SetCards(const TArray<FString>& NewCards);
    void RewardMonsterDefeat(int32 MonsterLevel,const FString& MonsterName=TEXT(""));

protected:
    virtual void BeginPlay() override;
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

private:
    AHonourWarMonster* FindNearestTarget(float MaxRange) const;
    float SkillRangeForClass() const;
    float BaseDamageForClass() const;
    float SkillImpactMultiplier(int32 SkillIndex,const AHonourWarMonster* Target) const;
    static int32 SkillSpeciesIndex(const FString& SpeciesName);
    void GainExperience(int32 Amount);
    void RecalculateVitals();

    UPROPERTY() AHonourWarMonster* LastTarget = nullptr;
    UPROPERTY(EditAnywhere) EHonourWarClass CharacterClass = EHonourWarClass::Warrior;
    UPROPERTY(Replicated,EditAnywhere) int32 Level = 1;
    UPROPERTY(Replicated,EditAnywhere) int32 Experience = 0;
    UPROPERTY(Replicated,EditAnywhere) int32 AgeDays = 0;
    UPROPERTY(Replicated,EditAnywhere) float MaxHealth = 1200.0f;
    UPROPERTY(Replicated,EditAnywhere) float CurrentHealth = 1200.0f;
    UPROPERTY(Replicated,EditAnywhere) float MaxSp = 500.0f;
    UPROPERTY(Replicated,EditAnywhere) float CurrentSp = 500.0f;
    UPROPERTY(Replicated,EditAnywhere) int64 Zeny = 0;
    UPROPERTY(Replicated,EditAnywhere) int32 EquipmentRefineLevel = 0;
    UPROPERTY(Replicated,EditAnywhere) int32 Phracon = 20;
    UPROPERTY(Replicated,EditAnywhere) int32 Emveretarcon = 10;
    UPROPERTY(Replicated,EditAnywhere) int32 Oridecon = 5;
    UPROPERTY(Replicated,EditAnywhere) int32 BasicSkillLevel = 1;
    UPROPERTY(Replicated,EditAnywhere) int32 Honours = 0;
    UPROPERTY(Replicated,EditAnywhere) int32 StatusPoints = 30;
    UPROPERTY(Replicated,EditAnywhere) int32 Strength = 10;
    UPROPERTY(Replicated,EditAnywhere) int32 Agility = 10;
    UPROPERTY(Replicated,EditAnywhere) int32 Vitality = 10;
    UPROPERTY(Replicated,EditAnywhere) int32 Intelligence = 10;
    UPROPERTY(Replicated,EditAnywhere) int32 Dexterity = 10;
    UPROPERTY(Replicated,EditAnywhere) int32 LuckStat = 10;
    UPROPERTY(Replicated,EditAnywhere) int32 SkillPoints = 0;
    UPROPERTY(Replicated,EditAnywhere) TArray<int32> SkillLevels;
    UPROPERTY() TArray<FString> InventoryItems;
    UPROPERTY() TArray<FString> Cards;
    UPROPERTY() FString LastLootMessage = TEXT("No loot yet");

    int32 XpToNextLevel = 100;
    TArray<float> SkillCooldowns;
};
