#include "HonourWarCombatComponent.h"
#include "HonourWarCharacter.h"
#include "HonourWarMonster.h"
#include "HonourWarLootDatabase.h"
#include "HonourWarDamagePopup.h"
#include "HonourWarClassProgression.h"
#include "HonourWarCombatEffect.h"
#include "HonourWarGameState.h"
#include "Kismet/GameplayStatics.h"
#include "Net/UnrealNetwork.h"

UHonourWarCombatComponent::UHonourWarCombatComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
    SetIsReplicatedByDefault(true);
    SkillCooldowns.Init(0.0f, 8);
}

void UHonourWarCombatComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(UHonourWarCombatComponent,Level);
    DOREPLIFETIME(UHonourWarCombatComponent,Experience);
    DOREPLIFETIME(UHonourWarCombatComponent,AgeDays);
    DOREPLIFETIME(UHonourWarCombatComponent,MaxHealth);
    DOREPLIFETIME(UHonourWarCombatComponent,CurrentHealth);
    DOREPLIFETIME(UHonourWarCombatComponent,MaxSp);
    DOREPLIFETIME(UHonourWarCombatComponent,CurrentSp);
    DOREPLIFETIME(UHonourWarCombatComponent,Zeny);
    DOREPLIFETIME(UHonourWarCombatComponent,EquipmentRefineLevel);
    DOREPLIFETIME(UHonourWarCombatComponent,Phracon);
    DOREPLIFETIME(UHonourWarCombatComponent,Emveretarcon);
    DOREPLIFETIME(UHonourWarCombatComponent,Oridecon);
    DOREPLIFETIME(UHonourWarCombatComponent,BasicSkillLevel);
    DOREPLIFETIME(UHonourWarCombatComponent,Honours);
    DOREPLIFETIME(UHonourWarCombatComponent,StatusPoints);
    DOREPLIFETIME(UHonourWarCombatComponent,Strength);
    DOREPLIFETIME(UHonourWarCombatComponent,Agility);
    DOREPLIFETIME(UHonourWarCombatComponent,Vitality);
    DOREPLIFETIME(UHonourWarCombatComponent,Intelligence);
    DOREPLIFETIME(UHonourWarCombatComponent,Dexterity);
    DOREPLIFETIME(UHonourWarCombatComponent,LuckStat);
}

void UHonourWarCombatComponent::BeginPlay()
{
    Super::BeginPlay();
    RecalculateVitals();
    CurrentHealth = MaxHealth;
    CurrentSp = MaxSp;
    XpToNextLevel = FMath::Max(100, Level * 120);
}

void UHonourWarCombatComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
    for (float& Cooldown : SkillCooldowns) Cooldown = FMath::Max(0.0f, Cooldown - DeltaTime);
    float SpRegenMultiplier=1.0f;
    if(const AHonourWarGameState* State=GetWorld()?GetWorld()->GetGameState<AHonourWarGameState>():nullptr)
        SpRegenMultiplier=State->GetWorldEventSpRegenMultiplier();
    CurrentSp = FMath::Min(MaxSp, CurrentSp + DeltaTime * 5.0f * SpRegenMultiplier);
}

float UHonourWarCombatComponent::SkillRangeForClass() const
{
    const FHonourWarJobProfile& Job=HonourWarClassProgression::JobFor(CharacterClass,HonourWarClassProgression::TierForLevel(Level));
    return static_cast<float>(Job.AttackRange);
}

float UHonourWarCombatComponent::BaseDamageForClass() const
{
    const float AgeYears = 18.0f + static_cast<float>(AgeDays) / 3.0f;
    const float AgeMultiplier = 1.0f + FMath::Clamp((AgeYears - 18.0f) * 0.005f, 0.0f, 1.0f);
    const float StatusAttack = static_cast<float>(Strength) * 2.0f + static_cast<float>(Dexterity) * 0.80f;
    const float MagicAttack = static_cast<float>(Intelligence) * 0.45f;
    const FHonourWarJobProfile& Job=HonourWarClassProgression::JobFor(CharacterClass,HonourWarClassProgression::TierForLevel(Level));
    const float JobPowerMultiplier=1.0f+static_cast<float>(Job.PowerRating-140)*0.0015f;
    const float LevelScale = (30.0f + Level * 8.0f + StatusAttack + MagicAttack) * AgeMultiplier * JobPowerMultiplier * (1.0f + BasicSkillLevel * 0.06f);
    switch (CharacterClass)
    {
        case EHonourWarClass::Mage: return LevelScale * 1.35f;
        case EHonourWarClass::Archer: return LevelScale * 1.18f;
        case EHonourWarClass::Ranger: return LevelScale * 1.28f;
        case EHonourWarClass::Thief: return LevelScale * 1.12f;
        case EHonourWarClass::Acolyte: return LevelScale * 0.95f;
        default: return LevelScale * 1.05f;
    }
}

