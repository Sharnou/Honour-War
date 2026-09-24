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

    FTimerHandle SetupTimer;
    int32 CaptureAttempts=0;
    FTimerHandle CaptureTimer;
    FTimerHandle ExitTimer;
};
