#include "HonourWarCharacter.h"
#include "HonourWarCombatComponent.h"
#include "HonourWarSaveGame.h"
#include "Components/CapsuleComponent.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"

namespace
{
    UStaticMesh* LoadMesh(const TCHAR* Path){return LoadObject<UStaticMesh>(nullptr,Path);}

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
                Component->SetMaterial(0,MID);
            }
        }
    }

    UStaticMeshComponent* AddPart(AActor* Owner,USceneComponent* Parent,UStaticMesh* Mesh,const TCHAR* Name,
        const FVector& Location,const FVector& Scale,const FRotator& Rotation,const FLinearColor& Color)
    {
        if (!Owner||!Parent||!Mesh) return nullptr;
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
    PrimaryActorTick.bCanEverTick=false;
    bReplicates=true;

    GetCapsuleComponent()->InitCapsuleSize(42.0f,96.0f);
    GetCharacterMovement()->MaxWalkSpeed=500.0f;
    GetCharacterMovement()->BrakingDecelerationWalking=1800.0f;

    CameraBoom=CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength=1100.0f;
    CameraBoom->SetRelativeRotation(FRotator(-48.0f,45.0f,0.0f));
    CameraBoom->bUsePawnControlRotation=true;
    CameraBoom->bDoCollisionTest=true;
    CameraBoom->ProbeSize=18.0f;

    FollowCamera=CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom,USpringArmComponent::SocketName);
    FollowCamera->FieldOfView=48.0f;

    VisualRoot=CreateDefaultSubobject<USceneComponent>(TEXT("VisualRoot"));
    VisualRoot->SetupAttachment(RootComponent);
    CombatComponent=CreateDefaultSubobject<UHonourWarCombatComponent>(TEXT("CombatComponent"));
    AutoPossessPlayer=EAutoReceiveInput::Player0;
}

void AHonourWarCharacter::BeginPlay()
{
    Super::BeginPlay();
    RespawnPoint=FVector(900.0f,900.0f,180.0f);
    SetActorLocation(RespawnPoint);
    BuildHeroVisual();
    LoadProgress();
}

void AHonourWarCharacter::MoveForward(float Value)
{
    if (!Controller||FMath::IsNearlyZero(Value)) return;
    const FRotator ControlRotation=Controller->GetControlRotation();
    const FVector Forward=FRotationMatrix(FRotator(0,ControlRotation.Yaw,0)).GetUnitAxis(EAxis::X);
    AddMovementInput(Forward,Value);
}

void AHonourWarCharacter::MoveRight(float Value)
{
    if (!Controller||FMath::IsNearlyZero(Value)) return;
    const FRotator ControlRotation=Controller->GetControlRotation();
    const FVector Right=FRotationMatrix(FRotator(0,ControlRotation.Yaw,0)).GetUnitAxis(EAxis::Y);
    AddMovementInput(Right,Value);
}

void AHonourWarCharacter::CameraTurn(float Value)
{
    if (FMath::Abs(Value)>KINDA_SMALL_NUMBER) AddControllerYawInput(Value);
}

void AHonourWarCharacter::CameraLookUp(float Value)
{
    if (!Controller||FMath::IsNearlyZero(Value)) return;
    const FRotator Control=Controller->GetControlRotation();
    const float NewPitch=FMath::ClampAngle(Control.Pitch+Value,-62.0f,-28.0f);
    Controller->SetControlRotation(FRotator(NewPitch,Control.Yaw,0.0f));
}

void AHonourWarCharacter::Attack(){ActivateSkill(0);}

void AHonourWarCharacter::ActivateSkill(int32 SkillIndex)
{
    if (!CombatComponent) return;
    if (CombatComponent->UseSkill(FMath::Clamp(SkillIndex,0,7)))
    {
        const TCHAR* Names[]={
            TEXT("Basic Attack"),TEXT("Class Skill"),TEXT("Power Strike"),TEXT("Arcane Burst"),
            TEXT("Rapid Volley"),TEXT("Guardian Light"),TEXT("Shadow Step"),TEXT("Finisher")
        };
        LastCombatMessage=FString::Printf(TEXT("%s • impact confirmed"),Names[FMath::Clamp(SkillIndex,0,7)]);
    }
}

