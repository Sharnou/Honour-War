#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "HonourWarTypes.h"
#include "HonourWarHUDWidget.generated.h"

class UCanvasPanel;
class UProgressBar;
class UTextBlock;
class UButton;
class UEditableTextBox;
class UBorder;
class UImage;
class UHonourWarQuestComponent;

UCLASS()
class HONOURWAR_API UHonourWarHUDWidget : public UUserWidget
{
    GENERATED_BODY()

protected:
    virtual void NativeConstruct() override;
    virtual void NativeTick(const FGeometry& MyGeometry,float InDeltaTime) override;

private:
    void BuildSurface();
    void BuildProfileCluster(UCanvasPanel* Root);
    void BuildMiniMap(UCanvasPanel* Root);
    void BuildQuestTracker(UCanvasPanel* Root);
    void BuildChatDock(UCanvasPanel* Root);
    void BuildAuthenticationPanel(UCanvasPanel* Root);
    void BuildCharacterSelectionPanel(UCanvasPanel* Root);
    UTexture2D* BuildLoginBackgroundTexture();

    void RefreshVitals();
    void RefreshCharacterSelection();
    UFUNCTION() void SubmitChat();
    UFUNCTION() void SubmitRegister();
    UFUNCTION() void SubmitLogin();
    UFUNCTION() void SelectOwnedCharacter();
    UFUNCTION() void CreateNewCharacter();
    UFUNCTION() void CreateWarriorCharacter();
    UFUNCTION() void CreateMageCharacter();
    UFUNCTION() void CreateArcherCharacter();

    UPROPERTY() UCanvasPanel* RootCanvas=nullptr;
    UPROPERTY() UProgressBar* HpBar=nullptr;
    UPROPERTY() UProgressBar* SpBar=nullptr;
    UPROPERTY() UProgressBar* XpBar=nullptr;
    UPROPERTY() UTextBlock* ProfileName=nullptr;
    UPROPERTY() UTextBlock* ProfileMeta=nullptr;
    UPROPERTY() UTextBlock* ChatText=nullptr;
    UPROPERTY() UEditableTextBox* ChatInput=nullptr;
    UPROPERTY() UButton* ChatSendButton=nullptr;
    UPROPERTY() UTextBlock* EconomyText=nullptr;
    UPROPERTY() UTextBlock* RefinementText=nullptr;
    UPROPERTY() UTextBlock* QuestText=nullptr;
    UPROPERTY() UTextBlock* CombatText=nullptr;

    UPROPERTY() UBorder* AuthPanel=nullptr;
    UPROPERTY() UEditableTextBox* AuthUsername=nullptr;
    UPROPERTY() UEditableTextBox* AuthPassword=nullptr;
    UPROPERTY() UTextBlock* AuthStatus=nullptr;
    UPROPERTY() UButton* AuthRegisterButton=nullptr;
    UPROPERTY() UButton* AuthLoginButton=nullptr;

    UPROPERTY() UBorder* CharacterSelectPanel=nullptr;
    UPROPERTY() UTextBlock* CharacterListText=nullptr;
    UPROPERTY() UEditableTextBox* CharacterSlotInput=nullptr;
    UPROPERTY() UTextBlock* CharacterSelectStatus=nullptr;
    UPROPERTY() UButton* CharacterSelectButton=nullptr;
    UPROPERTY() UButton* CharacterCreateButton=nullptr;
    UPROPERTY() UBorder* CharacterCreatePanel=nullptr;
    UPROPERTY() UEditableTextBox* CharacterNameInput=nullptr;
    UPROPERTY() UButton* CreateWarriorButton=nullptr;
    UPROPERTY() UButton* CreateMageButton=nullptr;
    UPROPERTY() UButton* CreateArcherButton=nullptr;
    UPROPERTY() UImage* AuthBackgroundImage=nullptr;
    UPROPERTY() UTexture2D* LoginBackgroundTexture=nullptr;
};
