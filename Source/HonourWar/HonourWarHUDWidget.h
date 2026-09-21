#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "HonourWarHUDWidget.generated.h"

class UCanvasPanel;
class UProgressBar;
class UTextBlock;
class UButton;

UCLASS()
class HONOURWAR_API UHonourWarHUDWidget : public UUserWidget
{
    GENERATED_BODY()

protected:
    virtual void NativeConstruct() override;
    virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;

private:
    void BuildSurface();
    void BuildProfileCluster(UCanvasPanel* Root);
    void BuildLeftNavigation(UCanvasPanel* Root);
    void BuildTopRightControls(UCanvasPanel* Root);
    void BuildMiniMap(UCanvasPanel* Root);
    void BuildQuestTracker(UCanvasPanel* Root);
    void BuildChatDock(UCanvasPanel* Root);
    void BuildBottomRightShortcuts(UCanvasPanel* Root);

    UButton* MakeNavButton(UCanvasPanel* Root, const FString& Icon, const FString& Text, float Y);
    UButton* MakeTopButton(UCanvasPanel* Root, const FString& Icon, float X);
    UButton* MakeShortcut(UCanvasPanel* Root, const FString& Icon, const FString& Text, float X);

    void RefreshVitals();

    UPROPERTY() UCanvasPanel* RootCanvas = nullptr;
    UPROPERTY() UProgressBar* HpBar = nullptr;
    UPROPERTY() UProgressBar* SpBar = nullptr;
    UPROPERTY() UProgressBar* XpBar = nullptr;
    UPROPERTY() UTextBlock* ProfileName = nullptr;
    UPROPERTY() UTextBlock* ProfileMeta = nullptr;
    UPROPERTY() UTextBlock* EconomyText = nullptr;
    UPROPERTY() UTextBlock* CombatText = nullptr;
};