AHonourWarMonster* UHonourWarCombatComponent::FindNearestTarget(float MaxRange) const
{
    UWorld* World = GetWorld();
    if (!World) return nullptr;

    TArray<AActor*> Found;
    UGameplayStatics::GetAllActorsOfClass(World, AHonourWarMonster::StaticClass(), Found);

    AHonourWarMonster* Best = nullptr;
    float BestDistSq = FMath::Square(MaxRange);
    const FVector Origin = GetOwner()->GetActorLocation();
    for (AActor* Candidate : Found)
    {
        AHonourWarMonster* Monster = Cast<AHonourWarMonster>(Candidate);
        if (!Monster || Monster->IsDead()) continue;
        const float DistSq = FVector::DistSquared(Origin, Monster->GetActorLocation());
        if (DistSq < BestDistSq)
        {
            BestDistSq = DistSq;
            Best = Monster;
        }
    }
    return Best;
}

bool UHonourWarCombatComponent::UseSkill(int32 SkillIndex)
{
    if (!SkillCooldowns.IsValidIndex(SkillIndex) || SkillCooldowns[SkillIndex] > 0.0f) return false;

    const float ManaCost = 18.0f + SkillIndex * 4.0f;
    if (CurrentSp < ManaCost) return false;

    AHonourWarMonster* Target = FindNearestTarget(SkillRangeForClass());
    if (!Target) return false;

    float EventDamageMultiplier=1.0f;
    if(const AHonourWarGameState* State=GetWorld()?GetWorld()->GetGameState<AHonourWarGameState>():nullptr)
        EventDamageMultiplier=State->GetWorldEventDamageMultiplier();
    const float Damage = BaseDamageForClass() * (1.0f + SkillIndex * 0.18f) * EventDamageMultiplier;
    bool bCritical=false;
    if(SkillIndex==0)
    {
        const bool bLucky=FMath::FRandRange(0.0f,100.0f)<FMath::Clamp(static_cast<float>(Target->GetLuck())*0.35f,1.0f,18.0f);
        if(bLucky)
        {
            if(UWorld* World=GetWorld())
                if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(AHonourWarDamagePopup::StaticClass(),Target->GetActorLocation()+FVector(0,0,240),FRotator(0,180,0)))
                    Popup->InitializeReaction(TEXT("Lucky!"),FLinearColor(0.25f,0.65f,1.0f),38.0f,0.72f);
            return false;
        }
        bCritical=FMath::FRandRange(0.0f,100.0f)<FMath::Clamp(static_cast<float>(GetCriticalRate()-Target->GetCritResistance()),1.0f,95.0f);
        if(!bCritical)
        {
            const float HitChance=FMath::Clamp(75.0f+(GetHitRating()-Target->GetFleeRating())*0.50f,5.0f,95.0f);
            if(FMath::FRandRange(0.0f,100.0f)>HitChance)
            {
                if(UWorld* World=GetWorld())
                    if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(AHonourWarDamagePopup::StaticClass(),Target->GetActorLocation()+FVector(0,0,240),FRotator(0,180,0)))
                        Popup->InitializeReaction(TEXT("MISS"),FLinearColor(0.80f,0.82f,0.86f),34.0f,0.62f);
                return false;
            }
        }
    }
    CurrentSp -= ManaCost;
    SkillCooldowns[SkillIndex] = (0.45f + SkillIndex * 0.08f) * GetSkillCooldownMultiplier();
    LastTarget = Target;

    Target->ReceiveCombatHit(Damage, CharacterClass,bCritical);
    if (Target->IsDead())
    {
        if (AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwner()))
            Character->HandleMonsterDefeat(Target->GetMonsterLevel(),Target->GetSpeciesName());
    }
    else
    {
        GainExperience(FMath::Max(1, FMath::RoundToInt(Damage * 0.08f)));
    }
    OnSkillUsed.Broadcast(SkillIndex, Damage);
    return true;
}

