#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarBaseBuilding.generated.h"

class UStaticMeshComponent;
class UTextRenderComponent;

UCLASS()
class HONOURWAR_API AHonourWarBaseBuilding : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarBaseBuilding();
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    void InitializeBaseLevel(int32 NewLevel);
    int32 GetBaseLevel() const { return BaseLevel; }

private:
    void BuildVisual();
    void UpdateSightState();

    UPROPERTY() UStaticMeshComponent* Base = nullptr;
    UPROPERTY() UStaticMeshComponent* Core = nullptr;
    UPROPERTY() UStaticMeshComponent* Ring = nullptr;
    UPROPERTY() UTextRenderComponent* Label = nullptr;
    UPROPERTY(EditAnywhere) int32 BaseLevel = 1;
    float SightTimer = 0.0f;
};
