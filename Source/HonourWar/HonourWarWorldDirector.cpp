#include "HonourWarWorldDirector.h"
#include "HonourWarMonster.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Components/SkyAtmosphereComponent.h"
#include "Components/ExponentialHeightFogComponent.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    UStaticMesh* FindMesh(const TCHAR* Path){ return LoadObject<UStaticMesh>(nullptr,Path); }

    void SetColor(UStaticMeshComponent* Component,const FLinearColor& Color,UMaterialInterface* Base, UObject* Outer)
    {
        if (!Component || !Base) return;
        if (UMaterialInstanceDynamic* MID=UMaterialInstanceDynamic::Create(Base,Outer))
        {
            MID->SetVectorParameterValue(TEXT("Color"),Color);
            MID->SetScalarParameterValue(TEXT("Roughness"),0.72f);
            Component->SetMaterial(0,MID);
        }
    }
}

AHonourWarWorldDirector::AHonourWarWorldDirector()
{
    PrimaryActorTick.bCanEverTick=false;
    Root=CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
    RootComponent=Root;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeFinder(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderFinder(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereFinder(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeFinder(TEXT("/Engine/BasicShapes/Cone.Cone"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> MaterialFinder(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));

    CubeMesh=CubeFinder.Object;
    CylinderMesh=CylinderFinder.Object;
    SphereMesh=SphereFinder.Object;
    ConeMesh=ConeFinder.Object;
    BaseMaterial=MaterialFinder.Object;
}

void AHonourWarWorldDirector::BeginPlay()
{
    Super::BeginPlay();
    BuildLighting();
    BuildGround();
    BuildBiomeRegions();
    BuildTownCenter();
    BuildHouses();
    BuildWalls();
    BuildMarket();
    BuildTownServices();
    BuildRoadFurniture();
    BuildVegetation();
    BuildDistantLandmarks();
    SpawnMonsters();
}

UMaterialInstanceDynamic* AHonourWarWorldDirector::MaterialFor(const FLinearColor& Color)
{
    if (!BaseMaterial) return nullptr;
    UMaterialInstanceDynamic* MID=UMaterialInstanceDynamic::Create(BaseMaterial,this);
    if (MID)
    {
        MID->SetVectorParameterValue(TEXT("Color"),Color);
        MID->SetScalarParameterValue(TEXT("Roughness"),0.72f);
    }
    return MID;
}

UStaticMeshComponent* AHonourWarWorldDirector::AddPart(UStaticMesh* Mesh,const TCHAR* Name,const FVector& Location,
    const FVector& Scale,const FRotator& Rotation,const FLinearColor& Color,bool bCollision)
{
    if (!Mesh) return nullptr;
    UStaticMeshComponent* Part=NewObject<UStaticMeshComponent>(this,FName(Name));
    AddInstanceComponent(Part);
    Part->SetStaticMesh(Mesh);
    Part->SetCollisionEnabled(bCollision?ECollisionEnabled::QueryAndPhysics:ECollisionEnabled::NoCollision);
    Part->SetMobility(EComponentMobility::Static);
    Part->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform);
    Part->SetRelativeLocation(Location);
    Part->SetRelativeRotation(Rotation);
    Part->SetRelativeScale3D(Scale);
    SetColor(Part,Color,BaseMaterial,this);
    Part->RegisterComponent();
    return Part;
}

void AHonourWarWorldDirector::BuildLighting()
{
    UDirectionalLightComponent* Sun=NewObject<UDirectionalLightComponent>(this,TEXT("Sun"));
    AddInstanceComponent(Sun);
    Sun->SetMobility(EComponentMobility::Movable);
    Sun->SetIntensity(8.0f);
    Sun->SetLightColor(FLinearColor(1.0f,0.92f,0.80f));
    Sun->SetRelativeRotation(FRotator(-50.0f,-35.0f,0.0f));
    Sun->CastShadows=true;
    Sun->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform);
    Sun->RegisterComponent();

    USkyLightComponent* Sky=NewObject<USkyLightComponent>(this,TEXT("SkyLight"));
    AddInstanceComponent(Sky);
    Sky->SetMobility(EComponentMobility::Movable);
    Sky->SourceType=ESkyLightSourceType::SLS_CapturedScene;
    Sky->Intensity=1.55f;
    Sky->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform);
    Sky->RegisterComponent();

    USkyAtmosphereComponent* Atmosphere=NewObject<USkyAtmosphereComponent>(this,TEXT("SkyAtmosphere"));
    AddInstanceComponent(Atmosphere);
    Atmosphere->SetMobility(EComponentMobility::Static);
    Atmosphere->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform);
    Atmosphere->RegisterComponent();

    UExponentialHeightFogComponent* Fog=NewObject<UExponentialHeightFogComponent>(this,TEXT("WorldFog"));
    AddInstanceComponent(Fog);
    Fog->SetMobility(EComponentMobility::Movable);
    Fog->FogDensity=0.004f;
    Fog->FogHeightFalloff=0.22f;
    Fog->FogInscatteringColor=FLinearColor(0.62f,0.70f,0.80f);
    Fog->AttachToComponent(RootComponent,FAttachmentTransformRules::KeepRelativeTransform);
    Fog->RegisterComponent();
}

