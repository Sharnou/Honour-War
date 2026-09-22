#include "HonourWarCharacter.h"
#include "Net/UnrealNetwork.h"
#include "HonourWarPlayerState.h"
#include "HonourWarCombatComponent.h"
#include "HonourWarQuestComponent.h"
#include "HonourWarSaveGame.h"
#include "HonourWarPlayerController.h"
#include "HonourWarMonster.h"
#include "Components/CapsuleComponent.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"

namespace
{
    UStaticMesh* LoadMesh(const TCHAR* Path){ return LoadObject<UStaticMesh>(nullptr,Path); }

    void ApplyColor(UStaticMeshComponent* Component,const FLinearColor& Color)
    {
        if (!Component) return;
        static UMaterialInterface* BaseMaterial=LoadObject<UMaterialInterface>(
            nullptr,TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        if (BaseMaterial)
        {
            if (UMaterialInstanceDynamic* MID=UMaterialInstanceDynamic::Create(BaseMaterial,Component))
            {
                MID->SetVectorParameterValue(TEXT("Color"),Color);
                MID->SetScalarParameterValue(TEXT("Roughness"),0.62f);
                Component->SetMaterial(0,MID);
            }
        }
    }

    UStaticMeshComponent* AddPart(AActor* Owner,USceneComponent* Parent,UStaticMesh* Mesh,const TCHAR* Name,
        const FVector& Location,const FVector& Scale,const FRotator& Rotation,const FLinearColor& Color)
    {
        if(!Owner||!Parent||!Mesh) return nullptr;
        UStaticMeshComponent* Part=NewObject<UStaticMeshComponent>(Owner,FName(Name));
        Owner->AddInstanceComponent(Part);
        Part->SetStaticMesh(Mesh);
        Part->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Part->AttachToComponent(Parent,FAttachmentTransformRules::KeepRelativeTransform);
        Part->SetRelativeLocation(Location);
        Part->SetRelativeRotation(Rotation);
        Part->SetRelativeScale3D(Scale);
        ApplyColor(Part,Color);
        Part->RegisterComponent();
        return Part;
    }
}

AHonourWarCharacter::AHonourWarCharacter()
{
    PrimaryActorTick.bCanEverTick=true;
    PrimaryActorTick.bStartWithTickEnabled=true;
    bReplicates=true;

    GetCapsuleComponent()->InitCapsuleSize(42.0f,96.0f);
    GetCharacterMovement()->MaxWalkSpeed=500.0f;
    GetCharacterMovement()->BrakingDecelerationWalking=1800.0f;
    GetCharacterMovement()->bOrientRotationToMovement=true;
    bUseControllerRotationYaw=false;

    CameraBoom=CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength=900.0f;
    CameraBoom->SetRelativeRotation(FRotator(-50.0f,45.0f,0.0f));
    CameraBoom->bEnableCameraLag=true;
    CameraBoom->CameraLagSpeed=12.0f;
    CameraBoom->bEnableCameraRotationLag=true;
    CameraBoom->CameraRotationLagSpeed=12.0f;
    CameraBoom->bUsePawnControlRotation=true;
    CameraBoom->bDoCollisionTest=true;
    CameraBoom->ProbeSize=18.0f;

    FollowCamera=CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom,USpringArmComponent::SocketName);
    FollowCamera->FieldOfView=48.0f;

    VisualRoot=CreateDefaultSubobject<USceneComponent>(TEXT("VisualRoot"));
    PlayerNameplate=CreateDefaultSubobject<UTextRenderComponent>(TEXT("PlayerNameplate"));
    PlayerNameplate->SetupAttachment(RootComponent);
    PlayerNameplate->SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
    PlayerNameplate->SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
    PlayerNameplate->SetWorldSize(30.0f);
    PlayerNameplate->SetRelativeLocation(FVector(0,0,270));
    PlayerNameplate->SetTextRenderColor(FColor(235,240,255,255));
    PlayerNameplate->bAlwaysRenderAsText=true;
    PlayerNameplate->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    VisualRoot->SetupAttachment(RootComponent);
    CombatComponent=CreateDefaultSubobject<UHonourWarCombatComponent>(TEXT("CombatComponent"));
    QuestComponent=CreateDefaultSubobject<UHonourWarQuestComponent>(TEXT("QuestComponent"));
    AutoPossessPlayer=EAutoReceiveInput::Player0;
}

