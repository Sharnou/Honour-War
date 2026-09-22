#include "HonourWarWorldDirector.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Components/SkyAtmosphereComponent.h"
#include "Components/ExponentialHeightFogComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
void ApplyColor(UStaticMeshComponent* C,const FLinearColor& Color,UMaterialInterface* Base,UObject* Outer)
{
    if(!C||!Base)return;
    if(UMaterialInstanceDynamic* MID=UMaterialInstanceDynamic::Create(Base,Outer))
    {
        MID->SetVectorParameterValue(TEXT("Color"),Color);
        MID->SetScalarParameterValue(TEXT("Roughness"),0.72f);
        C->SetMaterial(0,MID);
    }
}
}

AHonourWarWorldDirector::AHonourWarWorldDirector()
{
    PrimaryActorTick.bCanEverTick=true;
    Root=CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    RootComponent=Root;
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Cube(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Cylinder(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Sphere(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Cone(TEXT("/Engine/BasicShapes/Cone.Cone"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> Material(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
    CubeMesh=Cube.Object; CylinderMesh=Cylinder.Object; SphereMesh=Sphere.Object; ConeMesh=Cone.Object; BaseMaterial=Material.Object;
}

void AHonourWarWorldDirector::BeginPlay()
{
    Super::BeginPlay();
    BuildLighting(); BuildGround(); BuildBiomeRegions(); BuildTownCenter(); BuildHouses(); BuildWalls();
    BuildRoadFurniture(); BuildVegetation(); BuildDistantLandmarks(); SpawnMonsters();
}

void AHonourWarWorldDirector::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    for(FMonsterSlot& Slot:MonsterSlots)
        if(!Slot.Active.IsValid() && Slot.RespawnTimer>0.0f) Slot.RespawnTimer=FMath::Max(0.0f,Slot.RespawnTimer-DeltaSeconds);
}

UMaterialInstanceDynamic* AHonourWarWorldDirector::MaterialFor(const FLinearColor& Color)
{
    if(!BaseMaterial)return nullptr;
    UMaterialInstanceDynamic* MID=UMaterialInstanceDynamic::Create(BaseMaterial,this);
    if(MID){MID->SetVectorParameterValue(TEXT("Color"),Color);MID->SetScalarParameterValue(TEXT("Roughness"),0.72f);} return MID;
}

UStaticMeshComponent* AHonourWarWorldDirector::AddPart(UStaticMesh* Mesh,const TCHAR* Name,const FVector& Location,const FVector& Scale,const FRotator& Rotation,const FLinearColor& Color,bool bCollision)
{
    if(!Mesh)return nullptr;
    UStaticMeshComponent* Part=NewObject<UStaticMeshComponent>(this,FName(Name)); AddInstanceComponent(Part); Part->SetStaticMesh(Mesh);
    Part->SetCollisionEnabled(bCollision?ECollisionEnabled::QueryAndPhysics:ECollisionEnabled::NoCollision); Part->SetMobility(EComponentMobility::Static);
    Part->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform); Part->SetRelativeLocation(Location); Part->SetRelativeRotation(Rotation); Part->SetRelativeScale3D(Scale); ApplyColor(Part,Color,BaseMaterial,this); Part->RegisterComponent(); return Part;
}

void AHonourWarWorldDirector::BuildLighting()
{
    UDirectionalLightComponent* Sun=NewObject<UDirectionalLightComponent>(this,TEXT("Sun")); AddInstanceComponent(Sun); Sun->SetMobility(EComponentMobility::Movable); Sun->SetIntensity(8.0f); Sun->SetLightColor(FLinearColor(1.0f,0.92f,0.80f)); Sun->SetRelativeRotation(FRotator(-50,-35,0)); Sun->CastShadows=true; Sun->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform); Sun->RegisterComponent();
    USkyLightComponent* Sky=NewObject<USkyLightComponent>(this,TEXT("SkyLight")); AddInstanceComponent(Sky); Sky->SetMobility(EComponentMobility::Movable); Sky->SourceType=ESkyLightSourceType::SLS_CapturedScene; Sky->Intensity=1.55f; Sky->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform); Sky->RegisterComponent();
    USkyAtmosphereComponent* Atmosphere=NewObject<USkyAtmosphereComponent>(this,TEXT("SkyAtmosphere")); AddInstanceComponent(Atmosphere); Atmosphere->SetMobility(EComponentMobility::Static); Atmosphere->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform); Atmosphere->RegisterComponent();
    UExponentialHeightFogComponent* Fog=NewObject<UExponentialHeightFogComponent>(this,TEXT("WorldFog")); AddInstanceComponent(Fog); Fog->SetMobility(EComponentMobility::Movable); Fog->FogDensity=0.004f; Fog->FogHeightFalloff=0.22f; Fog->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform); Fog->RegisterComponent();
}

