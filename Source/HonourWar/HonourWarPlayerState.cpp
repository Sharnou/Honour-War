#include "HonourWarPlayerState.h"
#include "Net/UnrealNetwork.h"

AHonourWarPlayerState::AHonourWarPlayerState()
{
    bReplicates=true;
}

void AHonourWarPlayerState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(AHonourWarPlayerState,TeamId);
    DOREPLIFETIME(AHonourWarPlayerState,PartySlot);
}
