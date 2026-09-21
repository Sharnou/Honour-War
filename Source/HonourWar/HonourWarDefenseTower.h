#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarTypes.h"
#include "HonourWarDefenseTower.generated.h"

class UStaticMeshComponent;
class AHonourWarMonster;

UCLASS()
class HONOURWAR_API AHonourWarDefenseTower : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarDefenseTower();
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    void Initialize(int32 InLevel, EHonourWarClass InElementClass);

private:
    AHonourWarMonster* FindNearestMonster(float Range) const;

    UPROPERTY() UStaticMeshComponent* Base = nullptr;
    UPROPERTY() UStaticMeshComponent* Core = nullptr;
    UPROPERTY() UStaticMeshComponent* Beacon = nullptr;
    UPROPERTY(EditAnywhere) int32 Level = 25;
    UPROPERTY(EditAnywhere) EHonourWarClass ElementClass = EHonourWarClass::Mage;
    float Cooldown = 0.0f;
};
