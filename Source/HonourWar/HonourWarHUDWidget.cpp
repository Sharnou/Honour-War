#include "HonourWarHUDWidget.h"
#include "HonourWarCharacter.h"
#include "HonourWarCombatComponent.h"
#include "HonourWarQuestComponent.h"
#include "HonourWarPlayerController.h"
#include "HonourWarGameState.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/Border.h"
#include "Components/Image.h"
#include "Components/ProgressBar.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/HorizontalBox.h"
#include "Components/Overlay.h"
#include "Components/EditableTextBox.h"
#include "Engine/Texture2D.h"
#include "Rendering/Texture2DResource.h"
#include "Blueprint/WidgetTree.h"

namespace
{
    const FLinearColor Gold(0.95f,0.76f,0.30f,1.0f);
    const FLinearColor White(0.92f,0.92f,0.96f,1.0f);
    const FLinearColor Muted(0.66f,0.70f,0.76f,1.0f);
    const FLinearColor Glass(0.012f,0.018f,0.028f,0.92f);

    UBorder* Panel(UWidgetTree* Tree,const TCHAR* Name,const FLinearColor& Color,const FMargin& Padding=FMargin(8.0f))
    {
        UBorder* B=Tree->ConstructWidget<UBorder>(UBorder::StaticClass(),FName(Name));
        B->SetBrushColor(Color); B->SetPadding(Padding); return B;
    }

    UTextBlock* Text(UWidgetTree* Tree,const TCHAR* Name,const FString& Value,float Size,const FLinearColor& Color)
    {
        UTextBlock* T=Tree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(),FName(Name));
        T->SetText(FText::FromString(Value)); T->SetColorAndOpacity(FSlateColor(Color));
        FSlateFontInfo Font=T->GetFont(); Font.Size=FMath::RoundToInt(Size); T->SetFont(Font); return T;
    }

    void Place(UCanvasPanel* Root,UWidget* Widget,const FVector2D& Position,const FVector2D& Size,
        const FAnchors& Anchors=FAnchors(0,0,0,0),const FVector2D& Alignment=FVector2D::ZeroVector)
    {
        UCanvasPanelSlot* Slot=Root->AddChildToCanvas(Widget);
        Slot->SetAnchors(Anchors); Slot->SetPosition(Position); Slot->SetSize(Size); Slot->SetAlignment(Alignment);
    }

    UButton* Button(UWidgetTree* Tree,const TCHAR* Name,const FString& Label,const FLinearColor& Color)
    {
        UButton* B=Tree->ConstructWidget<UButton>(UButton::StaticClass(),FName(Name));
        B->SetColorAndOpacity(Color);
        B->SetContent(Text(Tree,*FString::Printf(TEXT("%s_Label"),Name),Label,15.0f,Gold));
        return B;
    }

    void Pixel(FColor* Data,int32 W,int32 H,int32 X,int32 Y,const FColor& C)
    {
        if(Data && X>=0 && X<W && Y>=0 && Y<H) Data[Y*W+X]=C;
    }

    void Rect(FColor* Data,int32 W,int32 H,int32 X0,int32 Y0,int32 X1,int32 Y1,const FColor& C)
    {
        for(int32 Y=FMath::Max(0,Y0);Y<FMath::Min(H,Y1);++Y)
            for(int32 X=FMath::Max(0,X0);X<FMath::Min(W,X1);++X) Pixel(Data,W,H,X,Y,C);
    }

    void Triangle(FColor* Data,int32 W,int32 H,FIntPoint A,FIntPoint B,FIntPoint C,const FColor& Color)
    {
        const int32 MinX=FMath::Max(0,FMath::Min3(A.X,B.X,C.X)), MaxX=FMath::Min(W-1,FMath::Max3(A.X,B.X,C.X));
        const int32 MinY=FMath::Max(0,FMath::Min3(A.Y,B.Y,C.Y)), MaxY=FMath::Min(H-1,FMath::Max3(A.Y,B.Y,C.Y));
        const int64 Area=int64(B.X-A.X)*int64(C.Y-A.Y)-int64(B.Y-A.Y)*int64(C.X-A.X);
        if(Area==0) return;
        for(int32 Y=MinY;Y<=MaxY;++Y) for(int32 X=MinX;X<=MaxX;++X)
        {
            const int64 W0=int64(B.X-A.X)*int64(Y-A.Y)-int64(B.Y-A.Y)*int64(X-A.X);
            const int64 W1=int64(C.X-B.X)*int64(Y-B.Y)-int64(C.Y-B.Y)*int64(X-B.X);
            const int64 W2=int64(A.X-C.X)*int64(Y-C.Y)-int64(A.Y-C.Y)*int64(X-C.X);
            if((W0>=0&&W1>=0&&W2>=0)||(W0<=0&&W1<=0&&W2<=0)) Pixel(Data,W,H,X,Y,Color);
        }
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
    BuildStatusPanel(RootCanvas);
    BuildMiniMap(RootCanvas);
    BuildWorldEventPanel(RootCanvas);
    BuildQuestTracker(RootCanvas);
    BuildChatDock(RootCanvas);
    BuildAuthenticationPanel(RootCanvas);
    BuildCharacterSelectionPanel(RootCanvas);
}

