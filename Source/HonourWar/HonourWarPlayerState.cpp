#include "HonourWarPlayerState.h"
#include "Net/UnrealNetwork.h"

AHonourWarPlayerState::AHonourWarPlayerState()
{
    bReplicates=true;
}

void AHonourWarPlayerState::SetGuild(const FString& Name,const FString& Rank)
{
    GuildName=Name;
    GuildRank=Rank;
}

void AHonourWarPlayerState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(AHonourWarPlayerState,TeamId);
    DOREPLIFETIME(AHonourWarPlayerState,PartySlot);
    DOREPLIFETIME(AHonourWarPlayerState,GuildName);
    DOREPLIFETIME(AHonourWarPlayerState,GuildRank);
}
