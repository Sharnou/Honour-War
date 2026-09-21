#include "HonourWarMonster.h"
#include "HonourWarCombatEffect.h"
#include "HonourWarDamagePopup.h"
#include "HonourWarCharacter.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
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

    Body->SetupAttachment(Root);
    Head->SetupAttachment(Root);
    LeftHorn->SetupAttachment(Root);
    RightHorn->SetupAttachment(Root);

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
    APawn* Player=UGameplayStatics::GetPlayerPawn(this,0);
    if (!Player) return;

    const FVector ToPlayer=Player->GetActorLocation()-GetActorLocation();
    const float Distance=ToPlayer.Size();

    if (Distance<1900.0f && Distance>280.0f)
    {
        const FVector Direction=ToPlayer.GetSafeNormal2D();
        AddActorWorldOffset(Direction*(260.0f*DeltaSeconds),true);
        if (!Direction.IsNearlyZero())
        {
            SetActorRotation(FMath::RInterpTo(GetActorRotation(),Direction.Rotation(),DeltaSeconds,8.0f));
        }
    }

    if (Distance<=330.0f && AttackTimer<=0.0f)
    {
        if (AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(Player))
            Character->ReceiveMonsterDamage(45.0f+Level*2.0f);
        AttackTimer=1.2f;
    }
}

void AHonourWarMonster::ReceiveCombatHit(float Damage,EHonourWarClass SourceClass)
{
    if (!HasAuthority() || bDead) return;

    const float Multiplier=
        SourceClass==EHonourWarClass::Mage ? 1.10f :
        SourceClass==EHonourWarClass::Archer ? 1.06f :
        SourceClass==EHonourWarClass::Ranger ? 1.08f : 1.0f;

    const float FinalDamage=FMath::Max(0.0f,Damage*Multiplier);
    CurrentHealth=FMath::Max(0.0f,CurrentHealth-FinalDamage);

    if(UWorld* World=GetWorld())
    {
        const FHonourWarClassStyle Style=HonourWarClassStyle(SourceClass);
        if(AHonourWarCombatEffect* Effect=World->SpawnActor<AHonourWarCombatEffect>(
            AHonourWarCombatEffect::StaticClass(),GetActorLocation()+FVector(0,0,130),FRotator::ZeroRotator))
        {
            Effect->Initialize(Style.Accent,FMath::Clamp(FinalDamage/80.0f,0.8f,2.2f),FinalDamage>=85.0f);
        }
        if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(
            AHonourWarDamagePopup::StaticClass(),GetActorLocation()+FVector(0,0,230),FRotator(0,180,0)))
        {
            Popup->Initialize(FinalDamage,Style.Accent,FinalDamage>=85.0f);
        }
    }

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