UTexture2D* UHonourWarHUDWidget::BuildLoginBackgroundTexture()
{
    const int32 W=960,H=540;
    UTexture2D* Texture=UTexture2D::CreateTransient(W,H,PF_B8G8R8A8);
    if(!Texture) return nullptr;
    Texture->SRGB=true;
    Texture->Filter=TF_Bilinear;
    FColor* Pixels=static_cast<FColor*>(Texture->GetPlatformData()->Mips[0].BulkData.Lock(LOCK_READ_WRITE));
    for(int32 Y=0;Y<H;++Y)
    {
        const float T=float(Y)/float(H-1);
        const FColor Sky(
            uint8(18+18*(1.0f-T)),uint8(48+28*(1.0f-T)),uint8(78+38*(1.0f-T)),255);
        for(int32 X=0;X<W;++X) Pixels[Y*W+X]=Sky;
    }
    Triangle(Pixels,W,H,FIntPoint(0,360),FIntPoint(300,170),FIntPoint(610,360),FColor(34,57,70,255));
    Triangle(Pixels,W,H,FIntPoint(340,360),FIntPoint(650,125),FIntPoint(960,360),FColor(42,66,77,255));
    Triangle(Pixels,W,H,FIntPoint(0,420),FIntPoint(460,255),FIntPoint(960,420),FColor(24,43,45,255));
    Rect(Pixels,W,H,0,420,W,H,FColor(20,32,28,255));
    for(int32 I=0;I<9;++I)
    {
        const int32 X=70+I*105;
        Rect(Pixels,W,H,X,365,X+78,422,FColor(57,48,45,255));
        Rect(Pixels,W,H,X+10,345,X+68,365,FColor(66,57,51,255));
        Triangle(Pixels,W,H,FIntPoint(X-4,345),FIntPoint(X+39,315),FIntPoint(X+82,345),FColor(71,45,39,255));
        Rect(Pixels,W,H,X+18,375,X+30,395,FColor(205,153,57,255));
        Rect(Pixels,W,H,X+46,375,X+58,395,FColor(92,152,177,255));
    }
    Rect(Pixels,W,H,455,245,505,370,FColor(56,48,52,255));
    Triangle(Pixels,W,H,FIntPoint(440,245),FIntPoint(480,195),FIntPoint(520,245),FColor(72,53,50,255));
    Rect(Pixels,W,H,468,300,492,370,FColor(18,24,29,255));
    Rect(Pixels,W,H,430,265,448,320,FColor(97,73,52,255));
    Rect(Pixels,W,H,512,265,530,320,FColor(97,73,52,255));
    Rect(Pixels,W,H,740,210,756,370,FColor(44,43,39,255));
    Triangle(Pixels,W,H,FIntPoint(724,212),FIntPoint(748,160),FIntPoint(772,212),FColor(48,45,40,255));
    Rect(Pixels,W,H,736,240,752,265,FColor(232,183,69,255));
    Rect(Pixels,W,H,738,280,750,300,FColor(96,171,210,255));
    Texture->GetPlatformData()->Mips[0].BulkData.Unlock();
    Texture->UpdateResource();
    return Texture;
}

void UHonourWarHUDWidget::BuildAuthenticationPanel(UCanvasPanel* Root)
{
    AuthPanel=Panel(WidgetTree,TEXT("AuthenticationPanel"),FLinearColor(0.01f,0.016f,0.025f,0.97f),FMargin(0));
    Place(Root,AuthPanel,FVector2D(0,0),FVector2D(620,660),FAnchors(0.5f,0.5f,0.5f,0.5f),FVector2D(0.5f,0.5f));
    UOverlay* Overlay=WidgetTree->ConstructWidget<UOverlay>(UOverlay::StaticClass(),TEXT("AuthOverlay"));
    AuthPanel->SetContent(Overlay);

    AuthBackgroundImage=WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(),TEXT("AuthBackground"));
    LoginBackgroundTexture=BuildLoginBackgroundTexture();
    FSlateBrush Brush; Brush.SetResourceObject(LoginBackgroundTexture); Brush.ImageSize=FVector2D(620,350);
    AuthBackgroundImage->SetBrush(Brush); Overlay->AddChildToOverlay(AuthBackgroundImage);

    UBorder* Shade=Panel(WidgetTree,TEXT("AuthShade"),FLinearColor(0.005f,0.010f,0.018f,0.68f),FMargin(0));
    Overlay->AddChildToOverlay(Shade);

    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("AuthenticationStack"));
    Overlay->AddChildToOverlay(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("AuthTitle"),TEXT("HONOUR WAR"),30.0f,Gold));
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("AuthSubtitle"),TEXT("Enter the world. Build your legend."),16.0f,White));
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("AuthHint"),TEXT("ACCOUNT REGISTRATION / LOGIN"),12.0f,Muted));
    AuthUsername=WidgetTree->ConstructWidget<UEditableTextBox>(UEditableTextBox::StaticClass(),TEXT("AuthUsername"));
    AuthUsername->SetHintText(FText::FromString(TEXT("Username")));
    Stack->AddChildToVerticalBox(AuthUsername);
    AuthPassword=WidgetTree->ConstructWidget<UEditableTextBox>(UEditableTextBox::StaticClass(),TEXT("AuthPassword"));
    AuthPassword->SetHintText(FText::FromString(TEXT("Password (6+ characters)")));
    AuthPassword->SetIsPassword(true);
    Stack->AddChildToVerticalBox(AuthPassword);
    UHorizontalBox* Buttons=WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(),TEXT("AuthButtons"));
    AuthRegisterButton=Button(WidgetTree,TEXT("AuthRegisterButton"),TEXT("REGISTER"),FLinearColor(0.035f,0.045f,0.060f,0.94f));
    AuthLoginButton=Button(WidgetTree,TEXT("AuthLoginButton"),TEXT("LOGIN"),FLinearColor(0.035f,0.045f,0.060f,0.94f));
    AuthRegisterButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::SubmitRegister);
    AuthLoginButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::SubmitLogin);
    Buttons->AddChildToHorizontalBox(AuthRegisterButton); Buttons->AddChildToHorizontalBox(AuthLoginButton);
    Stack->AddChildToVerticalBox(Buttons);
    AuthStatus=Text(WidgetTree,TEXT("AuthStatus"),TEXT("Not authenticated."),13.0f,White);
    Stack->AddChildToVerticalBox(AuthStatus);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("AuthConsoleHint"),TEXT("Console: @register name password  |  @login name password"),11.0f,Muted));
}

