#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarDamagePopup.generated.h"

class UTextRenderComponent;

UCLASS()
class HONOURWAR_API AHonourWarDamagePopup : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarDamagePopup();
    virtual void Tick(float DeltaSeconds) override;
    void Initialize(float Damage,const FLinearColor& Color,bool bCritical);

protected:
    virtual void BeginPlay() override;

private:
    UPROPERTY() UTextRenderComponent* Text = nullptr;
    float Age=0.0f;
    float Life=0.80f;
};
