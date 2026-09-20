#include "HonourWarGameMode.h"
#include "HonourWarCharacter.h"
#include "HonourWarPlayerController.h"
#include "HonourWarHUD.h"
#include "HonourWarWorldDirector.h"
#include "HonourWarScreenshotDirector.h"
#include "Engine/World.h"

AHonourWarGameMode::AHonourWarGameMode()
{
    DefaultPawnClass=AHonourWarCharacter::StaticClass();
    PlayerControllerClass=AHonourWarPlayerController::StaticClass();
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
