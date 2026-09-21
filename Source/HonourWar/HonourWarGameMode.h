#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "HonourWarGameMode.generated.h"

UCLASS()
class HONOURWAR_API AHonourWarGameMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    AHonourWarGameMode();
    virtual void BeginPlay() override;
    virtual void PostLogin(APlayerController* NewPlayer) override;
    virtual void PreLogin(const FString& Options,const FString& Address,const FUniqueNetIdRepl& UniqueId,FString& ErrorMessage) override;
};
