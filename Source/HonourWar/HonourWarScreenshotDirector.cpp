#include "HonourWarScreenshotDirector.h"
#include "Engine/HighResScreenshot.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "HAL/FileManager.h"
#include "HAL/PlatformMisc.h"
#include "TimerManager.h"
#include "Engine/World.h"

AHonourWarScreenshotDirector::AHonourWarScreenshotDirector()
{
    PrimaryActorTick.bCanEverTick=false;
    SetActorTickEnabled(false);
}

void AHonourWarScreenshotDirector::BeginPlay()
{
    Super::BeginPlay();

    if (!FParse::Param(FCommandLine::Get(),TEXT("HonourWarCapture")))
    {
        Destroy();
        return;
    }

    GetWorldTimerManager().SetTimer(CaptureTimer,this,&AHonourWarScreenshotDirector::RequestCapture,5.0f,false);
    GetWorldTimerManager().SetTimer(ExitTimer,this,&AHonourWarScreenshotDirector::FinishCapture,8.0f,false);
}

void AHonourWarScreenshotDirector::RequestCapture()
{
    const FString Output=FPaths::ProjectSavedDir()/TEXT("Screenshots/HonourWar-real-runtime.png");
    IFileManager::Get().MakeDirectory(*FPaths::GetPath(Output),true);
    FScreenshotRequest::RequestScreenshot(Output,false,false);
}

void AHonourWarScreenshotDirector::FinishCapture()
{
    FGenericPlatformMisc::RequestExit(false);
}
