#include "HonourWarPlayerController.h"
#include "HonourWarAccountSaveGame.h"
#include "HonourWarCharacter.h"
#include "HonourWarMonster.h"
#include "HonourWarGameMode.h"
#include "HonourWarGameState.h"
#include "InputCoreTypes.h"
#include "GameFramework/Actor.h"
#include "Misc/Parse.h"
#include "Misc/MD5.h"
#include "Kismet/GameplayStatics.h"

namespace
{
    const TCHAR* AccountSlot=TEXT("HonourWarAccount");
}

AHonourWarPlayerController::AHonourWarPlayerController()
{
    bShowMouseCursor=true;
    bEnableClickEvents=true;
    bEnableMouseOverEvents=true;
}

void AHonourWarPlayerController::BeginPlay()
{
    Super::BeginPlay();
    SetControlRotation(FRotator(-50.0f,45.0f,0.0f));

    FInputModeGameAndUI InputMode;
    InputMode.SetHideCursorDuringCapture(false);
    InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
    SetInputMode(InputMode);

    AuthenticateCaptureAccount();
}

void AHonourWarPlayerController::PlayerTick(float DeltaTime)
{
    Super::PlayerTick(DeltaTime);
    if (bRightMouseDown && bAuthenticated) RotateCameraFromMouse();
}

bool AHonourWarPlayerController::InputKey(const FInputKeyEventArgs& Params)
{
    if (Params.Key==EKeys::LeftMouseButton && Params.Event==IE_Pressed)
    {
        if (bAuthenticated) HandleMouseClick();
        return true;
    }
    if (Params.Key==EKeys::RightMouseButton)
    {
        bRightMouseDown=(Params.Event==IE_Pressed);
        if (bRightMouseDown && bAuthenticated)
        {
            float X=0.0f,Y=0.0f;
            if (GetMousePosition(X,Y)){LastMousePosition=FVector2D(X,Y);bHasLastMousePosition=true;}
        }
        else bHasLastMousePosition=false;
        return true;
    }
    if (Params.Key==EKeys::MouseScrollUp && Params.Event==IE_Pressed)
    {
        if (bAuthenticated) HandleMouseWheel(1.0f);
        return true;
    }
    if (Params.Key==EKeys::MouseScrollDown && Params.Event==IE_Pressed)
    {
        if (bAuthenticated) HandleMouseWheel(-1.0f);
        return true;
    }
    return Super::InputKey(Params);
}

void AHonourWarPlayerController::HandleMouseClick()
{
    AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn());
    if (!Character) return;
    FHitResult Hit;
    if (!GetHitResultUnderCursorByChannel(UEngineTypes::ConvertToTraceType(ECC_Visibility),true,Hit)) return;
    if (AHonourWarMonster* Monster=Cast<AHonourWarMonster>(Hit.GetActor())) Character->SetMouseTarget(Monster);
    else Character->SetMouseDestination(Hit.Location);
}

void AHonourWarPlayerController::HandleMouseWheel(float Delta)
{
    if (AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn())) Character->AdjustCameraZoom(Delta);
}

void AHonourWarPlayerController::RotateCameraFromMouse()
{
    float X=0.0f,Y=0.0f;
    if (!GetMousePosition(X,Y)) return;
    const FVector2D Current(X,Y);
    if (!bHasLastMousePosition){LastMousePosition=Current;bHasLastMousePosition=true;return;}
    const FVector2D Delta=Current-LastMousePosition;
    LastMousePosition=Current;
    if (AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn()))
    {
        Character->CameraTurn(Delta.X*0.50f);
        Character->CameraLookUp(Delta.Y*0.35f);
    }
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
    InputComponent->BindAction(TEXT("RefineEquipment"),IE_Pressed,this,&AHonourWarPlayerController::RefineEquipment);
    InputComponent->BindAction(TEXT("MixCards"),IE_Pressed,this,&AHonourWarPlayerController::MixCards);
    InputComponent->BindAction(TEXT("UpgradeBasicSkill"),IE_Pressed,this,&AHonourWarPlayerController::UpgradeBasicSkill);
}

void AHonourWarPlayerController::MoveForward(float V){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->MoveForward(V);}
void AHonourWarPlayerController::MoveRight(float V){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->MoveRight(V);}
void AHonourWarPlayerController::Turn(float V){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CameraTurn(V);}
void AHonourWarPlayerController::LookUp(float V){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CameraLookUp(V);}
void AHonourWarPlayerController::Attack(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->Attack();}
void AHonourWarPlayerController::ResetCamera(){if(bAuthenticated)SetControlRotation(FRotator(-50.0f,45.0f,0.0f));}
void AHonourWarPlayerController::SaveGame(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->SaveProgress();}
void AHonourWarPlayerController::LoadGame(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->LoadProgress();}
void AHonourWarPlayerController::NextClass(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CycleClass();}
void AHonourWarPlayerController::Skill1(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(0);}
void AHonourWarPlayerController::Skill2(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(1);}
void AHonourWarPlayerController::Skill3(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(2);}
void AHonourWarPlayerController::Skill4(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(3);}
void AHonourWarPlayerController::Skill5(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(4);}
void AHonourWarPlayerController::Skill6(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(5);}
void AHonourWarPlayerController::Skill7(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(6);}
void AHonourWarPlayerController::Skill8(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(7);}
void AHonourWarPlayerController::RefineEquipment(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->RefineEquipment();}
void AHonourWarPlayerController::MixCards(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->MixCards();}
void AHonourWarPlayerController::UpgradeBasicSkill(){if(bAuthenticated)if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->UpgradeBasicSkill();}

