#include "HonourWarGameMode.h"
#include "HonourWarCharacter.h"
#include "HonourWarPlayerController.h"
#include "HonourWarHUD.h"
#include "HonourWarWorldDirector.h"
#include "HonourWarScreenshotDirector.h"
#include "HonourWarPlayerState.h"
#include "Engine/World.h"

AHonourWarGameMode::AHonourWarGameMode()
{
    DefaultPawnClass=AHonourWarCharacter::StaticClass();
    PlayerControllerClass=AHonourWarPlayerController::StaticClass();
    PlayerStateClass=AHonourWarPlayerState::StaticClass();
    HUDClass=AHonourWarHUD::StaticClass();
}

void AHonourWarGameMode::BeginPlay()
{
    Super::BeginPlay();

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride=ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

    GetWorld()->SpawnActor<AHonourWarWorldDirector>(
        AHonourWarWorldDirector::StaticClass(),
        FVector::ZeroVector,
        FRotator::ZeroRotator,
        Params);

    GetWorld()->SpawnActor<AHonourWarScreenshotDirector>(
        AHonourWarScreenshotDirector::StaticClass(),
        FVector::ZeroVector,
        FRotator::ZeroRotator,
        Params);
}


void AHonourWarGameMode::PostLogin(APlayerController* NewPlayer)
{
    Super::PostLogin(NewPlayer);
    if(!NewPlayer) return;
    if(AHonourWarPlayerState* PS=NewPlayer->GetPlayerState<AHonourWarPlayerState>())
    {
        const int32 PlayerIndex=FMath::Max(0,GetNumPlayers()-1);
        PS->TeamId=(PlayerIndex%2);
        PS->PartySlot=FMath::Min(3,PlayerIndex/2);
    }
}


void AHonourWarGameMode::PreLogin(const FString& Options,const FString& Address,const FUniqueNetIdRepl& UniqueId,FString& ErrorMessage)
{
    Super::PreLogin(Options,Address,UniqueId,ErrorMessage);
    if(!ErrorMessage.IsEmpty()) return;

    const int32 CurrentPlayers=GetNumPlayers();
    if(CurrentPlayers>=8)
        ErrorMessage=TEXT("Honour War party capacity reached: maximum 8 active players (4v4).");
}
