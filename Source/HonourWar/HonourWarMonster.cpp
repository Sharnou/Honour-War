#include "HonourWarMonster.h"
#include "HonourWarCombatEffect.h"
#include "HonourWarDamagePopup.h"
#include "HonourWarCharacter.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Engine/StaticMesh.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
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
                MID->SetScalarParameterValue(TEXT("Roughness"),0.70f);
                Component->SetMaterial(0,MID);
            }
        }
    }

    UStaticMesh* Mesh(const TCHAR* Path){return LoadObject<UStaticMesh>(nullptr,Path);}
}

AHonourWarMonster::AHonourWarMonster()
{
    PrimaryActorTick.bCanEverTick=true;
    bReplicates=true;

    Root=CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    RootComponent=Root;

    Body=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Body"));
    Head=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Head"));
    LeftHorn=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("LeftHorn"));
    RightHorn=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("RightHorn"));
    Nameplate=CreateDefaultSubobject<UTextRenderComponent>(TEXT("Nameplate"));

    Body->SetupAttachment(Root);
    Head->SetupAttachment(Root);
    LeftHorn->SetupAttachment(Root);
    RightHorn->SetupAttachment(Root);
    Nameplate->SetupAttachment(Root);
    Nameplate->SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
    Nameplate->SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
    Nameplate->SetWorldSize(28.0f);
    Nameplate->SetRelativeLocation(FVector(0,0,320));
    Nameplate->SetTextRenderColor(FColor(255,240,190,255));
    Nameplate->bAlwaysRenderAsText=true;
    Nameplate->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    Body->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    Head->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Body->SetCollisionResponseToChannel(ECC_Visibility,ECR_Block);
    LeftHorn->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    RightHorn->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereFinder(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeFinder(TEXT("/Engine/BasicShapes/Cone.Cone"));
    if (SphereFinder.Succeeded()){Body->SetStaticMesh(SphereFinder.Object);Head->SetStaticMesh(SphereFinder.Object);}
    if (ConeFinder.Succeeded()){LeftHorn->SetStaticMesh(ConeFinder.Object);RightHorn->SetStaticMesh(ConeFinder.Object);}
}

void AHonourWarMonster::SetLevel(int32 NewLevel)
{
    Level=FMath::Clamp(NewLevel,1,300);
    MaxHealth=600.0f+Level*65.0f;
    CurrentHealth=MaxHealth;
    if(HasActorBegunPlay())
    {
        const float TierScale=0.80f+static_cast<float>(Level)/260.0f;
        Body->SetRelativeScale3D(FVector(1.20f*TierScale,1.00f*TierScale,1.35f*TierScale));
        Head->SetRelativeScale3D(FVector(0.84f*TierScale,0.84f*TierScale,0.74f*TierScale));
    }
}

void AHonourWarMonster::SetSpecies(EHonourWarMonsterSpecies NewSpecies)
{
    Species=NewSpecies;
    if(HasActorBegunPlay())
    {
        ApplySpeciesVisual();
        if(Nameplate) Nameplate->SetText(FText::FromString(FString::Printf(TEXT("Lv.%d %s [%s]"),Level,*GetSpeciesName(),Level>=250?TEXT("MVP"):(Level>=150?TEXT("Elite"):TEXT("Normal")))));
    }
}

void AHonourWarMonster::SetDisplayName(const FString& NewDisplayName)
{
    DisplayName=NewDisplayName.IsEmpty()?GetSpeciesName():NewDisplayName;
    if(Nameplate)
        Nameplate->SetText(FText::FromString(
            FString::Printf(TEXT("Lv.%d %s [%s]"),
                Level,*DisplayName,Level>=250?TEXT("MVP"):(Level>=150?TEXT("Elite"):TEXT("Normal")))));
}

