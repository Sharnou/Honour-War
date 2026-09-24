#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "TimerManager.h"
#include "HonourWarScreenshotDirector.generated.h"

UCLASS()
class HONOURWAR_API AHonourWarScreenshotDirector : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarScreenshotDirector();
    virtual void BeginPlay() override;

private:
    void SetupCaptureScene();
    void RequestCapture();
    void FinishCapture();
    void FailCapture(const FString& Reason);
    void SetupSoakTest();
    void RunSoakPhase();
    void SpawnSoakMonster();
    void FinishSoakTest(bool bSuccess);
    void RecordSoak(const FString& Line);

    FTimerHandle SetupTimer;
    int32 CaptureAttempts=0;
    FTimerHandle CaptureTimer;
    FTimerHandle ExitTimer;
    TWeakObjectPtr<AHonourWarMonster> ShowcaseMonster;
    TWeakObjectPtr<AHonourWarMonster> SoakMonster;
    TArray<EHonourWarClass> SoakClasses;
    int32 SoakClassIndex=0;
    int32 SoakSkillIndex=0;
    int32 SoakMovementRetries=0;
    int32 SoakSkillSuccesses=0;
    int32 SoakSkillFailures=0;
    int32 SoakSaveCount=0;
    float SoakWorldStartTime=0.0f;
    float SoakLastReportTime=0.0f;
    float SoakClassStartTime=0.0f;
    FString SoakReport;
};