void UHonourWarHUDWidget::BuildCharacterSelectionPanel(UCanvasPanel* Root)
{
    CharacterSelectPanel=Panel(WidgetTree,TEXT("CharacterSelectPanel"),FLinearColor(0.012f,0.018f,0.030f,0.98f),FMargin(22));
    Place(Root,CharacterSelectPanel,FVector2D(0,0),FVector2D(620,520),FAnchors(0.5f,0.5f,0.5f,0.5f),FVector2D(0.5f,0.5f));
    CharacterSelectPanel->SetVisibility(ESlateVisibility::Collapsed);
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("CharacterSelectionStack"));
    CharacterSelectPanel->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("CharacterTitle"),TEXT("SELECT YOUR CHARACTER"),28.0f,Gold));
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("CharacterHint"),TEXT("Choose a character you own, with its saved level and equipped look, or create a new character."),14.0f,White));
    CharacterListText=Text(WidgetTree,TEXT("CharacterList"),TEXT("Loading character roster..."),16.0f,White);
    Stack->AddChildToVerticalBox(CharacterListText);
    CharacterSlotInput=WidgetTree->ConstructWidget<UEditableTextBox>(UEditableTextBox::StaticClass(),TEXT("CharacterSlotInput"));
    CharacterSlotInput->SetText(FText::FromString(TEXT("1")));
    CharacterSlotInput->SetHintText(FText::FromString(TEXT("Character slot 1-70")));
    Stack->AddChildToVerticalBox(CharacterSlotInput);
    CharacterSelectButton=Button(WidgetTree,TEXT("CharacterSelectButton"),TEXT("SELECT OWNED CHARACTER"),FLinearColor(0.035f,0.045f,0.060f,0.96f));
    CharacterSelectButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::SelectOwnedCharacter);
    Stack->AddChildToVerticalBox(CharacterSelectButton);
    CharacterCreateButton=Button(WidgetTree,TEXT("CharacterCreateButton"),TEXT("CREATE NEW CHARACTER"),FLinearColor(0.045f,0.035f,0.025f,0.96f));
    CharacterCreateButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::CreateNewCharacter);
    Stack->AddChildToVerticalBox(CharacterCreateButton);
    CharacterSelectStatus=Text(WidgetTree,TEXT("CharacterSelectStatus"),TEXT(""),13.0f,Muted);
    Stack->AddChildToVerticalBox(CharacterSelectStatus);

    CharacterCreatePanel=Panel(WidgetTree,TEXT("CharacterCreatePanel"),FLinearColor(0.01f,0.015f,0.025f,0.99f),FMargin(18));
    Place(Root,CharacterCreatePanel,FVector2D(0,0),FVector2D(540,500),FAnchors(0.5f,0.5f,0.5f,0.5f),FVector2D(0.5f,0.5f));
    CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    UVerticalBox* CreateStack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("CharacterCreateStack"));
    CharacterCreatePanel->SetContent(CreateStack);
    CreateStack->AddChildToVerticalBox(Text(WidgetTree,TEXT("CreateTitle"),TEXT("CREATE NEW CHARACTER"),24.0f,Gold));
    CreateStack->AddChildToVerticalBox(Text(WidgetTree,TEXT("CreateHint"),TEXT("Choose a name and starting class."),13.0f,White));
    CharacterNameInput=WidgetTree->ConstructWidget<UEditableTextBox>(UEditableTextBox::StaticClass(),TEXT("CharacterNameInput"));
    CharacterNameInput->SetHintText(FText::FromString(TEXT("Character name")));
    CreateStack->AddChildToVerticalBox(CharacterNameInput);
    UHorizontalBox* ClassRow1=WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(),TEXT("CreateClassRow1"));
    UHorizontalBox* ClassRow2=WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(),TEXT("CreateClassRow2"));
    CreateWarriorButton=Button(WidgetTree,TEXT("CreateWarriorButton"),TEXT("WARRIOR"),FLinearColor(0.04f,0.04f,0.05f,0.96f));
    CreateMageButton=Button(WidgetTree,TEXT("CreateMageButton"),TEXT("MAGE"),FLinearColor(0.04f,0.04f,0.05f,0.96f));
    CreateArcherButton=Button(WidgetTree,TEXT("CreateArcherButton"),TEXT("ARCHER"),FLinearColor(0.04f,0.04f,0.05f,0.96f));
    CreateThiefButton=Button(WidgetTree,TEXT("CreateThiefButton"),TEXT("THIEF"),FLinearColor(0.04f,0.04f,0.05f,0.96f));
    CreateAcolyteButton=Button(WidgetTree,TEXT("CreateAcolyteButton"),TEXT("ACOLYTE"),FLinearColor(0.04f,0.04f,0.05f,0.96f));
    CreateMerchantButton=Button(WidgetTree,TEXT("CreateMerchantButton"),TEXT("MERCHANT"),FLinearColor(0.04f,0.04f,0.05f,0.96f));
    CreateRangerButton=Button(WidgetTree,TEXT("CreateRangerButton"),TEXT("RANGER"),FLinearColor(0.04f,0.04f,0.05f,0.96f));
    CreateWarriorButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::CreateWarriorCharacter);
    CreateMageButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::CreateMageCharacter);
    CreateArcherButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::CreateArcherCharacter);
    CreateThiefButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::CreateThiefCharacter);
    CreateAcolyteButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::CreateAcolyteCharacter);
    CreateMerchantButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::CreateMerchantCharacter);
    CreateRangerButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::CreateRangerCharacter);
    ClassRow1->AddChildToHorizontalBox(CreateWarriorButton);
    ClassRow1->AddChildToHorizontalBox(CreateMageButton);
    ClassRow1->AddChildToHorizontalBox(CreateArcherButton);
    ClassRow1->AddChildToHorizontalBox(CreateThiefButton);
    ClassRow2->AddChildToHorizontalBox(CreateAcolyteButton);
    ClassRow2->AddChildToHorizontalBox(CreateMerchantButton);
    ClassRow2->AddChildToHorizontalBox(CreateRangerButton);
    CreateStack->AddChildToVerticalBox(ClassRow1);
    CreateStack->AddChildToVerticalBox(ClassRow2);
}

