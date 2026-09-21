// Honour War current HD MMORPG runtime contract revision.
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "HonourWarTypes.h"
#include "HonourWarClassProgression.h"
#include "HonourWarCharacter.generated.h"

class UCameraComponent;
class UTextRenderComponent;
class USpringArmComponent;
class UHonourWarCombatComponent;
class UHonourWarQuestComponent;
class AHonourWarMonster;

UCLASS()
class HONOURWAR_API AHonourWarCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AHonourWarCharacter();
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

    void MoveForward(float Value);
    void MoveRight(float Value);
    void CameraTurn(float Value);
    void CameraLookUp(float Value);
    void Attack();
    void ActivateSkill(int32 SkillIndex);
    void SaveProgress();
    void LoadProgress();
    void HandleDeathAndRespawn();
    void ReceiveMonsterDamage(float Damage);
    void HandleMonsterDefeat(int32 MonsterLevel);
    UFUNCTION(BlueprintCallable) UHonourWarQuestComponent* GetQuestComponent() const { return QuestComponent; }
    void RefineEquipment();
    void MixCards();
    void UpgradeBasicSkill();
    void CycleClass();

    void SetMouseDestination(const FVector& Destination);
    void SetMouseTarget(AHonourWarMonster* Target);
    void ClearMouseCommand();
    void AdjustCameraZoom(float WheelDelta);

    UFUNCTION(BlueprintCallable) EHonourWarClass GetClassId() const;
    UFUNCTION(BlueprintCallable) FString GetClassName() const;
    UFUNCTION(BlueprintCallable) EHonourWarClassTier GetClassTier() const;
    UFUNCTION(BlueprintCallable) FString GetClassTierName() const;
    UFUNCTION(BlueprintCallable) FString GetFifthTierClassName() const;
    UFUNCTION(BlueprintCallable) UHonourWarCombatComponent* GetCombatComponent() const { return CombatComponent; }
    UFUNCTION(BlueprintCallable) FString GetLastCombatMessage() const { return LastCombatMessage; }
    UFUNCTION(Server, Reliable)
    void ServerSetClassId(EHonourWarClass NewClass);
    void SetClassId(EHonourWarClass NewClass);

private:
    void BuildHeroVisual();
    void BuildWeaponVisual();
    void BuildFifthTierVisual();
    UFUNCTION()
    void OnRepCharacterClass();

    UPROPERTY(VisibleAnywhere) USpringArmComponent* CameraBoom;
    UPROPERTY(VisibleAnywhere) UCameraComponent* FollowCamera;
    UPROPERTY(VisibleAnywhere) UHonourWarCombatComponent* CombatComponent;
    UPROPERTY(VisibleAnywhere) UHonourWarQuestComponent* QuestComponent;
    UPROPERTY() USceneComponent* VisualRoot;
    UPROPERTY() UTextRenderComponent* PlayerNameplate = nullptr;
    UPROPERTY() FString LastCombatMessage = TEXT("Ready");
    UPROPERTY(ReplicatedUsing=OnRepCharacterClass) EHonourWarClass CharacterClass = EHonourWarClass::Warrior;
    UPROPERTY() FVector RespawnPoint = FVector(900.0f, 900.0f, 180.0f);
    UPROPERTY() AHonourWarMonster* MouseTarget = nullptr;
    UPROPERTY() FVector MouseDestination = FVector::ZeroVector;
    UPROPERTY() bool bMouseMoveActive = false;
    UPROPERTY() int64 OnlineSeconds = 0;
    float AutoSaveAccumulator = 0.0f;
};