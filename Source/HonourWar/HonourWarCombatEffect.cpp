#include "HonourWarCombatEffect.h"
#include "Components/StaticMeshComponent.h"
#include "Components/PointLightComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"

namespace
{
    UStaticMesh* Mesh(const TCHAR* Path){return LoadObject<UStaticMesh>(nullptr,Path);}
    void SetGlow(UStaticMeshComponent* C,const FLinearColor& Color)
    {
        if(!C) return;
        UMaterialInterface* Base=LoadObject<UMaterialInterface>(nullptr,TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        if(!Base) return;
        if(UMaterialInstanceDynamic* MID=UMaterialInstanceDynamic::Create(Base,C))
        {
            MID->SetVectorParameterValue(TEXT("Color"),Color);
            MID->SetScalarParameterValue(TEXT("Roughness"),0.18f);
            C->SetMaterial(0,MID);
        }
    }
}

AHonourWarCombatEffect::AHonourWarCombatEffect()
{
    PrimaryActorTick.bCanEverTick=true;
    SetLifeSpan(Life);
    Root=CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    RootComponent=Root;
    Core=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Core"));
    Halo=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Halo"));
    BurstL=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BurstL"));
    BurstR=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BurstR"));
    Light=CreateDefaultSubobject<UPointLightComponent>(TEXT("Light"));
    Core->SetupAttachment(Root);
    Halo->SetupAttachment(Root);
    BurstL->SetupAttachment(Root);
    BurstR->SetupAttachment(Root);
    Light->SetupAttachment(Root);
    Core->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Halo->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    BurstL->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    BurstR->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Light->SetMobility(EComponentMobility::Movable);
    Light->Intensity=1200.0f;
    Light->AttenuationRadius=420.0f;
}

void AHonourWarCombatEffect::BeginPlay()
{
    Super::BeginPlay();
    if(UStaticMesh* Sphere=Mesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"))) Core->SetStaticMesh(Sphere);
    if(UStaticMesh* Cylinder=Mesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"))) Halo->SetStaticMesh(Cylinder);
    if(UStaticMesh* Cube=Mesh(TEXT("/Engine/BasicShapes/Cube.Cube")))
    {
        BurstL->SetStaticMesh(Cube);
        BurstR->SetStaticMesh(Cube);
    }
}

void AHonourWarCombatEffect::Initialize(const FLinearColor& Color,float InStrength,bool InFinisher)
{
    Strength=FMath::Max(0.5f,InStrength);
    bFinisher=InFinisher;
    SetLifeSpan(bFinisher?0.55f:0.34f);
    Life=bFinisher?0.55f:0.34f;

    SetGlow(Core,Color);
    SetGlow(Halo,Color);
    SetGlow(BurstL,Color);
    SetGlow(BurstR,Color);
    Light->SetLightColor(Color);
    Light->SetIntensity(bFinisher?2600.0f:1200.0f);

    Core->SetRelativeScale3D(FVector(0.28f,0.28f,0.28f)*Strength);
    Halo->SetRelativeLocation(FVector(0,0,-16));
    Halo->SetRelativeScale3D(FVector(0.55f,0.55f,0.08f)*Strength);
    BurstL->SetRelativeLocation(FVector(0,-4,0));
    BurstR->SetRelativeLocation(FVector(0,4,0));
    BurstL->SetRelativeScale3D(FVector(0.06f,0.42f,0.06f)*Strength);
    BurstR->SetRelativeScale3D(FVector(0.06f,0.42f,0.06f)*Strength);
    BurstL->SetRelativeRotation(FRotator(0,0,25));
    BurstR->SetRelativeRotation(FRotator(0,0,-25));
}

void AHonourWarCombatEffect::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    Age+=DeltaSeconds;
    const float T=FMath::Clamp(Age/Life,0.0f,1.0f);
    const float Growth=1.0f+T*2.8f;
    Core->SetRelativeScale3D(FVector(0.28f,0.28f,0.28f)*Strength*Growth);
    Halo->SetRelativeScale3D(FVector(0.55f,0.55f,0.08f)*Strength*(0.8f+T*2.4f));
    BurstL->AddLocalRotation(FRotator(0,0,360.0f*DeltaSeconds));
    BurstR->AddLocalRotation(FRotator(0,0,-360.0f*DeltaSeconds));
    AddActorWorldOffset(FVector(0,0,(bFinisher?70.0f:45.0f)*DeltaSeconds));
    Light->SetIntensity(FMath::Lerp(bFinisher?2600.0f:1200.0f,0.0f,T));
}
