using System.Collections.Generic;
namespace HonourWar {
 public static class HonourWarLootDatabase {
  public static readonly List<string> Equipment=new(); public static readonly List<string> Items=new(); public static readonly List<string> Cards=new();
  static HonourWarLootDatabase(){for(int i=1;i<=300;i++){Equipment.Add($"Equipment_{i:000}");Cards.Add($"Card_{i:000}");}for(int i=1;i<=76;i++)Items.Add($"Item_{i:000}");Items[74]="Machine Gun Bolts";Items[75]="Rune Bolts";}
 }
}