FString AHonourWarMonster::GetSpeciesName() const
{
    switch(Species)
    {
        case EHonourWarMonsterSpecies::Poring: return TEXT("Poring");
        case EHonourWarMonsterSpecies::Goblin: return TEXT("Goblin");
        case EHonourWarMonsterSpecies::Wolf: return TEXT("Wolf");
        case EHonourWarMonsterSpecies::Skeleton: return TEXT("Skeleton");
        case EHonourWarMonsterSpecies::Orc: return TEXT("Orc");
        case EHonourWarMonsterSpecies::Mantis: return TEXT("Mantis");
        case EHonourWarMonsterSpecies::Golem: return TEXT("Golem");
        case EHonourWarMonsterSpecies::Dragon: return TEXT("Dragon");
        default: return TEXT("Monster");
    }
}

void AHonourWarMonster::ApplySpeciesVisual()
{
    const float TierScale=0.80f+static_cast<float>(Level)/260.0f;
    UStaticMesh* Sphere=Mesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    UStaticMesh* Cube=Mesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    UStaticMesh* Cone=Mesh(TEXT("/Engine/BasicShapes/Cone.Cone"));
    if(!Sphere||!Cone) return;

    Body->SetStaticMesh(Sphere);
    Head->SetStaticMesh(Sphere);
    LeftHorn->SetStaticMesh(Cone);
    RightHorn->SetStaticMesh(Cone);
    LeftHorn->SetVisibility(true);
    RightHorn->SetVisibility(true);

    FLinearColor BodyColor(0.35f,0.17f,0.12f);
    FLinearColor HeadColor(0.46f,0.24f,0.15f);
    FVector BodyScale=FVector(1.20f,1.00f,1.35f)*TierScale;
    FVector HeadScale=FVector(0.84f,0.84f,0.74f)*TierScale;
    FVector HeadLocation(26,0,190);
    FVector LeftLocation(46,-42,245);
    FVector RightLocation(46,42,245);
    FRotator LeftRotation(-24,0,-14);
    FRotator RightRotation(-24,0,14);
    FVector HornScale(0.20f,0.20f,0.70f);

    switch(Species)
    {
        case EHonourWarMonsterSpecies::Poring:
            BodyScale=FVector(1.45f,1.45f,0.92f)*TierScale;
            HeadScale=FVector(0.40f,0.40f,0.32f)*TierScale;
            HeadLocation=FVector(42,0,135);
            LeftHorn->SetVisibility(false);
            RightHorn->SetVisibility(false);
            BodyColor=FLinearColor(0.12f,0.46f,0.92f);
            HeadColor=FLinearColor(0.28f,0.70f,1.00f);
            break;
        case EHonourWarMonsterSpecies::Goblin:
            BodyScale=FVector(0.90f,0.76f,0.96f)*TierScale;
            HeadScale=FVector(1.00f,0.82f,0.86f)*TierScale;
            HeadLocation=FVector(30,0,205);
            LeftLocation=FVector(36,-82,215);
            RightLocation=FVector(36,82,215);
            LeftRotation=FRotator(-70,0,-58);
            RightRotation=FRotator(-70,0,58);
            HornScale=FVector(0.16f,0.16f,0.78f)*TierScale;
            BodyColor=FLinearColor(0.20f,0.48f,0.18f);
            HeadColor=FLinearColor(0.36f,0.66f,0.24f);
            break;
        case EHonourWarMonsterSpecies::Wolf:
            BodyScale=FVector(1.48f,0.72f,0.76f)*TierScale;
            HeadScale=FVector(0.72f,0.58f,0.55f)*TierScale;
            HeadLocation=FVector(105,-12,155);
            LeftLocation=FVector(135,-42,175);
            RightLocation=FVector(135,42,175);
            LeftHorn->SetVisibility(false);
            RightHorn->SetVisibility(false);
            BodyColor=FLinearColor(0.20f,0.22f,0.25f);
            HeadColor=FLinearColor(0.30f,0.32f,0.36f);
            break;
        case EHonourWarMonsterSpecies::Skeleton:
            BodyScale=FVector(0.56f,0.46f,1.25f)*TierScale;
            HeadScale=FVector(0.58f,0.50f,0.66f)*TierScale;
            HeadLocation=FVector(22,0,215);
            LeftHorn->SetVisibility(false);
            RightHorn->SetVisibility(false);
            BodyColor=FLinearColor(0.72f,0.68f,0.55f);
            HeadColor=FLinearColor(0.85f,0.81f,0.68f);
            break;
        case EHonourWarMonsterSpecies::Orc:
            if(Cube) Body->SetStaticMesh(Cube);
            BodyScale=FVector(1.15f,0.95f,1.20f)*TierScale;
            HeadScale=FVector(0.78f,0.68f,0.72f)*TierScale;
            HeadLocation=FVector(26,0,215);
            LeftLocation=FVector(58,-30,185);
            RightLocation=FVector(58,30,185);
            LeftRotation=FRotator(20,0,-18);
            RightRotation=FRotator(20,0,18);
            HornScale=FVector(0.13f,0.13f,0.50f)*TierScale;
            BodyColor=FLinearColor(0.26f,0.44f,0.10f);
            HeadColor=FLinearColor(0.38f,0.56f,0.16f);
            break;
        case EHonourWarMonsterSpecies::Mantis:
            BodyScale=FVector(0.66f,0.62f,1.32f)*TierScale;
            HeadScale=FVector(0.50f,0.44f,0.48f)*TierScale;
            HeadLocation=FVector(36,0,225);
            LeftLocation=FVector(88,-75,170);
            RightLocation=FVector(88,75,170);
            LeftRotation=FRotator(0,0,-58);
            RightRotation=FRotator(0,0,58);
            HornScale=FVector(0.12f,0.10f,0.78f)*TierScale;
            BodyColor=FLinearColor(0.13f,0.52f,0.20f);
            HeadColor=FLinearColor(0.20f,0.70f,0.28f);
            break;
        case EHonourWarMonsterSpecies::Golem:
            if(Cube) Body->SetStaticMesh(Cube);
            if(Cube) Head->SetStaticMesh(Cube);
            BodyScale=FVector(1.35f,1.05f,1.30f)*TierScale;
            HeadScale=FVector(0.80f,0.72f,0.72f)*TierScale;
            HeadLocation=FVector(24,0,220);
            LeftLocation=FVector(0,-92,175);
            RightLocation=FVector(0,92,175);
            LeftRotation=FRotator(0,90,-12);
            RightRotation=FRotator(0,90,12);
            HornScale=FVector(0.34f,0.34f,0.34f)*TierScale;
            BodyColor=FLinearColor(0.34f,0.36f,0.38f);
            HeadColor=FLinearColor(0.46f,0.49f,0.52f);
            break;
        case EHonourWarMonsterSpecies::Dragon:
            BodyScale=FVector(1.58f,1.05f,1.20f)*TierScale;
            HeadScale=FVector(0.82f,0.70f,0.72f)*TierScale;
            HeadLocation=FVector(105,0,215);
            LeftLocation=FVector(110,-48,245);
            RightLocation=FVector(110,48,245);
            HornScale=FVector(0.18f,0.18f,0.95f)*TierScale;
            LeftRotation=FRotator(-30,0,-16);
            RightRotation=FRotator(-30,0,16);
            BodyColor=FLinearColor(0.54f,0.10f,0.08f);
            HeadColor=FLinearColor(0.70f,0.16f,0.10f);
            break;
    }

    Body->SetRelativeLocation(FVector(0,0,90));
    Body->SetRelativeScale3D(BodyScale);
    Head->SetRelativeLocation(HeadLocation);
    Head->SetRelativeScale3D(HeadScale);
    LeftHorn->SetRelativeLocation(LeftLocation);
    RightHorn->SetRelativeLocation(RightLocation);
    LeftHorn->SetRelativeRotation(LeftRotation);
    RightHorn->SetRelativeRotation(RightRotation);
    LeftHorn->SetRelativeScale3D(HornScale);
    RightHorn->SetRelativeScale3D(HornScale);

    ApplyColor(Body,BodyColor);
    ApplyColor(Head,HeadColor);

    UStaticMesh* DetailSphere=Mesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    UStaticMesh* DetailCube=Mesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    UStaticMesh* DetailCylinder=Mesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    auto AddDetail=[this](UStaticMesh* DetailMesh,const TCHAR* Name,const FVector& Location,const FVector& Scale,const FRotator& Rotation,const FLinearColor& Color)
    {
        if(!DetailMesh) return;
        const FName UniqueName=MakeUniqueObjectName(this,UStaticMeshComponent::StaticClass(),FName(Name));
        UStaticMeshComponent* Detail=NewObject<UStaticMeshComponent>(this,UniqueName);
        AddInstanceComponent(Detail);
        Detail->SetStaticMesh(DetailMesh);
        Detail->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Detail->AttachToComponent(Root,FAttachmentTransformRules::KeepRelativeTransform);
        Detail->SetRelativeLocation(Location);
        Detail->SetRelativeRotation(Rotation);
        Detail->SetRelativeScale3D(Scale);
        ApplyColor(Detail,Color);
        Detail->RegisterComponent();
    };

    switch(Species)
    {
        case EHonourWarMonsterSpecies::Wolf:
            AddDetail(DetailSphere,TEXT("WolfEarL"),FVector(78,-30,205),FVector(0.22f,0.18f,0.36f),FRotator(0,0,-12),HeadColor);
            AddDetail(DetailSphere,TEXT("WolfEarR"),FVector(78,30,205),FVector(0.22f,0.18f,0.36f),FRotator(0,0,12),HeadColor);
            AddDetail(DetailCylinder,TEXT("WolfTail"),FVector(-82,0,145),FVector(0.18f,0.18f,0.90f),FRotator(0,0,-35),BodyColor);
            break;
        case EHonourWarMonsterSpecies::Goblin:
        case EHonourWarMonsterSpecies::Orc:
            AddDetail(DetailCube,TEXT("MonsterChest"),FVector(54,0,132),FVector(0.10f,0.56f,0.28f),FRotator::ZeroRotator,FLinearColor(0.24f,0.17f,0.08f));
            AddDetail(DetailSphere,TEXT("MonsterBelt"),FVector(50,0,84),FVector(0.12f,0.62f,0.10f),FRotator::ZeroRotator,FLinearColor(0.12f,0.09f,0.07f));
            break;
        case EHonourWarMonsterSpecies::Skeleton:
            AddDetail(DetailCylinder,TEXT("SkeletonRibL"),FVector(52,-18,125),FVector(0.07f,0.07f,0.48f),FRotator(0,0,80),FLinearColor(0.90f,0.86f,0.72f));
            AddDetail(DetailCylinder,TEXT("SkeletonRibR"),FVector(52,18,125),FVector(0.07f,0.07f,0.48f),FRotator(0,0,-80),FLinearColor(0.90f,0.86f,0.72f));
            break;
        case EHonourWarMonsterSpecies::Mantis:
            AddDetail(DetailCylinder,TEXT("MantisArmL"),FVector(82,-72,150),FVector(0.10f,0.10f,0.85f),FRotator(0,0,-58),FLinearColor(0.08f,0.32f,0.12f));
            AddDetail(DetailCylinder,TEXT("MantisArmR"),FVector(82,72,150),FVector(0.10f,0.10f,0.85f),FRotator(0,0,58),FLinearColor(0.08f,0.32f,0.12f));
            break;
        case EHonourWarMonsterSpecies::Golem:
            AddDetail(DetailCube,TEXT("GolemCore"),FVector(72,0,150),FVector(0.14f,0.26f,0.26f),FRotator::ZeroRotator,FLinearColor(0.45f,0.62f,0.74f));
            AddDetail(DetailCube,TEXT("GolemShoulderL"),FVector(0,-105,170),FVector(0.48f,0.28f,0.34f),FRotator(0,0,-8),HeadColor);
            AddDetail(DetailCube,TEXT("GolemShoulderR"),FVector(0,105,170),FVector(0.48f,0.28f,0.34f),FRotator(0,0,8),HeadColor);
            break;
        case EHonourWarMonsterSpecies::Dragon:
            AddDetail(DetailCube,TEXT("DragonWingL"),FVector(-20,-95,180),FVector(0.20f,1.00f,0.95f),FRotator(0,0,-18),FLinearColor(0.28f,0.05f,0.09f));
            AddDetail(DetailCube,TEXT("DragonWingR"),FVector(-20,95,180),FVector(0.20f,1.00f,0.95f),FRotator(0,0,18),FLinearColor(0.28f,0.05f,0.09f));
            AddDetail(DetailSphere,TEXT("DragonChest"),FVector(62,0,145),FVector(0.16f,0.36f,0.34f),FRotator::ZeroRotator,FLinearColor(0.86f,0.32f,0.18f));
            break;
        case EHonourWarMonsterSpecies::Poring:
        default:
            break;
    }
}

