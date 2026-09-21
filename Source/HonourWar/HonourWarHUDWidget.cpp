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
    BuildSectionPanel(RootCanvas);
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
    EconomyText=Text(WidgetTree,TEXT("EconomyText"),TEXT("Zeny 0  •  Honours 0"),13.0f,Muted);
    Stack->AddChildToVerticalBox(EconomyText);
    RefinementText=Text(WidgetTree,TEXT("RefinementText"),TEXT("Equip +0  |  Refine 99.5%  |  R"),12.0f,Muted);
    Stack->AddChildToVerticalBox(RefinementText);
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
    UButton* Inventory=MakeNavButton(Root,TEXT("▣"),TEXT("Inventory"),150.0f);
    Inventory->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenInventory);
    UButton* Character=MakeNavButton(Root,TEXT("♙"),TEXT("Character"),222.0f);
    Character->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenCharacter);
    UButton* Skills=MakeNavButton(Root,TEXT("✦"),TEXT("Skills"),294.0f);
    Skills->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenSkills);
    UButton* Quests=MakeNavButton(Root,TEXT("☷"),TEXT("Quests"),366.0f);
    Quests->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenQuests);
}

void UHonourWarHUDWidget::BuildSectionPanel(UCanvasPanel* Root)
{
    SectionPanel=Panel(WidgetTree,TEXT("SectionPanel"),Glass,FMargin(18.0f));
    Place(Root,SectionPanel,FVector2D(280,170),FVector2D(650,430));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("SectionStack"));
    SectionPanel->SetContent(Stack);
    SectionTitle=Text(WidgetTree,TEXT("SectionTitle"),TEXT("Honour War"),26.0f,Gold);
    Stack->AddChildToVerticalBox(SectionTitle);
    SectionBody=Text(WidgetTree,TEXT("SectionBody"),
        TEXT("Select an MMORPG menu to inspect your character, inventory, skills and world services."),
        16.0f,White);
    Stack->AddChildToVerticalBox(SectionBody);
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
    UButton* Mail=MakeTopButton(Root,TEXT("✉"),1395.0f);
    Mail->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenParty);
    UButton* Ranking=MakeTopButton(Root,TEXT("♛"),1459.0f);
    Ranking->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenGuild);
    UButton* Social=MakeTopButton(Root,TEXT("♟"),1523.0f);
    Social->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenParty);
    UButton* System=MakeTopButton(Root,TEXT("⚙"),1587.0f);
    System->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenSystem);
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
    BaseSightText=Text(WidgetTree,TEXT("BaseSight"),TEXT("Base Sight  •  offline"),14.0f,Muted);
    Stack->AddChildToVerticalBox(BaseSightText);
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
    UButton* Map=MakeShortcut(Root,TEXT("✦"),TEXT("Map"),560.0f);
    Map->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenMap);
    UButton* Bag=MakeShortcut(Root,TEXT("▣"),TEXT("Bag"),660.0f);
    Bag->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenBag);
    UButton* Shop=MakeShortcut(Root,TEXT("◇"),TEXT("Shop"),760.0f);
    Shop->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenShop);
    UButton* Party=MakeShortcut(Root,TEXT("♟"),TEXT("Party"),860.0f);
    Party->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenParty);
    UButton* Guild=MakeShortcut(Root,TEXT("◆"),TEXT("Guild"),960.0f);
    Guild->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::OpenGuild);
}

void UHonourWarHUDWidget::ShowSection(const FString& Title,const FString& Body)
{
    if (SectionPanel) SectionPanel->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
    if (SectionTitle) SectionTitle->SetText(FText::FromString(Title));
    if (SectionBody) SectionBody->SetText(FText::FromString(Body));
}

void UHonourWarHUDWidget::OpenInventory()
{
    AHonourWarCharacter* C=Cast<AHonourWarCharacter>(GetOwningPlayerPawn());
    if (!C || !C->GetCombatComponent()) return;
    const TArray<FString>& Items=C->GetCombatComponent()->GetInventoryItems();
    FString Body=FString::Printf(TEXT("Equipment +%d\n\n"),C->GetCombatComponent()->GetEquipmentRefineLevel());
    Body+=Items.Num()==0 ? TEXT("Inventory is empty. Defeat monsters to receive equipment.") : FString::Join(Items,TEXT("\n"));
    ShowSection(TEXT("Inventory"),Body);
}

