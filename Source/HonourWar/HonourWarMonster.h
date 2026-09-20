#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarTypes.h"
#include "HonourWarMonster.generated.h"

class UStaticMeshComponent;

UCLASS()
class HONOURWAR_API AHonourWarMonster : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarMonster();
    virtual void Tick(float DeltaSeconds) override;
    void ReceiveCombatHit(float Damage, EHonourWarClass SourceClass);
    bool IsDead() const { return bDead; }

protected:
    virtual void BeginPlay() override;

private:
    UPROPERTY() USceneComponent* Root;
    UPROPERTY() UStaticMeshComponent* Body;
    UPROPERTY() UStaticMeshComponent* Head;
    UPROPERTY() UStaticMeshComponent* LeftHorn;
    UPROPERTY() UStaticMeshComponent* RightHorn;

    UPROPERTY(EditAnywhere) int32 Level = 12;
    float MaxHealth = 800.0f;
    float CurrentHealth = 800.0f;
    float AttackTimer = 0.0f;
    bool bDead = false;
};
