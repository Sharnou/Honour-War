#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarCombatEffect.generated.h"

class UStaticMeshComponent;
class UPointLightComponent;

UCLASS()
class HONOURWAR_API AHonourWarCombatEffect : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarCombatEffect();
    virtual void Tick(float DeltaSeconds) override;
    void Initialize(const FLinearColor& Color, float Strength, bool bFinisher);

protected:
    virtual void BeginPlay() override;

private:
    UPROPERTY() USceneComponent* Root = nullptr;
    UPROPERTY() UStaticMeshComponent* Core = nullptr;
    UPROPERTY() UStaticMeshComponent* Halo = nullptr;
    UPROPERTY() UStaticMeshComponent* BurstL = nullptr;
    UPROPERTY() UStaticMeshComponent* BurstR = nullptr;
    UPROPERTY() UPointLightComponent* Light = nullptr;

    float Age = 0.0f;
    float Life = 0.34f;
    float Strength = 1.0f;
    bool bFinisher = false;
};
