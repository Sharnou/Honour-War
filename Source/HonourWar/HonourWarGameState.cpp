#include "HonourWarGameState.h"
#include "Net/UnrealNetwork.h"

AHonourWarGameState::AHonourWarGameState()
{
    bReplicates=true;
}

void AHonourWarGameState::AddWorldMessage(const FString& Message)
{
    if(!HasAuthority() || Message.IsEmpty()) return;
    WorldMessages.Add(Message);
    if(WorldMessages.Num()>10)
        WorldMessages.RemoveAt(0);
}

void AHonourWarGameState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(AHonourWarGameState,WorldMessages);
}
