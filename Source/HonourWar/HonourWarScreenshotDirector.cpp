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
#include "HonourWarHUD.h"
#include "HonourWarHUDWidget.h"
#include "Misc/FileHelper.h"

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

    GetWorldTimerManager().SetTimer(SetupTimer,this,&AHonourWarScreenshotDirector::SetupCaptureScene,1.5f,false);
    GetWorldTimerManager().SetTimer(CaptureTimer,this,&AHonourWarScreenshotDirector::RequestCapture,9.0f,false);
    GetWorldTimerManager().SetTimer(ExitTimer,this,&AHonourWarScreenshotDirector::FinishCapture,17.0f,false);
}

void AHonourWarScreenshotDirector::SetupCaptureScene()
{
    UWorld* World=GetWorld();
    if(!World) return;

    if(FParse::Param(FCommandLine::Get(),TEXT("HonourWarE2E")))
    {
        APlayerController* PC=UGameplayStatics::GetPlayerController(World,0);
        AHonourWarHUD* HUD=PC?Cast<AHonourWarHUD>(PC->GetHUD()):nullptr;
        if(!HUD || !HUD->GetRuntimeWidget())
        {
            GetWorldTimerManager().SetTimer(SetupTimer,this,&AHonourWarScreenshotDirector::SetupCaptureScene,0.5f,false);
            return;
        }

        FString Failure;
        if(!HUD->GetRuntimeWidget()->RunAutomatedE2ETest(Failure))
        {
            const FString Report=FString::Printf(TEXT("Honour War E2E FAILED\n%s\n"),*Failure);
            FFileHelper::SaveStringToFile(Report,*FPaths::ProjectSavedDir()/TEXT("HonourWar-E2E-report.txt"));
            FGenericPlatformMisc::RequestExit(false);
            return;
        }
    }

    if (AHonourWarCharacter* Player=Cast<AHonourWarCharacter>(UGameplayStatics::GetPlayerPawn(World,0)))
    {
        Player->SetActorLocation(FVector(0.0f,1100.0f,180.0f));
        if (APlayerController* PC=Cast<APlayerController>(Player->GetController()))
        {
            PC->SetControlRotation(FRotator(-48.0f,45.0f,0.0f));
        }

        FActorSpawnParameters Params;
        Params.SpawnCollisionHandlingOverride=ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
        AHonourWarMonster* Showcase=World->SpawnActor<AHonourWarMonster>(
            AHonourWarMonster::StaticClass(),FVector(720.0f,1200.0f,180.0f),FRotator::ZeroRotator,Params);
        if (Showcase)
        {
            Showcase->SetLevel(300);
            Showcase->SetSpecies(EHonourWarMonsterSpecies::Dragon);
            Showcase->SetDisplayName(TEXT("Ancient Wyrm"));
            ShowcaseMonster=Showcase;
            Player->SetMouseTarget(Showcase);
        }
    }
}

void AHonourWarScreenshotDirector::RequestCapture()
{
    UWorld* World=GetWorld();
    if(!World) return;

    ++CaptureAttempts;
    AHonourWarCharacter* Player=Cast<AHonourWarCharacter>(UGameplayStatics::GetPlayerPawn(World,0));
    if(!Player)
    {
        if(CaptureAttempts<8) GetWorldTimerManager().SetTimer(CaptureTimer,this,&AHonourWarScreenshotDirector::RequestCapture,1.0f,false);
        else FailCapture(TEXT("Gameplay pawn missing at capture verification."));
        return;
    }

    const float DistanceToShowcase=ShowcaseMonster.IsValid()
        ? FVector::Dist2D(Player->GetActorLocation(),ShowcaseMonster->GetActorLocation())
        : 999999.0f;

    if(DistanceToShowcase>320.0f || !Player->GetLastCombatMessage().Contains(TEXT("impact confirmed"),ESearchCase::IgnoreCase))
    {
        if(CaptureAttempts<10)
        {
            Player->SetMouseTarget(ShowcaseMonster.Get());
            GetWorldTimerManager().SetTimer(CaptureTimer,this,&AHonourWarScreenshotDirector::RequestCapture,1.0f,false);
            return;
        }
        FailCapture(FString::Printf(TEXT("Gameplay verification failed: distance=%.1f combat='%s'"),
            DistanceToShowcase,*Player->GetLastCombatMessage()));
        return;
    }

    const FString Directory=FPaths::ProjectSavedDir()/TEXT("Screenshots");
    const FString Output=Directory/TEXT("HonourWar-real-runtime.png");
    IFileManager::Get().MakeDirectory(*Directory,true);

    FString Report;
    const FString ReportPath=FPaths::ProjectSavedDir()/TEXT("HonourWar-E2E-report.txt");
    if(FFileHelper::LoadFileToString(Report, *ReportPath))
    {
        Report += FString::Printf(TEXT("PASS[13] Runtime movement reached encounter: %.1f units.\n"),DistanceToShowcase);
        Report += FString::Printf(TEXT("PASS[14] Runtime combat impact confirmed: %s\n"),*Player->GetLastCombatMessage());
        FFileHelper::SaveStringToFile(Report,*ReportPath);
    }

    FScreenshotRequest::RequestScreenshot(Output,true,false,false,FIntRect(),true);
}

void AHonourWarScreenshotDirector::FailCapture(const FString& Reason)
{
    const FString ReportPath=FPaths::ProjectSavedDir()/TEXT("HonourWar-E2E-report.txt");
    FString Report=FString::Printf(TEXT("Honour War Runtime E2E FAILED\nFAIL[15] %s\n"),*Reason);
    FFileHelper::SaveStringToFile(Report,*ReportPath);
    FGenericPlatformMisc::RequestExit(false);
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