void UHonourWarHUDWidget::BuildProfileCluster(UCanvasPanel* Root)
{
    UBorder* Portrait=Panel(WidgetTree,TEXT("ProfilePortrait"),FLinearColor(0.04f,0.055f,0.075f,0.96f),FMargin(4));
    Place(Root,Portrait,FVector2D(28,22),FVector2D(104,104));
    Portrait->SetContent(Text(WidgetTree,TEXT("PortraitGlyph"),TEXT("♙"),52.0f,Gold));
    UBorder* Bars=Panel(WidgetTree,TEXT("ProfileBars"),FLinearColor(0.015f,0.022f,0.035f,0.70f),FMargin(10));
    Place(Root,Bars,FVector2D(124,28),FVector2D(360,110));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("ProfileStack"));
    Bars->SetContent(Stack);
    ProfileName=Text(WidgetTree,TEXT("ProfileName"),TEXT("Honour Hero"),24,White); Stack->AddChildToVerticalBox(ProfileName);
    ProfileMeta=Text(WidgetTree,TEXT("ProfileMeta"),TEXT("Lv. 1  •  Warrior"),16,Gold); Stack->AddChildToVerticalBox(ProfileMeta);
    HpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("HP")); HpBar->SetFillColorAndOpacity(FLinearColor(0.68f,0.10f,0.12f,1)); Stack->AddChildToVerticalBox(HpBar);
    SpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("SP")); SpBar->SetFillColorAndOpacity(FLinearColor(0.16f,0.34f,0.82f,1)); Stack->AddChildToVerticalBox(SpBar);
    XpBar=WidgetTree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(),TEXT("XP")); XpBar->SetFillColorAndOpacity(Gold); Stack->AddChildToVerticalBox(XpBar);
    EconomyText=Text(WidgetTree,TEXT("EconomyText"),TEXT("Zeny 0  •  Honours 0"),13,Muted); Stack->AddChildToVerticalBox(EconomyText);
    RefinementText=Text(WidgetTree,TEXT("RefinementText"),TEXT("Equip +0"),12,Muted); Stack->AddChildToVerticalBox(RefinementText);
}