int32 UHonourWarCombatComponent::GetHitRating() const
{
    const int32 ClassBonus=(CharacterClass==EHonourWarClass::Archer||CharacterClass==EHonourWarClass::Ranger)?18:(CharacterClass==EHonourWarClass::Thief?10:6);
    return 70+Level*2+BasicSkillLevel*3+Dexterity+ClassBonus+EquipmentRefineLevel;
}

int32 UHonourWarCombatComponent::GetFleeRating() const
{
    const int32 ClassBonus=CharacterClass==EHonourWarClass::Thief?24:((CharacterClass==EHonourWarClass::Archer||CharacterClass==EHonourWarClass::Ranger)?14:(CharacterClass==EHonourWarClass::Mage?8:4));
    return 35+Level+AgeDays/20+Agility+ClassBonus;
}

int32 UHonourWarCombatComponent::GetCriticalRate() const
{
    const int32 ClassBonus=CharacterClass==EHonourWarClass::Thief?12:((CharacterClass==EHonourWarClass::Archer||CharacterClass==EHonourWarClass::Ranger)?8:4);
    return FMath::Clamp(4+Level/8+AgeDays/30+LuckStat/4+ClassBonus+EquipmentRefineLevel/2,1,95);
}

int32 UHonourWarCombatComponent::GetLuck() const
{
    return 8+Level/12+AgeDays/45+BasicSkillLevel/2+LuckStat/5;
}

void UHonourWarCombatComponent::ReceiveMonsterAttack(float Damage,int32 AttackerLevel)
{
    const float LuckyChance=FMath::Clamp(static_cast<float>(GetLuck())*0.35f,1.0f,18.0f);
    if(FMath::FRandRange(0.0f,100.0f)<LuckyChance)
    {
        if(UWorld* World=GetWorld())
            if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(AHonourWarDamagePopup::StaticClass(),GetOwner()->GetActorLocation()+FVector(0,0,240),FRotator(0,180,0)))
                Popup->InitializeReaction(TEXT("Lucky!"),FLinearColor(0.25f,0.65f,1.0f),38.0f,0.72f);
        return;
    }

    const int32 AttackerHit=75+AttackerLevel*2;
    const float HitChance=FMath::Clamp(75.0f+(AttackerHit-GetFleeRating())*0.50f,5.0f,95.0f);
    if(FMath::FRandRange(0.0f,100.0f)>HitChance)
    {
        if(UWorld* World=GetWorld())
            if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(AHonourWarDamagePopup::StaticClass(),GetOwner()->GetActorLocation()+FVector(0,0,240),FRotator(0,180,0)))
                Popup->InitializeReaction(TEXT("MISS"),FLinearColor(0.80f,0.82f,0.86f),34.0f,0.62f);
        return;
    }

    const bool bCritical=FMath::FRandRange(0.0f,100.0f)<FMath::Clamp(4.0f+AttackerLevel/8.0f,1.0f,35.0f);
    const float MitigatedDamage=Damage*(bCritical?1.40f:1.0f)*(1.0f-GetDamageReductionPercent());
    ReceiveDamage(MitigatedDamage);
    if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwner()))
        Character->PlayIncomingAttackReaction(bCritical);

    if(UWorld* World=GetWorld())
    {
        const FLinearColor Color=bCritical?FLinearColor(1.0f,0.10f,0.05f):FLinearColor(0.95f,0.30f,0.25f);
        if(AHonourWarCombatEffect* Effect=World->SpawnActor<AHonourWarCombatEffect>(AHonourWarCombatEffect::StaticClass(),GetOwner()->GetActorLocation()+FVector(0,0,150),FRotator::ZeroRotator))
            Effect->Initialize(Color,FMath::Clamp(FinalDamage/80.0f,0.8f,2.2f),bCritical);
        if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(AHonourWarDamagePopup::StaticClass(),GetOwner()->GetActorLocation()+FVector(0,0,235),FRotator(0,180,0)))
            Popup->Initialize(FinalDamage,Color,bCritical);
    }
}

void UHonourWarCombatComponent::ReceiveDamage(float Damage)
{
    CurrentHealth = FMath::Max(0.0f, CurrentHealth - FMath::Max(0.0f, Damage));
    if (CurrentHealth <= 0.0f)
    {
        if (AHonourWarCharacter* Character = Cast<AHonourWarCharacter>(GetOwner()))
            Character->HandleDeathAndRespawn();
    }
}

