#include "HonourWarGameState.h"
#include "Net/UnrealNetwork.h"

namespace
{
    struct FWorldEventDefinition
    {
        const TCHAR* Title;
        const TCHAR* Body;
        float DamageMultiplier;
        float XpMultiplier;
        float ZenyMultiplier;
        float HonourMultiplier;
        float SpRegenMultiplier;
    };

    const FWorldEventDefinition Events[] =
    {
        {TEXT("Royal Hunt"), TEXT("The royal hunt is underway. Monsters yield +25% XP and +10% Zeny."), 1.00f, 1.25f, 1.10f, 1.00f, 1.00f},
        {TEXT("Arcane Surge"), TEXT("Arcane energy floods the fields. Skills deal +10% damage and SP regenerates 35% faster."), 1.10f, 1.00f, 1.00f, 1.00f, 1.35f},
        {TEXT("Treasure Wind"), TEXT("A warm treasure wind sweeps the roads. Monster Zeny rewards are increased by 30%."), 1.00f, 1.05f, 1.30f, 1.00f, 1.00f},
        {TEXT("Honour Rush"), TEXT("Champions gather for an honour rush. Combat damage is increased by 20% and Honour rewards by 25%."), 1.20f, 1.00f, 1.00f, 1.25f, 1.00f},
        {TEXT("Dragon Pressure"), TEXT("Ancient draconic pressure sharpens every strike. All combat damage is increased by 15%."), 1.15f, 1.10f, 1.00f, 1.10f, 1.05f},
        {TEXT("Relic Dawn"), TEXT("Relics have awakened across the world. XP and Zeny rewards each gain a 15% bonus."), 1.05f, 1.15f, 1.15f, 1.00f, 1.00f}
    };
}

AHonourWarGameState::AHonourWarGameState()
{
    bReplicates=true;
    PrimaryActorTick.bCanEverTick=true;
}

void AHonourWarGameState::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    WorldEventElapsed += DeltaSeconds;

    if(HasAuthority() && WorldEventElapsed >= WorldEventDuration)
    {
        constexpr int32 EventCount = static_cast<int32>(sizeof(Events)/sizeof(Events[0]));
        ActiveWorldEventId = (ActiveWorldEventId + 1) % EventCount;
        WorldEventElapsed = 0.0f;
        AddWorldMessage(FString::Printf(
            TEXT("[Event] %s — %s"),
            *GetActiveWorldEventTitle(),
            *GetActiveWorldEventBody()));
    }
}

void AHonourWarGameState::AddWorldMessage(const FString& Message)
{
    if(!HasAuthority() || Message.IsEmpty()) return;
    WorldMessages.Add(Message);
    if(WorldMessages.Num()>10)
        WorldMessages.RemoveAt(0);
}

FString AHonourWarGameState::GetActiveWorldEventTitle() const
{
    constexpr int32 EventCount = static_cast<int32>(sizeof(Events)/sizeof(Events[0]));
    return FString(Events[FMath::Clamp(ActiveWorldEventId,0,EventCount-1)].Title);
}

FString AHonourWarGameState::GetActiveWorldEventBody() const
{
    constexpr int32 EventCount = static_cast<int32>(sizeof(Events)/sizeof(Events[0]));
    return FString(Events[FMath::Clamp(ActiveWorldEventId,0,EventCount-1)].Body);
}

int32 AHonourWarGameState::GetEventSecondsRemaining() const
{
    return FMath::Max(0,FMath::CeilToInt(WorldEventDuration-WorldEventElapsed));
}

float AHonourWarGameState::GetWorldEventDamageMultiplier() const
{
    constexpr int32 EventCount = static_cast<int32>(sizeof(Events)/sizeof(Events[0]));
    return Events[FMath::Clamp(ActiveWorldEventId,0,EventCount-1)].DamageMultiplier;
}

float AHonourWarGameState::GetWorldEventXpMultiplier() const
{
    constexpr int32 EventCount = static_cast<int32>(sizeof(Events)/sizeof(Events[0]));
    return Events[FMath::Clamp(ActiveWorldEventId,0,EventCount-1)].XpMultiplier;
}

float AHonourWarGameState::GetWorldEventZenyMultiplier() const
{
    constexpr int32 EventCount = static_cast<int32>(sizeof(Events)/sizeof(Events[0]));
    return Events[FMath::Clamp(ActiveWorldEventId,0,EventCount-1)].ZenyMultiplier;
}

float AHonourWarGameState::GetWorldEventHonourMultiplier() const
{
    constexpr int32 EventCount = static_cast<int32>(sizeof(Events)/sizeof(Events[0]));
    return Events[FMath::Clamp(ActiveWorldEventId,0,EventCount-1)].HonourMultiplier;
}

float AHonourWarGameState::GetWorldEventSpRegenMultiplier() const
{
    constexpr int32 EventCount = static_cast<int32>(sizeof(Events)/sizeof(Events[0]));
    return Events[FMath::Clamp(ActiveWorldEventId,0,EventCount-1)].SpRegenMultiplier;
}

void AHonourWarGameState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(AHonourWarGameState,WorldMessages);
    DOREPLIFETIME(AHonourWarGameState,ActiveWorldEventId);
    DOREPLIFETIME(AHonourWarGameState,WorldEventElapsed);
}