void AHonourWarCharacter::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(AHonourWarCharacter,CharacterClass);
}

void AHonourWarCharacter::OnRepCharacterClass()
{
    if(CombatComponent) CombatComponent->SetClassId(CharacterClass);
    BuildHeroVisual();
    UpdateHonourWarPlayerNameplate(this);
}

void AHonourWarCharacter::ServerSetClassId_Implementation(EHonourWarClass NewClass)
{
    SetClassId(NewClass);
}

static void UpdateHonourWarPlayerNameplate(AHonourWarCharacter* Character)
{
    if(!Character) return;
    UTextRenderComponent* Plate=Character->FindComponentByClass<UTextRenderComponent>();
    if(!Plate || !Character->GetPlayerState()) return;
    Plate->SetText(FText::FromString(FString::Printf(
        TEXT("%s  |  %s  |  Lv.%d"),
        *Character->GetPlayerState()->GetPlayerName(),
        *Character->GetClassName(),
        Character->GetCombatComponent()?Character->GetCombatComponent()->GetLevel():1)));
}

void AHonourWarCharacter::BeginPlay()
{
    Super::BeginPlay();
    RespawnPoint=FVector(900.0f,900.0f,180.0f);
    SetActorLocation(RespawnPoint);
    BuildHeroVisual();
    LoadProgress();
    UpdateHonourWarPlayerNameplate(this);
}

void AHonourWarCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    OnlineTimeAccumulator += DeltaSeconds;
    if (OnlineTimeAccumulator >= 1.0f)
    {
        const int64 WholeSeconds = static_cast<int64>(OnlineTimeAccumulator);
        OnlineSeconds += WholeSeconds;
        OnlineTimeAccumulator -= static_cast<float>(WholeSeconds);
    }
    if (OnlineSeconds >= 86400)
    {
        const int64 OnlineDays = OnlineSeconds / 86400;
        OnlineSeconds %= 86400;
        if (CombatComponent) CombatComponent->SetAgeDays(CombatComponent->GetAgeDays() + static_cast<int32>(OnlineDays));
        BuildHeroVisual();
    }
    AutoSaveAccumulator += DeltaSeconds;
    if (AutoSaveAccumulator >= 60.0f)
    {
        AutoSaveAccumulator = 0.0f;
        SaveProgress();
    }
    if(!bMouseMoveActive || !GetCharacterMovement()) return;

    FVector Destination=MouseDestination;
    AHonourWarMonster* Target=MouseTarget;
    if(Target && Target->IsDead())
    {
        MouseTarget=nullptr;
        Target=nullptr;
    }

    if(Target)
    {
        const float Range=CombatComponent?CombatComponent->GetEngagementRange():220.0f;
        const FVector ToTarget=Target->GetActorLocation()-GetActorLocation();
        if(ToTarget.Size2D()<=Range)
        {
            GetCharacterMovement()->StopMovementImmediately();
            bMouseMoveActive=false;
            ActivateSkill(0);
            return;
        }
        Destination=Target->GetActorLocation();
    }

    const FVector ToDestination=Destination-GetActorLocation();
    const FVector FlatDirection=FVector(ToDestination.X,ToDestination.Y,0.0f).GetSafeNormal();
    if(ToDestination.Size2D()<=32.0f)
    {
        GetCharacterMovement()->StopMovementImmediately();
        bMouseMoveActive=false;
        return;
    }

    if(!FlatDirection.IsNearlyZero())
    {
        AddMovementInput(FlatDirection,1.0f);
        SetActorRotation(FMath::RInterpTo(GetActorRotation(),FlatDirection.Rotation(),DeltaSeconds,12.0f));
    }
}