FString AHonourWarPlayerController::HashPassword(const FString& Password) const
{
    return FMD5Hash::HashAnsiString(*Password).ToString();
}

bool AHonourWarPlayerController::ValidateAccountInput(const FString& Username,const FString& Password,FString& OutMessage) const
{
    const FString U=Username.TrimStartAndEnd();
    if(U.Len()<3 || U.Len()>24){OutMessage=TEXT("Account username must be 3-24 characters.");return false;}
    if(Password.Len()<6 || Password.Len()>128){OutMessage=TEXT("Password must be 6-128 characters.");return false;}
    for(const TCHAR C:U) if(!(FChar::IsAlnum(C) || C==TEXT('_') || C==TEXT('-'))){OutMessage=TEXT("Username may contain letters, numbers, _ and -.");return false;}
    return true;
}

bool AHonourWarPlayerController::LoadAccount(UHonourWarAccountSaveGame*& OutAccount) const
{
    OutAccount=Cast<UHonourWarAccountSaveGame>(UGameplayStatics::LoadGameFromSlot(AccountSlot,0));
    return OutAccount!=nullptr;
}

bool AHonourWarPlayerController::SaveAccount(const FString& Username,const FString& PasswordHash,const FDateTime& CreatedAtUtc,FString& OutMessage)
{
    UHonourWarAccountSaveGame* Account=Cast<UHonourWarAccountSaveGame>(UGameplayStatics::CreateSaveGameObject(UHonourWarAccountSaveGame::StaticClass()));
    if(!Account){OutMessage=TEXT("Account storage could not be created.");return false;}
    Account->Username=Username;
    Account->PasswordHash=PasswordHash;
    Account->CreatedAtUtc=CreatedAtUtc;
    Account->LastLoginAtUtc=FDateTime::UtcNow();
    if(!UGameplayStatics::SaveGameToSlot(Account,AccountSlot,0)){OutMessage=TEXT("Account could not be saved.");return false;}
    return true;
}

bool AHonourWarPlayerController::RegisterAccount(const FString& Username,const FString& Password,FString& OutMessage)
{
    if(!ValidateAccountInput(Username,Password,OutMessage)) return false;
    UHonourWarAccountSaveGame* Existing=nullptr;
    if(LoadAccount(Existing)){OutMessage=TEXT("An Honour War account is already registered on this local installation. Use @login.");return false;}
    if(!SaveAccount(Username.TrimStartAndEnd(),HashPassword(Password),FDateTime::UtcNow(),OutMessage)) return false;
    bAuthenticated=true;
    AccountUsername=Username.TrimStartAndEnd();
    OutMessage=FString::Printf(TEXT("Registration successful. Logged in as %s."),*AccountUsername);
    return true;
}

bool AHonourWarPlayerController::LoginAccount(const FString& Username,const FString& Password,FString& OutMessage)
{
    if(!ValidateAccountInput(Username,Password,OutMessage)) return false;
    UHonourWarAccountSaveGame* Account=nullptr;
    if(!LoadAccount(Account)){OutMessage=TEXT("No account is registered on this local installation. Use @register [username] [password].");return false;}
    const FString CleanUsername=Username.TrimStartAndEnd();
    if(!Account->Username.Equals(CleanUsername,ESearchCase::CaseSensitive) || Account->PasswordHash!=HashPassword(Password))
    {
        OutMessage=TEXT("Login failed: username or password is incorrect.");
        return false;
    }
    Account->LastLoginAtUtc=FDateTime::UtcNow();
    UGameplayStatics::SaveGameToSlot(Account,AccountSlot,0);
    bAuthenticated=true;
    AccountUsername=Account->Username;
    OutMessage=FString::Printf(TEXT("Login successful. Welcome, %s."),*AccountUsername);
    return true;
}

void AHonourWarPlayerController::AuthenticateCaptureAccount()
{
    if(!FParse::Param(FCommandLine::Get(),TEXT("HonourWarCapture"))) return;
    FString Result;
    if(!bAuthenticated)
    {
        UHonourWarAccountSaveGame* Existing=nullptr;
        if(!LoadAccount(Existing))
        {
            RegisterAccount(TEXT("CapturePlayer"),TEXT("HonourWarCapture2026"),Result);
        }
        else
        {
            LoginAccount(Existing->Username,TEXT("HonourWarCapture2026"),Result);
        }
    }
}

