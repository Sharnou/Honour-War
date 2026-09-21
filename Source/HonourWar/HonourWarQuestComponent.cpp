#include "HonourWarQuestComponent.h"
#include "HonourWarCombatComponent.h"
#include "Net/UnrealNetwork.h"

UHonourWarQuestComponent::UHonourWarQuestComponent()
{
    PrimaryComponentTick.bCanEverTick=false;
    SetIsReplicatedByDefault(true);
}

void UHonourWarQuestComponent::RecordMonsterDefeat(int32 MonsterLevel)
{
    if(!GetOwner() || !GetOwner()->HasAuthority() || bQuestComplete) return;

    if(!CombatComponent)
        CombatComponent=GetOwner()->FindComponentByClass<UHonourWarCombatComponent>();

    QuestProgress=FMath::Clamp(QuestProgress+1,0,QuestGoal);

    if(QuestProgress>=QuestGoal)
    {
        bQuestComplete=true;

        if(CombatComponent)
        {
            const int64 RewardZeny=25000LL+static_cast<int64>(FMath::Max(0,MonsterLevel))*50LL;
            CombatComponent->AddZeny(RewardZeny);
            CombatComponent->AddHonours(10);
            CombatComponent->AddQuestItem(TEXT("Lost Scroll"));
            CombatComponent->SetQuestMessage(FString::Printf(
                TEXT("QUEST COMPLETE | The Lost Scroll | +%lld Zeny | +10 Honours"),
                RewardZeny));
        }
    }
    else if(CombatComponent)
    {
        CombatComponent->SetQuestMessage(FString::Printf(
            TEXT("Quest progress | The Lost Scroll | %d / %d"),
            QuestProgress,QuestGoal));
    }
}

void UHonourWarQuestComponent::SetQuestState(int32 InQuestId,int32 InProgress,bool bInComplete)
{
    QuestId=FMath::Max(1,InQuestId);
    QuestProgress=FMath::Clamp(InProgress,0,QuestGoal);
    bQuestComplete=bInComplete;
}

FString UHonourWarQuestComponent::GetQuestTitle() const
{
    return TEXT("The Lost Scroll");
}

FString UHonourWarQuestComponent::GetQuestBody() const
{
    if(bQuestComplete)
        return TEXT("Quest complete. The lost scroll has been recovered.");
    return FString::Printf(
        TEXT("Defeat monsters to recover the lost scroll.\nProgress %d / %d"),
        QuestProgress,QuestGoal);
}

void UHonourWarQuestComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(UHonourWarQuestComponent,QuestId);
    DOREPLIFETIME(UHonourWarQuestComponent,QuestProgress);
    DOREPLIFETIME(UHonourWarQuestComponent,bQuestComplete);
}
