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

    void SetClassId(EHonourWarClass NewClass);
    void SetLevel(int32 NewLevel);
    void SetExperience(int32 NewExperience);
    void SetAgeDays(int32 NewAgeDays);

protected:
    virtual void BeginPlay() override;
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

private:
    AHonourWarMonster* FindNearestTarget(float MaxRange) const;
    float SkillRangeForClass() const;
    float BaseDamageForClass() const;
    void GainExperience(int32 Amount);

    UPROPERTY() AHonourWarMonster* LastTarget = nullptr;
    UPROPERTY(EditAnywhere) EHonourWarClass CharacterClass = EHonourWarClass::Warrior;
    UPROPERTY(EditAnywhere) int32 Level = 1;
    UPROPERTY(EditAnywhere) int32 Experience = 0;
    UPROPERTY(EditAnywhere) int32 AgeDays = 0;
    UPROPERTY(EditAnywhere) float MaxHealth = 1200.0f;
    UPROPERTY(EditAnywhere) float CurrentHealth = 1200.0f;
    UPROPERTY(EditAnywhere) float MaxSp = 500.0f;
    UPROPERTY(EditAnywhere) float CurrentSp = 500.0f;

    int32 XpToNextLevel = 100;
    TArray<float> SkillCooldowns;
};