void UHonourWarHUDWidget::OpenCharacter()
{
    AHonourWarCharacter* C=Cast<AHonourWarCharacter>(GetOwningPlayerPawn());
    if (!C || !C->GetCombatComponent()) return;
    UHonourWarCombatComponent* Combat=C->GetCombatComponent();
    ShowSection(TEXT("Character"),
        FString::Printf(TEXT("%s\nLv.%d\nTier %s\nAge %d online days\nZeny %lld\nHonours %d"),
            *C->GetClassName(),Combat->GetLevel(),*C->GetClassTierName(),Combat->GetAgeDays(),Combat->GetZeny(),Combat->GetHonours()));
}

void UHonourWarHUDWidget::OpenSkills()
{
    ShowSection(TEXT("Skills"),
        FString::Printf(TEXT("1 Basic Attack  |  Basic Skill Lv.%d\n2 Class Skill\n3 Power Strike\n4 Arcane Burst\n5 Rapid Volley\n6 Guardian Light\n7 Shadow Step\n8 Finisher\n\nU = upgrade basic skill\nC = mix 3 cards\nCooldown and SP are validated by the server."), C && C->GetCombatComponent() ? C->GetCombatComponent()->GetBasicSkillLevel() : 1));
}

void UHonourWarHUDWidget::OpenQuests()
{
    ShowSection(TEXT("Quests"),TEXT("The Lost Scroll\nFind the missing scroll in the northern forest.\n\nReward: experience, Zeny and adventure progress."));
}

void UHonourWarHUDWidget::OpenMap()
{
    ShowSection(TEXT("World Map"),
        TEXT("0  prontera_like_town\n1  forest_field\n2  mountain_pass\n3  desert_ruins\n4  snow_region\n5  arcane_dungeon\n\nFast travel: @go [map] [x]:[y]"));
}

void UHonourWarHUDWidget::OpenBag()
{
    OpenInventory();
}

void UHonourWarHUDWidget::OpenShop()
{
    ShowSection(TEXT("Town Shop"),TEXT("Weapon Refinement\nCard Mixing\nHero Skill Upgrade\nSoldier Production\n\nTown services use Zeny and monster-earned materials."));
}

void UHonourWarHUDWidget::OpenParty()
{
    ShowSection(TEXT("Party"),TEXT("Online party support: 2v1 through 4v4.\nTarget selection, combat skills and rewards are server-authoritative."));
}

void UHonourWarHUDWidget::OpenGuild()
{
    ShowSection(TEXT("Guild"),TEXT("Guild communication and group progression interface.\nThe panel is ready for persistent server-backed guild data."));
}

void UHonourWarHUDWidget::OpenSystem()
{
    ShowSection(TEXT("System"),TEXT("R = refine equipment\nF5 = save\nF6 = load\nQ = reset camera\nMouse wheel = zoom\nRight-mouse drag = orbit camera"));
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
    if (EconomyText)
        EconomyText->SetText(FText::FromString(FString::Printf(TEXT("Age %d days  |  Zeny %lld  |  Honours %d"),Combat->GetAgeDays(),Combat->GetZeny(),Combat->GetHonours())));
    if (BaseSightText)
        BaseSightText->SetText(FText::FromString(Character->GetBaseSightActive()?TEXT("Base Sight  •  ONLINE  •  minimap overlay"):TEXT("Base Sight  •  offline")));
    if (RefinementText)
        RefinementText->SetText(FText::FromString(FString::Printf(
            TEXT("Equip +%d  |  Refine %.1f%%  |  P:%d E:%d O:%d  |  R"),
            Combat->GetEquipmentRefineLevel(),
            Combat->GetRefineSuccessPercent(),
            Combat->GetPhracon(),
            Combat->GetEmveretarcon(),
            Combat->GetOridecon()
        )));
    CombatText->SetText(FText::FromString(FString::Printf(TEXT("[Combat] %s"),*Character->GetLastCombatMessage())));
}

void UHonourWarHUDWidget::NativeTick(const FGeometry& MyGeometry,float InDeltaTime)
{
    Super::NativeTick(MyGeometry,InDeltaTime);
    RefreshVitals();
}