void AHonourWarWorldDirector::BuildGround()
{
    AddPart(CubeMesh,TEXT("TerrainBase"),FVector(0,0,-75),FVector(145,145,0.75f),FRotator::ZeroRotator,FLinearColor(0.16f,0.29f,0.12f),true);
    AddPart(CubeMesh,TEXT("TownRoadX"),FVector(0,0,6),FVector(145,4.5f,0.08f),FRotator::ZeroRotator,FLinearColor(0.47f,0.36f,0.25f));
    AddPart(CubeMesh,TEXT("TownRoadY"),FVector(0,0,8),FVector(4.5f,145,0.08f),FRotator::ZeroRotator,FLinearColor(0.47f,0.36f,0.25f));
}

void AHonourWarWorldDirector::BuildBiomeRegions()
{
    AddPart(CubeMesh,TEXT("ForestRegion"),FVector(5200,2500,-6),FVector(26,18,0.08f),FRotator::ZeroRotator,FLinearColor(0.11f,0.28f,0.10f));
    AddPart(CubeMesh,TEXT("MountainRegion"),FVector(2700,6100,40),FVector(26,6,0.34f),FRotator(0,7,0),FLinearColor(0.29f,0.31f,0.28f));
    AddPart(CubeMesh,TEXT("DesertRegion"),FVector(-4800,-5000,-1),FVector(29,13,0.09f),FRotator::ZeroRotator,FLinearColor(0.72f,0.56f,0.31f));
    AddPart(CubeMesh,TEXT("SnowRegion"),FVector(-6500,2200,2),FVector(16,20,0.10f),FRotator::ZeroRotator,FLinearColor(0.80f,0.84f,0.88f));
    BuildDungeonGate(FVector(0,-5200,0)); BuildRiverBridge(FVector(3000,0,0));
    for(int32 I=0;I<8;++I){BuildRock(FVector(2600+I*520,5200+(I%3)*280,0),1.2f+(I%2)*0.25f);BuildRock(FVector(-5200+(I%3)*300,-4100-I*300,0),1.0f+(I%3)*0.18f);}
}

