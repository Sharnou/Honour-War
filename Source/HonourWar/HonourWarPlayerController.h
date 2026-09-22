#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "HonourWarAccountSaveGame.h"
#include "HonourWarPlayerController.generated.h"

UCLASS()
class HONOURWAR_API AHonourWarPlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    AHonourWarPlayerController();
    void SendChatMessage(const FString& Message);
    bool IsAuthenticated() const { return bAuthenticated; }
    bool IsReadyForGameplay() const { return bAuthenticated && bCharacterSelected; }
    FString GetAccountUsername() const { return AccountUsername; }
    const TArray<struct FHonourWarCharacterSlot>& GetOwnedCharacters() const;
    bool SelectCharacter(int32 SlotIndex, FString& OutMessage);
    bool CreateCharacter(const FString& CharacterName, EHonourWarClass ClassId, FString& OutMessage);
    void SyncActiveCharacterSummary(class AHonourWarCharacter* Character);
    bool SaveActiveCharacterData(const class UHonourWarSaveGame& SaveData);
    bool LoadActiveCharacterData(class UHonourWarSaveGame& OutSaveData) const;
    bool RegisterAccount(const FString& Username,const FString& Password,FString& OutMessage);
    bool LoginAccount(const FString& Username,const FString& Password,FString& OutMessage);

protected:
    virtual void BeginPlay() override;
    virtual void SetupInputComponent() override;
    virtual void PlayerTick(float DeltaTime) override;
    virtual bool InputKey(const FInputKeyEventArgs& Params) override;
    virtual bool Exec(UWorld* InWorld,const TCHAR* Cmd,FOutputDevice& Ar) override;

    UFUNCTION(Server,Reliable)
    void ServerSendChat(const FString& Message);

private:
    void MoveForward(float Value);
    void MoveRight(float Value);
    void Turn(float Value);
    void LookUp(float Value);
    void Attack();
    void ResetCamera();
    void NextClass();
    void Skill1();
    void Skill2();
    void Skill3();
    void Skill4();
    void Skill5();
    void Skill6();
    void Skill7();
    void Skill8();
    void RefineEquipment();
    void MixCards();
    void UpgradeBasicSkill();
    void HandleMouseClick();
    void HandleMouseWheel(float Delta);
    void RotateCameraFromMouse();
    bool ExecuteGoCommand(const FString& Command);
    bool ValidateAccountInput(const FString& Username,const FString& Password,FString& OutMessage) const;
    FString HashPassword(const FString& Password) const;
    bool LoadAccount(class UHonourWarAccountSaveGame*& OutAccount) const;
    bool SaveAccount(const FString& Username,const FString& PasswordHash,const FDateTime& CreatedAtUtc,FString& OutMessage);
    void AuthenticateCaptureAccount();
    void EnsureCharacterRoster();
    bool SaveCharacterRoster();

    bool bAuthenticated=false;
    bool bCharacterSelected=false;
    int32 ActiveCharacterSlot=-1;
    TArray<struct FHonourWarCharacterSlot> OwnedCharacters;
    bool bRightMouseDown=false;
    bool bHasLastMousePosition=false;
    FString AccountUsername;
    FVector2D LastMousePosition=FVector2D::ZeroVector;
};
