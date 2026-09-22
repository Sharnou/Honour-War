#include "HonourWarPlayerController.h"
#include "HonourWarAccountSaveGame.h"
#include "HonourWarSaveGame.h"
#include "HonourWarCharacter.h"
#include "HonourWarMonster.h"
#include "HonourWarGameMode.h"
#include "HonourWarGameState.h"
#include "HonourWarPlayerState.h"
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
    // Persistent camera identity: Ragnarok Online-inspired elevated isometric MMORPG view.\n    SetControlRotation(FRotator(-50.0f,45.0f,0.0f));

    FInputModeGameAndUI InputMode;
    InputMode.SetHideCursorDuringCapture(false);
    InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
    SetInputMode(InputMode);

    AuthenticateCaptureAccount();
}

void AHonourWarPlayerController::PlayerTick(float DeltaTime)
{
    Super::PlayerTick(DeltaTime);
    if (bRightMouseDown && IsReadyForGameplay()) RotateCameraFromMouse();
}

bool AHonourWarPlayerController::InputKey(const FInputKeyEventArgs& Params)
{
    if (Params.Key==EKeys::LeftMouseButton && Params.Event==IE_Pressed)
    {
        if (IsReadyForGameplay()) HandleMouseClick();
        return true;
    }
    if (Params.Key==EKeys::RightMouseButton)
    {
        bRightMouseDown=(Params.Event==IE_Pressed);
        if (bRightMouseDown && IsReadyForGameplay())
        {
            float X=0.0f,Y=0.0f;
            if (GetMousePosition(X,Y)){LastMousePosition=FVector2D(X,Y);bHasLastMousePosition=true;}
        }
        else bHasLastMousePosition=false;
        return true;
    }
    if (Params.Key==EKeys::MouseScrollUp && Params.Event==IE_Pressed)
    {
        if (IsReadyForGameplay()) HandleMouseWheel(1.0f);
        return true;
    }
    if (Params.Key==EKeys::MouseScrollDown && Params.Event==IE_Pressed)
    {
        if (IsReadyForGameplay()) HandleMouseWheel(-1.0f);
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

void AHonourWarPlayerController::MoveForward(float V){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->MoveForward(V);}
void AHonourWarPlayerController::MoveRight(float V){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->MoveRight(V);}
void AHonourWarPlayerController::Turn(float V){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CameraTurn(V);}
void AHonourWarPlayerController::LookUp(float V){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CameraLookUp(V);}
void AHonourWarPlayerController::Attack(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->Attack();}
void AHonourWarPlayerController::ResetCamera(){if(IsReadyForGameplay())SetControlRotation(FRotator(-50.0f,45.0f,0.0f));}
void AHonourWarPlayerController::SaveGame(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->SaveProgress();}
void AHonourWarPlayerController::LoadGame(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->LoadProgress();}
void AHonourWarPlayerController::NextClass(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->CycleClass();}
void AHonourWarPlayerController::Skill1(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(0);}
void AHonourWarPlayerController::Skill2(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(1);}
void AHonourWarPlayerController::Skill3(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(2);}
void AHonourWarPlayerController::Skill4(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(3);}
void AHonourWarPlayerController::Skill5(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(4);}
void AHonourWarPlayerController::Skill6(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(5);}
void AHonourWarPlayerController::Skill7(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(6);}
void AHonourWarPlayerController::Skill8(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->ActivateSkill(7);}
void AHonourWarPlayerController::RefineEquipment(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->RefineEquipment();}
void AHonourWarPlayerController::MixCards(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->MixCards();}
void AHonourWarPlayerController::UpgradeBasicSkill(){if(IsReadyForGameplay())if(auto*C=Cast<AHonourWarCharacter>(GetPawn()))C->UpgradeBasicSkill();}

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
    bCharacterSelected=false;
    ActiveCharacterSlot=-1;
    AccountUsername=Username.TrimStartAndEnd();
    EnsureCharacterRoster();
    OutMessage=FString::Printf(TEXT("Registration successful. Logged in as %s. Select or create a character."),*AccountUsername);
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
    bCharacterSelected=false;
    ActiveCharacterSlot=-1;
    AccountUsername=Account->Username;
    EnsureCharacterRoster();
    OutMessage=FString::Printf(TEXT("Login successful. Welcome, %s. Select a character to continue."),*AccountUsername);
    return true;
}

void AHonourWarPlayerController::AuthenticateCaptureAccount()
{
    if(!FParse::Param(FCommandLine::Get(),TEXT("HonourWarCapture"))) return;
    FString Result;
    if(!IsReadyForGameplay())
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
        if(bAuthenticated)
        {
            if(OwnedCharacters.Num()>0 && OwnedCharacters[0].bOwned)
                SelectCharacter(0,Result);
            else
                CreateCharacter(TEXT("CaptureHero"),EHonourWarClass::Warrior,Result);
        }
    }
}


const TArray<FHonourWarCharacterSlot>& AHonourWarPlayerController::GetOwnedCharacters() const
{
    return OwnedCharacters;
}

FString AHonourWarPlayerController::CharacterSlotName(int32 SlotIndex) const
{
    return FString::Printf(TEXT("HonourWar_Profile_%d"),FMath::Clamp(SlotIndex,0,3));
}

void AHonourWarPlayerController::EnsureCharacterRoster()
{
    UHonourWarAccountSaveGame* Account=nullptr;
    if(!LoadAccount(Account)) return;
    OwnedCharacters=Account->Characters;
    while(OwnedCharacters.Num()<4) OwnedCharacters.Add(FHonourWarCharacterSlot());
    if(SaveCharacterRoster()) return;
}

