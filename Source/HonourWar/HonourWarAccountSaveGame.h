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
    UPROPERTY() int32 Level=1;
    UPROPERTY() int32 EquipmentRefineLevel=0;
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
