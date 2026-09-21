#pragma once

#include "CoreMinimal.h"
#include "HonourWarTypes.h"
#include "HonourWarClassProgression.generated.h"

UENUM(BlueprintType)
enum class EHonourWarClassTier : uint8
{
    Tier1 = 1 UMETA(DisplayName="Tier 1 — Foundation"),
    Tier2 = 2 UMETA(DisplayName="Tier 2 — Specialization"),
    Tier3 = 3 UMETA(DisplayName="Tier 3 — Advanced"),
    Tier4 = 4 UMETA(DisplayName="Tier 4 — Mastery"),
    Tier5 = 5 UMETA(DisplayName="Tier 5 — Transcendence")
};

UENUM(BlueprintType)
enum class EHonourWarFifthTierArchetype : uint8
{
    AbyssalWarlord,
    EternalSpellwright,
    CausalityMarksman,
    AbsoluteShadow,
    EternalBenediction,
    InfiniteQuartermaster,
    VerdantParagon
};

USTRUCT(BlueprintType)
struct FHonourWarFifthTierProfile
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly) EHonourWarClass BaseClass = EHonourWarClass::Warrior;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) EHonourWarFifthTierArchetype Archetype = EHonourWarFifthTierArchetype::AbyssalWarlord;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FString Name = TEXT("Warrior — Abyssal Warlord");
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FString Title = TEXT("The Gravitational Vanguard");
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FString PrimaryWeapon = TEXT("Transcendent Greatsword");
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FString SecondaryWeapon = TEXT("Abyssal Shield");
};

namespace HonourWarClassProgression
{
    inline int32 RequiredLevel(EHonourWarClassTier Tier)
    {
        switch (Tier)
        {
            case EHonourWarClassTier::Tier2: return 25;
            case EHonourWarClassTier::Tier3: return 50;
            case EHonourWarClassTier::Tier4: return 150;
            case EHonourWarClassTier::Tier5: return 200;
            default: return 1;
        }
    }

    inline EHonourWarClassTier TierForLevel(int32 Level)
    {
        const int32 L = FMath::Clamp(Level, 1, 250);
        if (L >= 200) return EHonourWarClassTier::Tier5;
        if (L >= 150) return EHonourWarClassTier::Tier4;
        if (L >= 50) return EHonourWarClassTier::Tier3;
        if (L >= 25) return EHonourWarClassTier::Tier2;
        return EHonourWarClassTier::Tier1;
    }

    inline FString TierName(EHonourWarClassTier Tier)
    {
        switch (Tier)
        {
            case EHonourWarClassTier::Tier2: return TEXT("Specialization");
            case EHonourWarClassTier::Tier3: return TEXT("Advanced");
            case EHonourWarClassTier::Tier4: return TEXT("Mastery");
            case EHonourWarClassTier::Tier5: return TEXT("Transcendence");
            default: return TEXT("Foundation");
        }
    }

    inline EHonourWarFifthTierArchetype NaturalFifthTier(EHonourWarClass ClassId)
    {
        switch (ClassId)
        {
            case EHonourWarClass::Mage: return EHonourWarFifthTierArchetype::EternalSpellwright;
            case EHonourWarClass::Archer: return EHonourWarFifthTierArchetype::CausalityMarksman;
            case EHonourWarClass::Thief: return EHonourWarFifthTierArchetype::AbsoluteShadow;
            case EHonourWarClass::Acolyte: return EHonourWarFifthTierArchetype::EternalBenediction;
            case EHonourWarClass::Merchant: return EHonourWarFifthTierArchetype::InfiniteQuartermaster;
            case EHonourWarClass::Ranger: return EHonourWarFifthTierArchetype::VerdantParagon;
            default: return EHonourWarFifthTierArchetype::AbyssalWarlord;
        }
    }

    inline FString FifthTierName(EHonourWarClass ClassId)
    {
        switch (ClassId)
        {
            case EHonourWarClass::Mage: return TEXT("Mage — Eternal Spellwright");
            case EHonourWarClass::Archer: return TEXT("Archer — Causality Marksman");
            case EHonourWarClass::Thief: return TEXT("Thief — Absolute Shadow");
            case EHonourWarClass::Acolyte: return TEXT("Acolyte — Eternal Benediction");
            case EHonourWarClass::Merchant: return TEXT("Merchant — Infinite Quartermaster");
            case EHonourWarClass::Ranger: return TEXT("Ranger — Verdant Paragon");
            default: return TEXT("Warrior — Abyssal Warlord");
        }
    }

    inline FHonourWarFifthTierProfile FifthTierProfile(EHonourWarClass ClassId)
    {
        FHonourWarFifthTierProfile P;
        P.BaseClass = ClassId;
        P.Archetype = NaturalFifthTier(ClassId);
        P.Name = FifthTierName(ClassId);

        switch (ClassId)
        {
            case EHonourWarClass::Mage:
                P.Title = TEXT("The Eternal Spellwright");
                P.PrimaryWeapon = TEXT("Chrono Arcane Staff");
                P.SecondaryWeapon = TEXT("Aether Focus");
                break;
            case EHonourWarClass::Archer:
                P.Title = TEXT("The Causality Marksman");
                P.PrimaryWeapon = TEXT("Doomsday Longbow");
                P.SecondaryWeapon = TEXT("Causality Quiver");
                break;
            case EHonourWarClass::Thief:
                P.Title = TEXT("The Absolute Shadow");
                P.PrimaryWeapon = TEXT("Causality Twin Daggers");
                P.SecondaryWeapon = TEXT("Voidstep Blade");
                break;
            case EHonourWarClass::Acolyte:
                P.Title = TEXT("The Eternal Benediction");
                P.PrimaryWeapon = TEXT("Chrono Sanctified Mace");
                P.SecondaryWeapon = TEXT("Seraphic Scripture");
                break;
            case EHonourWarClass::Merchant:
                P.Title = TEXT("The Infinite Quartermaster");
                P.PrimaryWeapon = TEXT("Matrix Forged Axe");
                P.SecondaryWeapon = TEXT("Fabricator Ledger");
                break;
            case EHonourWarClass::Ranger:
                P.Title = TEXT("The Verdant Paragon");
                P.PrimaryWeapon = TEXT("Worldroot Longbow");
                P.SecondaryWeapon = TEXT("Verdant Spirit Quiver");
                break;
            default:
                P.Title = TEXT("The Gravitational Vanguard");
                P.PrimaryWeapon = TEXT("Transcendent Greatsword");
                P.SecondaryWeapon = TEXT("Abyssal Shield");
                break;
        }
        return P;
    }
}
