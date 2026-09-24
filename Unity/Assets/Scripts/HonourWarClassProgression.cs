using System; using System.Collections.Generic;
namespace HonourWar {
 [Serializable] public sealed class HonourWarJobProfile { public string Id,JobName,Title,Role,PrimaryStat,SecondaryStat,StatFocus,Clothing,EmotionProfile,SkillList,SignatureWeapon,Offhand,WeaponFamily,AmmoType,StatGrowth; public EHonourWarClass BaseClass; public EHonourWarClassTier Tier; public int RequiredLevel,PowerRating,AttackRange,StatPointBudget; }
 public static class HonourWarClassProgression {
  public static int RequiredLevel(EHonourWarClassTier t)=>t switch {EHonourWarClassTier.Tier2=>25,EHonourWarClassTier.Tier3=>50,EHonourWarClassTier.Tier4=>150,EHonourWarClassTier.Tier5=>200,_=>1};
  public static EHonourWarClassTier TierForLevel(int level)=>level>=200?EHonourWarClassTier.Tier5:level>=150?EHonourWarClassTier.Tier4:level>=50?EHonourWarClassTier.Tier3:level>=25?EHonourWarClassTier.Tier2:EHonourWarClassTier.Tier1;
  public static string TierName(EHonourWarClassTier t)=>t switch {EHonourWarClassTier.Tier2=>"Specialization",EHonourWarClassTier.Tier3=>"Advanced",EHonourWarClassTier.Tier4=>"Mastery",EHonourWarClassTier.Tier5=>"Transcendence",_=>"Foundation"};
  public static string FifthTierName(EHonourWarClass c)=>c switch {EHonourWarClass.Mage=>"Mage - Eternal Spellwright",EHonourWarClass.Archer=>"Archer - Causality Marksman",EHonourWarClass.Thief=>"Thief - Absolute Shadow",EHonourWarClass.Acolyte=>"Acolyte - Eternal Benediction",EHonourWarClass.Merchant=>"Merchant - Infinite Quartermaster",EHonourWarClass.Ranger=>"Ranger - Verdant Paragon",_=>"Warrior - Abyssal Warlord"};
  public static List<HonourWarJobProfile> BuildAllJobs() {
   var result=new List<HonourWarJobProfile>(); var names=new Dictionary<EHonourWarClass,string[]> {
    {EHonourWarClass.Warrior,new[]{"Swordsman","Knight","Paladin","Warlord","Abyssal Warlord"}},
    {EHonourWarClass.Mage,new[]{"Novice Mage","Wizard","High Wizard","Arcane Sage","Eternal Spellwright"}},
    {EHonourWarClass.Archer,new[]{"Bowman","Hunter","Sniper","Deadeye","Causality Marksman"}},
    {EHonourWarClass.Thief,new[]{"Dagger Initiate","Assassin","Shadowlord","Nightblade","Absolute Shadow"}},
    {EHonourWarClass.Acolyte,new[]{"Acolyte","Priest","High Priest","Saint","Eternal Benediction"}},
    {EHonourWarClass.Merchant,new[]{"Merchant","Ironforger","Royal Smith","Master Smith","Infinite Quartermaster"}},
    {EHonourWarClass.Ranger,new[]{"Ranger","Beastmaster","Forest Warden","Wild Sovereign","Verdant Paragon"}}};
   foreach(var kv in names) for(int i=0;i<5;i++) result.Add(new HonourWarJobProfile{Id=$"JOB_{kv.Key.ToString().ToUpperInvariant()}_T{i+1}",BaseClass=kv.Key,Tier=(EHonourWarClassTier)(i+1),RequiredLevel=RequiredLevel((EHonourWarClassTier)(i+1)),JobName=kv.Value[i],Title=FifthTierName(kv.Key),Role=TierName((EHonourWarClassTier)(i+1)),PrimaryStat=kv.Key==EHonourWarClass.Mage||kv.Key==EHonourWarClass.Acolyte?"INT":"STR",SecondaryStat="DEX",WeaponFamily=kv.Key==EHonourWarClass.Ranger?"Firearm":"Weapon",AmmoType=kv.Key==EHonourWarClass.Ranger?"machine_gun_bolt":""});
   return result;
  }
 } }