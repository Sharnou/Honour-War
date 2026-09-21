#include "HonourWarCombatComponent.h"
#include "HonourWarCharacter.h"
#include "HonourWarMonster.h"
#include "HonourWarLootDatabase.h"
#include "Kismet/GameplayStatics.h"

UHonourWarCombatComponent::UHonourWarCombatComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
    SetIsReplicatedByDefault(true);
    SkillCooldowns.Init(0.0f, 8);
}

void UHonourWarCombatComponent::BeginPlay()
{
    Super::BeginPlay();
    MaxHealth = 1200.0f + (Level - 1) * 120.0f;
    CurrentHealth = MaxHealth;
    MaxSp = 500.0f + (Level - 1) * 45.0f;
    CurrentSp = MaxSp;
    XpToNextLevel = FMath::Max(100, Level * 120);
}

void UHonourWarCombatComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
    for (float& Cooldown : SkillCooldowns) Cooldown = FMath::Max(0.0f, Cooldown - DeltaTime);
    CurrentSp = FMath::Min(MaxSp, CurrentSp + DeltaTime * 5.0f);
}

float UHonourWarCombatComponent::SkillRangeForClass() const
{
    switch (CharacterClass)
    {
        case EHonourWarClass::Mage: return 750.0f;
        case EHonourWarClass::Archer: return 1200.0f;
        case EHonourWarClass::Ranger: return 1350.0f;
        case EHonourWarClass::Acolyte: return 500.0f;
        case EHonourWarClass::Thief: return 220.0f;
        default: return 240.0f;
    }
}

float UHonourWarCombatComponent::BaseDamageForClass() const
{
    const float AgeYears = 18.0f + static_cast<float>(AgeDays) / 3.0f;
    const float AgeMultiplier = 1.0f + FMath::Clamp((AgeYears - 18.0f) * 0.005f, 0.0f, 1.0f);
    const float LevelScale = (30.0f + Level * 8.0f) * AgeMultiplier * (1.0f + BasicSkillLevel * 0.06f);
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
    if (GetOwner() && !GetOwner()->HasAuthority())
    {
        ServerUseSkill(FMath::Clamp(SkillIndex,0,7));
        return true;
    }

    if (!SkillCooldowns.IsValidIndex(SkillIndex) || SkillCooldowns[SkillIndex] > 0.0f) return false;

    const float ManaCost = 18.0f + SkillIndex * 4.0f;
    if (CurrentSp < ManaCost) return false;

    AHonourWarMonster* Target = FindNearestTarget(SkillRangeForClass());
    if (!Target) return false;

    const float Damage = BaseDamageForClass() * (1.0f + SkillIndex * 0.18f);
    CurrentSp -= ManaCost;
    SkillCooldowns[SkillIndex] = 0.45f + SkillIndex * 0.08f;
    LastTarget = Target;

    Target->ReceiveCombatHit(Damage, CharacterClass);
    if (Target->IsDead())
    {
        if (AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwner()))
            Character->HandleMonsterDefeat(Target->GetMonsterLevel());
    }
    else
    {
        GainExperience(FMath::Max(1, FMath::RoundToInt(Damage * 0.08f)));
    }
    OnSkillUsed.Broadcast(SkillIndex, Damage);
    return true;
}

void UHonourWarCombatComponent::ReceiveDamage(float Damage)
{
    if(!GetOwner() || !GetOwner()->HasAuthority()) return;
    CurrentHealth = FMath::Max(0.0f, CurrentHealth - FMath::Max(0.0f, Damage));
    if (CurrentHealth <= 0.0f)
    {
        if (AHonourWarCharacter* Character = Cast<AHonourWarCharacter>(GetOwner()))
            Character->HandleDeathAndRespawn();
    }
}

bool UHonourWarCombatComponent::ReceivePlayerDamage(float Damage)
{
    if(!GetOwner() || !GetOwner()->HasAuthority()) return false;
    if(CurrentHealth<=0.0f) return false;

    CurrentHealth=FMath::Max(0.0f,CurrentHealth-FMath::Max(0.0f,Damage));
    if(CurrentHealth<=0.0f)
    {
        if(AHonourWarCharacter* Character=Cast<AHonourWarCharacter>(GetOwner()))
            Character->HandleDeathAndRespawn();
        return true;
    }
    return false;
}

