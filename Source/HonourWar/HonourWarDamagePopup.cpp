#include "HonourWarDamagePopup.h"
#include "Components/TextRenderComponent.h"

AHonourWarDamagePopup::AHonourWarDamagePopup()
{
    PrimaryActorTick.bCanEverTick=true;
    SetLifeSpan(Life);
    Text=CreateDefaultSubobject<UTextRenderComponent>(TEXT("Text"));
    RootComponent=Text;
    Text->SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
    Text->SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
    Text->SetWorldSize(34.0f);
    Text->SetTextRenderColor(FColor::White);
    Text->SetHorizontalScale(0.85f);
    Text->SetCollisionEnabled(ECollisionEnabled::NoCollision);
}

void AHonourWarDamagePopup::BeginPlay(){Super::BeginPlay();}

void AHonourWarDamagePopup::Initialize(float Damage,const FLinearColor& Color,bool bCritical)
{
    const int32 Value=FMath::Max(1,FMath::RoundToInt(Damage));
    Text->SetText(FText::FromString(bCritical?FString::Printf(TEXT("CRIT %d"),Value):FString::FromInt(Value)));
    Text->SetTextRenderColor(Color.ToFColor(true));
    Text->SetWorldSize(bCritical?42.0f:34.0f);
    SetLifeSpan(bCritical?1.0f:Life);
}
void AHonourWarDamagePopup::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    Age+=DeltaSeconds;
    AddActorWorldOffset(FVector(0,0,85.0f*DeltaSeconds));
    const float T=FMath::Clamp(Age/Life,0.0f,1.0f);
    Text->SetWorldSize(FMath::Lerp(34.0f,28.0f,T));
}
