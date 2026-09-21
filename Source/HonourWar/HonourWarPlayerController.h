#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "HonourWarPlayerController.generated.h"

UCLASS()
class HONOURWAR_API AHonourWarPlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    AHonourWarPlayerController();

protected:
    virtual void BeginPlay() override;
    virtual void SetupInputComponent() override;
    virtual void PlayerTick(float DeltaTime) override;
    virtual bool InputKey(const FInputKeyEventArgs& Params) override;

private:
    void MoveForward(float Value);
    void MoveRight(float Value);
    void Turn(float Value);
    void LookUp(float Value);
    void Attack();
    void ResetCamera();
    void SaveGame();
    void LoadGame();
    void NextClass();
    void Skill1();
    void Skill2();
    void Skill3();
    void Skill4();
    void Skill5();
    void Skill6();
    void Skill7();
    void Skill8();
    void HandleMouseClick();
    void HandleMouseWheel(float Delta);
    void RotateCameraFromMouse();
    bool bRightMouseDown=false;
    bool bHasLastMousePosition=false;
    FVector2D LastMousePosition=FVector2D::ZeroVector;
};
