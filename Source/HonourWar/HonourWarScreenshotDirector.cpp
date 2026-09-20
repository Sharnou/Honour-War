#include "HonourWarScreenshotDirector.h"
#include "Engine/HighResScreenshot.h"
#include "Engine/UnrealClient.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "HAL/FileManager.h"
#include "HAL/PlatformMisc.h"
#include "TimerManager.h"
#include "Engine/World.h"

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

    GetWorldTimerManager().SetTimer(CaptureTimer,this,&AHonourWarScreenshotDirector::RequestCapture,6.0f,false);
    GetWorldTimerManager().SetTimer(ExitTimer,this,&AHonourWarScreenshotDirector::FinishCapture,12.0f,false);
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
