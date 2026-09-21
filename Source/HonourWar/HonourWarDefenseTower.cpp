#include "HonourWarDefenseTower.h"
#include "HonourWarMonster.h"
#include "HonourWarCombatEffect.h"
#include "Components/StaticMeshComponent.h"
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
            MID->SetScalarParameterValue(TEXT("Roughness"),0.30f);
            C->SetMaterial(0,MID);
        }
    }
}

AHonourWarDefenseTower::AHonourWarDefenseTower()
{
    PrimaryActorTick.bCanEverTick=true;
    bReplicates=true;
    Base=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Base"));
    Core=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Core"));
    Beacon=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Beacon"));
    RootComponent=Base;
    Core->SetupAttachment(Base);
    Beacon->SetupAttachment(Base);
    Base->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    Core->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Beacon->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if(UStaticMesh* Cube=Mesh(TEXT("/Engine/BasicShapes/Cube.Cube"))) Base->SetStaticMesh(Cube);
    if(UStaticMesh* Cylinder=Mesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"))) Core->SetStaticMesh(Cylinder);
    if(UStaticMesh* Sphere=Mesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"))) Beacon->SetStaticMesh(Sphere);
}

void AHonourWarDefenseTower::Initialize(int32 InLevel,EHonourWarClass InElementClass)
{
    Level=FMath::Clamp(InLevel,1,50);
    ElementClass=InElementClass;
    const FHonourWarClassStyle Style=HonourWarClassStyle(ElementClass);
    Base->SetRelativeScale3D(FVector(1.8f,1.8f,0.8f));
    Core->SetRelativeLocation(FVector(0,0,110));
    Core->SetRelativeScale3D(FVector(0.55f,0.55f,1.1f));
    Beacon->SetRelativeLocation(FVector(0,0,240));
    Beacon->SetRelativeScale3D(FVector(0.30f,0.30f,0.30f));
    Color(Base,Style.Secondary);
    Color(Core,Style.Primary);
    Color(Beacon,Style.Accent);
}

void AHonourWarDefenseTower::BeginPlay()
{
    Super::BeginPlay();
    Initialize(Level,ElementClass);
}

AHonourWarMonster* AHonourWarDefenseTower::FindNearestMonster(float Range) const
{
    TArray<AActor*> Found;
    UGameplayStatics::GetAllActorsOfClass(GetWorld(),AHonourWarMonster::StaticClass(),Found);
    AHonourWarMonster* Best=nullptr;
    float BestDistSq=FMath::Square(Range);
    for(AActor* Actor:Found)
    {
        AHonourWarMonster* Monster=Cast<AHonourWarMonster>(Actor);
        if(!Monster || Monster->IsDead()) continue;
        const float DistSq=FVector::DistSquared(GetActorLocation(),Monster->GetActorLocation());
        if(DistSq<BestDistSq){BestDistSq=DistSq;Best=Monster;}
    }
    return Best;
}

void AHonourWarDefenseTower::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if(!HasAuthority()) return;
    Cooldown=FMath::Max(0.0f,Cooldown-DeltaSeconds);
    if(Cooldown>0.0f) return;

    AHonourWarMonster* Target=FindNearestMonster(2400.0f);
    if(!Target) return;

    const float Damage=(24.0f+Level*3.0f)*(1.0f+static_cast<float>(static_cast<int32>(ElementClass))*0.015f);
    Target->ReceiveCombatHit(Damage,ElementClass);
    if(UWorld* World=GetWorld())
    {
        const FHonourWarClassStyle Style=HonourWarClassStyle(ElementClass);
        if(AHonourWarCombatEffect* Effect=World->SpawnActor<AHonourWarCombatEffect>(
            AHonourWarCombatEffect::StaticClass(),GetActorLocation()+FVector(0,0,150),FRotator::ZeroRotator))
        {
            Effect->Initialize(Style.Accent,FMath::Clamp(Damage/80.0f,0.8f,1.8f),Damage>=90.0f);
        }
    }
    Cooldown=1.25f;
}
