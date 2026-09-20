#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "HonourWarTypes.h"
#include "HonourWarClassProgression.h"
#include "HonourWarSaveGame.generated.h"

UCLASS()
class HONOURWAR_API UHonourWarSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY() int32 Level = 1;
    UPROPERTY() int32 Experience = 0;
    UPROPERTY() int32 AgeDays = 0;
    UPROPERTY() EHonourWarClass ClassId = EHonourWarClass::Warrior;
    UPROPERTY() EHonourWarClassTier ClassTier = EHonourWarClassTier::Tier1;
    UPROPERTY() EHonourWarFifthTierArchetype FifthTierArchetype = EHonourWarFifthTierArchetype::AbyssalWarlord;
    UPROPERTY() FDateTime SavedAtUtc;
};
