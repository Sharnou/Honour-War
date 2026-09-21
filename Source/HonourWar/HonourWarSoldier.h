#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarTypes.h"
#include "HonourWarSoldier.generated.h"

class UStaticMeshComponent;
class USceneComponent;
class AHonourWarMonster;

UCLASS()
class HONOURWAR_API AHonourWarSoldier : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarSoldier();
    virtual void Tick(float DeltaSeconds) override;

    void SetLevel(int32 NewLevel);
    void SetSoldierClass(EHonourWarClass NewClass);
    void ReceiveDamage(float Damage);

    int32 GetSoldierLevel() const { return Level; }
    bool IsDead() const { return bDead; }

protected:
    virtual void BeginPlay() override;

private:
    AHonourWarMonster* FindNearestMonster(float Range) const;
    void BuildVisual();

    UPROPERTY() USceneComponent* Root = nullptr;
    UPROPERTY() UStaticMeshComponent* Body = nullptr;
    UPROPERTY() UStaticMeshComponent* Head = nullptr;
    UPROPERTY() UStaticMeshComponent* Weapon = nullptr;

    UPROPERTY(EditAnywhere) int32 Level = 25;
    UPROPERTY(EditAnywhere) EHonourWarClass SoldierClass = EHonourWarClass::Warrior;

    float MaxHealth = 900.0f;
    float CurrentHealth = 900.0f;
    float AttackTimer = 0.0f;
    int32 AutoSkillIndex = 0;
    bool bDead = false;
};
