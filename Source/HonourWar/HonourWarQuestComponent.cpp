#include "HonourWarQuestComponent.h"
#include "HonourWarCombatComponent.h"
#include "Net/UnrealNetwork.h"

namespace
{
    const UHonourWarQuestComponent::FQuestDefinition QuestDefinitions[] =
    {
        {1,TEXT("The Lost Scroll"),TEXT("Recover a stolen royal scroll from roaming monsters."),TEXT("Any"),1,5,25000,10,TEXT("Lost Scroll")},
        {2,TEXT("Meadow Cleanup"),TEXT("Push the monsters away from the eastern meadow roads."),TEXT("Any"),10,8,18000,8,TEXT("Meadow Sigil")},
        {3,TEXT("Wolf Threat"),TEXT("Track the wolves that are closing in on the frontier paths."),TEXT("Wolf"),30,6,26000,12,TEXT("Wolf Fang Trophy")},
        {4,TEXT("Graveyard Silence"),TEXT("Break the skeleton wave before it reaches the ancient ruins."),TEXT("Skeleton"),50,8,32000,15,TEXT("Graveyard Seal")},
        {5,TEXT("Orc Breaker"),TEXT("Defeat veteran orcs guarding the mountain approach."),TEXT("Orc"),80,6,44000,18,TEXT("Orc War Medal")},
        {6,TEXT("Mantis Hunt"),TEXT("Hunt mantises through the deep green forest."),TEXT("Mantis"),100,10,52000,20,TEXT("Mantis Carapace")},
        {7,TEXT("Iron Colossus"),TEXT("Shatter the golems awakening around the iron pass."),TEXT("Golem"),100,5,65000,24,TEXT("Colossus Core")},
        {8,TEXT("Dragon Relic"),TEXT("Bring down ancient dragons and recover their relic fragments."),TEXT("Dragon"),150,3,95000,30,TEXT("Dragon Relic")},
        {9,TEXT("Elite Pursuit"),TEXT("Prove your battle mastery against elite monsters."),TEXT("Any"),150,5,110000,35,TEXT("Elite Crest")},
        {10,TEXT("Mythic Hunt"),TEXT("Defeat mythic-level monsters and survive the pressure."),TEXT("Any"),200,5,150000,45,TEXT("Mythic Hunt Seal")},
        {11,TEXT("World Monarch Trial"),TEXT("Defeat one level 300 monster to claim a monarch's proof."),TEXT("Any"),300,1,300000,100,TEXT("Monarch Proof")},
        {12,TEXT("Honour Beyond Limits"),TEXT("Complete a final mixed hunt using monsters from the upper world."),TEXT("Any"),230,8,220000,60,TEXT("Crown of Honour")}
    };
}

UHonourWarQuestComponent::UHonourWarQuestComponent()
{
    PrimaryComponentTick.bCanEverTick=false;
    SetIsReplicatedByDefault(true);
}

const UHonourWarQuestComponent::FQuestDefinition& UHonourWarQuestComponent::DefinitionFor(int32 InQuestId)
{
    const int32 Index=FMath::Clamp(InQuestId,1,QuestCount)-1;
    return QuestDefinitions[Index];
}

int32 UHonourWarQuestComponent::GetQuestGoal() const
{
    return DefinitionFor(QuestId).Goal;
}

void UHonourWarQuestComponent::RecordMonsterDefeat(int32 MonsterLevel,const FString& MonsterSpecies)
{
    if(!GetOwner() || !GetOwner()->HasAuthority()) return;

    if(!CombatComponent)
        CombatComponent=GetOwner()->FindComponentByClass<UHonourWarCombatComponent>();

    if(bQuestComplete)
    {
        QuestId=(QuestId%QuestCount)+1;
        QuestProgress=0;
        bQuestComplete=false;
    }

    const FQuestDefinition& Quest=DefinitionFor(QuestId);
    const bool bSpeciesMatch=FString(Quest.RequiredSpecies).Equals(TEXT("Any"),ESearchCase::IgnoreCase)
        || MonsterSpecies.Equals(Quest.RequiredSpecies,ESearchCase::IgnoreCase);
    const bool bLevelMatch=MonsterLevel>=Quest.RequiredLevel;

    if(!bSpeciesMatch || !bLevelMatch)
    {
        if(CombatComponent)
        {
            const FString Requirement=FString::Printf(
                TEXT("Quest target | %s | need %s Lv.%d | progress %d/%d"),
                Quest.Title,Quest.RequiredSpecies,Quest.RequiredLevel,QuestProgress,Quest.Goal);
            CombatComponent->SetQuestMessage(Requirement);
        }
        return;
    }

    QuestProgress=FMath::Clamp(QuestProgress+1,0,Quest.Goal);

    if(QuestProgress>=Quest.Goal)
    {
        bQuestComplete=true;
        if(CombatComponent)
        {
            const int64 RewardZeny=Quest.RewardZeny+static_cast<int64>(FMath::Max(0,MonsterLevel))*20LL;
            CombatComponent->AddZeny(RewardZeny);
            CombatComponent->AddHonours(Quest.RewardHonour);
            CombatComponent->AddQuestItem(Quest.RewardItem);
            CombatComponent->SetQuestMessage(FString::Printf(
                TEXT("QUEST COMPLETE | %s | +%lld Zeny | +%d Honours | %s"),
                Quest.Title,RewardZeny,Quest.RewardHonour,Quest.RewardItem));
        }
    }
    else if(CombatComponent)
    {
        CombatComponent->SetQuestMessage(FString::Printf(
            TEXT("Quest progress | %s | %d / %d"),
            Quest.Title,QuestProgress,Quest.Goal));
    }
}

void UHonourWarQuestComponent::SetQuestState(int32 InQuestId,int32 InProgress,bool bInComplete)
{
    QuestId=FMath::Clamp(InQuestId,1,QuestCount);
    QuestProgress=FMath::Clamp(InProgress,0,DefinitionFor(QuestId).Goal);
    bQuestComplete=bInComplete && QuestProgress>=DefinitionFor(QuestId).Goal;
}

FString UHonourWarQuestComponent::GetQuestTitle() const
{
    return FString::Printf(TEXT("Quest %d/12 — %s"),QuestId,DefinitionFor(QuestId).Title);
}

FString UHonourWarQuestComponent::GetQuestBody() const
{
    const FQuestDefinition& Quest=DefinitionFor(QuestId);
    if(bQuestComplete)
    {
        return FString::Printf(
            TEXT("Complete. Collect your reward, then continue with Quest %d.
+%lld Zeny • +%d Honours"),
            (QuestId%QuestCount)+1,Quest.RewardZeny,Quest.RewardHonour);
    }

    const FString SpeciesText=FString(Quest.RequiredSpecies).Equals(TEXT("Any"),ESearchCase::IgnoreCase)
        ? TEXT("any monster") : Quest.RequiredSpecies;
    return FString::Printf(
        TEXT("%s
Target: %s Lv.%d+
Progress %d / %d"),
        Quest.Body,*SpeciesText,Quest.RequiredLevel,QuestProgress,Quest.Goal);
}

void UHonourWarQuestComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(UHonourWarQuestComponent,QuestId);
    DOREPLIFETIME(UHonourWarQuestComponent,QuestProgress);
    DOREPLIFETIME(UHonourWarQuestComponent,bQuestComplete);
}