void AHonourWarCharacter::ReceiveMonsterDamage(float Damage)
{
    if (CombatComponent) CombatComponent->ReceiveDamage(Damage);
}

void AHonourWarCharacter::HandleDeathAndRespawn()
{
    SetActorLocation(RespawnPoint);
    GetCharacterMovement()->StopMovementImmediately();
    if (CombatComponent) CombatComponent->RestoreVitals();
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

void AHonourWarCharacter::SetClassId(EHonourWarClass NewClass)
{
    CharacterClass=NewClass;
    if (CombatComponent) CombatComponent->SetClassId(NewClass);
    BuildHeroVisual();
}

void AHonourWarCharacter::BuildHeroVisual()
{
    if (!VisualRoot) return;

    TArray<USceneComponent*> ExistingChildren;
    VisualRoot->GetChildrenComponents(true,ExistingChildren);
    for (USceneComponent* Child:ExistingChildren)
        if (Child&&Child!=VisualRoot) Child->DestroyComponent();

    UStaticMesh* Cube=LoadMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    UStaticMesh* Sphere=LoadMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    UStaticMesh* Cylinder=LoadMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    if (!Cube||!Sphere||!Cylinder) return;

    const FHonourWarClassStyle Style=HonourWarClassStyle(CharacterClass);
    const FLinearColor Skin(0.72f,0.48f,0.34f);
    const FLinearColor Hair(0.08f,0.05f,0.03f);
    const FLinearColor Metal(0.70f,0.66f,0.58f);

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
    AddPart(this,VisualRoot,Sphere,TEXT("Head"),FVector(0,0,172),FVector(0.54f,0.50f,0.58f),FRotator::ZeroRotator,Skin);
    AddPart(this,VisualRoot,Sphere,TEXT("Hair"),FVector(-4,0,197),FVector(0.58f,0.54f,0.28f),FRotator::ZeroRotator,Hair);
    AddPart(this,VisualRoot,Sphere,TEXT("LeftEye"),FVector(38,-16,176),FVector(0.055f,0.055f,0.055f),FRotator::ZeroRotator,FLinearColor::Black);
    AddPart(this,VisualRoot,Sphere,TEXT("RightEye"),FVector(38,16,176),FVector(0.055f,0.055f,0.055f),FRotator::ZeroRotator,FLinearColor::Black);
    BuildWeaponVisual();
}

void AHonourWarCharacter::BuildWeaponVisual()
{
    UStaticMesh* Cube=LoadMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    UStaticMesh* Cylinder=LoadMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    UStaticMesh* Sphere=LoadMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (!Cube||!Cylinder||!Sphere) return;

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
    if (!CombatComponent) return;
    UHonourWarSaveGame* Save=Cast<UHonourWarSaveGame>(
        UGameplayStatics::CreateSaveGameObject(UHonourWarSaveGame::StaticClass()));
    if (!Save) return;

    Save->Level=CombatComponent->GetLevel();
    Save->Experience=CombatComponent->GetExperience();
    Save->AgeDays=CombatComponent->GetAgeDays();
    Save->ClassId=CharacterClass;
    Save->SavedAtUtc=FDateTime::UtcNow();

    UGameplayStatics::SaveGameToSlot(Save,TEXT("HonourWar_Profile"),0);
    LastCombatMessage=TEXT("Progress saved");
}

void AHonourWarCharacter::LoadProgress()
{
    if (!CombatComponent||!UGameplayStatics::DoesSaveGameExist(TEXT("HonourWar_Profile"),0)) return;

    UHonourWarSaveGame* Save=Cast<UHonourWarSaveGame>(
        UGameplayStatics::LoadGameFromSlot(TEXT("HonourWar_Profile"),0));
    if (!Save) return;

    const int32 ElapsedDays=FMath::Max(0,static_cast<int32>((FDateTime::UtcNow()-Save->SavedAtUtc).GetTotalDays()));
    CharacterClass=Save->ClassId;
    CombatComponent->SetClassId(CharacterClass);
    CombatComponent->SetLevel(Save->Level);
    CombatComponent->SetExperience(Save->Experience);
    CombatComponent->SetAgeDays(Save->AgeDays+ElapsedDays);
    BuildHeroVisual();
}
