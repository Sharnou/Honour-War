#include "HonourWarBaseBuilding.h"
#include "HonourWarCharacter.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Engine/StaticMesh.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInstanceDynamic.h"

namespace
{
    UStaticMesh* Mesh(const TCHAR* Path){return LoadObject<UStaticMesh>(nullptr,Path);}
    void Color(UStaticMeshComponent* C,const FLinearColor& Value)
    {
        if(!C) return;
        UMaterialInterface* Base=LoadObject<UMaterialInterface>(nullptr,TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        if(!Base) return;
        if(UMaterialInstanceDynamic* MID=UMaterialInstanceDynamic::Create(Base,C))
        {
            MID->SetVectorParameterValue(TEXT("Color"),Value);
            MID->SetScalarParameterValue(TEXT("Roughness"),0.28f);
            C->SetMaterial(0,MID);
        }
    }
}

AHonourWarBaseBuilding::AHonourWarBaseBuilding()
{
    PrimaryActorTick.bCanEverTick=true;
    bReplicates=true;
    Base=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Base"));
    Core=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Core"));
    Ring=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Ring"));
    Label=CreateDefaultSubobject<UTextRenderComponent>(TEXT("Label"));
    RootComponent=Base;
    Core->SetupAttachment(Base);
    Ring->SetupAttachment(Base);
    Label->SetupAttachment(Base);
    Base->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    Core->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Ring->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Label->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if(UStaticMesh* Cube=Mesh(TEXT("/Engine/BasicShapes/Cube.Cube"))) Base->SetStaticMesh(Cube);
    if(UStaticMesh* Cylinder=Mesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"))) Core->SetStaticMesh(Cylinder);
    if(UStaticMesh* Sphere=Mesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"))) Ring->SetStaticMesh(Sphere);
    Label->SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
    Label->SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
    Label->SetWorldSize(30.0f);
    Label->SetRelativeLocation(FVector(0,0,350));
    Label->bAlwaysRenderAsText=true;
}

void AHonourWarBaseBuilding::InitializeBaseLevel(int32 NewLevel)
{
    BaseLevel=FMath::Clamp(NewLevel,0,1);
    BuildVisual();
}

void AHonourWarBaseBuilding::BeginPlay()
{
    Super::BeginPlay();
    BuildVisual();
}

void AHonourWarBaseBuilding::BuildVisual()
{
    const bool bUpgraded=BaseLevel>=1;
    Base->SetRelativeScale3D(bUpgraded?FVector(4.5f,4.5f,1.0f):FVector(3.8f,3.8f,0.8f));
    Core->SetRelativeLocation(FVector(0,0,bUpgraded?170.0f:120.0f));
    Core->SetRelativeScale3D(bUpgraded?FVector(0.95f,0.95f,1.4f):FVector(0.75f,0.75f,1.0f));
    Ring->SetRelativeLocation(FVector(0,0,26));
    Ring->SetRelativeScale3D(bUpgraded?FVector(2.8f,2.8f,0.12f):FVector(2.2f,2.2f,0.10f));
    Color(Base,FLinearColor(0.23f,0.19f,0.16f));
    Color(Core,bUpgraded?FLinearColor(0.15f,0.46f,0.85f):FLinearColor(0.20f,0.25f,0.30f));
    Color(Ring,bUpgraded?FLinearColor(0.30f,0.72f,1.00f):FLinearColor(0.28f,0.30f,0.32f));
    if(Label)
        Label->SetText(FText::FromString(bUpgraded?TEXT("BASE Lv.1  •  SIGHT ONLINE"):TEXT("BASE")));
}

void AHonourWarBaseBuilding::UpdateSightState()
{
    TArray<AActor*> Players;
    UGameplayStatics::GetAllActorsOfClass(GetWorld(),AHonourWarCharacter::StaticClass(),Players);
    for(AActor* Actor:Players)
    {
        AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(Actor);
        if(!Character) continue;
        const bool bInRadius=BaseLevel>=1 && FVector::DistSquared(GetActorLocation(),Character->GetActorLocation())<=FMath::Square(2200.0f);
        Character->SetBaseSightActive(bInRadius);
    }
}

void AHonourWarBaseBuilding::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if(!HasAuthority()) return;
    SightTimer+=DeltaSeconds;
    if(SightTimer>=0.25f)
    {
        SightTimer=0.0f;
        UpdateSightState();
    }
}