void AHonourWarMonster::BeginPlay()
{
    Super::BeginPlay();
    MaxHealth=600.0f+Level*65.0f;
    CurrentHealth=MaxHealth;

    Body->SetRelativeLocation(FVector(0,0,90));
    Body->SetRelativeScale3D(FVector(1.20f,1.00f,1.35f));
    Head->SetRelativeLocation(FVector(26,0,190));
    Head->SetRelativeScale3D(FVector(0.84f,0.84f,0.74f));

    LeftHorn->SetRelativeLocation(FVector(46,-42,245));
    LeftHorn->SetRelativeRotation(FRotator(-24,0,-14));
    LeftHorn->SetRelativeScale3D(FVector(0.20f,0.20f,0.70f));
    RightHorn->SetRelativeLocation(FVector(46,42,245));
    RightHorn->SetRelativeRotation(FRotator(-24,0,14));
    RightHorn->SetRelativeScale3D(FVector(0.20f,0.20f,0.70f));

    const float TierScale = 0.80f + static_cast<float>(Level) / 260.0f;
    Body->SetRelativeScale3D(FVector(1.20f*TierScale,1.00f*TierScale,1.35f*TierScale));
    Head->SetRelativeScale3D(FVector(0.84f*TierScale,0.84f*TierScale,0.74f*TierScale));
    const FLinearColor BodyColor = Level >= 300 ? FLinearColor(0.18f,0.03f,0.28f) : Level >= 200 ? FLinearColor(0.55f,0.08f,0.10f) : Level >= 100 ? FLinearColor(0.30f,0.12f,0.08f) : FLinearColor(0.35f,0.17f,0.12f);
    const FLinearColor HeadColor = Level >= 300 ? FLinearColor(0.38f,0.06f,0.52f) : Level >= 200 ? FLinearColor(0.68f,0.14f,0.12f) : Level >= 100 ? FLinearColor(0.46f,0.18f,0.12f) : FLinearColor(0.46f,0.24f,0.15f);
    ApplyColor(Body,BodyColor);
    ApplyColor(Head,HeadColor);
    ApplyColor(LeftHorn,FLinearColor(0.12f,0.07f,0.05f));
    ApplyColor(RightHorn,FLinearColor(0.12f,0.07f,0.05f));
    ApplySpeciesVisual();

    const FString TierLabel=Level>=250 ? TEXT("MVP") : (Level>=150 ? TEXT("Elite") : TEXT("Normal"));
    Nameplate->SetText(FText::FromString(FString::Printf(TEXT("Lv.%d %s [%s]"),Level,*GetSpeciesName(),*TierLabel)));
    Nameplate->SetWorldSize(Level>=250?34.0f:28.0f);

    UStaticMesh* Sphere=Mesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (Sphere)
    {
        for (int32 Side=-1;Side<=1;Side+=2)
        {
            UStaticMeshComponent* Eye=NewObject<UStaticMeshComponent>(this,*FString::Printf(TEXT("Eye%d"),Side));
            AddInstanceComponent(Eye);
            Eye->SetStaticMesh(Sphere);
            Eye->SetCollisionEnabled(ECollisionEnabled::NoCollision);
            Eye->AttachToComponent(Root,FAttachmentTransformRules::KeepRelativeTransform);
            Eye->SetRelativeLocation(FVector(65,Side*18,190));
            Eye->SetRelativeScale3D(FVector(0.10f,0.10f,0.10f));
            Eye->RegisterComponent();
            ApplyColor(Eye,FLinearColor(0.95f,0.75f,0.30f));
        }
    }
}

