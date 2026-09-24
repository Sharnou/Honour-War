#include "HonourWarScreenshotDirector.h"
#include "Engine/HighResScreenshot.h"
#include "Engine/UnrealClient.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "HAL/FileManager.h"
#include "HAL/PlatformMisc.h"
#include "TimerManager.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "HonourWarCharacter.h"
#include "HonourWarMonster.h"
#include "HonourWarTypes.h"

AHonourWarScreenshotDirector::AHonourWarScreenshotDirector()
{
    PrimaryActorTick.bCanEverTick=false;
}

void AHonourWarScreenshotDirector::BeginPlay()
{
    Super::BeginPlay();

    if (!FParse::Param(FCommandLine::Get(),TEXT("HonourWarCapture")))
    {
        Destroy();
        return;
    }

    GetWorldTimerManager().SetTimer(CaptureTimer,this,&AHonourWarScreenshotDirector::RequestCapture,7.0f,false);
    GetWorldTimerManager().SetTimer(ExitTimer,this,&AHonourWarScreenshotDirector::FinishCapture,14.0f,false);

    if (UWorld* World=GetWorld())
    {
        if (AHonourWarCharacter* Player=Cast<AHonourWarCharacter>(UGameplayStatics::GetPlayerPawn(World,0)))
        {
            Player->SetActorLocation(FVector(900.0f,900.0f,180.0f));
            if (APlayerController* PC=Cast<APlayerController>(Player->GetController()))
            {
                PC->SetControlRotation(FRotator(-48.0f,45.0f,0.0f));
            }
            FActorSpawnParameters Params;
            Params.SpawnCollisionHandlingOverride=ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
            AHonourWarMonster* Showcase=World->SpawnActor<AHonourWarMonster>(
                AHonourWarMonster::StaticClass(),FVector(1650.0f,900.0f,180.0f),FRotator::ZeroRotator,Params);
            if (Showcase)
            {
                Showcase->SetLevel(300);
                Showcase->SetSpecies(EHonourWarMonsterSpecies::Dragon);
                Showcase->SetDisplayName(TEXT("Ancient Wyrm"));
                Player->SetMouseTarget(Showcase);
            }
        }
    }
}

void AHonourWarScreenshotDirector::RequestCapture()
{
    if (!GetWorld()) return;

    const FString Directory=FPaths::ProjectSavedDir()/TEXT("Screenshots");
    const FString Output=Directory/TEXT("HonourWar-real-runtime.png");
    IFileManager::Get().MakeDirectory(*Directory,true);

    FScreenshotRequest::RequestScreenshot(Output,true,false,false,FIntRect(),true);
}

void AHonourWarScreenshotDirector::FinishCapture()
{
    const FString Output=FPaths::ProjectSavedDir()/TEXT("Screenshots/HonourWar-real-runtime.png");
    if (!IFileManager::Get().FileExists(*Output))
    {
        GetWorldTimerManager().SetTimer(ExitTimer,this,&AHonourWarScreenshotDirector::FinishCapture,1.0f,false);
        return;
    }
    FGenericPlatformMisc::RequestExit(false);
}