void AHonourWarCharacter::SetMouseDestination(const FVector& Destination)
{
    MouseTarget=nullptr;
    MouseDestination=Destination;
    MouseDestination.Z=GetActorLocation().Z;
    bMouseMoveActive=true;
}

void AHonourWarCharacter::SetMouseTarget(AHonourWarMonster* Target)
{
    MouseTarget=Target;
    if(Target)
    {
        MouseDestination=Target->GetActorLocation();
        MouseDestination.Z=GetActorLocation().Z;
        bMouseMoveActive=true;
    }
}

void AHonourWarCharacter::ClearMouseCommand()
{
    MouseTarget=nullptr;
    bMouseMoveActive=false;
    if(GetCharacterMovement()) GetCharacterMovement()->StopMovementImmediately();
}

void AHonourWarCharacter::AdjustCameraZoom(float WheelDelta)
{
    if(!CameraBoom) return;
    CameraBoom->TargetArmLength=FMath::Clamp(CameraBoom->TargetArmLength-WheelDelta*120.0f,550.0f,1350.0f);
}

void AHonourWarCharacter::MoveForward(float Value)
{
    if(!Controller||FMath::IsNearlyZero(Value)) return;
    const FRotator ControlRotation=Controller->GetControlRotation();
    const FVector Forward=FRotationMatrix(FRotator(0,ControlRotation.Yaw,0)).GetUnitAxis(EAxis::X);
    AddMovementInput(Forward,Value);
}

void AHonourWarCharacter::MoveRight(float Value)
{
    if(!Controller||FMath::IsNearlyZero(Value)) return;
    const FRotator ControlRotation=Controller->GetControlRotation();
    const FVector Right=FRotationMatrix(FRotator(0,ControlRotation.Yaw,0)).GetUnitAxis(EAxis::Y);
    AddMovementInput(Right,Value);
}

void AHonourWarCharacter::CameraTurn(float Value)
{
    if(FMath::Abs(Value)>KINDA_SMALL_NUMBER) AddControllerYawInput(Value);
}

void AHonourWarCharacter::CameraLookUp(float Value)
{
    if(!Controller||FMath::IsNearlyZero(Value)) return;
    const FRotator Control=Controller->GetControlRotation();
    const float NewPitch=FMath::ClampAngle(Control.Pitch+Value,-62.0f,-28.0f);
    Controller->SetControlRotation(FRotator(NewPitch,Control.Yaw,0.0f));
}

void AHonourWarCharacter::Attack(){ ActivateSkill(0); }

void AHonourWarCharacter::ActivateSkill(int32 SkillIndex)
{
    if(!CombatComponent) return;
    if(CombatComponent->UseSkill(FMath::Clamp(SkillIndex,0,7)))
    {
        static const TCHAR* Names[]={
            TEXT("Basic Attack"),TEXT("Class Skill"),TEXT("Power Strike"),TEXT("Arcane Burst"),
            TEXT("Rapid Volley"),TEXT("Guardian Light"),TEXT("Shadow Step"),TEXT("Finisher")
        };
        LastCombatMessage=FString::Printf(TEXT("%s • impact confirmed"),Names[FMath::Clamp(SkillIndex,0,7)]);
    }
}

void AHonourWarCharacter::ReceiveMonsterDamage(float Damage)
{
    if(CombatComponent) CombatComponent->ReceiveDamage(Damage);
}

void AHonourWarCharacter::RefineEquipment()
{
    if (CombatComponent)
        LastCombatMessage = CombatComponent->TryRefineEquipment() ? CombatComponent->GetLastLootMessage() : CombatComponent->GetLastLootMessage();
}

void AHonourWarCharacter::MixCards()
{
    if (CombatComponent)
        LastCombatMessage = CombatComponent->TryMixCards() ? CombatComponent->GetLastLootMessage() : CombatComponent->GetLastLootMessage();
}

void AHonourWarCharacter::UpgradeBasicSkill()
{
    if (CombatComponent)
        LastCombatMessage = CombatComponent->TryUpgradeBasicSkill() ? CombatComponent->GetLastLootMessage() : CombatComponent->GetLastLootMessage();
}