void UHonourWarCombatComponent::RestoreVitals()
{
    RecalculateVitals();
    CurrentHealth=MaxHealth;
    CurrentSp=MaxSp;
}

float UHonourWarCombatComponent::GetDamageReductionPercent() const
{
    return FMath::Clamp(static_cast<float>(Vitality)*0.0021f,0.0f,0.25f);
}

float UHonourWarCombatComponent::GetSkillCooldownMultiplier() const
{
    return 1.0f-FMath::Clamp(static_cast<float>(Agility)*0.0015f,0.0f,0.20f);
}

int32 UHonourWarCombatComponent::GetStatusPointCost(EHonourWarStatusStat Stat) const
{
    int32 Value=10;
    switch(Stat)
    {
        case EHonourWarStatusStat::Strength: Value=Strength; break;
        case EHonourWarStatusStat::Agility: Value=Agility; break;
        case EHonourWarStatusStat::Vitality: Value=Vitality; break;
        case EHonourWarStatusStat::Intelligence: Value=Intelligence; break;
        case EHonourWarStatusStat::Dexterity: Value=Dexterity; break;
        case EHonourWarStatusStat::Luck: Value=LuckStat; break;
    }
    return Value<80?1:(Value<100?2:3);
}

bool UHonourWarCombatComponent::SpendStatusPoint(EHonourWarStatusStat Stat,int32 Amount)
{
    if(Amount<=0) return false;

    int32 Value=10;
    switch(Stat)
    {
        case EHonourWarStatusStat::Strength: Value=Strength; break;
        case EHonourWarStatusStat::Agility: Value=Agility; break;
        case EHonourWarStatusStat::Vitality: Value=Vitality; break;
        case EHonourWarStatusStat::Intelligence: Value=Intelligence; break;
        case EHonourWarStatusStat::Dexterity: Value=Dexterity; break;
        case EHonourWarStatusStat::Luck: Value=LuckStat; break;
    }

    const int32 Allowed=FMath::Max(0,120-Value);
    const int32 Spend=FMath::Min(Amount,Allowed);
    if(Spend<=0) return false;

    int32 TotalCost=0;
    int32 Temp=Value;
    for(int32 I=0;I<Spend;++I)
    {
        const int32 Cost=Temp<80?1:(Temp<100?2:3);
        TotalCost+=Cost;
        ++Temp;
    }
    if(StatusPoints<TotalCost) return false;

    StatusPoints-=TotalCost;
    switch(Stat)
    {
        case EHonourWarStatusStat::Strength: Strength+=Spend; break;
        case EHonourWarStatusStat::Agility: Agility+=Spend; break;
        case EHonourWarStatusStat::Vitality: Vitality+=Spend; break;
        case EHonourWarStatusStat::Intelligence: Intelligence+=Spend; break;
        case EHonourWarStatusStat::Dexterity: Dexterity+=Spend; break;
        case EHonourWarStatusStat::Luck: LuckStat+=Spend; break;
    }
    const float HealthRatio=MaxHealth>0.0f?CurrentHealth/MaxHealth:1.0f;
    const float SpRatio=MaxSp>0.0f?CurrentSp/MaxSp:1.0f;
    RecalculateVitals();
    CurrentHealth=FMath::Clamp(MaxHealth*HealthRatio,0.0f,MaxHealth);
    CurrentSp=FMath::Clamp(MaxSp*SpRatio,0.0f,MaxSp);
    return true;
}

void UHonourWarCombatComponent::SetStatusState(int32 InStatusPoints,int32 InStrength,int32 InAgility,int32 InVitality,int32 InIntelligence,int32 InDexterity,int32 InLuck)
{
    StatusPoints=FMath::Max(0,InStatusPoints);
    Strength=FMath::Clamp(InStrength,10,120);
    Agility=FMath::Clamp(InAgility,10,120);
    Vitality=FMath::Clamp(InVitality,10,120);
    Intelligence=FMath::Clamp(InIntelligence,10,120);
    Dexterity=FMath::Clamp(InDexterity,10,120);
    LuckStat=FMath::Clamp(InLuck,10,120);
    RecalculateVitals();
    CurrentHealth=MaxHealth;
    CurrentSp=MaxSp;
}

