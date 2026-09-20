#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "HonourWarHUDWidget.generated.h"

class UCanvasPanel;
class UProgressBar;
class UTextBlock;
class UHorizontalBox;
class UButton;

UCLASS()
class HONOURWAR_API UHonourWarHUDWidget : public UUserWidget
{
    GENERATED_BODY()

protected:
    virtual void NativeConstruct() override;
    virtual void NativeTick(const FGeometry& MyGeometry,float InDeltaTime) override;

private:
    void BuildSurface();
    void BuildPlayerPanel(UCanvasPanel* Root);
    void BuildTargetPanel(UCanvasPanel* Root);
    void BuildMiniMap(UCanvasPanel* Root);
    void BuildChatPanel(UCanvasPanel* Root);
    void BuildSkillBar(UCanvasPanel* Root);
    UButton* MakeSkillButton(UHorizontalBox* Row,int32 Index,const FString& LabelText);

    UFUNCTION() void OnSkill1();
    UFUNCTION() void OnSkill2();
    UFUNCTION() void OnSkill3();
    UFUNCTION() void OnSkill4();
    UFUNCTION() void OnSkill5();
    UFUNCTION() void OnSkill6();
    UFUNCTION() void OnSkill7();
    UFUNCTION() void OnSkill8();

    void UseSkill(int32 Index);

    UPROPERTY() UCanvasPanel* RootCanvas=nullptr;
    UPROPERTY() UProgressBar* HpBar=nullptr;
    UPROPERTY() UProgressBar* SpBar=nullptr;
    UPROPERTY() UProgressBar* XpBar=nullptr;
    UPROPERTY() UTextBlock* PlayerInfo=nullptr;
    UPROPERTY() UTextBlock* CombatText=nullptr;
    UPROPERTY() UTextBlock* TargetInfo=nullptr;
    UPROPERTY() TArray<UButton*> SkillButtons;
};
