using System;
using UnityEngine;
namespace HonourWar {
 public enum EHonourWarClass { Warrior, Mage, Archer, Thief, Acolyte, Merchant, Ranger }
 public enum EHonourWarStatusStat { Strength, Agility, Vitality, Intelligence, Dexterity, Luck }
 public enum EHonourWarClassTier { Tier1=1,Tier2=2,Tier3=3,Tier4=4,Tier5=5 }
 public enum EHonourWarFifthTierArchetype { AbyssalWarlord,EternalSpellwright,CausalityMarksman,AbsoluteShadow,EternalBenediction,InfiniteQuartermaster,VerdantParagon }
 [Serializable] public struct HonourWarClassStyle { public Color Primary,Secondary,Accent; public HonourWarClassStyle(Color p,Color s,Color a){Primary=p;Secondary=s;Accent=a;} }
 public static class HonourWarTypes {
  public static string ClassName(EHonourWarClass c)=>c.ToString();
  public static string StatName(EHonourWarStatusStat s)=>s switch {EHonourWarStatusStat.Strength=>"STR",EHonourWarStatusStat.Agility=>"AGI",EHonourWarStatusStat.Vitality=>"VIT",EHonourWarStatusStat.Intelligence=>"INT",EHonourWarStatusStat.Dexterity=>"DEX",_=>"LUK"};
  public static HonourWarClassStyle Style(EHonourWarClass c)=>c switch {
   EHonourWarClass.Mage=>new(new Color(.28f,.38f,.9f),new Color(.12f,.1f,.24f),new Color(.65f,.8f,1f)),
   EHonourWarClass.Archer=>new(new Color(.26f,.52f,.22f),new Color(.12f,.17f,.1f),new Color(.7f,.95f,.45f)),
   EHonourWarClass.Thief=>new(new Color(.24f,.2f,.28f),new Color(.08f,.07f,.1f),new Color(.82f,.45f,.95f)),
   EHonourWarClass.Acolyte=>new(new Color(.82f,.75f,.95f),new Color(.18f,.12f,.2f),new Color(1f,.92f,.55f)),
   EHonourWarClass.Merchant=>new(new Color(.63f,.38f,.18f),new Color(.16f,.1f,.06f),new Color(1f,.72f,.26f)),
   EHonourWarClass.Ranger=>new(new Color(.2f,.44f,.3f),new Color(.09f,.13f,.1f),new Color(.58f,.88f,.68f)),
   _=>new(new Color(.52f,.22f,.13f),new Color(.12f,.08f,.06f),new Color(1f,.55f,.2f))};
 }
}