void AHonourWarWorldDirector::BuildGround()
{
    AddPart(CubeMesh,TEXT("TerrainBase"),FVector(0,0,-75),FVector(145,145,0.75f),FRotator::ZeroRotator,FLinearColor(0.16f,0.29f,0.12f),true);

    AddPart(CubeMesh,TEXT("TownRoadX"),FVector(0,0,6),FVector(145,4.5f,0.08f),FRotator::ZeroRotator,FLinearColor(0.47f,0.36f,0.25f));
    AddPart(CubeMesh,TEXT("TownRoadY"),FVector(0,0,8),FVector(4.5f,145,0.08f),FRotator::ZeroRotator,FLinearColor(0.47f,0.36f,0.25f));
    AddPart(CubeMesh,TEXT("RoadShoulderX"),FVector(0,6,11),FVector(145,0.35f,0.06f),FRotator::ZeroRotator,FLinearColor(0.64f,0.53f,0.37f));
    AddPart(CubeMesh,TEXT("RoadShoulderY"),FVector(6,0,12),FVector(0.35f,145,0.06f),FRotator::ZeroRotator,FLinearColor(0.64f,0.53f,0.37f));

    for (int32 I=-7;I<=7;++I)
    {
        const float P=I*1450.0f;
        AddPart(CubeMesh,TEXT("CrossRoadX"),FVector(P,0,14),FVector(0.40f,24.0f,0.05f),FRotator::ZeroRotator,FLinearColor(0.59f,0.48f,0.33f));
        AddPart(CubeMesh,TEXT("CrossRoadY"),FVector(0,P,15),FVector(24.0f,0.40f,0.05f),FRotator::ZeroRotator,FLinearColor(0.59f,0.48f,0.33f));
    }
}


void AHonourWarWorldDirector::BuildRiverBridge(const FVector& Center)
{
    const FLinearColor Water(0.12f,0.36f,0.62f);
    const FLinearColor Stone(0.48f,0.48f,0.44f);
    AddPart(CubeMesh,TEXT("RiverWater"),Center+FVector(0,0,8),FVector(5.5f,72.0f,0.08f),FRotator::ZeroRotator,Water);
    AddPart(CubeMesh,TEXT("BridgeDeck"),Center+FVector(0,0,42),FVector(7.0f,28.0f,0.38f),FRotator::ZeroRotator,FLinearColor(0.30f,0.17f,0.075f),true);
    for(int32 I=-6;I<=6;++I)
    {
        AddPart(CubeMesh,TEXT("BridgePlank"),Center+FVector(0,I*210.0f,80),
            FVector(6.4f,0.12f,0.22f),FRotator::ZeroRotator,FLinearColor(0.42f,0.24f,0.10f));
    }
    AddPart(CubeMesh,TEXT("BridgeRailL"),Center+FVector(-640,0,170),FVector(0.22f,28.0f,1.15f),FRotator::ZeroRotator,Stone);
    AddPart(CubeMesh,TEXT("BridgeRailR"),Center+FVector(640,0,170),FVector(0.22f,28.0f,1.15f),FRotator::ZeroRotator,Stone);
}

void AHonourWarWorldDirector::BuildShrine(const FVector& Center,float Scale)
{
    const FLinearColor Stone(0.58f,0.57f,0.52f);
    const FLinearColor Gold(0.74f,0.54f,0.18f);
    AddPart(CylinderMesh,TEXT("ShrineBase"),Center+FVector(0,0,55*Scale),FVector(7.0f*Scale,7.0f*Scale,0.38f*Scale),FRotator::ZeroRotator,Stone);
    AddPart(CubeMesh,TEXT("ShrinePillarL"),Center+FVector(-240*Scale,0,290*Scale),FVector(0.75f*Scale,1.2f*Scale,2.8f*Scale),FRotator::ZeroRotator,Stone);
    AddPart(CubeMesh,TEXT("ShrinePillarR"),Center+FVector(240*Scale,0,290*Scale),FVector(0.75f*Scale,1.2f*Scale,2.8f*Scale),FRotator::ZeroRotator,Stone);
    AddPart(ConeMesh,TEXT("ShrineRoof"),Center+FVector(0,0,660*Scale),FVector(4.8f*Scale,5.4f*Scale,2.2f*Scale),FRotator::ZeroRotator,FLinearColor(0.20f,0.28f,0.30f));
    AddPart(SphereMesh,TEXT("ShrineRelic"),Center+FVector(0,0,390*Scale),FVector(1.05f*Scale,1.05f*Scale,1.05f*Scale),FRotator::ZeroRotator,Gold);
}