bool AHonourWarPlayerController::SaveCharacterRoster()
{
    UHonourWarAccountSaveGame* Account=nullptr;
    if(!LoadAccount(Account)) return false;
    Account->Characters=OwnedCharacters;
    return UGameplayStatics::SaveGameToSlot(Account,AccountSlot,0);
}

bool AHonourWarPlayerController::SelectCharacter(int32 SlotIndex,FString& OutMessage)
{
    if(!bAuthenticated){OutMessage=TEXT("Login required before character selection.");return false;}
    if(SlotIndex<0 || SlotIndex>=OwnedCharacters.Num() || !OwnedCharacters[SlotIndex].bOwned)
    {OutMessage=TEXT("That character slot is empty.");return false;}
    ActiveCharacterSlot=SlotIndex;
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn()))
    {
        Character->LoadProgress();
        Character->SetClassId(OwnedCharacters[SlotIndex].ClassId);
        if(AHonourWarPlayerState* PS=GetPlayerState<AHonourWarPlayerState>()) PS->SetPlayerName(OwnedCharacters[SlotIndex].CharacterName);
    }
    bCharacterSelected=true;
    OutMessage=FString::Printf(TEXT("Character selected: %s  |  Lv.%d  |  %s"),*OwnedCharacters[SlotIndex].CharacterName,OwnedCharacters[SlotIndex].Level,*HonourWarClassName(OwnedCharacters[SlotIndex].ClassId));
    return true;
}

void AHonourWarPlayerController::SyncActiveCharacterSummary(AHonourWarCharacter* Character)
{
    if(!Character || ActiveCharacterSlot<0 || ActiveCharacterSlot>=OwnedCharacters.Num()) return;
    if(!Character->GetCombatComponent()) return;
    OwnedCharacters[ActiveCharacterSlot].bOwned=true;
    if(OwnedCharacters[ActiveCharacterSlot].CharacterName.IsEmpty()) OwnedCharacters[ActiveCharacterSlot].CharacterName=AccountUsername;
    OwnedCharacters[ActiveCharacterSlot].ClassId=Character->GetClassId();
    OwnedCharacters[ActiveCharacterSlot].Level=Character->GetCombatComponent()->GetLevel();
    OwnedCharacters[ActiveCharacterSlot].EquipmentRefineLevel=Character->GetCombatComponent()->GetEquipmentRefineLevel();
    SaveCharacterRoster();
}

bool AHonourWarPlayerController::CreateCharacter(const FString& CharacterName,EHonourWarClass ClassId,FString& OutMessage)
{
    if(!bAuthenticated){OutMessage=TEXT("Login required before creating a character.");return false;}
    const FString Clean=CharacterName.TrimStartAndEnd();
    if(Clean.Len()<3 || Clean.Len()>20){OutMessage=TEXT("Character name must be 3-20 characters.");return false;}
    for(const TCHAR C:Clean) if(!(FChar::IsAlnum(C)||C==TEXT('_')||C==TEXT('-'))){OutMessage=TEXT("Character name may contain letters, numbers, _ and -.");return false;}
    for(int32 i=0;i<OwnedCharacters.Num();++i) if(OwnedCharacters[i].bOwned && OwnedCharacters[i].CharacterName.Equals(Clean,ESearchCase::IgnoreCase)){OutMessage=TEXT("That character name is already owned.");return false;}
    int32 Slot=-1;
    for(int32 i=0;i<4;++i){if(i>=OwnedCharacters.Num()) OwnedCharacters.Add(FHonourWarCharacterSlot()); if(!OwnedCharacters[i].bOwned){Slot=i;break;}}
    if(Slot<0){OutMessage=TEXT("All four character slots are occupied.");return false;}
    UHonourWarSaveGame* Save=Cast<UHonourWarSaveGame>(UGameplayStatics::CreateSaveGameObject(UHonourWarSaveGame::StaticClass()));
    if(!Save){OutMessage=TEXT("Character save could not be created.");return false;}
    Save->ClassId=ClassId;
    Save->ClassTier=EHonourWarClassTier::Tier1;
    Save->PlayerLocation=FVector(900,900,180);
    Save->SavedAtUtc=FDateTime::UtcNow();
    if(!UGameplayStatics::SaveGameToSlot(Save,*CharacterSlotName(Slot),0)){OutMessage=TEXT("Character could not be saved.");return false;}
    OwnedCharacters[Slot].bOwned=true;
    OwnedCharacters[Slot].CharacterName=Clean;
    OwnedCharacters[Slot].ClassId=ClassId;
    OwnedCharacters[Slot].Level=1;
    OwnedCharacters[Slot].EquipmentRefineLevel=0;
    SaveCharacterRoster();
    ActiveCharacterSlot=Slot;
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn()))
    {
        Character->SetClassId(ClassId);
        Character->LoadProgress();
        if(AHonourWarPlayerState* PS=GetPlayerState<AHonourWarPlayerState>()) PS->SetPlayerName(Clean);
    }
    bCharacterSelected=true;
    OutMessage=FString::Printf(TEXT("New character created: %s  |  %s"),*Clean,*HonourWarClassName(ClassId));
    return true;
}

void AHonourWarPlayerController::SendChatMessage(const FString& Message)
{
    if(!IsReadyForGameplay()) return;
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
    if(!IsReadyForGameplay()) return false;
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
        ClientMessage(!bAuthenticated?TEXT("Not authenticated. Use @register or @login."):IsReadyForGameplay()?FString::Printf(TEXT("Authenticated as %s. Character slot %d selected."),*AccountUsername,ActiveCharacterSlot+1):FString::Printf(TEXT("Authenticated as %s. Character selection required."),*AccountUsername));
        return true;
    }

    if(ExecuteGoCommand(Command)) return true;

    if(!IsReadyForGameplay())
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
