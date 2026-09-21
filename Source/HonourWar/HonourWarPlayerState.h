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

    UPROPERTY(Replicated, BlueprintReadOnly) FString GuildName;
    UPROPERTY(Replicated, BlueprintReadOnly) FString GuildRank=TEXT("Member");

    FString GetGuildName() const { return GuildName; }
    FString GetGuildRank() const { return GuildRank; }
    void SetGuild(const FString& Name,const FString& Rank);

protected:
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;
};