void AHonourWarMonster::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (bDead) return;

    AttackTimer=FMath::Max(0.0f,AttackTimer-DeltaSeconds);
    FlinchTimer=FMath::Max(0.0f,FlinchTimer);
    if(FlinchTimer>0.0f)
    {
        const float Pulse=1.0f+FMath::Sin(FlinchTimer*65.0f)*0.06f;
        Body->SetRelativeScale3D(ReactionBaseScale*Pulse);
    }
    else if(!ReactionBaseScale.IsNearlyZero())
    {
        Body->SetRelativeScale3D(ReactionBaseScale);
    }
    APawn* Player=UGameplayStatics::GetPlayerPawn(this,0);
    if (!Player) return;

    const FVector ToPlayer=Player->GetActorLocation()-GetActorLocation();
    const float Distance=ToPlayer.Size();

    if (Distance<1900.0f && Distance>280.0f)
    {
        const FVector Direction=ToPlayer.GetSafeNormal2D();
        AddActorWorldOffset(Direction*(260.0f*DeltaSeconds),true);
        if (!Direction.IsNearlyZero())
            SetActorRotation(FMath::RInterpTo(GetActorRotation(),Direction.Rotation(),DeltaSeconds,8.0f));
    }

    if (Distance<=330.0f && AttackTimer<=0.0f)
    {
        if (AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(Player))
            Character->ReceiveMonsterDamage(45.0f+Level*2.0f,Level);
        AttackTimer=1.2f;
    }
}

