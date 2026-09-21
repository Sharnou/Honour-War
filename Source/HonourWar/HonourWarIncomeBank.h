#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HonourWarIncomeBank.generated.h"

class UStaticMeshComponent;
class AHonourWarMonster;

UCLASS()
class HONOURWAR_API AHonourWarIncomeBank : public AActor
{
    GENERATED_BODY()

public:
    AHonourWarIncomeBank();
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    void InitializeBank(int32 InBankId, AHonourWarMonster* InGuardian);
    bool IsUnlocked() const { return bUnlocked; }
    int32 GetBankId() const { return BankId; }

private:
    bool HasOccupyingSoldier() const;
    void BuildVisual();

    UPROPERTY() UStaticMeshComponent* Base = nullptr;
    UPROPERTY() UStaticMeshComponent* Core = nullptr;
    UPROPERTY() AHonourWarMonster* Guardian = nullptr;

    UPROPERTY(EditAnywhere) int32 BankId = 0;
    UPROPERTY(EditAnywhere) int64 ZenyPerSecond = 250;
    bool bUnlocked = false;
    float IncomeAccumulator = 0.0f;
};