void AHonourWarWorldDirector::BuildDungeonGate(const FVector& Center)
{
    const FLinearColor Stone(0.22f,0.23f,0.23f);
    const FLinearColor Iron(0.10f,0.075f,0.055f);
    AddPart(CubeMesh,TEXT("DungeonPillarL"),Center+FVector(-920,0,500),FVector(2.0f,5.0f,5.5f),FRotator::ZeroRotator,Stone,true);
    AddPart(CubeMesh,TEXT("DungeonPillarR"),Center+FVector(920,0,500),FVector(2.0f,5.0f,5.5f),FRotator::ZeroRotator,Stone,true);
    AddPart(CubeMesh,TEXT("DungeonLintel"),Center+FVector(0,0,1060),FVector(20.0f,5.2f,2.0f),FRotator::ZeroRotator,Stone,true);
    AddPart(CubeMesh,TEXT("DungeonDoor"),Center+FVector(0,-160,500),FVector(7.0f,0.6f,5.0f),FRotator::ZeroRotator,Iron);
    AddPart(SphereMesh,TEXT("DungeonTorchL"),Center+FVector(-760,-260,710),FVector(0.55f,0.55f,0.55f),FRotator::ZeroRotator,FLinearColor(1.0f,0.46f,0.16f));
    AddPart(SphereMesh,TEXT("DungeonTorchR"),Center+FVector(760,-260,710),FVector(0.55f,0.55f,0.55f),FRotator::ZeroRotator,FLinearColor(1.0f,0.46f,0.16f));
}

void AHonourWarWorldDirector::BuildBiomeRegions()
{
    AddPart(CubeMesh,TEXT("ForestRegion"),FVector(5200,2500,-6),FVector(26,18,0.08f),FRotator::ZeroRotator,FLinearColor(0.11f,0.28f,0.10f));
    AddPart(CubeMesh,TEXT("MountainRegion"),FVector(2700,6100,40),FVector(26,6,0.34f),FRotator(0,7,0),FLinearColor(0.29f,0.31f,0.28f));
    AddPart(CubeMesh,TEXT("DesertRegion"),FVector(-4800,-5000,-1),FVector(29,13,0.09f),FRotator::ZeroRotator,FLinearColor(0.72f,0.56f,0.31f));
    AddPart(CubeMesh,TEXT("SnowRegion"),FVector(-6500,2200,2),FVector(16,20,0.10f),FRotator::ZeroRotator,FLinearColor(0.80f,0.84f,0.88f));
    AddPart(CubeMesh,TEXT("DungeonApproach"),FVector(0,-5200,5),FVector(12,7,0.11f),FRotator::ZeroRotator,FLinearColor(0.19f,0.18f,0.17f));

    for(int32 I=0;I<8;++I)
    {
        BuildRock(FVector(2600+I*520,5200+(I%3)*280,0),1.2f+(I%2)*0.25f);
        BuildRock(FVector(-5200+(I%3)*300,-4100-I*300,0),1.0f+(I%3)*0.18f);
    }

    const FVector ForestTrees[]={
        FVector(5000,2700,0),FVector(5400,3000,0),FVector(5800,2500,0),
        FVector(5200,3500,0),FVector(6100,3300,0),FVector(4700,3400,0),
        FVector(6000,2000,0),FVector(4550,2200,0)
    };
    int32 I=0;
    for(const FVector& P:ForestTrees)
    {
        BuildTree(P,1.05f+(I%3)*0.12f,I%2);
        ++I;
    }

    for(int32 K=0;K<7;++K)
    {
        const FVector Desert=(-4800.0f+K*650.0f,-4950.0f-(K%2)*420.0f,0);
        AddPart(CubeMesh,TEXT("DesertPillar"),Desert+FVector(0,0,330),FVector(1.8f,1.8f,3.8f),FRotator(0,K*11.0f,0),FLinearColor(0.46f,0.34f,0.18f));
        AddPart(ConeMesh,TEXT("DesertCap"),Desert+FVector(0,0,720),FVector(2.6f,2.6f,0.75f),FRotator(0,0,0),FLinearColor(0.60f,0.45f,0.24f));
    }

    BuildShrine(FVector(-6500,2200,0),1.05f);
    BuildDungeonGate(FVector(0,-5200,0));
    BuildRiverBridge(FVector(3000,0,0));
    AddPart(CubeMesh,TEXT("RiverBankL"),FVector(3000,-1050,12),FVector(7.5f,4.8f,0.08f),FRotator::ZeroRotator,FLinearColor(0.56f,0.46f,0.30f));
    AddPart(CubeMesh,TEXT("RiverBankR"),FVector(3000,1050,12),FVector(7.5f,4.8f,0.08f),FRotator::ZeroRotator,FLinearColor(0.56f,0.46f,0.30f));
}

