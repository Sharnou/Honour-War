#include "HonourWarPlayerController.h"
#include "HonourWarContentCatalog.h"
#include "HonourWarAccountSaveGame.h"
#include "HonourWarSaveGame.h"
#include "HonourWarCharacter.h"
#include "HonourWarMonster.h"
#include "HonourWarGameMode.h"
#include "HonourWarItemEncyclopedia.h"
#include "HonourWarGameState.h"
#include "HonourWarPlayerState.h"
#include "HonourWarCombatComponent.h"
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
    if(!FParse::Param(FCommandLine::Get(),TEXT("HonourWarCapture")) || FParse::Param(FCommandLine::Get(),TEXT("HonourWarE2E"))) return;
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


void AHonourWarPlayerController::EndSessionForE2E()
{
    bAuthenticated=false;
    bCharacterSelected=false;
    ActiveCharacterSlot=-1;
    AccountUsername.Empty();
    OwnedCharacters.Reset();
}

void AHonourWarPlayerController::ResetLocalAccountForE2E()
{
    UGameplayStatics::DeleteGameInSlot(AccountSlot,0);
    EndSessionForE2E();
}

const TArray<FHonourWarCharacterSlot>& AHonourWarPlayerController::GetOwnedCharacters() const
{
    return OwnedCharacters;
}

