#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "HonourWarHUD.generated.h"

class UHonourWarHUDWidget;

UCLASS()
class HONOURWAR_API AHonourWarHUD : public AHUD
{
    GENERATED_BODY()
public:
    virtual void BeginPlay() override;
    UHonourWarHUDWidget* GetRuntimeWidget() const { return RuntimeWidget; }

private:
    UPROPERTY() UHonourWarHUDWidget* RuntimeWidget=nullptr;
};
