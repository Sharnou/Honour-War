#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "HonourWarAccountSaveGame.generated.h"

UCLASS()
class HONOURWAR_API UHonourWarAccountSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY() FString Username;
    UPROPERTY() FString PasswordHash;
    UPROPERTY() FDateTime CreatedAtUtc;
    UPROPERTY() FDateTime LastLoginAtUtc;
};
