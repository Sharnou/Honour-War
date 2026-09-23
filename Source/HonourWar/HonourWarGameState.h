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

    virtual void Tick(float DeltaSeconds) override;

    void AddWorldMessage(const FString& Message);
    const TArray<FString>& GetWorldMessages() const { return WorldMessages; }

    int32 GetActiveWorldEventId() const { return ActiveWorldEventId; }
    FString GetActiveWorldEventTitle() const;
    FString GetActiveWorldEventBody() const;
    int32 GetEventSecondsRemaining() const;
    float GetWorldEventDamageMultiplier() const;
    float GetWorldEventXpMultiplier() const;
    float GetWorldEventZenyMultiplier() const;
    float GetWorldEventHonourMultiplier() const;
    float GetWorldEventSpRegenMultiplier() const;

protected:
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

private:
    UPROPERTY(Replicated) TArray<FString> WorldMessages;
    UPROPERTY(Replicated) int32 ActiveWorldEventId = 0;
    UPROPERTY(Replicated) float WorldEventElapsed = 0.0f;

    static constexpr float WorldEventDuration = 180.0f;
};