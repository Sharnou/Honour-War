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
    CurrentHealth = FMath::Max(0.0f, CurrentHealth - FMath::Max(0.0f, Damage));
    if (CurrentHealth <= 0.0f)
    {
        if (AHonourWarCharacter* Character = Cast<AHonourWarCharacter>(GetOwner()))
            Character->HandleDeathAndRespawn();
    }
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


