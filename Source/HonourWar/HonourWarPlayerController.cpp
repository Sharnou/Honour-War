#include "HonourWarPlayerController.h"
#include "HonourWarCharacter.h"

AHonourWarPlayerController::AHonourWarPlayerController()
{
    bShowMouseCursor=true;
    bEnableClickEvents=true;
    bEnableMouseOverEvents=true;
}

void AHonourWarPlayerController::BeginPlay()
{
    Super::BeginPlay();
    SetControlRotation(FRotator(-48.0f,45.0f,0.0f));

    FInputModeGameAndUI InputMode;
    InputMode.SetHideCursorDuringCapture(false);
    InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
    SetInputMode(InputMode);
}

void AHonourWarPlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();
    InputComponent->BindAxis(TEXT("MoveForward"),this,&AHonourWarPlayerController::MoveForward);
    InputComponent->BindAxis(TEXT("MoveRight"),this,&AHonourWarPlayerController::MoveRight);
    InputComponent->BindAxis(TEXT("Turn"),this,&AHonourWarPlayerController::Turn);
    InputComponent->BindAxis(TEXT("LookUp"),this,&AHonourWarPlayerController::LookUp);

    InputComponent->BindAction(TEXT("Attack"),IE_Pressed,this,&AHonourWarPlayerController::Attack);
    InputComponent->BindAction(TEXT("CameraReset"),IE_Pressed,this,&AHonourWarPlayerController::ResetCamera);
    InputComponent->BindAction(TEXT("SaveGame"),IE_Pressed,this,&AHonourWarPlayerController::SaveGame);
    InputComponent->BindAction(TEXT("LoadGame"),IE_Pressed,this,&AHonourWarPlayerController::LoadGame);
    InputComponent->BindAction(TEXT("NextClass"),IE_Pressed,this,&AHonourWarPlayerController::NextClass);

    InputComponent->BindAction(TEXT("Skill1"),IE_Pressed,this,&AHonourWarPlayerController::Skill1);
    InputComponent->BindAction(TEXT("Skill2"),IE_Pressed,this,&AHonourWarPlayerController::Skill2);
    InputComponent->BindAction(TEXT("Skill3"),IE_Pressed,this,&AHonourWarPlayerController::Skill3);
    InputComponent->BindAction(TEXT("Skill4"),IE_Pressed,this,&AHonourWarPlayerController::Skill4);
    InputComponent->BindAction(TEXT("Skill5"),IE_Pressed,this,&AHonourWarPlayerController::Skill5);
    InputComponent->BindAction(TEXT("Skill6"),IE_Pressed,this,&AHonourWarPlayerController::Skill6);
    InputComponent->BindAction(TEXT("Skill7"),IE_Pressed,this,&AHonourWarPlayerController::Skill7);
    InputComponent->BindAction(TEXT("Skill8"),IE_Pressed,this,&AHonourWarPlayerController::Skill8);
}

void AHonourWarPlayerController::MoveForward(float V){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->MoveForward(V);}
void AHonourWarPlayerController::MoveRight(float V){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->MoveRight(V);}
void AHonourWarPlayerController::Turn(float V){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CameraTurn(V);}
void AHonourWarPlayerController::LookUp(float V){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CameraLookUp(V);}
void AHonourWarPlayerController::Attack(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->Attack();}
void AHonourWarPlayerController::ResetCamera(){SetControlRotation(FRotator(-48.0f,45.0f,0.0f));}
void AHonourWarPlayerController::SaveGame(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->SaveProgress();}
void AHonourWarPlayerController::LoadGame(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->LoadProgress();}
void AHonourWarPlayerController::NextClass(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CycleClass();}
void AHonourWarPlayerController::Skill1(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(0);}
void AHonourWarPlayerController::Skill2(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(1);}
void AHonourWarPlayerController::Skill3(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(2);}
void AHonourWarPlayerController::Skill4(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(3);}
void AHonourWarPlayerController::Skill5(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(4);}
void AHonourWarPlayerController::Skill6(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(5);}
void AHonourWarPlayerController::Skill7(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(6);}
void AHonourWarPlayerController::Skill8(){if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(7);}