void UHonourWarHUDWidget::BuildStatusPanel(UCanvasPanel* Root)
{
    UBorder* PanelRoot=Panel(WidgetTree,TEXT("StatusPanel"),FLinearColor(0.012f,0.018f,0.028f,0.94f),FMargin(10));
    Place(Root,PanelRoot,FVector2D(28,142),FVector2D(500,238));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("StatusStack"));
    PanelRoot->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("StatusHeader"),TEXT("◆ STATUS ATTRIBUTES"),17,Gold));

    StatusText=Text(WidgetTree,TEXT("StatusText"),TEXT("STR 10 • AGI 10 • VIT 10\nINT 10 • DEX 10 • LUK 10\nStatus Points 30"),14,White);
    Stack->AddChildToVerticalBox(StatusText);

    UHorizontalBox* Row=WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(),TEXT("StatusButtonRow"));
    StrengthButton=Button(WidgetTree,TEXT("STRButton"),TEXT("+ STR"),FLinearColor(0.10f,0.045f,0.035f,0.96f));
    AgilityButton=Button(WidgetTree,TEXT("AGIButton"),TEXT("+ AGI"),FLinearColor(0.035f,0.10f,0.055f,0.96f));
    VitalityButton=Button(WidgetTree,TEXT("VITButton"),TEXT("+ VIT"),FLinearColor(0.12f,0.07f,0.035f,0.96f));
    IntelligenceButton=Button(WidgetTree,TEXT("INTButton"),TEXT("+ INT"),FLinearColor(0.04f,0.06f,0.13f,0.96f));
    DexterityButton=Button(WidgetTree,TEXT("DEXButton"),TEXT("+ DEX"),FLinearColor(0.08f,0.11f,0.04f,0.96f));
    LuckButton=Button(WidgetTree,TEXT("LUKButton"),TEXT("+ LUK"),FLinearColor(0.10f,0.06f,0.13f,0.96f));

    StrengthButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::AddStrength);
    AgilityButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::AddAgility);
    VitalityButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::AddVitality);
    IntelligenceButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::AddIntelligence);
    DexterityButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::AddDexterity);
    LuckButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::AddLuck);

    Row->AddChildToHorizontalBox(StrengthButton);
    Row->AddChildToHorizontalBox(AgilityButton);
    Row->AddChildToHorizontalBox(VitalityButton);
    Row->AddChildToHorizontalBox(IntelligenceButton);
    Row->AddChildToHorizontalBox(DexterityButton);
    Row->AddChildToHorizontalBox(LuckButton);
    Stack->AddChildToVerticalBox(Row);

    StatusDerivedText=Text(WidgetTree,TEXT("StatusDerivedText"),TEXT("ATK —  |  HIT —  |  FLEE —  |  CRIT —  |  LUCK —  |  DMG RED —"),12,Gold);
    Stack->AddChildToVerticalBox(StatusDerivedText);
    StatusRulesText=Text(WidgetTree,TEXT("StatusRulesText"),
        TEXT("Per level: +3 Status Points; every 25th level: +5 bonus.\n10-79 costs 1 • 80-99 costs 2 • 100-120 costs 3.\nSTR ATK • AGI FLEE/CD • VIT HP/mitigation • INT SP/skill scaling • DEX HIT • LUK critical/lucky."),
        11,Muted);
    Stack->AddChildToVerticalBox(StatusRulesText);
}

void UHonourWarHUDWidget::BuildMiniMap(UCanvasPanel* Root)
{
    UBorder* Map=Panel(WidgetTree,TEXT("MMORPGMiniMap"),FLinearColor(0.025f,0.035f,0.050f,0.94f),FMargin(10));
    Place(Root,Map,FVector2D(-300,90),FVector2D(276,276),FAnchors(1,0,1,0),FVector2D(1,0));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("MapStack")); Map->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("MapTitle"),TEXT("Crownfall Capital"),20,White));
    MapCoordsText=Text(WidgetTree,TEXT("MapCoords"),TEXT("(900, 900)   •   N"),13,Muted);
    MapStatusText=Text(WidgetTree,TEXT("MapStatus"),TEXT("Daylight • World ready"),14,White);
    Stack->AddChildToVerticalBox(MapCoordsText);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("MapCompass"),TEXT("        N\n     W  ✦  E\n        S"),24,Gold));
    Stack->AddChildToVerticalBox(MapStatusText);
}

void UHonourWarHUDWidget::BuildWorldEventPanel(UCanvasPanel* Root)
{
    UBorder* EventPanel=Panel(WidgetTree,TEXT("WorldEventPanel"),FLinearColor(0.018f,0.024f,0.036f,0.92f),FMargin(10));
    Place(Root,EventPanel,FVector2D(0,-18),FVector2D(560,88),FAnchors(0.5f,0,0.5f,0),FVector2D(0.5f,0));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("WorldEventStack"));
    EventPanel->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("WorldEventHeader"),TEXT("◆ LIVE WORLD EVENT"),12,Muted));
    EventText=Text(WidgetTree,TEXT("WorldEventText"),TEXT("Royal Hunt • +25% XP • +10% Zeny"),17,Gold);
    Stack->AddChildToVerticalBox(EventText);
}