void UHonourWarCombatComponent::AddHonours(int32 Amount)
{
    if(Amount>0) Honours+=Amount;
}

bool UHonourWarCombatComponent::UseSkillOnPlayer(AHonourWarCharacter* Target)
{
    if(!Target || Target==GetOwner()) return false;
    if(GetOwner() && !GetOwner()->HasAuthority())
    {
        ServerUseSkillOnPlayer(Target);
        return true;
    }

    AHonourWarCharacter* Attacker=Cast<AHonourWarCharacter>(GetOwner());
    if(!Attacker || !Attacker->CanAttackPlayer(Target)) return false;

    const float ManaCost=24.0f;
    if(CurrentSp<ManaCost) return false;

    const float Damage=BaseDamageForClass()*(1.0f+BasicSkillLevel*0.06f);
    CurrentSp-=ManaCost;
    Target->ReceivePlayerDamage(Damage,Attacker);

    if(UWorld* World=GetWorld())
    {
        const FHonourWarClassStyle Style=HonourWarClassStyle(CharacterClass);
        if(AHonourWarCombatEffect* Effect=World->SpawnActor<AHonourWarCombatEffect>(
            AHonourWarCombatEffect::StaticClass(),Target->GetActorLocation()+FVector(0,0,130),FRotator::ZeroRotator))
            Effect->Initialize(Style.Accent,FMath::Clamp(Damage/80.0f,0.8f,1.8f),Damage>=90.0f);
        if(AHonourWarDamagePopup* Popup=World->SpawnActor<AHonourWarDamagePopup>(
            AHonourWarDamagePopup::StaticClass(),Target->GetActorLocation()+FVector(0,0,230),FRotator(0,180,0)))
            Popup->Initialize(Damage,Style.Accent,Damage>=90.0f);
    }

    return true;
}

void UHonourWarCombatComponent::RestoreVitals()
{
    CurrentHealth = MaxHealth;
    CurrentSp = MaxSp;
}

void UHonourWarCombatComponent::GainExperience(int32 Amount)
{
    Experience += Amount;
    while (Experience >= XpToNextLevel && Level < 250)
    {
        Experience -= XpToNextLevel;
        ++Level;
        MaxHealth += 120.0f;
        MaxSp += 45.0f;
        RestoreVitals();
        XpToNextLevel = FMath::Max(100, Level * 120);
    }
}

void UHonourWarCombatComponent::SetClassId(EHonourWarClass NewClass){ CharacterClass = NewClass; }
void UHonourWarCombatComponent::SetLevel(int32 NewLevel)
{
    Level = FMath::Clamp(NewLevel,1,250);
    MaxHealth = 1200.0f + (Level - 1) * 120.0f;
    MaxSp = 500.0f + (Level - 1) * 45.0f;
    XpToNextLevel = FMath::Max(100, Level * 120);
    RestoreVitals();
}
void UHonourWarCombatComponent::SetExperience(int32 NewExperience){ Experience = FMath::Max(0, NewExperience); }
void UHonourWarCombatComponent::SetAgeDays(int32 NewAgeDays){ AgeDays = FMath::Max(0, NewAgeDays); }
void UHonourWarCombatComponent::SetZeny(int64 NewZeny){ Zeny = FMath::Max<int64>(0, NewZeny); }
void UHonourWarCombatComponent::AddZeny(int64 Amount){ if(Amount>0) Zeny+=Amount; }
void UHonourWarCombatComponent::SetEquipmentRefineLevel(int32 NewRefine){ EquipmentRefineLevel = FMath::Clamp(NewRefine,0,15); }
void UHonourWarCombatComponent::SetPhracon(int32 Value){ Phracon = FMath::Max(0,Value); }
void UHonourWarCombatComponent::SetEmveretarcon(int32 Value){ Emveretarcon = FMath::Max(0,Value); }
void UHonourWarCombatComponent::SetOridecon(int32 Value){ Oridecon = FMath::Max(0,Value); }
void UHonourWarCombatComponent::SetBasicSkillLevel(int32 Value){ BasicSkillLevel=FMath::Clamp(Value,1,10); }