void AHonourWarWorldDirector::BuildTownCenter(){AddPart(CylinderMesh,TEXT("StonePlaza"),FVector(0,0,20),FVector(23,23,0.36f),FRotator::ZeroRotator,FLinearColor(0.55f,0.56f,0.54f),true);AddPart(CylinderMesh,TEXT("FountainBase"),FVector(0,0,48),FVector(8.2f,8.2f,0.48f),FRotator::ZeroRotator,FLinearColor(0.34f,0.37f,0.39f));AddPart(SphereMesh,TEXT("FountainWater"),FVector(0,0,82),FVector(3.5f,3.5f,0.25f),FRotator::ZeroRotator,FLinearColor(0.12f,0.42f,0.80f));}
void AHonourWarWorldDirector::BuildHouses(){BuildHouse(FVector(850,650,0),0,FLinearColor(0.55f,0.38f,0.22f),FLinearColor(0.30f,0.16f,0.08f));BuildHouse(FVector(-850,650,0),0,FLinearColor(0.60f,0.48f,0.30f),FLinearColor(0.26f,0.13f,0.07f));BuildHouse(FVector(850,-650,0),180,FLinearColor(0.48f,0.34f,0.22f),FLinearColor(0.32f,0.17f,0.08f));BuildHouse(FVector(-850,-650,0),180,FLinearColor(0.58f,0.42f,0.27f),FLinearColor(0.28f,0.15f,0.08f));}
void AHonourWarWorldDirector::BuildWalls(){AddPart(CubeMesh,TEXT("TownWallNorth"),FVector(0,2100,300),FVector(42,0.45f,3),FRotator::ZeroRotator,FLinearColor(0.31f,0.32f,0.31f),true);AddPart(CubeMesh,TEXT("TownWallSouth"),FVector(0,-2100,300),FVector(42,0.45f,3),FRotator::ZeroRotator,FLinearColor(0.31f,0.32f,0.31f),true);AddPart(CubeMesh,TEXT("TownWallEast"),FVector(2100,0,300),FVector(0.45f,42,3),FRotator::ZeroRotator,FLinearColor(0.31f,0.32f,0.31f),true);AddPart(CubeMesh,TEXT("TownWallWest"),FVector(-2100,0,300),FVector(0.45f,42,3),FRotator::ZeroRotator,FLinearColor(0.31f,0.32f,0.31f),true);}
void AHonourWarWorldDirector::BuildRoadFurniture(){BuildLamp(FVector(520,260,0));BuildLamp(FVector(-520,260,0));BuildLamp(FVector(520,-260,0));BuildLamp(FVector(-520,-260,0));BuildBanner(FVector(0,980,0),0,FLinearColor(0.72f,0.10f,0.08f));}
void AHonourWarWorldDirector::BuildVegetation(){const FVector Trees[]={FVector(3600,2300,0),FVector(4300,2800,0),FVector(5000,3200,0),FVector(5700,2500,0),FVector(6200,3400,0),FVector(4500,3600,0)};int32 I=0;for(const FVector& P:Trees)BuildTree(P,1.0f+(I++%3)*0.15f,I%2);}
void AHonourWarWorldDirector::BuildDistantLandmarks(){AddPart(CylinderMesh,TEXT("DistantLandmark"),FVector(5000,6000,900),FVector(4,4,12),FRotator::ZeroRotator,FLinearColor(0.25f,0.27f,0.30f));}
void AHonourWarWorldDirector::BuildHouse(const FVector& C,float Yaw,const FLinearColor& Wall,const FLinearColor& Roof){AddPart(CubeMesh,TEXT("HouseBody"),C+FVector(0,0,260),FVector(4.5f,3.5f,2.6f),FRotator(0,Yaw,0),Wall,true);AddPart(ConeMesh,TEXT("HouseRoof"),C+FVector(0,0,620),FVector(5.2f,4.2f,2),FRotator(0,Yaw,0),Roof);}
void AHonourWarWorldDirector::BuildTree(const FVector& C,float Scale,int32 Variant){AddPart(CylinderMesh,TEXT("TreeTrunk"),C+FVector(0,0,300*Scale),FVector(0.65f*Scale,0.65f*Scale,3*Scale),FRotator::ZeroRotator,FLinearColor(0.27f,0.13f,0.06f));AddPart(SphereMesh,TEXT("TreeCrown"),C+FVector(0,0,780*Scale),FVector(2.5f*Scale,2.5f*Scale,2.5f*Scale),FRotator::ZeroRotator,Variant==0?FLinearColor(0.10f,0.34f,0.12f):FLinearColor(0.16f,0.42f,0.15f));}
void AHonourWarWorldDirector::BuildLamp(const FVector& C){AddPart(CylinderMesh,TEXT("LampPost"),C+FVector(0,0,280),FVector(0.22f,0.22f,2.8f),FRotator::ZeroRotator,FLinearColor(0.08f,0.08f,0.09f));AddPart(SphereMesh,TEXT("LampGlow"),C+FVector(0,0,600),FVector(0.5f,0.5f,0.5f),FRotator::ZeroRotator,FLinearColor(1.0f,0.70f,0.22f));}
void AHonourWarWorldDirector::BuildBanner(const FVector& C,float Yaw,const FLinearColor& Cloth){AddPart(CylinderMesh,TEXT("BannerPole"),C+FVector(0,0,360),FVector(0.16f,0.16f,3.6f),FRotator(0,Yaw,0),FLinearColor(0.18f,0.11f,0.06f));AddPart(CubeMesh,TEXT("BannerCloth"),C+FVector(0,0,620),FVector(1.5f,0.12f,1),FRotator(0,Yaw,0),Cloth);}
void AHonourWarWorldDirector::BuildFence(const FVector& C,float Yaw,float Length){AddPart(CubeMesh,TEXT("FenceRail"),C+FVector(0,0,150),FVector(Length,0.15f,0.15f),FRotator(0,Yaw,0),FLinearColor(0.35f,0.20f,0.09f));}
void AHonourWarWorldDirector::BuildRock(const FVector& C,float Scale){AddPart(CubeMesh,TEXT("Rock"),C+FVector(0,0,90*Scale),FVector(1.2f*Scale,1.0f*Scale,0.9f*Scale),FRotator(0,17,0),FLinearColor(0.28f,0.29f,0.27f));}
void AHonourWarWorldDirector::BuildDungeonGate(const FVector& C){AddPart(CubeMesh,TEXT("DungeonPillarL"),C+FVector(-920,0,500),FVector(2,5,5.5f),FRotator::ZeroRotator,FLinearColor(0.22f,0.23f,0.23f),true);AddPart(CubeMesh,TEXT("DungeonPillarR"),C+FVector(920,0,500),FVector(2,5,5.5f),FRotator::ZeroRotator,FLinearColor(0.22f,0.23f,0.23f),true);AddPart(CubeMesh,TEXT("DungeonLintel"),C+FVector(0,0,1060),FVector(20,5.2f,2),FRotator::ZeroRotator,FLinearColor(0.22f,0.23f,0.23f),true);AddPart(CubeMesh,TEXT("DungeonDoor"),C+FVector(0,-160,500),FVector(7,0.6f,5),FRotator::ZeroRotator,FLinearColor(0.10f,0.075f,0.055f));}
void AHonourWarWorldDirector::BuildRiverBridge(const FVector& C){AddPart(CubeMesh,TEXT("RiverWater"),C+FVector(0,0,8),FVector(5.5f,72,0.08f),FRotator::ZeroRotator,FLinearColor(0.12f,0.36f,0.62f));AddPart(CubeMesh,TEXT("BridgeDeck"),C+FVector(0,0,42),FVector(7,28,0.38f),FRotator::ZeroRotator,FLinearColor(0.30f,0.17f,0.075f),true);}
void AHonourWarWorldDirector::SpawnMonsters(){MonsterSlots.Reset();const FVector MonsterLocations[]={FVector(9200,9200,120),FVector(-9200,9200,120),FVector(9200,-9200,120),FVector(-9200,-9200,120),FVector(12000,0,120),FVector(-12000,0,120)};for(int32 I=0;I<UE_ARRAY_COUNT(MonsterLocations);++I){FMonsterSlot& Slot=MonsterSlots.AddDefaulted_GetRef();Slot.Location=MonsterLocations[I];if(FVector2D(Slot.Location.X,Slot.Location.Y).Size()<7800.0f){MonsterSlots.RemoveAt(MonsterSlots.Num()-1);continue;}Slot.Level=FMath::Clamp(20+I*20,1,300);Slot.Species=EHonourWarMonsterSpecies::Goblin;Slot.RespawnTimer=0.0f;}}
void AHonourWarWorldDirector::SpawnMonsterSlot(int32 SlotIndex){if(MonsterSlots.IsValidIndex(SlotIndex))MonsterSlots[SlotIndex].RespawnTimer=0.0f;}
