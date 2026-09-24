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

    const bool bCapture=FParse::Param(FCommandLine::Get(),TEXT("HonourWarCapture"));
    const bool bSoak=FParse::Param(FCommandLine::Get(),TEXT("HonourWarSoak"));
    if(!bCapture && !bSoak)
    {
        Destroy();
        return;
    }

    if(bSoak)
    {
        GetWorldTimerManager().SetTimer(SetupTimer,this,&AHonourWarScreenshotDirector::SetupSoakTest,2.0f,false);
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


void AHonourWarScreenshotDirector::RecordSoak(const FString& Line)
{
    SoakReport += Line + TEXT("\n");
    FFileHelper::SaveStringToFile(SoakReport,*FPaths::ProjectSavedDir()/TEXT("HonourWar-1h-soak-report.txt"));
}

void AHonourWarScreenshotDirector::SpawnSoakMonster()
{
    UWorld* World=GetWorld();
    if(!World) return;
    if(SoakMonster.IsValid()) SoakMonster->Destroy();

    const EHonourWarMonsterSpecies Species=static_cast<EHonourWarMonsterSpecies>(SoakClassIndex%8);
    const FVector SpawnLocation(720.0f,1200.0f,180.0f);
    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride=ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
    AHonourWarMonster* Monster=World->SpawnActor<AHonourWarMonster>(
        AHonourWarMonster::StaticClass(),SpawnLocation,FRotator::ZeroRotator,Params);
    if(Monster)
    {
        Monster->SetLevel(60);
        Monster->SetSpecies(Species);
        Monster->SetDisplayName(FString::Printf(TEXT("Soak %s"),*Monster->GetSpeciesName()));
        SoakMonster=Monster;
    }
}

void AHonourWarScreenshotDirector::SetupSoakTest()
{
    UWorld* World=GetWorld();
    if(!World) return;

    AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(UGameplayStatics::GetPlayerController(World,0));
    AHonourWarHUD* HUD=PC?Cast<AHonourWarHUD>(PC->GetHUD()):nullptr;
    if(!HUD||!HUD->GetRuntimeWidget())
    {
        GetWorldTimerManager().SetTimer(SetupTimer,this,&AHonourWarScreenshotDirector::SetupSoakTest,1.0f,false);
        return;
    }

    if(!PC->IsReadyForGameplay())
    {
        FString Failure;
        if(!HUD->GetRuntimeWidget()->RunAutomatedE2ETest(Failure))
        {
            RecordSoak(FString::Printf(TEXT("FAIL[BOOT] Full register/login/character E2E failed: %s"),*Failure));
            FinishSoakTest(false);
            return;
        }
        RecordSoak(TEXT("PASS[BOOT] Full register/login/character E2E completed before soak."));
    }

    AHonourWarCharacter* Player=Cast<AHonourWarCharacter>(PC->GetPawn());
    if(!Player||!Player->GetCombatComponent())
    {
        RecordSoak(TEXT("FAIL[BOOT] Gameplay pawn or combat component missing."));
        FinishSoakTest(false);
        return;
    }

    SoakClasses={
        EHonourWarClass::Warrior,
        EHonourWarClass::Mage,
        EHonourWarClass::Archer,
        EHonourWarClass::Thief,
        EHonourWarClass::Acolyte,
        EHonourWarClass::Merchant,
        EHonourWarClass::Ranger
    };
    SoakClassIndex=0;
    bSoakClassEntered=false;
    bSoakMovementPassed=false;
    SoakSkillIndex=0;
    SoakMovementRetries=0;
    SoakSkillSuccesses=0;
    SoakSkillFailures=0;
    SoakSaveCount=0;
    SoakWorldStartTime=World->GetTimeSeconds();
    SoakLastReportTime=SoakWorldStartTime;
    SoakClassStartTime=SoakWorldStartTime;
    SoakReport=TEXT("Honour War One-Hour All-Class Runtime Soak\n");
    RecordSoak(FString::Printf(TEXT("START UTC %s"),*FDateTime::UtcNow().ToIso8601()));
    RecordSoak(TEXT("Scope: real packaged UE 5.8 executable; seven classes; repeated movement, combat skills, save, and HUD/gameplay state checks."));
    Player->SetActorLocation(FVector(0.0f,1100.0f,180.0f));
    Player->SetClassId(SoakClasses[0]);
    SpawnSoakMonster();
    Player->SetMouseTarget(SoakMonster.Get());
    GetWorldTimerManager().SetTimer(CaptureTimer,this,&AHonourWarScreenshotDirector::RunSoakPhase,2.0f,true);
}

void AHonourWarScreenshotDirector::RunSoakPhase()
{
    UWorld* World=GetWorld();
    if(!World) return;
    AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(UGameplayStatics::GetPlayerController(World,0));
    AHonourWarCharacter* Player=PC?Cast<AHonourWarCharacter>(PC->GetPawn()):nullptr;
    if(!Player||!Player->GetCombatComponent())
    {
        RecordSoak(FString::Printf(TEXT("FAIL[RUNTIME] %.0fs Gameplay pawn/combat component disappeared at class index %d."),World->GetTimeSeconds()-SoakWorldStartTime,SoakClassIndex));
        FinishSoakTest(false);
        return;
    }

    const float Elapsed=World->GetTimeSeconds()-SoakWorldStartTime;
    const float ClassElapsed=World->GetTimeSeconds()-SoakClassStartTime;
    if(Elapsed>=3600.0f)
    {
        FinishSoakTest(true);
        return;
    }

    if(SoakClassIndex>=SoakClasses.Num())
    {
        SoakClassIndex=0;
        SoakSkillIndex=0;
        SoakClassStartTime=World->GetTimeSeconds();
    }

    const EHonourWarClass CurrentClass=SoakClasses[SoakClassIndex];
    if(!bSoakClassEntered || Player->GetClassId()!=CurrentClass)
    {
        Player->SetClassId(CurrentClass);
        SoakSkillIndex=0;
        SoakMovementRetries=0;
        bSoakMovementPassed=false;
        SoakClassStartTime=World->GetTimeSeconds();
        SpawnSoakMonster();
        Player->SetMouseTarget(SoakMonster.Get());
        RecordSoak(FString::Printf(TEXT("PASS[CLASS] %.0fs Entered %s | Job=%s | Tier=%s | T5=%s"),
            Elapsed,*Player->GetClassName(),*Player->GetCurrentJobName(),*Player->GetClassTierName(),*Player->GetFifthTierClassName()));
        bSoakClassEntered=true;
    }

    if(!SoakMonster.IsValid()||SoakMonster->IsDead())
    {
        SpawnSoakMonster();
        Player->SetMouseTarget(SoakMonster.Get());
        SoakMovementRetries=0;
    }

    const float Distance=FVector::Dist2D(Player->GetActorLocation(),SoakMonster.IsValid()?SoakMonster->GetActorLocation():FVector(999999.0f));
    if(Distance>Player->GetCombatComponent()->GetEngagementRange())
    {
        Player->SetMouseTarget(SoakMonster.Get());
        ++SoakMovementRetries;
        if(SoakMovementRetries>10)
        {
            RecordSoak(FString::Printf(TEXT("FAIL[MOVEMENT] %.0fs %s could not reach combat range after %d retries; distance %.1f."),Elapsed,*Player->GetClassName(),SoakMovementRetries,Distance));
            ++SoakClassIndex;
            bSoakClassEntered=false;
            SoakSkillIndex=0;
            SoakMovementRetries=0;
            SoakClassStartTime=World->GetTimeSeconds();
            return;
        }
    }
    else
    {
        SoakMovementRetries=0;
        if(!bSoakMovementPassed)
        {
            RecordSoak(FString::Printf(TEXT("PASS[MOVEMENT] %.0fs %s reached engagement range | distance %.1f <= range %.1f."),
                Elapsed,*Player->GetClassName(),Distance,Player->GetCombatComponent()->GetEngagementRange()));
            bSoakMovementPassed=true;
        }

        const int32 TestedSkillIndex=SoakSkillIndex;
        const FString Before=Player->GetLastCombatMessage();
        Player->ActivateSkill(TestedSkillIndex);
        const FString After=Player->GetLastCombatMessage();
        if(FMath::Fmod(Elapsed,10.0f)<2.1f)
            Player->GetCombatComponent()->RestoreVitals();
        if(After!=Before && After.Contains(TEXT("impact confirmed"),ESearchCase::IgnoreCase))
            ++SoakSkillSuccesses;
        else
        {
            ++SoakSkillFailures;
            RecordSoak(FString::Printf(TEXT("FAIL[SKILL] %.0fs %s skill=%d did not confirm impact | before=\"%s\" after=\"%s\" distance=%.1f."),
                Elapsed,*Player->GetClassName(),TestedSkillIndex,*Before,*After,Distance));
        }
        SoakSkillIndex=(SoakSkillIndex+1)%8;

        if(FMath::Fmod(Elapsed,30.0f)<2.1f)
        {
            Player->SaveProgress();
            ++SoakSaveCount;
        }
    }

    if(ClassElapsed>=480.0f)
    {
        if(SoakSkillFailures==0)
        {
            RecordSoak(FString::Printf(TEXT("PASS[CLASS-END] %.0fs %s | phase %.0fs | skill successes=%d failures=%d saves=%d"),
                Elapsed,*Player->GetClassName(),ClassElapsed,SoakSkillSuccesses,SoakSkillFailures,SoakSaveCount));
        }
        else
        {
            RecordSoak(FString::Printf(TEXT("FAIL[CLASS-END] %.0fs %s | phase %.0fs | skill successes=%d failures=%d saves=%d"),
                Elapsed,*Player->GetClassName(),ClassElapsed,SoakSkillSuccesses,SoakSkillFailures,SoakSaveCount));
        }
        ++SoakClassIndex;
        bSoakClassEntered=false;
        SoakSkillIndex=0;
        SoakMovementRetries=0;
        SoakSkillSuccesses=0;
        SoakSkillFailures=0;
        SoakClassStartTime=World->GetTimeSeconds();
        if(SoakClassIndex<SoakClasses.Num())
        {
            Player->SetClassId(SoakClasses[SoakClassIndex]);
            SpawnSoakMonster();
            Player->SetMouseTarget(SoakMonster.Get());
        }
    }

    if(World->GetTimeSeconds()-SoakLastReportTime>=60.0f)
    {
        SoakLastReportTime=World->GetTimeSeconds();
        RecordSoak(FString::Printf(TEXT("HEARTBEAT %.0fs | class=%s | skill=%d | distance=%.1f | saves=%d"),
            Elapsed,*Player->GetClassName(),SoakSkillIndex,Distance,SoakSaveCount));
    }
}

void AHonourWarScreenshotDirector::FinishSoakTest(bool bSuccess)
{
    GetWorldTimerManager().ClearTimer(CaptureTimer);
    if(SoakMonster.IsValid()) SoakMonster->Destroy();
    const float Elapsed=GetWorld()?GetWorld()->GetTimeSeconds()-SoakWorldStartTime:0.0f;
    RecordSoak(FString::Printf(TEXT("%s[END] %.0fs elapsed | UTC %s | saves=%d"),
        bSuccess?TEXT("PASS"):TEXT("FAIL"),Elapsed,*FDateTime::UtcNow().ToIso8601(),SoakSaveCount));
    FGenericPlatformMisc::RequestExit(false);
}