void AHonourWarWorldDirector::BuildTownCenter()
{
    AddPart(CylinderMesh,TEXT("StonePlaza"),FVector(0,0,20),FVector(23,23,0.36f),FRotator::ZeroRotator,FLinearColor(0.55f,0.56f,0.54f));

    AddPart(CylinderMesh,TEXT("FountainBase"),FVector(0,0,48),FVector(8.2f,8.2f,0.48f),FRotator::ZeroRotator,FLinearColor(0.34f,0.37f,0.39f));
    AddPart(CylinderMesh,TEXT("FountainBasin"),FVector(0,0,74),FVector(6.4f,6.4f,0.18f),FRotator::ZeroRotator,FLinearColor(0.20f,0.46f,0.78f));
    AddPart(CylinderMesh,TEXT("FountainColumn"),FVector(0,0,155),FVector(1.5f,1.5f,2.2f),FRotator::ZeroRotator,FLinearColor(0.66f,0.66f,0.61f));
    AddPart(SphereMesh,TEXT("FountainOrb"),FVector(0,0,270),FVector(0.95f,0.95f,0.95f),FRotator::ZeroRotator,FLinearColor(0.60f,0.86f,1.00f));

    const FVector BenchPositions[]={
        FVector(420,980,0),FVector(-420,-980,0),FVector(980,-420,0),FVector(-980,420,0)
    };
    for (const FVector& P:BenchPositions)
    {
        AddPart(CubeMesh,TEXT("BenchSeat"),P+FVector(0,0,72),FVector(3.4f,0.42f,0.26f),FRotator::ZeroRotator,FLinearColor(0.30f,0.14f,0.05f));
        AddPart(CubeMesh,TEXT("BenchBack"),P+FVector(-65,0,150),FVector(0.28f,0.42f,0.62f),FRotator::ZeroRotator,FLinearColor(0.30f,0.14f,0.05f));
    }
}

void AHonourWarWorldDirector::BuildHouse(const FVector& Center,float Yaw,const FLinearColor& WallColor,const FLinearColor& RoofColor)
{
    const FRotator R(0,Yaw,0);
    const FVector SideA=R.RotateVector(FVector(0,-620,0));
    const FVector SideB=R.RotateVector(FVector(0,620,0));
    const FVector Front=R.RotateVector(FVector(720,0,0));

    AddPart(CubeMesh,TEXT("HouseBody"),Center+R.RotateVector(FVector(0,0,190)),FVector(19,15,3.8f),R,WallColor,true);
    AddPart(CubeMesh,TEXT("HouseLowerTrim"),Center+R.RotateVector(FVector(0,0,74)),FVector(20,15.6f,0.32f),R,FLinearColor(0.24f,0.13f,0.07f));
    AddPart(CubeMesh,TEXT("HouseRoofL"),Center+SideA+R.RotateVector(FVector(0,0,545)),FVector(20,7.9f,0.40f),R+FRotator(0,0,26),RoofColor);
    AddPart(CubeMesh,TEXT("HouseRoofR"),Center+SideB+R.RotateVector(FVector(0,0,545)),FVector(20,7.9f,0.40f),R+FRotator(0,0,-26),RoofColor);

    AddPart(CubeMesh,TEXT("Door"),Center+Front+FVector(0,0,150),FVector(2.5f,0.60f,3.0f),R,FLinearColor(0.16f,0.075f,0.028f));
    AddPart(CubeMesh,TEXT("DoorFrameTop"),Center+Front+FVector(0,0,315),FVector(3.1f,0.30f,0.26f),R,FLinearColor(0.24f,0.13f,0.06f));

    const FLinearColor Glass(0.16f,0.34f,0.50f);
    for (int32 S=-1;S<=1;S+=2)
    {
        AddPart(CubeMesh,TEXT("Window"),Center+R.RotateVector(FVector(675,S*370,270)),
            FVector(2.2f,0.30f,1.70f),R,Glass);
        AddPart(CubeMesh,TEXT("WindowFrameV"),Center+R.RotateVector(FVector(680,S*370,270)),
            FVector(2.25f,0.12f,1.80f),R,FLinearColor(0.18f,0.10f,0.05f));
    }

    for (int32 I=-2;I<=2;++I)
    {
        AddPart(CubeMesh,TEXT("Timber"),Center+R.RotateVector(FVector(720,I*280.0f,175)),
            FVector(0.34f,0.30f,3.15f),R,FLinearColor(0.18f,0.09f,0.035f));
    }

    AddPart(ConeMesh,TEXT("Chimney"),Center+R.RotateVector(FVector(-260,0,650)),FVector(2.0f,2.0f,1.8f),R,FLinearColor(0.34f,0.24f,0.20f));
}

