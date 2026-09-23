#include "HonourWarItemEncyclopedia.h"
#include "HonourWarContentCatalog.h"
#include "HonourWarLootDatabase.h"
#include "Algo/Sort.h"

namespace HonourWarItemEncyclopedia
{
namespace
{
int32 TierForLevel(int32 Level){if(Level>=300)return 7;if(Level>=230)return 6;if(Level>=170)return 5;if(Level>=120)return 4;if(Level>=80)return 3;if(Level>=50)return 2;if(Level>=30)return 1;return 0;}
int32 FamilyIndex(const FString& Name)
{
 static const TCHAR* Families[]={
  TEXT("Poring"),TEXT("Poporing"),TEXT("Drops"),TEXT("Marin"),TEXT("Goblin"),TEXT("Kobold"),TEXT("Hobgoblin"),TEXT("Orclet"),
  TEXT("Wolf"),TEXT("Desert Wolf"),TEXT("Warg"),TEXT("Dire Wolf"),TEXT("Skeleton"),TEXT("Zombie Guard"),TEXT("Bone Archer"),TEXT("Skull Knight"),
  TEXT("Orc"),TEXT("Orc Warrior"),TEXT("Orc Champion"),TEXT("Orc Warlord"),TEXT("Mantis"),TEXT("Hunter Fly"),TEXT("Scorpion"),TEXT("Venom Beetle"),
  TEXT("Golem"),TEXT("Stone Golem"),TEXT("Crystal Golem"),TEXT("Iron Golem"),TEXT("Dragon"),TEXT("Drake"),TEXT("Wyvern"),TEXT("Elder Dragon")
 };
 for(int32 I=0;I<32;++I) if(Name.Contains(Families[I])) return I;
 return 0;
}
FString SourceTextForRank(int32 Rank)
{
 const int32 Tier=FMath::Clamp((Rank-1)/30,0,7),Slot=(Rank-1)%30;
 const TArray<HonourWarContentCatalog::FMonsterTemplate>& Monsters=HonourWarContentCatalog::Monsters();
 int32 Seen=0;
 for(const auto& M:Monsters)
 {
  if(TierForLevel(M.Level)!=Tier) continue;
  if(Seen==Slot) return FString::Printf(TEXT("%s [Lv.%d]"),*M.Name,M.Level);
  ++Seen;
 }
 return TEXT("Unknown monster source");
}
FString MapForRank(int32 Rank)
{
 const int32 Tier=FMath::Clamp((Rank-1)/30,0,7),Slot=(Rank-1)%30;
 const TArray<HonourWarContentCatalog::FMonsterTemplate>& Monsters=HonourWarContentCatalog::Monsters();
 int32 Seen=0;
 FVector Source=FVector::ZeroVector;
 for(const auto& M:Monsters){if(TierForLevel(M.Level)!=Tier)continue;if(Seen==Slot){Source=M.Location;break;}++Seen;}
 FString Best=TEXT("Unknown map"); double BestDist=1.0e30;
 for(const auto& Map:HonourWarContentCatalog::Maps()){const double D=FVector2D(Source.X-Map.Anchor.X,Source.Y-Map.Anchor.Y).SizeSquared();if(D<BestDist){BestDist=D;Best=Map.Name;}}
 return Best;
}
FHelpEntry MakeStandard(int32 Index,const FString& Type,const FString& Name,const FString& Details)
{
 const int32 Rank=Index+1;
 return {FString::Printf(TEXT("%s_%03d"),*Type,Rank),Name,Type,Details,
  FString::Printf(TEXT("%s | %s"),*SourceTextForRank(Rank),*MapForRank(Rank)),
  TEXT("On monster defeat; permanent daylight; source respawns 12 seconds after defeat")};
}
}
const TArray<FHelpEntry>& Entries()
{
 static const TArray<FHelpEntry> V=[]{TArray<FHelpEntry> Out;
 const auto& Equip=HonourWarLootDatabase::Items();
 for(int32 I=0;I<240;++I) Out.Add(MakeStandard(I,TEXT("EQUIP"),Equip[I],FString::Printf(TEXT("Equipment | Tier %d | level band %d-%d | refine cap +15 | Phracon/Emveretarcon/Oridecon/Zeny"),1+(I/48),1+(I/48)*50,FMath::Min(250,50+(I/48)*50))));
 for(int32 I=0;I<74;++I){const int32 Mi=(I*3+7)%HonourWarContentCatalog::Monsters().Num();const auto& M=HonourWarContentCatalog::Monsters()[Mi];FString Map=TEXT("Unknown map");double DBest=1.0e30;for(const auto& MapT:HonourWarContentCatalog::Maps()){double D=FVector2D(M.Location.X-MapT.Anchor.X,M.Location.Y-MapT.Anchor.Y).SizeSquared();if(D<DBest){DBest=D;Map=MapT.Name;}}Out.Add({FString::Printf(TEXT("ITEM_%03d"),I+1),Equip[240+I],TEXT("ITEM"),TEXT("General item | rotating monster-drop table"),FString::Printf(TEXT("%s [Lv.%d] | %s"),*M.Name,M.Level,*Map),TEXT("On monster defeat; permanent daylight; source respawns 12 seconds after defeat")});}
 const auto& Cards=HonourWarLootDatabase::Cards(); for(int32 I=0;I<240;++I) Out.Add(MakeStandard(I,TEXT("CARD"),Cards[I],FString::Printf(TEXT("Socket card | tier band %d | card source follows equipment rank %d"),1+(I/48),I+1)));
 for(const auto& J:Out){} return Out;}();
 return V;
}
TArray<FString> BuildHelpLines(const FString& Query)
{
 TArray<FString> Lines; const FString Q=Query.TrimStartAndEnd();
 if(Q.IsEmpty()){Lines.Add(TEXT("HELP: empty query."));return Lines;}
 const TArray<FHelpEntry>& V=Entries(); TArray<int32> Hits;
 for(int32 I=0;I<V.Num();++I) if(V[I].Id.Equals(Q,ESearchCase::IgnoreCase)||V[I].Name.Equals(Q,ESearchCase::IgnoreCase)) Hits.Add(I);
 if(Hits.Num()==0) for(int32 I=0;I<V.Num();++I) if(V[I].Id.Contains(Q,ESearchCase::IgnoreCase)||V[I].Name.Contains(Q,ESearchCase::IgnoreCase)) Hits.Add(I);
 if(Hits.Num()==0){Lines.Add(FString::Printf(TEXT("HELP: no item/card/job-artifact match for '%s'."),*Q));return Lines;}
 if(Hits.Num()>8){Lines.Add(FString::Printf(TEXT("HELP: %d matches; showing first 8:"),Hits.Num()));for(int32 J=0;J<8;++J) Lines.Add(FString::Printf(TEXT("%s | %s"),*V[Hits[J]].Id,*V[Hits[J]].Name));return Lines;}
 for(int32 I:Hits){const FHelpEntry& E=V[I];Lines.Add(FString::Printf(TEXT("%s | %s | %s"),*E.Id,*E.Name,*E.Type));Lines.Add(FString::Printf(TEXT("  %s"),*E.Details));Lines.Add(FString::Printf(TEXT("  Source: %s"),*E.Source));Lines.Add(FString::Printf(TEXT("  When: %s"),*E.When));}
 return Lines;
}
}