void AHonourWarCharacter::HandleMonsterDefeat(int32 MonsterLevel)
{
    if(CombatComponent)
    {
        CombatComponent->RewardMonsterDefeat(MonsterLevel);
        if(QuestComponent) QuestComponent->RecordMonsterDefeat(MonsterLevel);
        LastCombatMessage = CombatComponent->GetLastLootMessage();
    }
}

void AHonourWarCharacter::HandleDeathAndRespawn()
{
    SetActorLocation(RespawnPoint);
    GetCharacterMovement()->StopMovementImmediately();
    if(CombatComponent) CombatComponent->RestoreVitals();
    LastCombatMessage=TEXT("Respawned at the city point");
}

void AHonourWarCharacter::CycleClass()
{
    const int32 Next=(static_cast<int32>(CharacterClass)+1)%7;
    SetClassId(static_cast<EHonourWarClass>(Next));
    LastCombatMessage=FString::Printf(TEXT("Class changed to %s"),*GetClassName());
}

EHonourWarClass AHonourWarCharacter::GetClassId() const{return CharacterClass;}
FString AHonourWarCharacter::GetClassName() const{return HonourWarClassName(CharacterClass);}
EHonourWarClassTier AHonourWarCharacter::GetClassTier() const
{
    return CombatComponent?HonourWarClassProgression::TierForLevel(CombatComponent->GetLevel()):EHonourWarClassTier::Tier1;
}
FString AHonourWarCharacter::GetClassTierName() const{return HonourWarClassProgression::TierName(GetClassTier());}
FString AHonourWarCharacter::GetFifthTierClassName() const{return HonourWarClassProgression::FifthTierName(CharacterClass);}

void AHonourWarCharacter::SetClassId(EHonourWarClass NewClass)
{
    if(!HasAuthority())
    {
        ServerSetClassId(NewClass);
        return;
    }

    CharacterClass=NewClass;
    if(CombatComponent) CombatComponent->SetClassId(NewClass);
    BuildHeroVisual();
}