void AHonourWarWorldDirector::BuildHouses()
{
    const struct FHouse { FVector P; float Y; FLinearColor W; FLinearColor R; } Houses[]={
        {FVector(3900,1900,0),0,FLinearColor(0.58f,0.39f,0.25f),FLinearColor(0.50f,0.17f,0.12f)},
        {FVector(3900,-1900,0),180,FLinearColor(0.64f,0.44f,0.28f),FLinearColor(0.24f,0.20f,0.15f)},
        {FVector(-3900,1900,0),0,FLinearColor(0.46f,0.39f,0.31f),FLinearColor(0.20f,0.17f,0.14f)},
        {FVector(-3900,-1900,0),180,FLinearColor(0.52f,0.36f,0.25f),FLinearColor(0.45f,0.15f,0.11f)},
        {FVector(1900,3900,0),90,FLinearColor(0.60f,0.49f,0.33f),FLinearColor(0.26f,0.16f,0.09f)},
        {FVector(-1900,3900,0),90,FLinearColor(0.45f,0.38f,0.30f),FLinearColor(0.20f,0.15f,0.12f)},
        {FVector(1900,-3900,0),-90,FLinearColor(0.56f,0.41f,0.27f),FLinearColor(0.45f,0.17f,0.11f)},
        {FVector(-1900,-3900,0),-90,FLinearColor(0.64f,0.50f,0.34f),FLinearColor(0.25f,0.20f,0.14f)}
    };
    for (const FHouse& H:Houses) BuildHouse(H.P,H.Y,H.W,H.R);
}

void AHonourWarWorldDirector::BuildWalls()
{
    const FLinearColor Stone(0.35f,0.36f,0.36f);
    const FLinearColor DarkStone(0.26f,0.28f,0.28f);

    AddPart(CubeMesh,TEXT("NorthWall"),FVector(0,6200,300),FVector(124,1.8f,4.8f),FRotator::ZeroRotator,Stone,true);
    AddPart(CubeMesh,TEXT("SouthWall"),FVector(0,-6200,300),FVector(124,1.8f,4.8f),FRotator::ZeroRotator,Stone,true);
    AddPart(CubeMesh,TEXT("EastWall"),FVector(6200,0,300),FVector(1.8f,124,4.8f),FRotator::ZeroRotator,Stone,true);
    AddPart(CubeMesh,TEXT("WestWall"),FVector(-6200,0,300),FVector(1.8f,124,4.8f),FRotator::ZeroRotator,Stone,true);

    const FVector TowerPositions[]={
        FVector(5600,5600,0),FVector(-5600,5600,0),FVector(5600,-5600,0),FVector(-5600,-5600,0)
    };
    for (const FVector& P:TowerPositions)
    {
        AddPart(CylinderMesh,TEXT("GateTower"),P+FVector(0,0,400),FVector(5.8f,5.8f,7.2f),FRotator::ZeroRotator,DarkStone,true);
        AddPart(ConeMesh,TEXT("TowerRoof"),P+FVector(0,0,1140),FVector(6.6f,6.6f,2.7f),FRotator::ZeroRotator,FLinearColor(0.18f,0.11f,0.09f));
    }
    AddPart(CubeMesh,TEXT("MainGate"),FVector(0,6120,185),FVector(9.2f,0.8f,2.15f),FRotator::ZeroRotator,FLinearColor(0.14f,0.075f,0.028f),true);
    AddPart(CubeMesh,TEXT("GateBeam"),FVector(0,6050,650),FVector(11.0f,1.0f,0.45f),FRotator::ZeroRotator,Stone);
}

