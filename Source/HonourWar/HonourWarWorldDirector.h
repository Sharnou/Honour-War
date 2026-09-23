#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarTypes.h"
#include "HonourWarMonster.h"
#include "HonourWarWorldDirector.generated.h"

class UStaticMesh;
class UStaticMeshComponent;
class UMaterialInterface;
class UMaterialInstanceDynamic;
class USceneComponent;
class AHonourWarMonster;
class AHonourWarCharacter;

UCLASS()
class HONOURWAR_API AHonourWarWorldDirector : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarWorldDirector();

protected:
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

private:
    UPROPERTY() USceneComponent* Root;
    UPROPERTY() UStaticMesh* CubeMesh=nullptr;
    UPROPERTY() UStaticMesh* CylinderMesh=nullptr;
    UPROPERTY() UStaticMesh* SphereMesh=nullptr;
    UPROPERTY() UStaticMesh* ConeMesh=nullptr;
    UPROPERTY() UMaterialInterface* BaseMaterial=nullptr;

    struct FMonsterSlot
    {
        FVector Location=FVector::ZeroVector;
        int32 Level=1;
        FString Name;
        EHonourWarMonsterSpecies Species=EHonourWarMonsterSpecies::Goblin;
        TWeakObjectPtr<AHonourWarMonster> Active;
        float RespawnTimer=0.0f;
    };

    TArray<FMonsterSlot> MonsterSlots;
    void SpawnMonsterSlot(int32 SlotIndex);

    UStaticMeshComponent* AddPart(UStaticMesh* Mesh,const TCHAR* Name,const FVector& Location,const FVector& Scale,
        const FRotator& Rotation,const FLinearColor& Color,bool bCollision=false);
    UMaterialInstanceDynamic* MaterialFor(const FLinearColor& Color);

    void BuildLighting();
    void BuildGround();
    void BuildBiomeRegions();
    void BuildTownCenter();
    void BuildHouses();
    void BuildWalls();
    void BuildRoadFurniture();
    void BuildVegetation();
    void BuildDistantLandmarks();
    void SpawnMonsters();

    void BuildHouse(const FVector& Center,float Yaw,const FLinearColor& WallColor,const FLinearColor& RoofColor);
    void BuildTree(const FVector& Center,float Scale,int32 Variant);
    void BuildLamp(const FVector& Center);
    void BuildBanner(const FVector& Center,float Yaw,const FLinearColor& ClothColor);
    void BuildFence(const FVector& Center,float Yaw,float Length);
    void BuildRock(const FVector& Center,float Scale);
    void BuildDungeonGate(const FVector& Center);
    void BuildRiverBridge(const FVector& Center);
};
