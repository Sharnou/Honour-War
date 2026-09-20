#include "HonourWarCombatComponent.h"
#include "HonourWarCharacter.h"
#include "HonourWarMonster.h"
#include "Kismet/GameplayStatics.h"

UHonourWarCombatComponent::UHonourWarCombatComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
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
    const float LevelScale = 30.0f + Level * 8.0f;
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
    GainExperience(FMath::Max(1, FMath::RoundToInt(Damage * 0.08f)));
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
