#include "HonourWarHUDWidget.h"
#include "HonourWarCharacter.h"
#include "HonourWarCombatComponent.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/Border.h"
#include "Components/ProgressBar.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/HorizontalBox.h"
#include "Blueprint/WidgetTree.h"

namespace
{
    const FLinearColor Gold(0.95f,0.76f,0.30f,1.0f);
    const FLinearColor White(0.92f,0.92f,0.96f,1.0f);
    const FLinearColor Muted(0.66f,0.70f,0.76f,1.0f);
    const FLinearColor Glass(0.015f,0.022f,0.035f,0.86f);
    const FLinearColor GlassSoft(0.015f,0.022f,0.035f,0.70f);

    UBorder* Panel(UWidgetTree* Tree,const TCHAR* Name,const FLinearColor& Color,const FMargin& Padding=FMargin(8.0f))
    {
        UBorder* B=Tree->ConstructWidget<UBorder>(UBorder::StaticClass(),FName(Name));
        B->SetBrushColor(Color);
        B->SetPadding(Padding);
        return B;
    }

    UTextBlock* Text(UWidgetTree* Tree,const TCHAR* Name,const FString& Value,float Size,const FLinearColor& Color)
    {
        UTextBlock* T=Tree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(),FName(Name));
        T->SetText(FText::FromString(Value));
        T->SetColorAndOpacity(FSlateColor(Color));
        FSlateFontInfo Font=T->GetFont();
        Font.Size=FMath::RoundToInt(Size);
        T->SetFont(Font);
        return T;
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
    RootCanvas=WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(),TEXT("MMORPGRoot"));
    WidgetTree->RootWidget=RootCanvas;

    BuildProfileCluster(RootCanvas);
    BuildLeftNavigation(RootCanvas);
    BuildTopRightControls(RootCanvas);
    BuildMiniMap(RootCanvas);
    BuildQuestTracker(RootCanvas);
    BuildChatDock(RootCanvas);
    BuildBottomRightShortcuts(RootCanvas);
}

void UHonourWarHUDWidget::BuildProfileCluster(UCanvasPanel* Root)
{
    UBorder* Portrait=Panel(WidgetTree,TEXT("ProfilePortrait"),FLinearColor(0.04f,0.055f,0.075f,0.96f),FMargin(4.0f));
    Place(Root,Portrait,FVector2D(28,22),FVector2D(104,104));
    Portrait->SetContent(Text(WidgetTree,TEXT("PortraitGlyph"),TEXT("♙"),52.0f,Gold));

    UBorder* Bars=Panel(WidgetTree,TEXT("ProfileBars"),GlassSoft,FMargin(10.0f));
    Place(Root,Bars,FVector2D(124,28),FVector2D(360,110));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("ProfileStack"));
    Bars->SetContent(Stack);

    ProfileName=Text(WidgetTree,TEXT("ProfileName"),TEXT("Sharnou"),24.0f,White);
    Stack->AddChildToVerticalBox(ProfileName);
    ProfileMeta=Text(WidgetTree,TEXT("ProfileMeta"),TEXT("Lv. 1  •  Warrior"),16.0f,Gold);
    Stack->AddChildToVerticalBox(ProfileMeta);

    HpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("HP"));
    HpBar->SetFillColorAndOpacity(FLinearColor(0.68f,0.10f,0.12f,1.0f));
    Stack->AddChildToVerticalBox(HpBar);
    SpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("SP"));
    SpBar->SetFillColorAndOpacity(FLinearColor(0.16f,0.34f,0.82f,1.0f));
    Stack->AddChildToVerticalBox(SpBar);
    XpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("XP"));
    XpBar->SetFillColorAndOpacity(Gold);
    Stack->AddChildToVerticalBox(XpBar);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("AgeText"),TEXT("Age 18  •  Honours 0"),13.0f,Muted));
}

UButton* UHonourWarHUDWidget::MakeNavButton(UCanvasPanel* Root,const FString& Icon,const FString& LabelText,float Y)
{
    UButton* Button=WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(),*FString::Printf(TEXT("Nav_%s"),*LabelText));
    Button->SetColorAndOpacity(FLinearColor(0.025f,0.032f,0.045f,0.88f));
    UHorizontalBox* Row=WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(),*FString::Printf(TEXT("NavRow_%s"),*LabelText));
    Row->AddChildToHorizontalBox(Text(WidgetTree,*FString::Printf(TEXT("NavIcon_%s"),*LabelText),Icon,28.0f,Gold));
    Row->AddChildToHorizontalBox(Text(WidgetTree,*FString::Printf(TEXT("NavLabel_%s"),*LabelText),LabelText,19.0f,White));
    Button->SetContent(Row);
    Place(Root,Button,FVector2D(24,Y),FVector2D(220,64));
    return Button;
}

void UHonourWarHUDWidget::BuildLeftNavigation(UCanvasPanel* Root)
{
    MakeNavButton(Root,TEXT("▣"),TEXT("Inventory"),150.0f);
    MakeNavButton(Root,TEXT("♙"),TEXT("Character"),222.0f);
    MakeNavButton(Root,TEXT("✦"),TEXT("Skills"),294.0f);
    MakeNavButton(Root,TEXT("☷"),TEXT("Quests"),366.0f);
}

UButton* UHonourWarHUDWidget::MakeTopButton(UCanvasPanel* Root,const FString& Icon,float X)
{
    UButton* Button=WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(),*FString::Printf(TEXT("Top_%d"),FMath::RoundToInt(X)));
    Button->SetColorAndOpacity(FLinearColor(0.035f,0.045f,0.060f,0.90f));
    Button->SetContent(Text(WidgetTree,*FString::Printf(TEXT("TopIcon_%d"),FMath::RoundToInt(X)),Icon,25.0f,Gold));
    Place(Root,Button,FVector2D(X,20),FVector2D(58,58));
    return Button;
}