void AHonourWarCharacter::BuildHeroVisual()
{
    if(!VisualRoot) return;

    TArray<USceneComponent*> ExistingChildren;
    VisualRoot->GetChildrenComponents(true,ExistingChildren);
    for(USceneComponent* Child:ExistingChildren) if(Child) Child->DestroyComponent();

    UStaticMesh* Cube=LoadMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    UStaticMesh* Sphere=LoadMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    UStaticMesh* Cylinder=LoadMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    if(!Cube||!Sphere||!Cylinder) return;

    const FHonourWarClassStyle Style=HonourWarClassStyle(CharacterClass);
    const float AgeYears=18.0f+static_cast<float>(CombatComponent?CombatComponent->GetAgeDays():0)/3.0f;
    const float Mature=FMath::Clamp((AgeYears-18.0f)/42.0f,0.0f,1.0f);
    const FLinearColor YoungSkin(0.76f,0.53f,0.40f);
    const FLinearColor MatureSkin(0.62f,0.46f,0.38f);
    const FLinearColor Skin=FLinearColor::LerpUsingHSV(YoungSkin,MatureSkin,Mature);
    const FLinearColor YoungHair(0.055f,0.035f,0.025f);
    const FLinearColor SilverHair(0.68f,0.68f,0.72f);
    const FLinearColor Hair=FLinearColor::LerpUsingHSV(YoungHair,SilverHair,Mature*0.82f);
    const FLinearColor Metal(0.62f,0.63f,0.64f);
    const float HeadMaturityScale=1.0f+Mature*0.08f;

    AddPart(this,VisualRoot,Cylinder,TEXT("Body"),FVector(0,0,75),FVector(0.62f,0.48f,0.82f),FRotator::ZeroRotator,Style.Primary);
    AddPart(this,VisualRoot,Cube,TEXT("ChestPlate"),FVector(0,0,112),FVector(0.68f,0.54f,0.28f),FRotator::ZeroRotator,Metal);
    AddPart(this,VisualRoot,Cube,TEXT("Waist"),FVector(0,0,82),FVector(0.60f,0.45f,0.14f),FRotator::ZeroRotator,Style.Secondary);
    AddPart(this,VisualRoot,Cylinder,TEXT("LeftLeg"),FVector(0,-24,35),FVector(0.24f,0.24f,0.48f),FRotator::ZeroRotator,Style.Primary);
    AddPart(this,VisualRoot,Cylinder,TEXT("RightLeg"),FVector(0,24,35),FVector(0.24f,0.24f,0.48f),FRotator::ZeroRotator,Style.Primary);
    AddPart(this,VisualRoot,Cube,TEXT("LeftBoot"),FVector(18,-24,10),FVector(0.34f,0.28f,0.18f),FRotator::ZeroRotator,Style.Secondary);
    AddPart(this,VisualRoot,Cube,TEXT("RightBoot"),FVector(18,24,10),FVector(0.34f,0.28f,0.18f),FRotator::ZeroRotator,Style.Secondary);
    AddPart(this,VisualRoot,Cylinder,TEXT("LeftArm"),FVector(0,-49,100),FVector(0.18f,0.18f,0.48f),FRotator(0,0,-8),Style.Primary);
    AddPart(this,VisualRoot,Cylinder,TEXT("RightArm"),FVector(0,49,100),FVector(0.18f,0.18f,0.48f),FRotator(0,0,8),Style.Primary);
    AddPart(this,VisualRoot,Sphere,TEXT("LeftGlove"),FVector(12,-54,72),FVector(0.20f,0.20f,0.20f),FRotator::ZeroRotator,Style.Secondary);
    AddPart(this,VisualRoot,Sphere,TEXT("RightGlove"),FVector(12,54,72),FVector(0.20f,0.20f,0.20f),FRotator::ZeroRotator,Style.Secondary);
    AddPart(this,VisualRoot,Sphere,TEXT("Head"),FVector(0,0,172),FVector(0.54f*HeadMaturityScale,0.50f*HeadMaturityScale,0.58f*HeadMaturityScale),FRotator::ZeroRotator,Skin);
    AddPart(this,VisualRoot,Sphere,TEXT("Hair"),FVector(-4,0,197+Mature*3.0f),FVector(0.58f,0.54f,0.28f+Mature*0.03f),FRotator::ZeroRotator,Hair);
    AddPart(this,VisualRoot,Sphere,TEXT("LeftEye"),FVector(38,-16,176),FVector(0.055f,0.055f,0.055f),FRotator::ZeroRotator,FLinearColor::Black);
    AddPart(this,VisualRoot,Sphere,TEXT("RightEye"),FVector(38,16,176),FVector(0.055f,0.055f,0.055f),FRotator::ZeroRotator,FLinearColor::Black);

    const FLinearColor FaceMark(0.46f,0.32f,0.27f);
    if(Mature>0.05f)
    {
        AddPart(this,VisualRoot,Cube,TEXT("AgeMarkL"),FVector(42,-17,167),FVector(0.015f,0.05f,0.10f),FRotator(0,0,8),FaceMark);
        AddPart(this,VisualRoot,Cube,TEXT("AgeMarkR"),FVector(42,17,167),FVector(0.015f,0.05f,0.10f),FRotator(0,0,-8),FaceMark);
    }
    if(Mature>=0.70f)
    {
        AddPart(this,VisualRoot,Cube,TEXT("MatureJaw"),FVector(43,0,162),FVector(0.018f,0.16f,0.025f),FRotator::ZeroRotator,FaceMark);
    }

    BuildWeaponVisual();
    BuildFifthTierVisual();
}

