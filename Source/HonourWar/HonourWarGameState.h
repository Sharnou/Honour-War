#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameStateBase.h"
#include "HonourWarGameState.generated.h"

UCLASS()
class HONOURWAR_API AHonourWarGameState : public AGameStateBase
{
    GENERATED_BODY()

public:
    AHonourWarGameState();

    void AddWorldMessage(const FString& Message);
    const TArray<FString>& GetWorldMessages() const { return WorldMessages; }

protected:
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

private:
    UPROPERTY(Replicated) TArray<FString> WorldMessages;
};