void UHonourWarCombatComponent::RecalculateVitals()
{
    MaxHealth=1200.0f+(Level-1)*120.0f+Vitality*25.0f;
    MaxSp=500.0f+(Level-1)*45.0f+Intelligence*15.0f;
}

void UHonourWarCombatComponent::GainExperience(int32 Amount)
{
    Experience+=FMath::Max(0,Amount);
    while(Experience>=XpToNextLevel && Level<250)
    {
        Experience-=XpToNextLevel;
        ++Level;
        StatusPoints+=3;
        if(Level%25==0) StatusPoints+=5;
        RecalculateVitals();
        RestoreVitals();
        XpToNextLevel=FMath::Max(100,Level*120);
    }
}

void UHonourWarCombatComponent::SetClassId(EHonourWarClass NewClass){ CharacterClass=NewClass; }

void UHonourWarCombatComponent::SetLevel(int32 NewLevel)
{
    Level=FMath::Clamp(NewLevel,1,250);
    RecalculateVitals();
    XpToNextLevel=FMath::Max(100,Level*120);
    RestoreVitals();
}

void UHonourWarCombatComponent::SetExperience(int32 NewExperience){ Experience=FMath::Max(0,NewExperience); }
void UHonourWarCombatComponent::SetAgeDays(int32 NewAgeDays){ AgeDays=FMath::Max(0,NewAgeDays); }
void UHonourWarCombatComponent::SetZeny(int64 NewZeny){ Zeny=FMath::Max<int64>(0,NewZeny); }
void UHonourWarCombatComponent::AddZeny(int64 Amount){ if(Amount>0) Zeny+=Amount; }
void UHonourWarCombatComponent::SetEquipmentRefineLevel(int32 NewRefine){ EquipmentRefineLevel=FMath::Clamp(NewRefine,0,15); }
void UHonourWarCombatComponent::SetPhracon(int32 Value){ Phracon=FMath::Max(0,Value); }
void UHonourWarCombatComponent::SetEmveretarcon(int32 Value){ Emveretarcon=FMath::Max(0,Value); }
void UHonourWarCombatComponent::SetOridecon(int32 Value){ Oridecon=FMath::Max(0,Value); }
void UHonourWarCombatComponent::SetBasicSkillLevel(int32 Value){ BasicSkillLevel=FMath::Clamp(Value,1,10); }

bool UHonourWarCombatComponent::TryMixCards()
{
    if(Cards.Num()<3)
    {
        LastLootMessage=TEXT("Card Mixing blocked | need 3 cards.");
        return false;
    }

    const int64 AgeDiscountedCost=FMath::Max<int64>(
        1000LL,
        static_cast<int64>(FMath::RoundToFloat(
            5000.0f*(1.0f-FMath::Clamp(static_cast<float>(AgeDays)*0.005f,0.0f,0.60f)))));

    if(Zeny<AgeDiscountedCost)
    {
        LastLootMessage=FString::Printf(TEXT("Card Mixing blocked | need %lld Zeny."),AgeDiscountedCost);
        return false;
    }

    const FString CardA=Cards[0];
    const FString CardB=Cards[1];
    const FString CardC=Cards[2];
    Cards.RemoveAt(0);
    Cards.RemoveAt(0);
    Cards.RemoveAt(0);
    Zeny-=AgeDiscountedCost;

    const FString Mixed=FString::Printf(TEXT("Mixed Card | %s + %s + %s"),*CardA,*CardB,*CardC);
    Cards.Insert(Mixed,0);
    LastLootMessage=FString::Printf(TEXT("CARD MIX SUCCESS | %s | %lld Zeny"),*Mixed,AgeDiscountedCost);
    return true;
}

bool UHonourWarCombatComponent::TryUpgradeBasicSkill()
{
    if(BasicSkillLevel>=10)
    {
        LastLootMessage=TEXT("Basic Skill is already at level 10.");
        return false;
    }

    const float AgeDiscount=FMath::Clamp(static_cast<float>(AgeDays)*0.005f,0.0f,0.60f);
    const int64 Cost=FMath::Max<int64>(
        1000LL,
        static_cast<int64>(FMath::RoundToFloat((2500.0f+BasicSkillLevel*1750.0f)*(1.0f-AgeDiscount))));

    if(Zeny<Cost)
    {
        LastLootMessage=FString::Printf(TEXT("Basic Skill upgrade blocked | need %lld Zeny."),Cost);
        return false;
    }

    Zeny-=Cost;
    ++BasicSkillLevel;
    LastLootMessage=FString::Printf(
        TEXT("Basic Skill upgraded to Lv.%d | %lld Zeny | age discount %.0f%%"),
        BasicSkillLevel,Cost,AgeDiscount*100.0f);
    return true;
}