void UHonourWarHUDWidget::BuildQuestTracker(UCanvasPanel* Root)
{
    UBorder* Quest=Panel(WidgetTree,TEXT("ActiveQuest"),Glass,FMargin(14));
    Place(Root,Quest,FVector2D(-410,380),FVector2D(370,150),FAnchors(1,0,1,0),FVector2D(1,0));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("QuestStack")); Quest->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("QuestHeader"),TEXT("◆  Active Quest"),19,Gold));
    QuestText=Text(WidgetTree,TEXT("QuestText"),TEXT("The Lost Scroll\nDefeat monsters to recover the lost scroll."),14,White); Stack->AddChildToVerticalBox(QuestText);
}

void UHonourWarHUDWidget::BuildChatDock(UCanvasPanel* Root)
{
    UBorder* Chat=Panel(WidgetTree,TEXT("MMORPGChat"),FLinearColor(0.015f,0.022f,0.035f,0.70f),FMargin(10));
    Place(Root,Chat,FVector2D(28,-190),FVector2D(500,160),FAnchors(0,1,0,1));
    UVerticalBox* Stack=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(),TEXT("ChatStack")); Chat->SetContent(Stack);
    Stack->AddChildToVerticalBox(Text(WidgetTree,TEXT("ChatTabs"),TEXT("All    World    Party    Guild    System    Combat"),13,Gold));
    ChatText=Text(WidgetTree,TEXT("ChatText"),TEXT("[World] Welcome to Honour War."),14,White); Stack->AddChildToVerticalBox(ChatText);
    CombatText=Text(WidgetTree,TEXT("CombatText"),TEXT("[Combat] Ready"),13,Muted); Stack->AddChildToVerticalBox(CombatText);
    UHorizontalBox* Row=WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass(),TEXT("ChatInputRow"));
    ChatInput=WidgetTree->ConstructWidget<UEditableTextBox>(UEditableTextBox::StaticClass(),TEXT("ChatInput")); ChatInput->SetHintText(FText::FromString(TEXT("Type a world message...")));
    ChatSendButton=Button(WidgetTree,TEXT("ChatSendButton"),TEXT("SEND"),FLinearColor(0.035f,0.045f,0.060f,0.94f));
    ChatSendButton->OnClicked.AddDynamic(this,&UHonourWarHUDWidget::SubmitChat);
    Row->AddChildToHorizontalBox(ChatInput); Row->AddChildToHorizontalBox(ChatSendButton); Stack->AddChildToVerticalBox(Row);
}

void UHonourWarHUDWidget::RefreshCharacterSelection()
{
    AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer());
    if(!PC || !CharacterListText) return;
    const TArray<FHonourWarCharacterSlot>& Slots=PC->GetOwnedCharacters();
    FString List;
    int32 Owned=0;
    for(int32 i=0;i<Slots.Num();++i)
    {
        if(!Slots[i].bOwned) continue;
        ++Owned;
        List+=FString::Printf(TEXT("Character %d  •  %s  •  Lv.%d  •  %s  •  Equipped +%d\n"),
            i+1,*Slots[i].CharacterName,Slots[i].Level,*HonourWarClassName(Slots[i].ClassId),Slots[i].EquipmentRefineLevel);
    }
    if(Owned==0) List=TEXT("No characters owned yet. Create your first character.");
    CharacterListText->SetText(FText::FromString(List));
    CharacterSelectButton->SetIsEnabled(Owned>0);
}

