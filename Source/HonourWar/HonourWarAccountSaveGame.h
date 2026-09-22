#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "HonourWarTypes.h"
#include "HonourWarAccountSaveGame.generated.h"

USTRUCT()
struct FHonourWarCharacterSlot
{
    GENERATED_BODY()

    UPROPERTY() bool bOwned=false;
    UPROPERTY() FString CharacterName;
    UPROPERTY() EHonourWarClass ClassId=EHonourWarClass::Warrior;
    UPROPERTY() EHonourWarClassTier ClassTier=EHonourWarClassTier::Tier1;
    UPROPERTY() EHonourWarFifthTierArchetype FifthTierArchetype=EHonourWarFifthTierArchetype::AbyssalWarlord;
    UPROPERTY() int32 Level=1;
    UPROPERTY() int32 Experience=0;
    UPROPERTY() int32 AgeDays=0;
    UPROPERTY() int64 OnlineSeconds=0;
    UPROPERTY() FVector PlayerLocation=FVector::ZeroVector;
    UPROPERTY() int64 Zeny=0;
    UPROPERTY() int32 EquipmentRefineLevel=0;
    UPROPERTY() int32 Phracon=20;
    UPROPERTY() int32 Emveretarcon=10;
    UPROPERTY() int32 Oridecon=5;
    UPROPERTY() int32 BasicSkillLevel=1;
    UPROPERTY() int32 Honours=0;
    UPROPERTY() TArray<FString> InventoryItems;
    UPROPERTY() TArray<FString> Cards;
    UPROPERTY() int32 QuestId=1;
    UPROPERTY() int32 QuestProgress=0;
    UPROPERTY() bool QuestComplete=false;
    UPROPERTY() FString GuildName;
    UPROPERTY() FString GuildRank=TEXT("Member");
    UPROPERTY() FDateTime SavedAtUtc;
};

UCLASS()
class HONOURWAR_API UHonourWarAccountSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY() FString Username;
    UPROPERTY() FString PasswordHash;
    UPROPERTY() FDateTime CreatedAtUtc;
    UPROPERTY() FDateTime LastLoginAtUtc;
    UPROPERTY() TArray<FHonourWarCharacterSlot> Characters;
};