float UHonourWarCombatComponent::GetRefineSuccessPercent() const
{
    if(EquipmentRefineLevel>=15) return 0.0f;
    const float BaseSuccess=100.0f-static_cast<float>(EquipmentRefineLevel+1)*5.5f;
    const float AgeBonus=FMath::Min(25.0f,static_cast<float>(AgeDays)*0.25f);
    return FMath::Clamp(BaseSuccess+AgeBonus,5.0f,99.5f);
}

int64 UHonourWarCombatComponent::GetRefineZenyCost() const
{
    const float AgeDiscount=FMath::Clamp(static_cast<float>(AgeDays)*0.005f,0.0f,0.60f);
    const int64 BaseCost=1000LL+static_cast<int64>(EquipmentRefineLevel)*1500LL;
    return FMath::Max<int64>(1,static_cast<int64>(
        FMath::RoundToFloat(static_cast<float>(BaseCost)*(1.0f-AgeDiscount))));
}

bool UHonourWarCombatComponent::TryRefineEquipment()
{
    if(EquipmentRefineLevel>=15)
    {
        LastLootMessage=TEXT("Equipment is already at maximum refinement +15.");
        return false;
    }

    const float AgeDiscount=FMath::Clamp(static_cast<float>(AgeDays)*0.005f,0.0f,0.60f);
    const int32 OreCost=FMath::Max(
        1,
        FMath::CeilToInt((1.0f+static_cast<float>(EquipmentRefineLevel)/4.0f)*(1.0f-AgeDiscount)));

    int32& PrimaryMaterial=
        EquipmentRefineLevel<5 ? Phracon :
        (EquipmentRefineLevel<10 ? Emveretarcon : Oridecon);

    const int64 ZenyCost=GetRefineZenyCost();
    if(Zeny<ZenyCost || PrimaryMaterial<OreCost)
    {
        LastLootMessage=FString::Printf(
            TEXT("Refine +%d blocked | need %lld Zeny + %d ore."),
            EquipmentRefineLevel+1,ZenyCost,OreCost);
        return false;
    }

    Zeny-=ZenyCost;
    PrimaryMaterial-=OreCost;

    const float Success=GetRefineSuccessPercent();
    if(FMath::FRandRange(0.0f,100.0f)<=Success)
    {
        ++EquipmentRefineLevel;
        LastLootMessage=FString::Printf(
            TEXT("Refinement SUCCESS | equipment +%d | %.1f%% success | age discount %.0f%%"),
            EquipmentRefineLevel,Success,AgeDiscount*100.0f);
        return true;
    }

    LastLootMessage=FString::Printf(
        TEXT("Refinement FAILED | equipment remains +%d | %.1f%% success | materials consumed"),
        EquipmentRefineLevel,Success);
    return false;
}

void UHonourWarCombatComponent::AddHonours(int32 Amount)
{
    if(Amount>0) Honours+=Amount;
}

void UHonourWarCombatComponent::AddQuestItem(const FString& ItemName)
{
    if(!ItemName.IsEmpty()) InventoryItems.Add(ItemName);
}

void UHonourWarCombatComponent::SetQuestMessage(const FString& Message)
{
    LastLootMessage=Message;
}

void UHonourWarCombatComponent::SetHonours(int32 NewHonours){ Honours = FMath::Max(0, NewHonours); }
void UHonourWarCombatComponent::SetInventoryItems(const TArray<FString>& NewItems){ InventoryItems = NewItems; }
void UHonourWarCombatComponent::SetCards(const TArray<FString>& NewCards){ Cards = NewCards; }

