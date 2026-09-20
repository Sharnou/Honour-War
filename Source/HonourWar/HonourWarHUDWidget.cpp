#include "HonourWarHUDWidget.h"
#include "HonourWarCharacter.h"
#include "HonourWarCombatComponent.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/Border.h"
#include "Components/ProgressBar.h"
#include "Components/TextBlock.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Blueprint/WidgetTree.h"

namespace
{
    UBorder* Panel(UWidgetTree* Tree,const TCHAR* Name,const FLinearColor& Color)
    {
        UBorder* Border=Tree->ConstructWidget<UBorder>(UBorder::StaticClass(),FName(Name));
        Border->SetBrushColor(Color);
        Border->SetPadding(FMargin(10.0f));
        return Border;
    }

    UTextBlock* Label(UWidgetTree* Tree,const TCHAR* Name,const FString& Text,float Size,const FLinearColor& Color)
    {
        UTextBlock* Widget=Tree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(),FName(Name));
        Widget->SetText(FText::FromString(Text));
        Widget->SetColorAndOpacity(FSlateColor(Color));
        FSlateFontInfo Font=Widget->GetFont();
        Font.Size=FMath::RoundToInt(Size);
        Widget->SetFont(Font);
        return Widget;
    }

    void Place(UCanvasPanel* Root,UWidget* Widget,const FVector2D& Position,const FVector2D& Size,
        const FAnchors& Anchors=FAnchors(0.0f,0.0f,0.0f,0.0f),const FVector2D& Alignment=FVector2D::ZeroVector)
    {
        UCanvasPanelSlot* Slot=Root->AddChildToCanvas(Widget);
        Slot->SetAnchors(Anchors);
        Slot->SetPosition(Position);
        Slot->SetSize(Size);
        Slot->SetAlignment(Alignment);
    }
}

void UHonourWarHUDWidget::NativeConstruct()
{
    Super::NativeConstruct();
    BuildSurface();
}

void UHonourWarHUDWidget::BuildSurface()
{
    RootCanvas=WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(),TEXT("Root"));
    WidgetTree->RootWidget=RootCanvas;
    BuildPlayerPanel(RootCanvas);
    BuildTargetPanel(RootCanvas);
    BuildMiniMap(RootCanvas);
    BuildChatPanel(RootCanvas);
    BuildSkillBar(RootCanvas);
}

void UHonourWarHUDWidget::BuildPlayerPanel(UCanvasPanel* Root)
{
    UBorder* Box=Panel(WidgetTree,TEXT("PlayerPanel"),FLinearColor(0.035f,0.045f,0.065f,0.92f));
    Place(Root,Box,FVector2D(28,28),FVector2D(360,145));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("PlayerStack"));
    Box->SetContent(Stack);

    PlayerInfo=Label(WidgetTree,TEXT("PlayerInfo"),TEXT("HONOUR WAR  •  WARRIOR  •  Lv. 1"),24.0f,FLinearColor(1.0f,0.90f,0.62f));
    Stack->AddChildToVerticalBox(PlayerInfo);

    HpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("HP"));
    HpBar->SetFillColorAndOpacity(FLinearColor(0.62f,0.08f,0.10f,1.0f));
    Stack->AddChildToVerticalBox(HpBar);

    SpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("SP"));
    SpBar->SetFillColorAndOpacity(FLinearColor(0.18f,0.36f,0.86f,1.0f));
    Stack->AddChildToVerticalBox(SpBar);

    XpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("XP"));
    XpBar->SetFillColorAndOpacity(FLinearColor(0.72f,0.50f,0.10f,1.0f));
    Stack->AddChildToVerticalBox(XpBar);
}

void UHonourWarHUDWidget::BuildTargetPanel(UCanvasPanel* Root)
{
    UBorder* Box=Panel(WidgetTree,TEXT("TargetPanel"),FLinearColor(0.035f,0.045f,0.065f,0.88f));
    Place(Root,Box,FVector2D(0,24),FVector2D(420,88),FAnchors(0.5f,0.0f,0.5f,0.0f),FVector2D(0.5f,0.0f));
    TargetInfo=Label(WidgetTree,TEXT("TargetInfo"),TEXT("TARGET  •  Combat search active"),20.0f,FLinearColor(0.92f,0.92f,0.95f));
    Box->SetContent(TargetInfo);
}

void UHonourWarHUDWidget::BuildMiniMap(UCanvasPanel* Root)
{
    UBorder* Box=Panel(WidgetTree,TEXT("MiniMap"),FLinearColor(0.025f,0.035f,0.045f,0.94f));
    Place(Root,Box,FVector2D(34,32),FVector2D(230,230),FAnchors(1.0f,0.0f,1.0f,0.0f),FVector2D(1.0f,0.0f));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("MapStack"));
    Box->SetContent(Stack);
    Stack->AddChildToVerticalBox(Label(WidgetTree,TEXT("MapTitle"),TEXT("WORLD MAP"),18.0f,FLinearColor(1.0f,0.90f,0.62f)));
    Stack->AddChildToVerticalBox(Label(WidgetTree,TEXT("MapZone"),TEXT("Medieval Town • Daylight"),14.0f,FLinearColor(0.74f,0.78f,0.82f)));
    Stack->AddChildToVerticalBox(Label(WidgetTree,TEXT("Landmarks"),TEXT("● Plaza   ▲ Guild Hall\n◆ Market   ■ Gate"),17.0f,FLinearColor(0.92f,0.92f,0.95f)));
}