void AHonourWarWorldDirector::BuildMarketStall(const FVector& Center,float Yaw)
{
    const FRotator R(0,Yaw,0);
    const FLinearColor Wood(0.30f,0.145f,0.055f);
    const FLinearColor Cloth=FLinearColor(0.58f,0.13f,0.11f);

    AddPart(CubeMesh,TEXT("MarketTable"),Center+FVector(0,0,95),FVector(4.8f,3.2f,0.44f),R,Wood);
    AddPart(CubeMesh,TEXT("MarketRoof"),Center+FVector(0,0,420),FVector(5.4f,3.8f,0.32f),R,Cloth);

    const FVector Poles[]={
        FVector(-390,-250,255),FVector(-390,250,255),FVector(390,-250,255),FVector(390,250,255)
    };
    for (const FVector& Offset:Poles) AddPart(CylinderMesh,TEXT("MarketPole"),Center+R.RotateVector(Offset),FVector(0.16f,0.16f,2.65f),R,Wood);

    AddPart(SphereMesh,TEXT("GoodsA"),Center+R.RotateVector(FVector(0,0,165)),FVector(0.55f,0.55f,0.46f),R,FLinearColor(0.84f,0.56f,0.16f));
    AddPart(SphereMesh,TEXT("GoodsB"),Center+R.RotateVector(FVector(110,0,165)),FVector(0.38f,0.38f,0.32f),R,FLinearColor(0.68f,0.20f,0.12f));
}

void AHonourWarWorldDirector::BuildMarket()
{
    BuildMarketStall(FVector(1050,520,0),0);
    BuildMarketStall(FVector(1050,-520,0),0);
    BuildMarketStall(FVector(-1050,520,0),180);
    BuildMarketStall(FVector(-1050,-520,0),180);
}

void AHonourWarWorldDirector::BuildLamp(const FVector& Center)
{
    AddPart(CylinderMesh,TEXT("LampPost"),Center+FVector(0,0,190),FVector(0.14f,0.14f,2.9f),FRotator::ZeroRotator,FLinearColor(0.14f,0.10f,0.07f));
    AddPart(SphereMesh,TEXT("LampGlow"),Center+FVector(0,0,390),FVector(0.34f,0.34f,0.34f),FRotator::ZeroRotator,FLinearColor(1.0f,0.68f,0.26f));
    AddPart(ConeMesh,TEXT("LampCap"),Center+FVector(0,0,448),FVector(0.42f,0.42f,0.20f),FRotator::ZeroRotator,FLinearColor(0.12f,0.09f,0.06f));
}

void AHonourWarWorldDirector::BuildBanner(const FVector& Center,float Yaw,const FLinearColor& ClothColor)
{
    const FRotator R(0,Yaw,0);
    AddPart(CylinderMesh,TEXT("BannerPole"),Center+R.RotateVector(FVector(0,0,320)),FVector(0.10f,0.10f,4.4f),R,FLinearColor(0.16f,0.09f,0.04f));
    AddPart(CubeMesh,TEXT("BannerCloth"),Center+R.RotateVector(FVector(0,-95,500)),FVector(0.10f,1.3f,1.05f),R,ClothColor);
}

void AHonourWarWorldDirector::BuildFence(const FVector& Center,float Yaw,float Length)
{
    const FRotator R(0,Yaw,0);
    const int32 Count=FMath::Max(2,FMath::RoundToInt(Length/260.0f));
    for (int32 I=0;I<Count;++I)
    {
        const float Offset=-Length*0.5f+(I+0.5f)*(Length/Count);
        AddPart(CylinderMesh,TEXT("FencePost"),Center+R.RotateVector(FVector(0,Offset,120)),
            FVector(0.10f,0.10f,1.6f),R,FLinearColor(0.20f,0.11f,0.05f));
    }
    AddPart(CubeMesh,TEXT("FenceRail"),Center+R.RotateVector(FVector(0,0,145)),
        FVector(0.12f,Length*0.5f,0.12f),R,FLinearColor(0.26f,0.14f,0.06f));
}

void AHonourWarWorldDirector::BuildRock(const FVector& Center,float Scale)
{
    AddPart(SphereMesh,TEXT("RockA"),Center+FVector(0,0,80*Scale),
        FVector(1.8f*Scale,1.25f*Scale,0.95f*Scale),FRotator(0,18,0),FLinearColor(0.30f,0.31f,0.29f));
    AddPart(SphereMesh,TEXT("RockB"),Center+FVector(110*Scale,60*Scale,48*Scale),
        FVector(0.90f*Scale,0.72f*Scale,0.60f*Scale),FRotator(0,-10,0),FLinearColor(0.24f,0.25f,0.24f));
}