bool UHonourWarCombatComponent::TryMixCards()
{
    if (GetOwner() && !GetOwner()->HasAuthority())
    {
        ServerTryMixCards();
        return true;
    }

    if (Cards.Num() < 3)
    {
        LastLootMessage=TEXT("Card Mixing blocked | need 3 cards.");
        return false;
    }

    const int64 AgeDiscountedCost=FMath::Max<int64>(1000LL,static_cast<int64>(
        FMath::RoundToFloat(5000.0f*(1.0f-FMath::Clamp(static_cast<float>(AgeDays)*0.005f,0.0f,0.60f)))));
    if (Zeny<AgeDiscountedCost)
    {
        LastLootMessage=FString::Printf(TEXT("Card Mixing blocked | need %lld Zeny."),AgeDiscountedCost);
        return false;
    }

    const FString A=Cards[0];
    const FString B=Cards[1];
    const FString C=Cards[2];
    Cards.RemoveAt(0);
    Cards.RemoveAt(0);
    Cards.RemoveAt(0);
    Zeny-=AgeDiscountedCost;
    const FString Mixed=FString::Printf(TEXT("Mixed Card | %s + %s + %s"),*A,*B,*C);
    Cards.Insert(Mixed,0);
    LastLootMessage=FString::Printf(TEXT("CARD MIX SUCCESS | %s | %lld Zeny"),*Mixed,AgeDiscountedCost);
    return true;
}

bool UHonourWarCombatComponent::TryUpgradeBasicSkill()
{
    if (GetOwner() && !GetOwner()->HasAuthority())
    {
        ServerTryUpgradeBasicSkill();
        return true;
    }

    if (BasicSkillLevel>=10)
    {
        LastLootMessage=TEXT("Basic Skill is already at level 10.");
        return false;
    }

    const float AgeDiscount=FMath::Clamp(static_cast<float>(AgeDays)*0.005f,0.0f,0.60f);
    const int64 Cost=FMath::Max<int64>(1000LL,static_cast<int64>(
        FMath::RoundToFloat((2500.0f+BasicSkillLevel*1750.0f)*(1.0f-AgeDiscount))));
    if (Zeny<Cost)
    {
        LastLootMessage=FString::Printf(TEXT("Basic Skill upgrade blocked | need %lld Zeny."),Cost);
        return false;
    }

    Zeny-=Cost;
    ++BasicSkillLevel;
    LastLootMessage=FString::Printf(TEXT("Basic Skill upgraded to Lv.%d | %lld Zeny | age discount %.0f%%"),BasicSkillLevel,Cost,AgeDiscount*100.0f);
    return true;
}

float UHonourWarCombatComponent::GetRefineSuccessPercent() const
{
    if (EquipmentRefineLevel>=15) return 0.0f;
    const float BaseSuccess=100.0f-static_cast<float>(EquipmentRefineLevel+1)*5.5f;
    const float AgeBonus=FMath::Min(25.0f,static_cast<float>(AgeDays)*0.25f);
    return FMath::Clamp(BaseSuccess+AgeBonus,5.0f,99.5f);
}

int64 UHonourWarCombatComponent::GetRefineZenyCost() const
{
    const float AgeDiscount=FMath::Clamp(static_cast<float>(AgeDays)*0.005f,0.0f,0.60f);
    const int64 BaseCost=1000LL+static_cast<int64>(EquipmentRefineLevel)*1500LL;
    return FMath::Max<int64>(1,static_cast<int64>(FMath::RoundToFloat(static_cast<float>(BaseCost)*(1.0f-AgeDiscount))));
}

