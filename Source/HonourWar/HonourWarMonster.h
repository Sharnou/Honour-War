#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarTypes.h"
#include "HonourWarMonster.generated.h"

class UStaticMeshComponent;
class UTextRenderComponent;

UENUM(BlueprintType)
enum class EHonourWarMonsterSpecies : uint8
{
    Poring,
    Goblin,
    Wolf,
    Skeleton,
    Orc,
    Mantis,
    Golem,
    Dragon
};

UCLASS()
class HONOURWAR_API AHonourWarMonster : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarMonster();
    virtual void Tick(float DeltaSeconds) override;
    void ReceiveCombatHit(float Damage, EHonourWarClass SourceClass, bool bCritical=false);
    void SetLevel(int32 NewLevel);
    void SetSpecies(EHonourWarMonsterSpecies NewSpecies);
    FString GetSpeciesName() const;
    int32 GetMonsterLevel() const { return Level; }
    bool IsDead() const { return bDead; }
    int32 GetHitRating() const { return 80 + Level / 3; }
    int32 GetFleeRating() const { return 50 + Level / 4; }
    int32 GetCritResistance() const { return 2 + Level / 30; }
    int32 GetLuck() const { return 8 + Level / 10; }

protected:
    virtual void BeginPlay() override;

private:
    void ApplySpeciesVisual();
    void PlayCombatReaction(bool bHit,bool bCritical,bool bLucky,float Damage,EHonourWarClass SourceClass);

    UPROPERTY() USceneComponent* Root;
    UPROPERTY() UStaticMeshComponent* Body;
    UPROPERTY() UStaticMeshComponent* Head;
    UPROPERTY() UStaticMeshComponent* LeftHorn;
    UPROPERTY() UStaticMeshComponent* RightHorn;
    UPROPERTY() UTextRenderComponent* Nameplate;

    UPROPERTY(EditAnywhere) int32 Level = 12;
    UPROPERTY(EditAnywhere) EHonourWarMonsterSpecies Species = EHonourWarMonsterSpecies::Goblin;
    float MaxHealth = 800.0f;
    float CurrentHealth = 800.0f;
    float AttackTimer = 0.0f;
    float FlinchTimer = 0.0f;
    FVector ReactionBaseScale = FVector::OneVector;
    bool bDead = false;
};
