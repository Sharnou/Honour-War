// Current HD MMORPG runtime pass: keep soldier support in the active Unreal build path.
#include "HonourWarSoldier.h"
#include "HonourWarCharacter.h"
#include "HonourWarMonster.h"
#include "HonourWarWorldDirector.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInstanceDynamic.h"

namespace
{
    UStaticMesh* Mesh(const TCHAR* Path)
    {
        return LoadObject<UStaticMesh>(nullptr,Path);
    }

    void Color(UStaticMeshComponent* Component,const FLinearColor& Value)
    {
        if (!Component) return;
        UMaterialInterface* Base=LoadObject<UMaterialInterface>(
            nullptr,TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        if (!Base) return;
        if (UMaterialInstanceDynamic* MID=UMaterialInstanceDynamic::Create(Base,Component))
        {
            MID->SetVectorParameterValue(TEXT("Color"),Value);
            MID->SetScalarParameterValue(TEXT("Roughness"),0.58f);
            Component->SetMaterial(0,MID);
        }
    }
}

AHonourWarSoldier::AHonourWarSoldier()
{
    PrimaryActorTick.bCanEverTick=true;
    bReplicates=true;

    Root=CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    RootComponent=Root;

    Body=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Body"));
    Head=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Head"));
    Weapon=CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Weapon"));

    Body->SetupAttachment(Root);
    Head->SetupAttachment(Root);
    Weapon->SetupAttachment(Root);

    Body->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Head->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Weapon->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    if (UStaticMesh* Sphere=Mesh(TEXT("/Engine/BasicShapes/Sphere.Sphere")))
    {
        Body->SetStaticMesh(Sphere);
        Head->SetStaticMesh(Sphere);
    }
    if (UStaticMesh* Cylinder=Mesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder")))
        Weapon->SetStaticMesh(Cylinder);
}

void AHonourWarSoldier::SetLevel(int32 NewLevel)
{
    Level=FMath::Clamp(NewLevel,1,50);
    MaxHealth=900.0f+Level*22.0f;
    CurrentHealth=MaxHealth;
    if (HasActorBegunPlay()) BuildVisual();
}

void AHonourWarSoldier::SetSoldierClass(EHonourWarClass NewClass)
{
    SoldierClass=NewClass;
    if (HasActorBegunPlay()) BuildVisual();
}

void AHonourWarSoldier::BeginPlay()
{
    Super::BeginPlay();
    SetLevel(Level);
    BuildVisual();
}

void AHonourWarSoldier::BuildVisual()
{
    const float Scale=0.78f+static_cast<float>(Level)/125.0f;
    Body->SetRelativeLocation(FVector(0,0,70));
    Body->SetRelativeScale3D(FVector(0.48f*Scale,0.38f*Scale,0.70f*Scale));
    Head->SetRelativeLocation(FVector(22,0,150));
    Head->SetRelativeScale3D(FVector(0.34f*Scale,0.31f*Scale,0.38f*Scale));
    Weapon->SetRelativeLocation(FVector(30,0,90));
    Weapon->SetRelativeScale3D(FVector(0.07f,0.07f,0.45f));

    const FHonourWarClassStyle Style=HonourWarClassStyle(SoldierClass);
    Color(Body,Style.Primary);
    Color(Head,Style.Accent);
    Color(Weapon,FLinearColor(0.72f,0.75f,0.80f));
}

AHonourWarMonster* AHonourWarSoldier::FindNearestMonster(float Range) const
{
    UWorld* World=GetWorld();
    if (!World) return nullptr;

    TArray<AActor*> Found;
    UGameplayStatics::GetAllActorsOfClass(World,AHonourWarMonster::StaticClass(),Found);

    AHonourWarMonster* Best=nullptr;
    float BestDistSq=FMath::Square(Range);
    const FVector Origin=GetActorLocation();

    for (AActor* Actor:Found)
    {
        AHonourWarMonster* Monster=Cast<AHonourWarMonster>(Actor);
        if (!Monster || Monster->IsDead()) continue;
        const float DistSq=FVector::DistSquared(Origin,Monster->GetActorLocation());
        if (DistSq<BestDistSq)
        {
            BestDistSq=DistSq;
            Best=Monster;
        }
    }
    return Best;
}

void AHonourWarSoldier::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (bDead) return;

    AttackTimer=FMath::Max(0.0f,AttackTimer-DeltaSeconds);
    APawn* Player=UGameplayStatics::GetPlayerPawn(this,0);
    if (!Player) return;

    AHonourWarMonster* Target=FindNearestMonster(1300.0f);
    if (!Target)
    {
        const FVector ToPlayer=Player->GetActorLocation()-GetActorLocation();
        if (ToPlayer.Size2D()>650.0f)
        {
            AddActorWorldOffset(ToPlayer.GetSafeNormal2D()*(220.0f*DeltaSeconds),true);
        }
        return;
    }

    const FVector ToTarget=Target->GetActorLocation()-GetActorLocation();
    const float Distance=ToTarget.Size2D();

    if (Distance>300.0f)
    {
        const FVector Direction=ToTarget.GetSafeNormal2D();
        AddActorWorldOffset(Direction*(250.0f*DeltaSeconds),true);
        if (!Direction.IsNearlyZero())
            SetActorRotation(FMath::RInterpTo(GetActorRotation(),Direction.Rotation(),DeltaSeconds,9.0f));
    }
    else if (AttackTimer<=0.0f)
    {
        const float SkillMultiplier=AutoSkillIndex==0 ? 1.0f : 1.35f;
        const float Damage=(18.0f+Level*2.4f)*SkillMultiplier;
        const bool WasDead=Target->IsDead();
        Target->ReceiveCombatHit(Damage,SoldierClass);
        if (!WasDead && Target->IsDead())
        {
            if (AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(Player))
                Character->HandleMonsterDefeat(Target->GetMonsterLevel());
        }
        AutoSkillIndex=(AutoSkillIndex+1)%2;
        AttackTimer=1.0f;
    }
}

void AHonourWarSoldier::ReceiveDamage(float Damage)
{
    if (bDead) return;
    CurrentHealth=FMath::Max(0.0f,CurrentHealth-FMath::Max(0.0f,Damage));
    if (CurrentHealth<=0.0f)
    {
        bDead=true;
        if (!bDeathRegistered)
        {
            bDeathRegistered=true;
            if (AHonourWarWorldDirector* Director=Cast<AHonourWarWorldDirector>(
                UGameplayStatics::GetActorOfClass(GetWorld(),AHonourWarWorldDirector::StaticClass())))
                Director->RegisterSoldierDeath();
        }
        SetActorEnableCollision(false);
        SetLifeSpan(0.2f);
    }
}