void UHonourWarHUDWidget::RefreshVitals()
{
    AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer());
    const bool bAuth=PC && PC->IsAuthenticated();
    const bool bReady=PC && PC->IsReadyForGameplay();
    if(AuthPanel) AuthPanel->SetVisibility(bAuth?ESlateVisibility::Collapsed:ESlateVisibility::Visible);
    if(CharacterSelectPanel) CharacterSelectPanel->SetVisibility(bAuth&&!bReady?ESlateVisibility::Visible:ESlateVisibility::Collapsed);
    if(CharacterCreatePanel && bReady) CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    if(!bReady) { RefreshCharacterSelection(); return; }

    AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn());
    if(!Character||!Character->GetCombatComponent()) return;
    UHonourWarCombatComponent* Combat=Character->GetCombatComponent();
    ProfileName->SetText(FText::FromString(PC->GetAccountUsername()));
    ProfileMeta->SetText(FText::FromString(FString::Printf(TEXT("Lv. %d  |  %s  |  %s  |  %s"),Combat->GetLevel(),*Character->GetCurrentJobName(),*Character->GetClassTierName(),*Character->GetClassName())));
    HpBar->SetPercent(Combat->GetHealthPercent()); SpBar->SetPercent(Combat->GetSpPercent()); XpBar->SetPercent(Combat->GetXpPercent());
    EconomyText->SetText(FText::FromString(FString::Printf(TEXT("Age %d days  |  Zeny %lld  |  Honours %d"),Combat->GetAgeDays(),Combat->GetZeny(),Combat->GetHonours())));
    if(StatusText)
    {
        StatusText->SetText(FText::FromString(FString::Printf(
            TEXT("STR %d  •  AGI %d  •  VIT %d\\nINT %d  •  DEX %d  •  LUK %d\\nStatus Points %d  |  Costs %d/%d/%d"),
            Combat->GetStrength(),Combat->GetAgility(),Combat->GetVitality(),
            Combat->GetIntelligence(),Combat->GetDexterity(),Combat->GetLuckStat(),
            Combat->GetStatusPoints(),
            Combat->GetStatusPointCost(EHonourWarStatusStat::Strength),
            Combat->GetStatusPointCost(EHonourWarStatusStat::Agility),
            Combat->GetStatusPointCost(EHonourWarStatusStat::Vitality))));
    }
    if(StatusDerivedText)
    {
        StatusDerivedText->SetText(FText::FromString(FString::Printf(
            TEXT("HP %d/%d  •  SP %d/%d\\nHIT %d  •  FLEE %d  •  CRIT %d%%  •  LUCK %d  •  MIT %.1f%%  •  CD %.1f%%↓"),
            FMath::RoundToInt(Combat->GetCurrentHealth()),FMath::RoundToInt(Combat->GetMaxHealth()),
            FMath::RoundToInt(Combat->GetCurrentSp()),FMath::RoundToInt(Combat->GetMaxSp()),
            Combat->GetHitRating(),Combat->GetFleeRating(),Combat->GetCriticalRate(),Combat->GetLuck(),
            Combat->GetDamageReductionPercent()*100.0f,(1.0f-Combat->GetSkillCooldownMultiplier())*100.0f)));
    }
    const bool bCanSpend=Combat->GetStatusPoints()>0;
    if(StrengthButton) StrengthButton->SetIsEnabled(bCanSpend && Combat->GetStrength()<120);
    if(AgilityButton) AgilityButton->SetIsEnabled(bCanSpend && Combat->GetAgility()<120);
    if(VitalityButton) VitalityButton->SetIsEnabled(bCanSpend && Combat->GetVitality()<120);
    if(IntelligenceButton) IntelligenceButton->SetIsEnabled(bCanSpend && Combat->GetIntelligence()<120);
    if(DexterityButton) DexterityButton->SetIsEnabled(bCanSpend && Combat->GetDexterity()<120);
    if(LuckButton) LuckButton->SetIsEnabled(bCanSpend && Combat->GetLuckStat()<120);
    RefinementText->SetText(FText::FromString(FString::Printf(TEXT("Equip +%d  |  Refine %.1f%%  |  P:%d E:%d O:%d"),Combat->GetEquipmentRefineLevel(),Combat->GetRefineSuccessPercent(),Combat->GetPhracon(),Combat->GetEmveretarcon(),Combat->GetOridecon())));
    if(ChatText)
    {
        if(AHonourWarGameState* State=GetWorld()?GetWorld()->GetGameState<AHonourWarGameState>():nullptr)
        {
            const TArray<FString>& Messages=State->GetWorldMessages();
            if(Messages.Num()>0) ChatText->SetText(FText::FromString(FString::Join(Messages,TEXT("\n"))));
        }
    }
    if(QuestText && Character->GetQuestComponent())
        QuestText->SetText(FText::FromString(FString::Printf(TEXT("%s\n%s"),*Character->GetQuestComponent()->GetQuestTitle(),*Character->GetQuestComponent()->GetQuestBody())));

    if(const AHonourWarGameState* State=GetWorld()?GetWorld()->GetGameState<AHonourWarGameState>():nullptr)
    {
        if(EventText)
        {
            EventText->SetText(FText::FromString(FString::Printf(
                TEXT("%s  •  %ds remaining\n%s"),
                *State->GetActiveWorldEventTitle(),
                State->GetEventSecondsRemaining(),
                *State->GetActiveWorldEventBody())));
        }
        if(MapCoordsText)
        {
            const FVector P=Character->GetActorLocation();
            MapCoordsText->SetText(FText::FromString(FString::Printf(
                TEXT("(%.0f, %.0f)   •   LIVE POSITION"),P.X,P.Y)));
        }
        if(MapStatusText)
            MapStatusText->SetText(FText::FromString(FString::Printf(
                TEXT("Daylight  •  Event cycle %ds"),State->GetEventSecondsRemaining())));
    }

    if(CombatText) CombatText->SetText(FText::FromString(FString::Printf(TEXT("[Combat] %s"),*Character->GetLastCombatMessage())));
}

void UHonourWarHUDWidget::AddStrength()
{
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn()))
        if(UHonourWarCombatComponent* Combat=Character->GetCombatComponent())
            if(Combat->SpendStatusPoint(EHonourWarStatusStat::Strength)) Character->SaveProgress();
}
void UHonourWarHUDWidget::AddAgility()
{
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn()))
        if(UHonourWarCombatComponent* Combat=Character->GetCombatComponent())
            if(Combat->SpendStatusPoint(EHonourWarStatusStat::Agility)) Character->SaveProgress();
}
void UHonourWarHUDWidget::AddVitality()
{
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn()))
        if(UHonourWarCombatComponent* Combat=Character->GetCombatComponent())
            if(Combat->SpendStatusPoint(EHonourWarStatusStat::Vitality)) Character->SaveProgress();
}
void UHonourWarHUDWidget::AddIntelligence()
{
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn()))
        if(UHonourWarCombatComponent* Combat=Character->GetCombatComponent())
            if(Combat->SpendStatusPoint(EHonourWarStatusStat::Intelligence)) Character->SaveProgress();
}
void UHonourWarHUDWidget::AddDexterity()
{
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn()))
        if(UHonourWarCombatComponent* Combat=Character->GetCombatComponent())
            if(Combat->SpendStatusPoint(EHonourWarStatusStat::Dexterity)) Character->SaveProgress();
}
void UHonourWarHUDWidget::AddLuck()
{
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwningPlayerPawn()))
        if(UHonourWarCombatComponent* Combat=Character->GetCombatComponent())
            if(Combat->SpendStatusPoint(EHonourWarStatusStat::Luck)) Character->SaveProgress();
}