namespace { struct FHonourWarTier5Drop { const TCHAR* EquipmentId; const TCHAR* EquipmentName; const TCHAR* CardId; const TCHAR* CardName; const TCHAR* SourceMonsterName; }; FHonourWarTier5Drop HonourWarTier5Drop(EHonourWarClass ClassId){ switch(ClassId){ case EHonourWarClass::Mage:return {TEXT("JOBEQ_MAG_001"),TEXT("Chrono Arcane Staff"),TEXT("JOBCARD_MAG_001"),TEXT("Eternal Spellwright Card"),TEXT("Night Poring Worldbreaker")}; case EHonourWarClass::Archer:return {TEXT("JOBEQ_ARC_001"),TEXT("Doomsday Longbow"),TEXT("JOBCARD_ARC_001"),TEXT("Causality Marksman Card"),TEXT("Night Bone Archer Worldbreaker")}; case EHonourWarClass::Thief:return {TEXT("JOBEQ_THI_001"),TEXT("Causality Twin Daggers"),TEXT("JOBCARD_THI_001"),TEXT("Absolute Shadow Card"),TEXT("Night Venom Beetle Worldbreaker")}; case EHonourWarClass::Acolyte:return {TEXT("JOBEQ_ACO_001"),TEXT("Chrono Sanctified Mace"),TEXT("JOBCARD_ACO_001"),TEXT("Eternal Benediction Card"),TEXT("Night Drake Worldbreaker")}; case EHonourWarClass::Merchant:return {TEXT("JOBEQ_MER_001"),TEXT("Matrix Forged Axe"),TEXT("JOBCARD_MER_001"),TEXT("Infinite Quartermaster Card"),TEXT("Night Iron Golem Worldbreaker")}; case EHonourWarClass::Ranger:return {TEXT("JOBEQ_RAN_001"),TEXT("Verdant Paragon Bolt Gun"),TEXT("JOBCARD_RAN_001"),TEXT("Verdant Paragon Card"),TEXT("Night Hunter Fly Worldbreaker")}; default:return {TEXT("JOBEQ_WAR_001"),TEXT("Transcendent Greatsword"),TEXT("JOBCARD_WAR_001"),TEXT("Abyssal Warlord Card"),TEXT("Night Orc Warlord Worldbreaker")}; }} }

namespace { int32 HonourWarMonsterTier(int32 Level){if(Level>=300)return 7;if(Level>=230)return 6;if(Level>=170)return 5;if(Level>=120)return 4;if(Level>=80)return 3;if(Level>=50)return 2;if(Level>=30)return 1;return 0;} int32 HonourWarMonsterFamilyIndex(const FString& Name){struct FFamilyToken{const TCHAR* Name;int32 Index;};
static const FFamilyToken F[]={
 {TEXT("Zombie Guard"),13},{TEXT("Skull Knight"),15},{TEXT("Bone Archer"),14},{TEXT("Orc Warlord"),19},{TEXT("Orc Champion"),18},{TEXT("Orc Warrior"),17},{TEXT("Desert Wolf"),9},{TEXT("Dire Wolf"),11},{TEXT("Poporing"),1},{TEXT("Venom Beetle"),23},{TEXT("Hunter Fly"),21},{TEXT("Stone Golem"),25},{TEXT("Crystal Golem"),26},{TEXT("Iron Golem"),27},{TEXT("Elder Dragon"),31},
 {TEXT("Poring"),0},{TEXT("Drops"),2},{TEXT("Marin"),3},{TEXT("Goblin"),4},{TEXT("Kobold"),5},{TEXT("Hobgoblin"),6},{TEXT("Orclet"),7},{TEXT("Wolf"),8},{TEXT("Warg"),10},{TEXT("Skeleton"),12},{TEXT("Orc"),16},{TEXT("Mantis"),20},{TEXT("Scorpion"),22},{TEXT("Golem"),24},{TEXT("Dragon"),28},{TEXT("Drake"),29},{TEXT("Wyvern"),30}
};for(const FFamilyToken& Token:F)if(Name.Contains(Token.Name))return Token.Index;return 0;} }