void AHonourWarMonster::PlayCombatReaction(bool bHit,bool bCritical,bool bLucky,float Damage,EHonourWarClass SourceClass)
{
    if(UWorld* World=GetWorld())
    {
        if(!bHit)
        {
            if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(
                AHonourWarDamagePopup::StaticClass(),GetActorLocation()+FVector(0,0,240),FRotator(0,180,0)))
            {
                Popup->InitializeReaction(
                    bLucky?TEXT("Lucky!"):TEXT("MISS"),
                    bLucky?FLinearColor(0.25f,0.65f,1.0f):FLinearColor(0.80f,0.82f,0.86f),
                    bLucky?38.0f:34.0f,0.72f);
            }
            return;
        }

        FlinchTimer=bCritical?0.16f:0.25f;
        ReactionBaseScale=Body->GetRelativeScale3D();
        const FLinearColor ImpactColor=bCritical?FLinearColor(1.0f,0.08f,0.03f):FLinearColor(1.0f,0.25f,0.20f);
        if(AHonourWarCombatEffect* Effect=World->SpawnActor<AHonourWarCombatEffect>(
            AHonourWarCombatEffect::StaticClass(),GetActorLocation()+FVector(0,0,145),FRotator::ZeroRotator))
        {
            Effect->Initialize(ImpactColor,FMath::Clamp(Damage/80.0f,0.8f,2.2f),bCritical);
        }
        if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(
            AHonourWarDamagePopup::StaticClass(),GetActorLocation()+FVector(0,0,235),FRotator(0,180,0)))
        {
            const FLinearColor NumberColor=bCritical?FLinearColor(1.0f,0.12f,0.08f):HonourWarClassStyle(SourceClass).Accent;
            Popup->Initialize(Damage,NumberColor,bCritical);
        }
    }
}

void AHonourWarMonster::ReceiveCombatHit(float Damage,EHonourWarClass SourceClass,bool bCritical)
{
    if (bDead) return;

    const float Multiplier=
        SourceClass==EHonourWarClass::Mage ? 1.10f :
        SourceClass==EHonourWarClass::Archer ? 1.06f :
        SourceClass==EHonourWarClass::Ranger ? 1.08f : 1.0f;

    const float CriticalMultiplier=bCritical?1.40f:1.0f;
    const float FinalDamage=FMath::Max(0.0f,Damage*Multiplier*CriticalMultiplier);
    CurrentHealth=FMath::Max(0.0f,CurrentHealth-FinalDamage);
    PlayCombatReaction(true,bCritical,false,FinalDamage,SourceClass);

    if (CurrentHealth<=0.0f)
    {
        bDead=true;
        SetActorEnableCollision(false);
        Body->SetVisibility(false);
        Head->SetVisibility(false);
        LeftHorn->SetVisibility(false);
        RightHorn->SetVisibility(false);
        SetLifeSpan(1.0f);
    }
}