void AHonourWarCharacter::BuildFifthTierVisual()
{
    if(GetClassTier()!=EHonourWarClassTier::Tier5||!VisualRoot) return;

    UStaticMesh* Sphere=LoadMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    UStaticMesh* Cylinder=LoadMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    if(!Sphere||!Cylinder) return;

    const FHonourWarClassStyle Style=HonourWarClassStyle(CharacterClass);
    AddPart(this,VisualRoot,Cylinder,TEXT("Tier5Mantle"),FVector(0,0,142),FVector(0.88f,0.70f,0.12f),FRotator::ZeroRotator,Style.Accent);
    AddPart(this,VisualRoot,Sphere,TEXT("Tier5Crown"),FVector(-18,0,224),FVector(0.22f,0.22f,0.22f),FRotator::ZeroRotator,Style.Accent);
    AddPart(this,VisualRoot,Sphere,TEXT("Tier5ShoulderL"),FVector(8,-63,126),FVector(0.24f,0.24f,0.22f),FRotator::ZeroRotator,Style.Accent);
    AddPart(this,VisualRoot,Sphere,TEXT("Tier5ShoulderR"),FVector(8,63,126),FVector(0.24f,0.24f,0.22f),FRotator::ZeroRotator,Style.Accent);
}

void AHonourWarCharacter::BuildWeaponVisual()
{
    UStaticMesh* Cube=LoadMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    UStaticMesh* Cylinder=LoadMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    UStaticMesh* Sphere=LoadMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if(!Cube||!Cylinder||!Sphere) return;

    const FHonourWarClassStyle Style=HonourWarClassStyle(CharacterClass);
    const FLinearColor Steel(0.78f,0.82f,0.88f);

    switch(CharacterClass)
    {
        case EHonourWarClass::Warrior:
            AddPart(this,VisualRoot,Cube,TEXT("SwordBlade"),FVector(52,-22,96),FVector(0.10f,0.12f,0.68f),FRotator(0,0,-7),Steel);
            AddPart(this,VisualRoot,Cube,TEXT("SwordGuard"),FVector(44,-22,47),FVector(0.25f,0.12f,0.08f),FRotator::ZeroRotator,Style.Accent);
            break;
        case EHonourWarClass::Mage:
        case EHonourWarClass::Acolyte:
            AddPart(this,VisualRoot,Cylinder,TEXT("Staff"),FVector(48,32,120),FVector(0.09f,0.09f,0.92f),FRotator(0,0,12),FLinearColor(0.35f,0.20f,0.08f));
            AddPart(this,VisualRoot,Sphere,TEXT("StaffOrb"),FVector(58,34,205),FVector(0.20f,0.20f,0.20f),FRotator::ZeroRotator,Style.Accent);
            break;
        case EHonourWarClass::Archer:
        case EHonourWarClass::Ranger:
            AddPart(this,VisualRoot,Cube,TEXT("BowGrip"),FVector(48,-25,105),FVector(0.08f,0.10f,0.58f),FRotator(0,0,-5),Style.Accent);
            AddPart(this,VisualRoot,Cylinder,TEXT("Quiver"),FVector(-8,-46,115),FVector(0.12f,0.12f,0.45f),FRotator(0,0,8),Style.Secondary);
            break;
        case EHonourWarClass::Thief:
            AddPart(this,VisualRoot,Cube,TEXT("DaggerL"),FVector(48,-32,96),FVector(0.07f,0.08f,0.42f),FRotator(0,0,-22),Style.Accent);
            AddPart(this,VisualRoot,Cube,TEXT("DaggerR"),FVector(48,32,96),FVector(0.07f,0.08f,0.42f),FRotator(0,0,22),Style.Accent);
            break;
        case EHonourWarClass::Merchant:
            AddPart(this,VisualRoot,Cube,TEXT("TradePack"),FVector(-24,-35,112),FVector(0.32f,0.18f,0.34f),FRotator::ZeroRotator,Style.Accent);
            AddPart(this,VisualRoot,Cylinder,TEXT("MerchantTool"),FVector(50,28,100),FVector(0.10f,0.10f,0.52f),FRotator(0,0,18),Steel);
            break;
    }
}