void UHonourWarHUDWidget::NativeTick(const FGeometry& MyGeometry,float InDeltaTime)
{
    Super::NativeTick(MyGeometry,InDeltaTime);
    RefreshVitals();
}

void UHonourWarHUDWidget::SubmitChat()
{
    if(!ChatInput) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer())) PC->SendChatMessage(ChatInput->GetText().ToString());
    ChatInput->SetText(FText::GetEmpty());
}

void UHonourWarHUDWidget::SubmitRegister()
{
    if(!AuthUsername||!AuthPassword) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; PC->RegisterAccount(AuthUsername->GetText().ToString(),AuthPassword->GetText().ToString(),Message);
        AuthStatus->SetText(FText::FromString(Message));
    }
}

void UHonourWarHUDWidget::SubmitLogin()
{
    if(!AuthUsername||!AuthPassword) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; PC->LoginAccount(AuthUsername->GetText().ToString(),AuthPassword->GetText().ToString(),Message);
        AuthStatus->SetText(FText::FromString(Message));
    }
}

void UHonourWarHUDWidget::SelectOwnedCharacter()
{
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        int32 SlotIndex=0;
        if(CharacterSlotInput)
            SlotIndex=FMath::Clamp(FCString::Atoi(*CharacterSlotInput->GetText().ToString())-1,0,69);
        FString Message; bool bSelected=PC->SelectCharacter(SlotIndex,Message);
        CharacterSelectStatus->SetText(FText::FromString(Message));
        if(bSelected) CharacterSelectPanel->SetVisibility(ESlateVisibility::Collapsed);
    }
}

void UHonourWarHUDWidget::CreateNewCharacter()
{
    if(CharacterCreatePanel) CharacterCreatePanel->SetVisibility(ESlateVisibility::Visible);
}

void UHonourWarHUDWidget::CreateWarriorCharacter()
{
    if(!CharacterNameInput) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; const bool bCreated=PC->CreateCharacter(CharacterNameInput->GetText().ToString(),EHonourWarClass::Warrior,Message);
        CharacterSelectStatus->SetText(FText::FromString(Message)); if(bCreated) CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    }
}
void UHonourWarHUDWidget::CreateMageCharacter()
{
    if(!CharacterNameInput) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; const bool bCreated=PC->CreateCharacter(CharacterNameInput->GetText().ToString(),EHonourWarClass::Mage,Message);
        CharacterSelectStatus->SetText(FText::FromString(Message)); if(bCreated) CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    }
}
void UHonourWarHUDWidget::CreateArcherCharacter()
{
    if(!CharacterNameInput) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; const bool bCreated=PC->CreateCharacter(CharacterNameInput->GetText().ToString(),EHonourWarClass::Archer,Message);
        CharacterSelectStatus->SetText(FText::FromString(Message)); if(bCreated) CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    }
}
void UHonourWarHUDWidget::CreateThiefCharacter()
{
    if(!CharacterNameInput) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; const bool bCreated=PC->CreateCharacter(CharacterNameInput->GetText().ToString(),EHonourWarClass::Thief,Message);
        CharacterSelectStatus->SetText(FText::FromString(Message)); if(bCreated) CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    }
}
void UHonourWarHUDWidget::CreateAcolyteCharacter()
{
    if(!CharacterNameInput) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; const bool bCreated=PC->CreateCharacter(CharacterNameInput->GetText().ToString(),EHonourWarClass::Acolyte,Message);
        CharacterSelectStatus->SetText(FText::FromString(Message)); if(bCreated) CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    }
}
void UHonourWarHUDWidget::CreateMerchantCharacter()
{
    if(!CharacterNameInput) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; const bool bCreated=PC->CreateCharacter(CharacterNameInput->GetText().ToString(),EHonourWarClass::Merchant,Message);
        CharacterSelectStatus->SetText(FText::FromString(Message)); if(bCreated) CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    }
}
void UHonourWarHUDWidget::CreateRangerCharacter()
{
    if(!CharacterNameInput) return;
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetOwningPlayer()))
    {
        FString Message; const bool bCreated=PC->CreateCharacter(CharacterNameInput->GetText().ToString(),EHonourWarClass::Ranger,Message);
        CharacterSelectStatus->SetText(FText::FromString(Message)); if(bCreated) CharacterCreatePanel->SetVisibility(ESlateVisibility::Collapsed);
    }
}
