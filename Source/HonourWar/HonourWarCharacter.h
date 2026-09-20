#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "HonourWarTypes.h"
#include "HonourWarCharacter.generated.h"

class UCameraComponent;
class USpringArmComponent;
class UHonourWarCombatComponent;

UCLASS()
class HONOURWAR_API AHonourWarCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AHonourWarCharacter();
    virtual void BeginPlay() override;

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
    void CycleClass();

    UFUNCTION(BlueprintCallable) EHonourWarClass GetClassId() const;
    UFUNCTION(BlueprintCallable) FString GetClassName() const;
    UFUNCTION(BlueprintCallable) UHonourWarCombatComponent* GetCombatComponent() const { return CombatComponent; }
    UFUNCTION(BlueprintCallable) FString GetLastCombatMessage() const { return LastCombatMessage; }
    void SetClassId(EHonourWarClass NewClass);

private:
    void BuildHeroVisual();
    void BuildWeaponVisual();

    UPROPERTY(VisibleAnywhere) USpringArmComponent* CameraBoom;
    UPROPERTY(VisibleAnywhere) UCameraComponent* FollowCamera;
    UPROPERTY(VisibleAnywhere) UHonourWarCombatComponent* CombatComponent;
    UPROPERTY() USceneComponent* VisualRoot;
    UPROPERTY() FString LastCombatMessage = TEXT("Ready");
    UPROPERTY() EHonourWarClass CharacterClass = EHonourWarClass::Warrior;
    UPROPERTY() FVector RespawnPoint = FVector(900.0f, 900.0f, 180.0f);
};