bool UHonourWarCombatComponent::TryRefineEquipment()
{
    if (GetOwner() && !GetOwner()->HasAuthority())
    {
        ServerTryRefineEquipment();
        return true;
    }

    if (EquipmentRefineLevel>=15)
    {
        LastLootMessage=TEXT("Equipment is already at maximum refinement +15.");
        return false;
    }

    const float AgeDiscount=FMath::Clamp(static_cast<float>(AgeDays)*0.005f,0.0f,0.60f);
    const int32 OreCost=FMath::Max(1,FMath::CeilToInt((1.0f+static_cast<float>(EquipmentRefineLevel)/4.0f)*(1.0f-AgeDiscount)));
    int32& PrimaryMaterial = EquipmentRefineLevel<5 ? Phracon : (EquipmentRefineLevel<10 ? Emveretarcon : Oridecon);

    if (Zeny<GetRefineZenyCost() || PrimaryMaterial<OreCost)
    {
        LastLootMessage=FString::Printf(TEXT("Refine +%d blocked | need %lld Zeny + %d ore."),EquipmentRefineLevel+1,GetRefineZenyCost(),OreCost);
        return false;
    }

    Zeny-=GetRefineZenyCost();
    PrimaryMaterial-=OreCost;

    const float Roll=FMath::FRandRange(0.0f,100.0f);
    const float Success=GetRefineSuccessPercent();
    if (Roll<=Success)
    {
        ++EquipmentRefineLevel;
        LastLootMessage=FString::Printf(TEXT("Refinement SUCCESS | equipment +%d | %.1f%% success | age discount %.0f%%"),EquipmentRefineLevel,Success,AgeDiscount*100.0f);
        return true;
    }

    LastLootMessage=FString::Printf(TEXT("Refinement FAILED | equipment remains +%d | %.1f%% success | materials consumed"),EquipmentRefineLevel,Success);
    return false;
}
void UHonourWarCombatComponent::SetHonours(int32 NewHonours){ Honours = FMath::Max(0, NewHonours); }
void UHonourWarCombatComponent::SetInventoryItems(const TArray<FString>& NewItems){ InventoryItems = NewItems; }
void UHonourWarCombatComponent::SetCards(const TArray<FString>& NewCards){ Cards = NewCards; }

void UHonourWarCombatComponent::RewardMonsterDefeat(int32 MonsterLevel)
{
    const int32 SafeLevel = FMath::Clamp(MonsterLevel, 1, 300);
    const int32 KillXp = SafeLevel >= 300 ? 50000 : FMath::Max(25, SafeLevel * 35);
    const int64 ZenyReward = SafeLevel >= 300 ? 250000 : static_cast<int64>(SafeLevel) * 45 + 75;
    const int32 HonourReward = SafeLevel >= 300 ? 100 : FMath::Max(1, SafeLevel / 10);

    GainExperience(KillXp);
    Zeny += ZenyReward;
    Honours += HonourReward;

    FString Rarity = TEXT("Rare");
    if (SafeLevel >= 300) Rarity = TEXT("Mythic");
    else if (SafeLevel >= 200) Rarity = TEXT("Legendary");
    else if (SafeLevel >= 100) Rarity = TEXT("Epic");

    const int32 LootRank = FMath::Clamp(101 - FMath::RoundToInt(static_cast<float>(SafeLevel) * 100.0f / 300.0f), 1, 100);
    const FString DatabaseItem = HonourWarLootDatabase::ItemForRank(LootRank);
    const FString ItemName = FString::Printf(TEXT("%s | %s"), *Rarity, *DatabaseItem);
    InventoryItems.Add(ItemName);

    if (SafeLevel >= 100)
    {
        const FString DatabaseCard = HonourWarLootDatabase::CardForRank(LootRank);
        Cards.Add(DatabaseCard);
    }

    if (SafeLevel >= 300)
    {
        Cards.Add(TEXT("World Monarch Card"));
        InventoryItems.Add(TEXT("Transcendent Monster Suit"));
        LastLootMessage = FString::Printf(TEXT("Lv.%d MONSTER DEFEATED | %lld Zeny | Mythic | %s | World Monarch Card | +%d XP"), SafeLevel, ZenyReward, *DatabaseItem, KillXp);
    }
    else
    {
        LastLootMessage = FString::Printf(TEXT("Lv.%d defeated | %lld Zeny | %s | +%d XP"), SafeLevel, ZenyReward, *ItemName, KillXp);
    }
}


void UHonourWarCombatComponent::ServerUseSkill_Implementation(int32 SkillIndex)
{
    UseSkill(SkillIndex);
}

void UHonourWarCombatComponent::ServerTryRefineEquipment_Implementation()
{
    TryRefineEquipment();
}

void UHonourWarCombatComponent::ServerTryMixCards_Implementation()
{
    TryMixCards();
}

void UHonourWarCombatComponent::ServerTryUpgradeBasicSkill_Implementation()
{
    TryUpgradeBasicSkill();
}


void UHonourWarCombatComponent::ServerUseSkillOnPlayer_Implementation(AHonourWarCharacter* Target)
{
    UseSkillOnPlayer(Target);
}