void AHonourWarPlayerController::SendChatMessage(const FString& Message)
{
    if(!bAuthenticated) return;
    FString Clean=Message;
    Clean.TrimStartAndEndInline();
    Clean.LeftInline(180,true);
    if(Clean.IsEmpty()) return;
    if(!HasAuthority()){ServerSendChat(Clean);return;}
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn()))
    {
        if(AHonourWarGameMode* GameMode=GetWorld()?GetWorld()->GetAuthGameMode<AHonourWarGameMode>():nullptr)
        {
            FString Result;
            GameMode->HandleChatCommand(Character,Clean,Result);
        }
    }
}

void AHonourWarPlayerController::ServerSendChat_Implementation(const FString& Message){SendChatMessage(Message);}

bool AHonourWarPlayerController::ExecuteGoCommand(const FString& Command)
{
    if(!bAuthenticated) return false;
    TArray<FString> Tokens;
    Command.ParseIntoArrayWS(Tokens);
    if(Tokens.Num()<3 || Tokens[0].Compare(TEXT("@go"),ESearchCase::IgnoreCase)!=0) return false;
    FString MapId=Tokens[1].ToLower();
    static const TArray<FString> MapNames={TEXT("prontera_like_town"),TEXT("forest_field"),TEXT("mountain_pass"),TEXT("desert_ruins"),TEXT("snow_region"),TEXT("arcane_dungeon")};
    int32 MapIndex=MapId.IsNumeric()?FCString::Atoi(*MapId):MapNames.IndexOfByKey(MapId);
    if(MapIndex<0 || MapIndex>=MapNames.Num()) return false;
    TArray<FString> Coordinates;
    Tokens[2].ParseIntoArray(Coordinates,TEXT(":"),true);
    if(Coordinates.Num()!=2) return false;
    const float X=FCString::Atof(*Coordinates[0]);
    const float Y=FCString::Atof(*Coordinates[1]);
    static const FVector Anchors[]={FVector(0,0,180),FVector(-2600,-2200,180),FVector(-2700,1700,180),FVector(2850,-1750,180),FVector(-2850,-2100,180),FVector(0,2850,180)};
    APawn* Pawn=GetPawn();
    if(!Pawn) return false;
    Pawn->SetActorLocation(Anchors[MapIndex]+FVector(X*10.0f,Y*10.0f,0.0f));
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(Pawn)) Character->ClearMouseCommand();
    return true;
}

bool AHonourWarPlayerController::Exec(UWorld* InWorld,const TCHAR* Cmd,FOutputDevice& Ar)
{
    if(!Cmd) return Super::Exec(InWorld,Cmd,Ar);
    const FString Command(Cmd);

    TArray<FString> Tokens;
    Command.ParseIntoArrayWS(Tokens);
    if(Tokens.Num()>=3 && Tokens[0].Compare(TEXT("@register"),ESearchCase::IgnoreCase)==0)
    {
        FString Message;
        RegisterAccount(Tokens[1],Tokens[2],Message);
        ClientMessage(Message);
        return true;
    }
    if(Tokens.Num()>=3 && Tokens[0].Compare(TEXT("@login"),ESearchCase::IgnoreCase)==0)
    {
        FString Message;
        LoginAccount(Tokens[1],Tokens[2],Message);
        ClientMessage(Message);
        return true;
    }
    if(Command.Equals(TEXT("@auth"),ESearchCase::IgnoreCase))
    {
        ClientMessage(bAuthenticated?FString::Printf(TEXT("Authenticated as %s."),*AccountUsername):TEXT("Not authenticated. Use @register or @login."));
        return true;
    }

    if(ExecuteGoCommand(Command)) return true;

    if(!bAuthenticated)
    {
        if(Command.StartsWith(TEXT("@say"),ESearchCase::IgnoreCase) || Command.StartsWith(TEXT("@guild"),ESearchCase::IgnoreCase))
        {
            ClientMessage(TEXT("Login required before gameplay commands."));
            return true;
        }
        return Super::Exec(InWorld,Cmd,Ar);
    }

    if(Command.StartsWith(TEXT("@say"),ESearchCase::IgnoreCase))
    {
        FString Message=Command.RightChop(4).TrimStart();
        if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn()))
        {
            if(AHonourWarGameMode* GameMode=GetWorld()?GetWorld()->GetAuthGameMode<AHonourWarGameMode>():nullptr)
            {
                FString Result;
                if(GameMode->HandleChatCommand(Character,Message,Result)){ClientMessage(Result);return true;}
            }
        }
    }

    if(Command.StartsWith(TEXT("@guild"),ESearchCase::IgnoreCase))
    {
        if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn()))
        {
            if(AHonourWarGameMode* GameMode=GetWorld()?GetWorld()->GetAuthGameMode<AHonourWarGameMode>():nullptr)
            {
                FString Message;
                if(GameMode->HandleGuildCommand(Character,Command,Message)){ClientMessage(Message);return true;}
            }
        }
    }

    return Super::Exec(InWorld,Cmd,Ar);
}
