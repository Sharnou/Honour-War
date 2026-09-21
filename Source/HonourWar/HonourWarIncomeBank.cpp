#include "HonourWarIncomeBank.h"
#include "HonourWarMonster.h"
#include "HonourWarSoldier.h"
#include "HonourWarCharacter.h"
#include "HonourWarCombatComponent.h"
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
            MID->SetScalarParameterValue(TEXT("Roughness"),0.44f);
            C->SetMaterial(0,MID);
        }
    }
}

AHonourWarIncomeBank::AHonourWarIncomeBank()
{
    PrimaryActorTick.bCanEverTick=true;
    bReplicates=true;
    Base=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Base"));
    Core=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Core"));
    RootComponent=Base;
    Core->SetupAttachment(Base);
    Base->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    Core->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    if(UStaticMesh* Cube=Mesh(TEXT("/Engine/BasicShapes/Cube.Cube"))) Base->SetStaticMesh(Cube);
    if(UStaticMesh* Sphere=Mesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"))) Core->SetStaticMesh(Sphere);
}

void AHonourWarIncomeBank::InitializeBank(int32 InBankId,AHonourWarMonster* InGuardian)
{
    BankId=InBankId;
    Guardian=InGuardian;
    SetActorScale3D(FVector(2.5f,2.5f,0.65f));
    BuildVisual();
}

void AHonourWarIncomeBank::BeginPlay()
{
    Super::BeginPlay();
    BuildVisual();
}

void AHonourWarIncomeBank::BuildVisual()
{
    Color(Base,bUnlocked?FLinearColor(0.16f,0.42f,0.18f):FLinearColor(0.38f,0.14f,0.12f));
    Color(Core,bUnlocked?FLinearColor(0.95f,0.72f,0.20f):FLinearColor(0.45f,0.12f,0.10f));
    Core->SetRelativeLocation(FVector(0,0,95));
    Core->SetRelativeScale3D(FVector(0.35f,0.35f,0.35f));
}

bool AHonourWarIncomeBank::HasOccupyingSoldier() const
{
    UWorld* World=GetWorld();
    if(!World) return false;
    TArray<AActor*> Soldiers;
    UGameplayStatics::GetAllActorsOfClass(World,AHonourWarSoldier::StaticClass(),Soldiers);
    for(AActor* Actor:Soldiers)
    {
        AHonourWarSoldier* Soldier=Cast<AHonourWarSoldier>(Actor);
        if(Soldier && !Soldier->IsDead() && FVector::DistSquared(GetActorLocation(),Soldier->GetActorLocation())<=FMath::Square(500.0f))
            return true;
    }
    return false;
}

void AHonourWarIncomeBank::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if(!HasAuthority()) return;

    if(!bUnlocked && Guardian && Guardian->IsDead())
    {
        bUnlocked=true;
        BuildVisual();
    }
    if(!bUnlocked || !HasOccupyingSoldier()) return;

    IncomeAccumulator+=DeltaSeconds;
    if(IncomeAccumulator<1.0f) return;
    IncomeAccumulator=0.0f;

    TArray<AActor*> Players;
    UGameplayStatics::GetAllActorsOfClass(GetWorld(),AHonourWarCharacter::StaticClass(),Players);
    for(AActor* Actor:Players)
    {
        AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(Actor);
        if(!Character || FVector::DistSquared(GetActorLocation(),Character->GetActorLocation())>FMath::Square(2200.0f))
            continue;
        if(UHonourWarCombatComponent* Combat=Character->GetCombatComponent())
            Combat->AddZeny(ZenyPerSecond);
    }
}