void AHonourWarPlayerController::EnsureCharacterRoster()
{
    UHonourWarAccountSaveGame* Account=nullptr;
    if(!LoadAccount(Account)) return;
    OwnedCharacters=Account->Characters;
    while(OwnedCharacters.Num()<70) OwnedCharacters.Add(FHonourWarCharacterSlot());
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
bool AHonourWarPlayerController::SaveActiveCharacterData(const UHonourWarSaveGame& SaveData)
{
    if(!bAuthenticated || ActiveCharacterSlot<0 || ActiveCharacterSlot>=OwnedCharacters.Num()) return false;
    UHonourWarAccountSaveGame* Account=nullptr;
    if(!LoadAccount(Account)) return false;
    FHonourWarCharacterSlot& Slot=OwnedCharacters[ActiveCharacterSlot];
    Slot.bOwned=true;
    Slot.ClassId=SaveData.ClassId;
    Slot.ClassTier=SaveData.ClassTier;
    Slot.FifthTierArchetype=SaveData.FifthTierArchetype;
    Slot.Level=SaveData.Level;
    Slot.Experience=SaveData.Experience;
    Slot.AgeDays=SaveData.AgeDays;
    Slot.OnlineSeconds=SaveData.OnlineSeconds;
    Slot.PlayerLocation=SaveData.PlayerLocation;
    Slot.Zeny=SaveData.Zeny;
    Slot.EquipmentRefineLevel=SaveData.EquipmentRefineLevel;
    Slot.Phracon=SaveData.Phracon;
    Slot.Emveretarcon=SaveData.Emveretarcon;
    Slot.Oridecon=SaveData.Oridecon;
    Slot.BasicSkillLevel=SaveData.BasicSkillLevel;
    Slot.SkillPoints=SaveData.SkillPoints;
    Slot.SkillLevels=SaveData.SkillLevels;
    Slot.Honours=SaveData.Honours;
    Slot.StatusPoints=SaveData.StatusPoints;
    Slot.Strength=SaveData.Strength;
    Slot.Agility=SaveData.Agility;
    Slot.Vitality=SaveData.Vitality;
    Slot.Intelligence=SaveData.Intelligence;
    Slot.Dexterity=SaveData.Dexterity;
    Slot.LuckStat=SaveData.LuckStat;
    Slot.InventoryItems=SaveData.InventoryItems;
    Slot.Cards=SaveData.Cards;
    Slot.QuestId=SaveData.QuestId;
    Slot.QuestProgress=SaveData.QuestProgress;
    Slot.QuestComplete=SaveData.QuestComplete;
    Slot.GuildName=SaveData.GuildName;
    Slot.GuildRank=SaveData.GuildRank;
    Slot.SavedAtUtc=FDateTime::UtcNow();
    Account->Characters=OwnedCharacters;
    return UGameplayStatics::SaveGameToSlot(Account,AccountSlot,0);
}

bool AHonourWarPlayerController::LoadActiveCharacterData(UHonourWarSaveGame& OutSaveData) const
{
    if(!bAuthenticated || ActiveCharacterSlot<0 || ActiveCharacterSlot>=OwnedCharacters.Num() || !OwnedCharacters[ActiveCharacterSlot].bOwned) return false;
    const FHonourWarCharacterSlot& Slot=OwnedCharacters[ActiveCharacterSlot];
    OutSaveData.Level=Slot.Level;
    OutSaveData.Experience=Slot.Experience;
    OutSaveData.AgeDays=Slot.AgeDays;
    OutSaveData.ClassId=Slot.ClassId;
    OutSaveData.ClassTier=Slot.ClassTier;
    OutSaveData.FifthTierArchetype=Slot.FifthTierArchetype;
    OutSaveData.OnlineSeconds=Slot.OnlineSeconds;
    OutSaveData.PlayerLocation=Slot.PlayerLocation;
    OutSaveData.Zeny=Slot.Zeny;
    OutSaveData.EquipmentRefineLevel=Slot.EquipmentRefineLevel;
    OutSaveData.Phracon=Slot.Phracon;
    OutSaveData.Emveretarcon=Slot.Emveretarcon;
    OutSaveData.Oridecon=Slot.Oridecon;
    OutSaveData.BasicSkillLevel=Slot.BasicSkillLevel;
    OutSaveData.SkillPoints=Slot.SkillPoints;
    OutSaveData.SkillLevels=Slot.SkillLevels;
    OutSaveData.Honours=Slot.Honours;
    OutSaveData.StatusPoints=Slot.StatusPoints;
    OutSaveData.Strength=Slot.Strength;
    OutSaveData.Agility=Slot.Agility;
    OutSaveData.Vitality=Slot.Vitality;
    OutSaveData.Intelligence=Slot.Intelligence;
    OutSaveData.Dexterity=Slot.Dexterity;
    OutSaveData.LuckStat=Slot.LuckStat;
    OutSaveData.InventoryItems=Slot.InventoryItems;
    OutSaveData.Cards=Slot.Cards;
    OutSaveData.QuestId=Slot.QuestId;
    OutSaveData.QuestProgress=Slot.QuestProgress;
    OutSaveData.QuestComplete=Slot.QuestComplete;
    OutSaveData.GuildName=Slot.GuildName;
    OutSaveData.GuildRank=Slot.GuildRank;
    OutSaveData.SavedAtUtc=Slot.SavedAtUtc;
    return true;
}


bool AHonourWarPlayerController::CreateCharacter(const FString& CharacterName,EHonourWarClass ClassId,FString& OutMessage)
{
    if(!bAuthenticated){OutMessage=TEXT("Login required before creating a character.");return false;}
    const FString Clean=CharacterName.TrimStartAndEnd();
    if(Clean.Len()<3 || Clean.Len()>20){OutMessage=TEXT("Character name must be 3-20 characters.");return false;}
    for(const TCHAR C:Clean) if(!(FChar::IsAlnum(C)||C==TEXT('_')||C==TEXT('-'))){OutMessage=TEXT("Character name may contain letters, numbers, _ and -.");return false;}
    for(int32 i=0;i<OwnedCharacters.Num();++i) if(OwnedCharacters[i].bOwned && OwnedCharacters[i].CharacterName.Equals(Clean,ESearchCase::IgnoreCase)){OutMessage=TEXT("That character name is already owned.");return false;}
    int32 Slot=-1;
    for(int32 i=0;i<70;++i){if(i>=OwnedCharacters.Num()) OwnedCharacters.Add(FHonourWarCharacterSlot()); if(!OwnedCharacters[i].bOwned){Slot=i;break;}}
    if(Slot<0){OutMessage=TEXT("All 70 character slots are occupied.");return false;}
    OwnedCharacters[Slot].bOwned=true;
    OwnedCharacters[Slot].CharacterName=Clean;
    OwnedCharacters[Slot].ClassId=ClassId;
    OwnedCharacters[Slot].ClassTier=EHonourWarClassTier::Tier1;
    OwnedCharacters[Slot].Level=1;
    OwnedCharacters[Slot].Experience=0;
    OwnedCharacters[Slot].AgeDays=0;
    OwnedCharacters[Slot].OnlineSeconds=0;
    OwnedCharacters[Slot].PlayerLocation=FVector(0,1100,180);
    OwnedCharacters[Slot].Zeny=0;
    OwnedCharacters[Slot].EquipmentRefineLevel=0;
    OwnedCharacters[Slot].Phracon=20;
    OwnedCharacters[Slot].Emveretarcon=10;
    OwnedCharacters[Slot].Oridecon=5;
    OwnedCharacters[Slot].BasicSkillLevel=1;
    OwnedCharacters[Slot].SkillPoints=0;
    OwnedCharacters[Slot].SkillLevels.Init(1,8);
    OwnedCharacters[Slot].Honours=0;
    OwnedCharacters[Slot].StatusPoints=30;
    OwnedCharacters[Slot].Strength=10;
    OwnedCharacters[Slot].Agility=10;
    OwnedCharacters[Slot].Vitality=10;
    OwnedCharacters[Slot].Intelligence=10;
    OwnedCharacters[Slot].Dexterity=10;
    OwnedCharacters[Slot].LuckStat=10;
    OwnedCharacters[Slot].InventoryItems.Reset();
    OwnedCharacters[Slot].Cards.Reset();
    OwnedCharacters[Slot].QuestId=1;
    OwnedCharacters[Slot].QuestProgress=0;
    OwnedCharacters[Slot].QuestComplete=false;
    OwnedCharacters[Slot].GuildName.Reset();
    OwnedCharacters[Slot].GuildRank=TEXT("Member");
    OwnedCharacters[Slot].SavedAtUtc=FDateTime::UtcNow();
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
    FString Clean=Message;
    Clean.TrimStartAndEndInline();
    Clean.LeftInline(180,true);
    if(Clean.IsEmpty()) return;
    if(!HasAuthority()){ServerSendChat(Clean);return;}
    if(Clean.Equals(TEXT("@auth"),ESearchCase::IgnoreCase))
    {
        ClientMessage(!bAuthenticated?TEXT("Not authenticated. Use @register or @login."):IsReadyForGameplay()?FString::Printf(TEXT("Authenticated as %s. Character slot %d selected."),*AccountUsername,ActiveCharacterSlot+1):FString::Printf(TEXT("Authenticated as %s. Character selection required."),*AccountUsername));
        return;
    }
    if(!IsReadyForGameplay()) return;
    if(ExecuteHelpCommand(Clean) || ExecuteGoCommand(Clean) || ExecuteStatCommand(Clean) || ExecuteSkillCommand(Clean) || ExecuteRestSkillsCommand(Clean)) return;
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

bool AHonourWarPlayerController::ExecuteHelpCommand(const FString& Command)
{
    TArray<FString> Tokens;
    Command.ParseIntoArrayWS(Tokens);
    if(Tokens.Num()==0) return false;
    const bool bHelp = Tokens[0].Equals(TEXT("@help"),ESearchCase::IgnoreCase) || Tokens[0].Equals(TEXT("/help"),ESearchCase::IgnoreCase);
    if(!bHelp) return false;

    if(Tokens.Num()==1)
    {
        ClientMessage(TEXT("HELP: /help [item/card/pet ID or name] | /skill | /skill impact <monster> | /restskills confirm"));
        ClientMessage(TEXT("IDs: EQUIP_001-300 | ITEM_001-076 | CARD_001-300 | JOBEQ_* | JOBCARD_* | PETEQ_001-100"));
        return true;
    }

    FString Query;
    for(int32 i=1;i<Tokens.Num();++i)
    {
        if(!Query.IsEmpty()) Query+=TEXT(" ");
        Query+=Tokens[i];
    }
    const TArray<FString> Lines=HonourWarItemEncyclopedia::BuildHelpLines(Query);
    for(const FString& Line:Lines) ClientMessage(Line);
    return true;
}

bool AHonourWarPlayerController::ExecuteStatCommand(const FString& Command)
{
    if(!IsReadyForGameplay()) return false;
    AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn());
    if(!Character || !Character->GetCombatComponent()) return false;
    UHonourWarCombatComponent* Combat=Character->GetCombatComponent();

    TArray<FString> Tokens;
    Command.ParseIntoArrayWS(Tokens);
    if(Tokens.Num()<=0 || Tokens[0].Compare(TEXT("@stat"),ESearchCase::IgnoreCase)!=0) return false;

    if(Tokens.Num()==1 || Tokens[1].Compare(TEXT("help"),ESearchCase::IgnoreCase)==0 || Tokens[1].Compare(TEXT("all"),ESearchCase::IgnoreCase)==0)
    {
        ClientMessage(FString::Printf(
            TEXT("Stats | Points %d | STR %d AGI %d VIT %d INT %d DEX %d LUK %d | Use @stat STR 1"),
            Combat->GetStatusPoints(),Combat->GetStrength(),Combat->GetAgility(),Combat->GetVitality(),
            Combat->GetIntelligence(),Combat->GetDexterity(),Combat->GetLuckStat()));
        return true;
    }

    if(Tokens.Num()<3) return true;
    const FString Name=Tokens[1].ToUpper();
    const int32 Amount=FMath::Clamp(FCString::Atoi(*Tokens[2]),1,20);
    EHonourWarStatusStat Stat=EHonourWarStatusStat::Strength;
    bool bValid=true;
    if(Name==TEXT("STR")) Stat=EHonourWarStatusStat::Strength;
    else if(Name==TEXT("AGI")) Stat=EHonourWarStatusStat::Agility;
    else if(Name==TEXT("VIT")) Stat=EHonourWarStatusStat::Vitality;
    else if(Name==TEXT("INT")) Stat=EHonourWarStatusStat::Intelligence;
    else if(Name==TEXT("DEX")) Stat=EHonourWarStatusStat::Dexterity;
    else if(Name==TEXT("LUK")) Stat=EHonourWarStatusStat::Luck;
    else bValid=false;

    if(!bValid){ ClientMessage(TEXT("Unknown stat. Use STR AGI VIT INT DEX LUK.")); return true; }

    if(Combat->SpendStatusPoint(Stat,Amount))
    {
        Character->SaveProgress();
        int32 NewValue=Combat->GetLuckStat();
        switch(Stat)
        {
            case EHonourWarStatusStat::Strength: NewValue=Combat->GetStrength(); break;
            case EHonourWarStatusStat::Agility: NewValue=Combat->GetAgility(); break;
            case EHonourWarStatusStat::Vitality: NewValue=Combat->GetVitality(); break;
            case EHonourWarStatusStat::Intelligence: NewValue=Combat->GetIntelligence(); break;
            case EHonourWarStatusStat::Dexterity: NewValue=Combat->GetDexterity(); break;
            case EHonourWarStatusStat::Luck: NewValue=Combat->GetLuckStat(); break;
        }
        ClientMessage(FString::Printf(
            TEXT("STAT ALLOCATION | %s +%d | remaining %d | new value %d"),
            *HonourWarStatusStatName(Stat),Amount,Combat->GetStatusPoints(),NewValue));
    }
    else
    {
        ClientMessage(TEXT("STAT ALLOCATION BLOCKED | insufficient points, invalid cap, or too-high cost."));
    }
    return true;
}

bool AHonourWarPlayerController::ExecuteSkillCommand(const FString& Command)
{
    if(!IsReadyForGameplay()) return false;
    AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn());
    if(!Character || !Character->GetCombatComponent()) return false;
    TArray<FString> Tokens;
    Command.ParseIntoArrayWS(Tokens);
    if(Tokens.Num()==0) return false;
    const bool bSkill=Tokens[0].Equals(TEXT("@skill"),ESearchCase::IgnoreCase)||Tokens[0].Equals(TEXT("/skill"),ESearchCase::IgnoreCase);
    if(!bSkill) return false;
    UHonourWarCombatComponent* Combat=Character->GetCombatComponent();
    if(Tokens.Num()==1 || Tokens[1].Equals(TEXT("help"),ESearchCase::IgnoreCase))
    {
        ClientMessage(FString::Printf(
            TEXT("SKILLS | 8 class skills | Skill Points %d | levels %d/%d/%d/%d/%d/%d/%d/%d | Use @skill 1 1"),
            Combat->GetSkillPoints(),Combat->GetSkillLevel(0),Combat->GetSkillLevel(1),Combat->GetSkillLevel(2),Combat->GetSkillLevel(3),
            Combat->GetSkillLevel(4),Combat->GetSkillLevel(5),Combat->GetSkillLevel(6),Combat->GetSkillLevel(7)));
        return true;
    }
    if(Tokens[1].Equals(TEXT("impact"),ESearchCase::IgnoreCase))
    {
        const FString Species=Tokens.Num()>=3?Tokens[2]:TEXT("Skeleton");
        ClientMessage(FString::Printf(TEXT("SKILL IMPACT | %s | Tier %s | class %s"),*Species,*Character->GetClassTierName(),*Character->GetClassName()));
        for(int32 I=0;I<8;++I)
            ClientMessage(FString::Printf(TEXT("  %d | Lv.%d | x%.2f"),I+1,Combat->GetSkillLevel(I),Combat->GetSkillImpactMultiplierForSpecies(I,Species)));
        return true;
    }
    if(Tokens.Num()<3) return true;
    const int32 Index=FMath::Clamp(FCString::Atoi(*Tokens[1])-1,0,7);
    const int32 Amount=FMath::Clamp(FCString::Atoi(*Tokens[2]),1,9);
    Character->UpgradeSkill(Index,Amount);
    ClientMessage(Combat->GetLastLootMessage());
    return true;
}