void UHonourWarHUDWidget::BuildChatPanel(UCanvasPanel* Root)
{
    UBorder* Box=Panel(WidgetTree,TEXT("ChatPanel"),FLinearColor(0.025f,0.032f,0.045f,0.80f));
    Place(Root,Box,FVector2D(28,-155),FVector2D(500,125),FAnchors(0.0f,1.0f,0.0f,1.0f));
    CombatText=Label(WidgetTree,TEXT("ChatText"),TEXT("[World] Welcome to Honour War.\n[Combat] Ready.\n[System] 1–8 activate class skills • C changes class."),16.0f,FLinearColor(0.86f,0.89f,0.94f));
    Box->SetContent(CombatText);
}

void UHonourWarHUDWidget::BuildSkillBar(UCanvasPanel* Root)
{
    UBorder* Box=Panel(WidgetTree,TEXT("CombatSkills"),FLinearColor(0.02f,0.025f,0.035f,0.96f));
    Place(Root,Box,FVector2D(0,-30),FVector2D(1260,124),FAnchors(0.5f,1.0f,0.5f,1.0f),FVector2D(0.5f,1.0f));

    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("SkillStack"));
    Box->SetContent(Stack);
    Stack->AddChildToVerticalBox(Label(WidgetTree,TEXT("SkillTitle"),TEXT("COMBAT SKILLS"),18.0f,FLinearColor(1.0f,0.90f,0.62f)));

    UHorizontalBox* Row=WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(),TEXT("SkillRow"));
    Stack->AddChildToVerticalBox(Row);

    const FString Labels[] = {TEXT("BASIC"),TEXT("CLASS"),TEXT("POWER"),TEXT("ARCANE"),TEXT("RAPID"),TEXT("WARD"),TEXT("SHADOW"),TEXT("FINISH")};
    for (int32 I=0;I<8;++I) SkillButtons.Add(MakeSkillButton(Row,I,Labels[I]));
}

UButton* UHonourWarHUDWidget::MakeSkillButton(UHorizontalBox* Row,int32 Index,const FString& LabelText)
{
    UButton* Button=WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(),FName(*FString::Printf(TEXT("SkillSlot_%d"),Index+1)));
    Button->SetColorAndOpacity(FLinearColor(0.10f,0.12f,0.17f,1.0f));
    UTextBlock* Text=Label(WidgetTree,*FString::Printf(TEXT("SkillText_%d"),Index+1),FString::Printf(TEXT("%d\n%s"),Index+1,*LabelText),16.0f,FLinearColor(0.95f,0.92f,0.82f));
    Button->AddChild(Text);
    UHorizontalBoxSlot* Slot=Row->AddChildToHorizontalBox(Button);
    Slot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
    Slot->SetPadding(FMargin(4.0f,2.0f));

    switch (Index)
    {
        case 0: Button->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OnSkill1); break;
        case 1: Button->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OnSkill2); break;
        case 2: Button->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OnSkill3); break;
        case 3: Button->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OnSkill4); break;
        case 4: Button->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OnSkill5); break;
        case 5: Button->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OnSkill6); break;
        case 6: Button->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OnSkill7); break;
        case 7: Button->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OnSkill8); break;
        default: break;
    }
    return Button;
}

void UHonourWarHUDWidget::NativeTick(const FGeometry& MyGeometry,float InDeltaTime)
{
    Super::NativeTick(MyGeometry,InDeltaTime);
    AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn());
    if (!Character || !Character->GetCombatComponent()) return;

    UHonourWarCombatComponent* Combat=Character->GetCombatComponent();
    PlayerInfo->SetText(FText::FromString(FString::Printf(
        TEXT("HONOUR WAR  •  %s  •  Lv. %d  •  Age %d days"),
        *Character->GetClassName(),Combat->GetLevel(),Combat->GetAgeDays())));
    HpBar->SetPercent(Combat->GetHealthPercent());
    SpBar->SetPercent(Combat->GetSpPercent());
    XpBar->SetPercent(Combat->GetXpPercent());
    CombatText->SetText(FText::FromString(FString::Printf(TEXT("[Combat] %s"),*Character->GetLastCombatMessage())));
}

void UHonourWarHUDWidget::UseSkill(int32 Index)
{
    if (AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn()))
        Character->ActivateSkill(Index);
}
void UHonourWarHUDWidget::OnSkill1(){UseSkill(0);}
void UHonourWarHUDWidget::OnSkill2(){UseSkill(1);}
void UHonourWarHUDWidget::OnSkill3(){UseSkill(2);}
void UHonourWarHUDWidget::OnSkill4(){UseSkill(3);}
void UHonourWarHUDWidget::OnSkill5(){UseSkill(4);}
void UHonourWarHUDWidget::OnSkill6(){UseSkill(5);}
void UHonourWarHUDWidget::OnSkill7(){UseSkill(6);}
void UHonourWarHUDWidget::OnSkill8(){UseSkill(7);}
