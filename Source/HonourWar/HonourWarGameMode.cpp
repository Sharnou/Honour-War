#include "HonourWarGameMode.h"
#include "HonourWarCharacter.h"
#include "HonourWarPlayerController.h"
#include "HonourWarHUD.h"
#include "HonourWarWorldDirector.h"
#include "HonourWarScreenshotDirector.h"
#include "HonourWarPlayerState.h"
#include "HonourWarGameState.h"
#include "GameFramework/GameStateBase.h"
#include "Engine/World.h"

AHonourWarGameMode::AHonourWarGameMode()
{
    DefaultPawnClass=AHonourWarCharacter::StaticClass();
    PlayerControllerClass=AHonourWarPlayerController::StaticClass();
    PlayerStateClass=AHonourWarPlayerState::StaticClass();
    GameStateClass=AHonourWarGameState::StaticClass();
    HUDClass=AHonourWarHUD::StaticClass();
}

void AHonourWarGameMode::BeginPlay()
{
    Super::BeginPlay();

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride=ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

    GetWorld()->SpawnActor<AHonourWarWorldDirector>(
        AHonourWarWorldDirector::StaticClass(),
        FVector::ZeroVector,
        FRotator::ZeroRotator,
        Params);

    GetWorld()->SpawnActor<AHonourWarScreenshotDirector>(
        AHonourWarScreenshotDirector::StaticClass(),
        FVector::ZeroVector,
        FRotator::ZeroRotator,
        Params);
}


void AHonourWarGameMode::PostLogin(APlayerController* NewPlayer)
{
    Super::PostLogin(NewPlayer);
    if(!NewPlayer) return;
    if(AHonourWarPlayerState* PS=NewPlayer->GetPlayerState<AHonourWarPlayerState>())
    {
        const int32 PlayerIndex=FMath::Max(0,GetNumPlayers()-1);
        PS->TeamId=(PlayerIndex%2);
        PS->PartySlot=FMath::Min(3,PlayerIndex/2);
    }
}


void AHonourWarGameMode::PreLogin(const FString& Options,const FString& Address,const FUniqueNetIdRepl& UniqueId,FString& ErrorMessage)
{
    Super::PreLogin(Options,Address,UniqueId,ErrorMessage);
    if(!ErrorMessage.IsEmpty()) return;

    const int32 CurrentPlayers=GetNumPlayers();
    if(CurrentPlayers>=8)
        ErrorMessage=TEXT("Honour War party capacity reached: maximum 8 active players (4v4).");
}


bool AHonourWarGameMode::HandleChatCommand(AHonourWarCharacter* Character,const FString& Message,FString& OutMessage)
{
    if(!Character || !Character->HasAuthority()) return false;
    FString Clean=Message;
    Clean.TrimStartAndEndInline();
    if(Clean.IsEmpty())
    {
        OutMessage=TEXT("Usage: @say [message]");
        return true;
    }
    Clean.LeftInline(180,true);

    if(AHonourWarGameState* State=GetGameState<AHonourWarGameState>())
    {
        const FString Name=Character->GetPlayerState() ? Character->GetPlayerState()->GetPlayerName() : TEXT("Player");
        State->AddWorldMessage(FString::Printf(TEXT("[World] %s: %s"),*Name,*Clean));
    }
    OutMessage=TEXT("Message sent.");
    return true;
}

bool AHonourWarGameMode::HandleGuildCommand(AHonourWarCharacter* Character,const FString& Command,FString& OutMessage)
{
    OutMessage.Empty();
    if(!Character || !Character->HasAuthority()) return false;

    AHonourWarPlayerState* Self=Character->GetPlayerState<AHonourWarPlayerState>();
    if(!Self) return false;

    TArray<FString> Tokens;
    Command.ParseIntoArrayWS(Tokens);
    if(Tokens.Num()<2 || Tokens[0].Compare(TEXT("@guild"),ESearchCase::IgnoreCase)!=0)
        return false;

    const FString Action=Tokens[1].ToLower();

    if(Action==TEXT("leave"))
    {
        Self->SetGuild(TEXT(""),TEXT("Member"));
        OutMessage=TEXT("Guild: left current guild.");
        return true;
    }

    if(Action==TEXT("create") || Action==TEXT("join"))
    {
        if(Tokens.Num()<3)
        {
            OutMessage=TEXT("Usage: @guild create [name] | @guild join [name]");
            return true;
        }

        FString Name=Tokens[2];
        Name.LeftInline(24,true);
        if(Name.IsEmpty())
        {
            OutMessage=TEXT("Guild name is empty.");
            return true;
        }

        if(!Self->GuildName.IsEmpty() && Action==TEXT("create"))
        {
            OutMessage=TEXT("Guild: leave your current guild before creating one.");
            return true;
        }

        bool bExists=false;
        if(AGameStateBase* State=GetGameState<AGameStateBase>())
        {
            for(APlayerState* PS:State->PlayerArray)
            {
                if(const AHonourWarPlayerState* Other=Cast<AHonourWarPlayerState>(PS))
                {
                    if(Other->GetGuildName().Equals(Name,ESearchCase::IgnoreCase))
                    {
                        bExists=true;
                        break;
                    }
                }
            }
        }

        if(Action==TEXT("create"))
        {
            if(bExists)
            {
                OutMessage=TEXT("Guild: that guild already exists.");
                return true;
            }
            Self->SetGuild(Name,TEXT("Leader"));
            OutMessage=FString::Printf(TEXT("Guild created: %s"),*Name);
            return true;
        }

        if(!bExists)
        {
            OutMessage=TEXT("Guild: guild not found on this server.");
            return true;
        }

        Self->SetGuild(Name,TEXT("Member"));
        OutMessage=FString::Printf(TEXT("Guild joined: %s"),*Name);
        return true;
    }

    OutMessage=TEXT("Usage: @guild create [name] | @guild join [name] | @guild leave");
    return true;
}