bool AHonourWarPlayerController::ExecuteRestSkillsCommand(const FString& Command)
{
    if(!IsReadyForGameplay()) return false;
    TArray<FString> Tokens;
    Command.ParseIntoArrayWS(Tokens);
    if(Tokens.Num()==0) return false;
    const bool bReset=Tokens[0].Equals(TEXT("@restskills"),ESearchCase::IgnoreCase)||Tokens[0].Equals(TEXT("/restskills"),ESearchCase::IgnoreCase);
    if(!bReset) return false;
    AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetPawn());
    if(!Character || !Character->GetCombatComponent()) return false;
    if(Tokens.Num()<2 || !Tokens[1].Equals(TEXT("confirm"),ESearchCase::IgnoreCase))
    {
        ClientMessage(TEXT("SKILL RESET | Available only at Tier 5 (Lv.200+). Type @restskills confirm to reset all 8 class skills to Lv.1 and refund spent points."));
        return true;
    }
    Character->ResetSkills();
    ClientMessage(Character->GetLastCombatMessage());
    return true;
}

bool AHonourWarPlayerController::ExecuteGoCommand(const FString& Command)
{
    if(!IsReadyForGameplay()) return false;
    TArray<FString> Tokens;
    Command.ParseIntoArrayWS(Tokens);
    if(Tokens.Num()<3 || Tokens[0].Compare(TEXT("@go"),ESearchCase::IgnoreCase)!=0) return false;

    const TArray<HonourWarContentCatalog::FMapTemplate>& Maps = HonourWarContentCatalog::Maps();
    const FString Requested = Tokens[1].ToLower();
    int32 MapIndex = Requested.IsNumeric() ? FCString::Atoi(*Requested) : INDEX_NONE;
    if (MapIndex == INDEX_NONE)
    {
        for (int32 I=0; I<Maps.Num(); ++I)
        {
            if (Maps[I].Id.Equals(Requested,ESearchCase::IgnoreCase))
            {
                MapIndex = I;
                break;
            }
        }
    }
    if(MapIndex<0 || MapIndex>=Maps.Num()) return false;

    TArray<FString> Coordinates;
    Tokens[2].ParseIntoArray(Coordinates,TEXT(":"),true);
    if(Coordinates.Num()!=2) return false;
    const float X=FCString::Atof(*Coordinates[0]);
    const float Y=FCString::Atof(*Coordinates[1]);
    const FVector Offset=FVector(X*10.0f,Y*10.0f,0.0f);

    APawn* Pawn=GetPawn();
    if(!Pawn) return false;
    Pawn->SetActorLocation(Maps[MapIndex].Anchor+Offset);
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
    if(ExecuteHelpCommand(Command)) return true;
    if(Command.Equals(TEXT("@auth"),ESearchCase::IgnoreCase))
    {
        ClientMessage(!bAuthenticated?TEXT("Not authenticated. Use @register or @login."):IsReadyForGameplay()?FString::Printf(TEXT("Authenticated as %s. Character slot %d selected."),*AccountUsername,ActiveCharacterSlot+1):FString::Printf(TEXT("Authenticated as %s. Character selection required."),*AccountUsername));
        return true;
    }

    if(ExecuteGoCommand(Command)) return true;
    if(ExecuteStatCommand(Command)) return true;
    if(ExecuteSkillCommand(Command)) return true;
    if(ExecuteRestSkillsCommand(Command)) return true;

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