void AHonourWarWorldDirector::BuildTownServices()
{
    const FLinearColor Stone=FLinearColor(0.40f,0.39f,0.36f);
    const FLinearColor DarkStone=FLinearColor(0.22f,0.22f,0.22f);
    const FLinearColor Wood=FLinearColor(0.28f,0.13f,0.05f);
    const FLinearColor Gold=FLinearColor(0.78f,0.58f,0.20f);
    const FLinearColor Magic=FLinearColor(0.48f,0.62f,1.00f);
    const FLinearColor Banner=FLinearColor(0.55f,0.10f,0.12f);

    // Weapon refinement / blacksmith service.
    AddPart(CubeMesh,TEXT("BlacksmithFloor"),FVector(1550,1450,22),FVector(7.5f,5.5f,0.18f),FRotator::ZeroRotator,Stone,true);
    AddPart(CubeMesh,TEXT("BlacksmithForge"),FVector(1550,1450,145),FVector(3.1f,2.6f,1.1f),FRotator::ZeroRotator,DarkStone);
    AddPart(CylinderMesh,TEXT("BlacksmithAnvil"),FVector(1730,1450,265),FVector(1.2f,1.2f,0.7f),FRotator::ZeroRotator,Gold);
    AddPart(SphereMesh,TEXT("ForgeEmber"),FVector(1550,1450,330),FVector(0.65f,0.65f,0.65f),FRotator::ZeroRotator,FLinearColor(1.0f,0.30f,0.08f));

    // Card mixing station.
    AddPart(CubeMesh,TEXT("CardMixerDesk"),FVector(-1550,1450,115),FVector(4.8f,2.8f,0.42f),FRotator::ZeroRotator,Wood);
    AddPart(CylinderMesh,TEXT("CardMixerRing"),FVector(-1550,1450,190),FVector(2.1f,2.1f,0.18f),FRotator::ZeroRotator,Gold);
    AddPart(SphereMesh,TEXT("CardMixerCrystal"),FVector(-1550,1450,285),FVector(0.65f,0.65f,0.85f),FRotator::ZeroRotator,Magic);

    // Hero skill-upgrade shrine.
    BuildShrine(FVector(1550,-1450,0),0.55f);
    AddPart(SphereMesh,TEXT("SkillShrineCore"),FVector(1550,-1450,520),FVector(0.55f,0.55f,0.55f),FRotator::ZeroRotator,Magic);

    // Soldier production workshop; integrated into the town as an RPG service building.
    AddPart(CubeMesh,TEXT("SoldierWorkshop"),FVector(-1550,-1450,190),FVector(8.0f,6.0f,3.3f),FRotator::ZeroRotator,Stone,true);
    AddPart(ConeMesh,TEXT("SoldierWorkshopRoof"),FVector(-1550,-1450,650),FVector(8.7f,6.8f,2.5f),FRotator::ZeroRotator,Banner);
    AddPart(CubeMesh,TEXT("SoldierWorkshopDoor"),FVector(-1550,-2035,220),FVector(2.2f,0.35f,3.0f),FRotator::ZeroRotator,Wood);
}

void AHonourWarWorldDirector::BuildRoadFurniture()
{
    const FVector LampPositions[]={
        FVector(680,680,0),FVector(-680,680,0),FVector(680,-680,0),FVector(-680,-680,0),
        FVector(1450,0,0),FVector(-1450,0,0),FVector(0,1450,0),FVector(0,-1450,0)
    };
    for (const FVector& P:LampPositions) BuildLamp(P);

    BuildBanner(FVector(420,0,0),90,FLinearColor(0.58f,0.12f,0.10f));
    BuildBanner(FVector(-420,0,0),-90,FLinearColor(0.18f,0.32f,0.62f));

    BuildFence(FVector(1850,1150,0),0,1600);
    BuildFence(FVector(-1850,-1150,0),0,1600);
    BuildFence(FVector(1150,-1850,0),90,1600);
    BuildFence(FVector(-1150,1850,0),90,1600);
}

void AHonourWarWorldDirector::BuildTree(const FVector& Center,float Scale,int32 Variant)
{
    const FLinearColor Trunk(0.23f,0.11f,0.045f);
    const FLinearColor LeafA=Variant==0?FLinearColor(0.10f,0.32f,0.10f):FLinearColor(0.15f,0.39f,0.12f);
    const FLinearColor LeafB=Variant==0?FLinearColor(0.14f,0.39f,0.12f):FLinearColor(0.20f,0.47f,0.15f);

    AddPart(CylinderMesh,TEXT("TreeTrunk"),Center+FVector(0,0,180*Scale),
        FVector(0.82f*Scale,0.82f*Scale,3.0f*Scale),FRotator::ZeroRotator,Trunk);

    AddPart(SphereMesh,TEXT("TreeCrownA"),Center+FVector(0,0,540*Scale),
        FVector(3.0f*Scale,2.7f*Scale,2.2f*Scale),FRotator::ZeroRotator,LeafA);
    AddPart(SphereMesh,TEXT("TreeCrownB"),Center+FVector(190*Scale,40*Scale,650*Scale),
        FVector(2.15f*Scale,1.90f*Scale,1.70f*Scale),FRotator::ZeroRotator,LeafB);
    if (Variant==1)
    {
        AddPart(SphereMesh,TEXT("TreeCrownC"),Center+FVector(-165*Scale,-30*Scale,610*Scale),
            FVector(1.85f*Scale,1.70f*Scale,1.50f*Scale),FRotator::ZeroRotator,LeafB);
    }
}

