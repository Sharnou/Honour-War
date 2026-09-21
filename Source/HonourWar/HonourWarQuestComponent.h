#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "HonourWarQuestComponent.generated.h"

class UHonourWarCombatComponent;

UCLASS(ClassGroup=(HonourWar),meta=(BlueprintSpawnableComponent))
class HONOURWAR_API UHonourWarQuestComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    UHonourWarQuestComponent();

    void RecordMonsterDefeat(int32 MonsterLevel);
    void SetQuestState(int32 InQuestId,int32 InProgress,bool bInComplete);

    int32 GetQuestId() const { return QuestId; }
    int32 GetQuestProgress() const { return QuestProgress; }
    int32 GetQuestGoal() const { return QuestGoal; }
    bool IsQuestComplete() const { return bQuestComplete; }
    FString GetQuestTitle() const;
    FString GetQuestBody() const;

protected:
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

private:
    UPROPERTY() UHonourWarCombatComponent* CombatComponent=nullptr;
    UPROPERTY(Replicated) int32 QuestId=1;
    UPROPERTY(Replicated) int32 QuestProgress=0;
    UPROPERTY(Replicated) bool bQuestComplete=false;
    static constexpr int32 QuestGoal=5;
};
