#pragma once
#include "CoreMinimal.h"
namespace HonourWarItemEncyclopedia
{
struct FHelpEntry
{
 FString Id,Name,Type,Details,Source,When;
};
const TArray<FHelpEntry>& Entries();
TArray<FString> BuildHelpLines(const FString& Query);
}
