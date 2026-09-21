#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "HonourWarGameMode.generated.h"

class AHonourWarCharacter;

UCLASS()
class HONOURWAR_API AHonourWarGameMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    AHonourWarGameMode();
    virtual void BeginPlay() override;
    bool HandleGuildCommand(AHonourWarCharacter* Character,const FString& Command,FString& OutMessage);
    bool HandleChatCommand(AHonourWarCharacter* Character,const FString& Message,FString& OutMessage);
};
