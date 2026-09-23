#pragma once

#include "CoreMinimal.h"

UENUM(BlueprintType)
enum class EHonourWarClass : uint8
{
    Warrior,
    Mage,
    Archer,
    Thief,
    Acolyte,
    Merchant,
    Ranger
};

UENUM(BlueprintType)
enum class EHonourWarStatusStat : uint8
{
    Strength,
    Agility,
    Vitality,
    Intelligence,
    Dexterity,
    Luck
};

inline FString HonourWarStatusStatName(EHonourWarStatusStat Stat)
{
    switch(Stat)
    {
        case EHonourWarStatusStat::Strength: return TEXT("STR");
        case EHonourWarStatusStat::Agility: return TEXT("AGI");
        case EHonourWarStatusStat::Vitality: return TEXT("VIT");
        case EHonourWarStatusStat::Intelligence: return TEXT("INT");
        case EHonourWarStatusStat::Dexterity: return TEXT("DEX");
        case EHonourWarStatusStat::Luck: return TEXT("LUK");
        default: return TEXT("STR");
    }
}

inline FString HonourWarClassName(EHonourWarClass ClassId)
{
    switch (ClassId)
    {
        case EHonourWarClass::Warrior: return TEXT("Warrior");
        case EHonourWarClass::Mage: return TEXT("Mage");
        case EHonourWarClass::Archer: return TEXT("Archer");
        case EHonourWarClass::Thief: return TEXT("Thief");
        case EHonourWarClass::Acolyte: return TEXT("Acolyte");
        case EHonourWarClass::Merchant: return TEXT("Merchant");
        case EHonourWarClass::Ranger: return TEXT("Ranger");
        default: return TEXT("Warrior");
    }
}

struct FHonourWarClassStyle
{
    FLinearColor Primary;
    FLinearColor Secondary;
    FLinearColor Accent;
};

inline FHonourWarClassStyle HonourWarClassStyle(EHonourWarClass ClassId)
{
    switch (ClassId)
    {
        case EHonourWarClass::Mage:
            return {FLinearColor(0.28f,0.38f,0.90f),FLinearColor(0.12f,0.10f,0.24f),FLinearColor(0.65f,0.80f,1.00f)};
        case EHonourWarClass::Archer:
            return {FLinearColor(0.26f,0.52f,0.22f),FLinearColor(0.12f,0.17f,0.10f),FLinearColor(0.70f,0.95f,0.45f)};
        case EHonourWarClass::Thief:
            return {FLinearColor(0.24f,0.20f,0.28f),FLinearColor(0.08f,0.07f,0.10f),FLinearColor(0.82f,0.45f,0.95f)};
        case EHonourWarClass::Acolyte:
            return {FLinearColor(0.82f,0.75f,0.95f),FLinearColor(0.18f,0.12f,0.20f),FLinearColor(1.00f,0.92f,0.55f)};
        case EHonourWarClass::Merchant:
            return {FLinearColor(0.63f,0.38f,0.18f),FLinearColor(0.16f,0.10f,0.06f),FLinearColor(1.00f,0.72f,0.26f)};
        case EHonourWarClass::Ranger:
            return {FLinearColor(0.20f,0.44f,0.30f),FLinearColor(0.09f,0.13f,0.10f),FLinearColor(0.58f,0.88f,0.68f)};
        default:
            return {FLinearColor(0.52f,0.22f,0.13f),FLinearColor(0.12f,0.08f,0.06f),FLinearColor(1.00f,0.55f,0.20f)};
    }
}