void AHonourWarCharacter::SaveProgress()
{
    if(!CombatComponent) return;
    UHonourWarSaveGame* Save=Cast<UHonourWarSaveGame>(
        UGameplayStatics::CreateSaveGameObject(UHonourWarSaveGame::StaticClass()));
    if(!Save) return;

    Save->Level=CombatComponent->GetLevel();
    Save->Experience=CombatComponent->GetExperience();
    Save->AgeDays=CombatComponent->GetAgeDays();
    Save->ClassId=CharacterClass;
    Save->ClassTier=GetClassTier();
    Save->FifthTierArchetype=HonourWarClassProgression::NaturalFifthTier(CharacterClass);
    Save->Zeny=CombatComponent->GetZeny();
    Save->EquipmentRefineLevel=CombatComponent->GetEquipmentRefineLevel();
    Save->Phracon=CombatComponent->GetPhracon();
    Save->Emveretarcon=CombatComponent->GetEmveretarcon();
    Save->Oridecon=CombatComponent->GetOridecon();
    Save->BasicSkillLevel=CombatComponent->GetBasicSkillLevel();
    Save->Honours=CombatComponent->GetHonours();
    Save->InventoryItems=CombatComponent->GetInventoryItems();
    Save->Cards=CombatComponent->GetCards();
    Save->SavedAtUtc=FDateTime::UtcNow();
    Save->OnlineSeconds=OnlineSeconds;
    Save->PlayerLocation=GetActorLocation();
    if(AHonourWarPlayerState* PS=GetPlayerState<AHonourWarPlayerState>())
    {
        Save->GuildName=PS->GetGuildName();
        Save->GuildRank=PS->GetGuildRank();
    }
    if(QuestComponent)
    {
        Save->QuestId=QuestComponent->GetQuestId();
        Save->QuestProgress=QuestComponent->GetQuestProgress();
        Save->QuestComplete=QuestComponent->IsQuestComplete();
    }
    FString SaveSlot=TEXT("HonourWar_Profile_0");
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetController()))
        SaveSlot=FString::Printf(TEXT("HonourWar_Profile_%d"),PC->GetActiveCharacterSlot()>=0?PC->GetActiveCharacterSlot():0);
    UGameplayStatics::SaveGameToSlot(Save,*SaveSlot,0);
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetController())) PC->SyncActiveCharacterSummary(this);
    LastCombatMessage=TEXT("Progress saved");
}

void AHonourWarCharacter::LoadProgress()
{
    FString SaveSlot=TEXT("HonourWar_Profile_0");
    if(AHonourWarPlayerController* PC=Cast<AHonourWarPlayerController>(GetController()))
        SaveSlot=FString::Printf(TEXT("HonourWar_Profile_%d"),PC->GetActiveCharacterSlot()>=0?PC->GetActiveCharacterSlot():0);
    if(!CombatComponent||!UGameplayStatics::DoesSaveGameExist(*SaveSlot,0)) return;

    UHonourWarSaveGame* Save=Cast<UHonourWarSaveGame>(
        UGameplayStatics::LoadGameFromSlot(*SaveSlot,0));
    if(!Save) return;

    OnlineSeconds=FMath::Max<int64>(0,Save->OnlineSeconds);
    CharacterClass=Save->ClassId;
    SetActorLocation(Save->PlayerLocation);
    CombatComponent->SetClassId(CharacterClass);
    CombatComponent->SetLevel(Save->Level);
    CombatComponent->SetExperience(Save->Experience);
    CombatComponent->SetAgeDays(Save->AgeDays);
    CombatComponent->SetZeny(Save->Zeny);
    CombatComponent->SetEquipmentRefineLevel(Save->EquipmentRefineLevel);
    CombatComponent->SetPhracon(Save->Phracon);
    CombatComponent->SetEmveretarcon(Save->Emveretarcon);
    CombatComponent->SetOridecon(Save->Oridecon);
    CombatComponent->SetHonours(Save->Honours);
    CombatComponent->SetBasicSkillLevel(Save->BasicSkillLevel);
    CombatComponent->SetInventoryItems(Save->InventoryItems);
    CombatComponent->SetCards(Save->Cards);
    BuildHeroVisual();
}