#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerState.h"
#include "HonourWarPlayerState.generated.h"

UCLASS()
class HONOURWAR_API AHonourWarPlayerState : public APlayerState
{
    GENERATED_BODY()

public:
    AHonourWarPlayerState();

    UPROPERTY(Replicated, BlueprintReadOnly) int32 TeamId=0;
    UPROPERTY(Replicated, BlueprintReadOnly) int32 PartySlot=0;

    int32 GetTeamId() const { return TeamId; }
    int32 GetPartySlot() const { return PartySlot; }

protected:
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;
};