void AHonourWarWorldDirector::BuildVegetation()
{
    const FVector Trees[]={
        FVector(4700,1100,0),FVector(4800,-1500,0),FVector(-4700,1000,0),FVector(-4900,-1750,0),
        FVector(3100,4700,0),FVector(-3200,4700,0),FVector(3400,-4700,0),FVector(-2900,-4600,0),
        FVector(7300,2100,0),FVector(-7200,-2400,0),FVector(7000,-3300,0),FVector(-6600,3500,0),
        FVector(5200,3300,0),FVector(-5200,3200,0),FVector(5150,-3400,0),FVector(-5200,-3350,0)
    };
    int32 Index=0;
    for (const FVector& P:Trees) BuildTree(P,1.0f+(Index%3)*0.10f,Index++%2);

    const FVector Rocks[]={
        FVector(2500,2300,0),FVector(2900,-2600,0),FVector(-2500,2450,0),FVector(-3000,-2500,0),
        FVector(5600,800,0),FVector(-5500,-900,0),FVector(6200,2700,0),FVector(-6100,2500,0)
    };
    for (const FVector& P:Rocks) BuildRock(P,0.9f+(P.X>0?0.15f:0.0f));

    const FVector FlowerBeds[]={
        FVector(780,1180,0),FVector(-780,-1180,0),FVector(1180,-780,0),FVector(-1180,780,0)
    };
    for (const FVector& P:FlowerBeds)
    {
        AddPart(CubeMesh,TEXT("GardenBed"),P+FVector(0,0,22),FVector(4.0f,2.2f,0.12f),FRotator::ZeroRotator,FLinearColor(0.23f,0.17f,0.09f));
        AddPart(SphereMesh,TEXT("GardenFlowers"),P+FVector(0,0,82),FVector(1.5f,0.8f,0.32f),FRotator::ZeroRotator,FLinearColor(0.78f,0.36f,0.28f));
    }
}

void AHonourWarWorldDirector::BuildDistantLandmarks()
{
    const FVector Shrine=FVector(0,3200,0);
    AddPart(CubeMesh,TEXT("GuildHall"),Shrine+FVector(0,0,300),FVector(20,9,3.6f),FRotator::ZeroRotator,FLinearColor(0.38f,0.30f,0.22f));
    AddPart(ConeMesh,TEXT("GuildHallRoof"),Shrine+FVector(0,0,760),FVector(22,11,3.2f),FRotator::ZeroRotator,FLinearColor(0.23f,0.12f,0.09f));
    AddPart(CubeMesh,TEXT("GuildDoor"),Shrine+FVector(0,-925,260),FVector(3.0f,0.40f,3.7f),FRotator::ZeroRotator,FLinearColor(0.13f,0.07f,0.03f));

    const FVector HillPositions[]={FVector(10000,7000,0),FVector(-10000,7000,0),FVector(10500,-6500,0),FVector(-10500,-6500,0)};
    for (const FVector& P:HillPositions)
    {
        AddPart(SphereMesh,TEXT("DistantHill"),P+FVector(0,0,900),FVector(18,15,10),FRotator::ZeroRotator,FLinearColor(0.18f,0.30f,0.16f));
    }
}

void AHonourWarWorldDirector::SpawnMonsters()
{
    const FVector MonsterLocations[]={
        FVector(2600,1000,110),FVector(3100,1300,110),FVector(3350,750,110),
        FVector(-2700,1100,110),FVector(-3200,1500,110),FVector(-3600,800,110),
        FVector(2600,-1250,110),FVector(3200,-1650,110),FVector(-3000,-1400,110)
    };
    const int32 MonsterLevels[] = {12, 28, 55, 90, 140, 180, 220, 260, 300};
    for (int32 Index=0; Index<UE_ARRAY_COUNT(MonsterLocations); ++Index)
    {
        FActorSpawnParameters Params;
        Params.SpawnCollisionHandlingOverride=ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
        if (AHonourWarMonster* Monster=GetWorld()->SpawnActor<AHonourWarMonster>(
            AHonourWarMonster::StaticClass(),MonsterLocations[Index],FRotator::ZeroRotator,Params))
        {
            Monster->SetLevel(MonsterLevels[Index]);
        }
    }
}