void UHonourWarHUDWidget::BuildTopRightControls(UCanvasPanel* Root)
{
    MakeTopButton(Root,TEXT("✉"),1395.0f);
    MakeTopButton(Root,TEXT("♛"),1459.0f);
    MakeTopButton(Root,TEXT("♟"),1523.0f);
    MakeTopButton(Root,TEXT("⚙"),1587.0f);
}

void UHonourWarHUDWidget::BuildMiniMap(UCanvasPanel* Root)
{
    UBorder* Map=Panel(WidgetTree,TEXT("MMORPGMiniMap"),FLinearColor(0.025f,0.035f,0.050f,0.94f),FMargin(10.0f));
    Place(Root,Map,FVector2D(-300,90),FVector2D(276,276),FAnchors(1.0f,0.0f,1.0f,0.0f),FVector2D(1.0f,0.0f));

    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("MapStack"));
    Map->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("MapTitle"),TEXT("Prontera City"),20.0f,White));
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("MapCoords"),TEXT("(128, 214)   •   N"),13.0f,Muted));
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("MapCompass"),TEXT("        N\n     W  ✦  E\n        S"),24.0f,Gold));
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("MapStatus"),TEXT("Daylight  •  14:32"),14.0f,White));
}

void UHonourWarHUDWidget::BuildQuestTracker(UCanvasPanel* Root)
{
    UBorder* Quest=Panel(WidgetTree,TEXT("ActiveQuest"),Glass,FMargin(14.0f));
    Place(Root,Quest,FVector2D(-410,380),FVector2D(370,150),FAnchors(1.0f,0.0f,1.0f,0.0f),FVector2D(1.0f,0.0f));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("QuestStack"));
    Quest->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("QuestHeader"),TEXT("◆  Active Quest"),19.0f,Gold));
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("QuestName"),TEXT("The Lost Scroll"),17.0f,White));
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("QuestBody"),TEXT("Find the missing scroll in the northern forest."),14.0f,Muted));
}

void UHonourWarHUDWidget::BuildChatDock(UCanvasPanel* Root)
{
    UBorder* Chat=Panel(WidgetTree,TEXT("MMORPGChat"),GlassSoft,FMargin(10.0f));
    Place(Root,Chat,FVector2D(28,-190),FVector2D(500,160),FAnchors(0.0f,1.0f,0.0f,1.0f));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("ChatStack"));
    Chat->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("ChatTabs"),TEXT("All    World    Party    Guild    System    Combat"),13.0f,Gold));
    CombatText=Text(WidgetTree,TEXT("ChatText"),TEXT("[World] Welcome to Honour War.\n[World] The town gate is open.\n[System] Your adventure begins here."),14.0f,White);
    Stack->AddChildToVerticalBox(CombatText);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("ChatInput"),TEXT("  Type a message...                         ◉  ➤"),13.0f,Muted));
}

UButton* UHonourWarHUDWidget::MakeShortcut(UCanvasPanel* Root,const FString& Icon,const FString& LabelText,float X)
{
    UButton* Button=WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(),*FString::Printf(TEXT("Shortcut_%s"),*LabelText));
    Button->SetColorAndOpacity(FLinearColor(0.035f,0.045f,0.060f,0.94f));
    UVerticalBox* Box=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),*FString::Printf(TEXT("ShortcutBox_%s"),*LabelText));
    Box->AddChildToVerticalBox(Text(WidgetTree,*FString::Printf(TEXT("ShortcutIcon_%s"),*LabelText),Icon,28.0f,Gold));
    Box->AddChildToVerticalBox(Text(WidgetTree,*FString::Printf(TEXT("ShortcutLabel_%s"),*LabelText),LabelText,13.0f,White));
    Button->SetContent(Box);
    Place(Root,Button,FVector2D(X,-92),FVector2D(92,78),FAnchors(1.0f,1.0f,1.0f,1.0f),FVector2D(1.0f,1.0f));
    return Button;
}

void UHonourWarHUDWidget::BuildBottomRightShortcuts(UCanvasPanel* Root)
{
    MakeShortcut(Root,TEXT("✦"),TEXT("Map"),560.0f);
    MakeShortcut(Root,TEXT("▣"),TEXT("Bag"),660.0f);
    MakeShortcut(Root,TEXT("◇"),TEXT("Shop"),760.0f);
    MakeShortcut(Root,TEXT("♟"),TEXT("Party"),860.0f);
    MakeShortcut(Root,TEXT("◆"),TEXT("Guild"),960.0f);
}

void UHonourWarHUDWidget::RefreshVitals()
{
    AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn());
    if (!Character||!Character->GetCombatComponent()) return;
    UHonourWarCombatComponent* Combat=Character->GetCombatComponent();
    ProfileName->SetText(FText::FromString(TEXT("Sharnou")));
    ProfileMeta->SetText(FText::FromString(FString::Printf(TEXT("Lv. %d  |  Tier %d %s  |  %s"),Combat->GetLevel(),static_cast<int32>(Character->GetClassTier()),*Character->GetClassTierName(),*Character->GetClassName())));
    HpBar->SetPercent(Combat->GetHealthPercent());
    SpBar->SetPercent(Combat->GetSpPercent());
    XpBar->SetPercent(Combat->GetXpPercent());
    CombatText->SetText(FText::FromString(FString::Printf(TEXT("[Combat] %s"),*Character->GetLastCombatMessage())));
}

void UHonourWarHUDWidget::NativeTick(const FGeometry& MyGeometry,float InDeltaTime)
{
    Super::NativeTick(MyGeometry,InDeltaTime);
    RefreshVitals();
}