void UHonourWarCombatComponent::RewardMonsterDefeat(int32 MonsterLevel,const FString& MonsterName)
{
    const int32 SafeLevel = FMath::Clamp(MonsterLevel, 1, 300);
    const int32 BaseKillXp = SafeLevel >= 300 ? 50000 : FMath::Max(25, SafeLevel * 35);
    const int64 BaseZenyReward = SafeLevel >= 300 ? 250000 : static_cast<int64>(SafeLevel) * 45 + 75;
    const int32 BaseHonourReward = SafeLevel >= 300 ? 100 : FMath::Max(1, SafeLevel / 10);

    float XpMultiplier=1.0f;
    float ZenyMultiplier=1.0f;
    float HonourMultiplier=1.0f;
    FString EventName=TEXT("Normal");
    if(const AHonourWarGameState* State=GetWorld()?GetWorld()->GetGameState<AHonourWarGameState>():nullptr)
    {
        XpMultiplier=State->GetWorldEventXpMultiplier();
        ZenyMultiplier=State->GetWorldEventZenyMultiplier();
        HonourMultiplier=State->GetWorldEventHonourMultiplier();
        EventName=State->GetActiveWorldEventTitle();
    }

    const int32 KillXp=FMath::Max(1,FMath::RoundToInt(static_cast<float>(BaseKillXp)*XpMultiplier));
    const int64 ZenyReward=FMath::Max<int64>(1,static_cast<int64>(FMath::RoundToDouble(static_cast<double>(BaseZenyReward)*ZenyMultiplier)));
    const int32 HonourReward=FMath::Max(1,FMath::RoundToInt(static_cast<float>(BaseHonourReward)*HonourMultiplier));

    GainExperience(KillXp);
    Zeny += ZenyReward;
    Honours += HonourReward;

    const int32 MonsterTier = HonourWarMonsterTier(SafeLevel);
    const int32 MonsterFamilySlot = FMath::Clamp(HonourWarMonsterFamilyIndex(MonsterName),0,29);
    const int32 LootRank = FMath::Clamp(MonsterTier*40+MonsterFamilySlot+1,1,300);

    FString Rarity = TEXT("Rare");
    if (SafeLevel >= 300) Rarity = TEXT("Mythic");
    else if (SafeLevel >= 200) Rarity = TEXT("Legendary");
    else if (SafeLevel >= 100) Rarity = TEXT("Epic");

    const int32 GeneralItemIndex=(MonsterTier*30+MonsterFamilySlot)%76;
    const int32 GeneralItemId = GeneralItemIndex + 1;
    const FString GeneralItemName = HonourWarLootDatabase::Items()[300+GeneralItemIndex];
    InventoryItems.Add(FString::Printf(TEXT("ITEM_%03d | %s"),GeneralItemId,*GeneralItemName));

    const FString DatabaseItem = HonourWarLootDatabase::EquipmentForRank(LootRank);
    const bool bRangerBoltWeapon = CharacterClass==EHonourWarClass::Ranger;
    const FString RangerAmmoTag = bRangerBoltWeapon ? TEXT("Machine Gun Bolts | ITEM_075") : TEXT("");
    const FString ItemName = CharacterClass==EHonourWarClass::Ranger ? FString::Printf(TEXT("%s | EQUIP_%03d | %s | %s"), *Rarity, LootRank, *DatabaseItem, *RangerAmmoTag) : FString::Printf(TEXT("%s | EQUIP_%03d | %s"), *Rarity, LootRank, *DatabaseItem);
    InventoryItems.Add(ItemName);

    {
        const FString DatabaseCard = HonourWarLootDatabase::CardForRank(LootRank);
        Cards.Add(FString::Printf(TEXT("CARD_%03d | %s"),LootRank,*DatabaseCard));
    }

    if (SafeLevel >= 300)
    {
        LastLootMessage = FString::Printf(TEXT("Lv.%d MONSTER DEFEATED | %lld Zeny | Mythic | %s | World Monarch Card | +%d XP | %s"), SafeLevel, ZenyReward, *DatabaseItem, KillXp, *EventName);
    }
    else
    {
        LastLootMessage = FString::Printf(TEXT("Lv.%d defeated | %lld Zeny | %s | +%d XP | %s"), SafeLevel, ZenyReward, *ItemName, KillXp, *EventName);
    }

    const FHonourWarTier5Drop Reward = HonourWarTier5Drop(CharacterClass);
    if (SafeLevel >= 300 && MonsterName.Equals(Reward.SourceMonsterName,ESearchCase::IgnoreCase) && FMath::FRand() <= 0.05f)
    {
        InventoryItems.Add(FString::Printf(TEXT("Tier 5 Worldbreaker Drop | %s | %s"), Reward.EquipmentId, Reward.EquipmentName));
        Cards.Add(FString::Printf(TEXT("Tier 5 Worldbreaker Drop | %s | %s"), Reward.CardId, Reward.CardName));
        LastLootMessage += FString::Printf(TEXT(" | T5 DROP 5%%: %s + %s"), Reward.EquipmentId, Reward.CardId);
    }
}
