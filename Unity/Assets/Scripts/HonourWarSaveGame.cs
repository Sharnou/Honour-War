using System;
using UnityEngine;
namespace HonourWar
{
    [Serializable]
    public sealed class HonourWarSaveGame
    {
        public string Username="player", CharacterName="Adventurer";
        public int Level=1,Experience,AgeDays,EquipmentRefineLevel=0,Phracon=20,Emveretarcon=10,Oridecon=5,BasicSkillLevel=1,SkillPoints,Honours,StatusPoints=30,Strength=10,Agility=10,Vitality=10,Intelligence=10,Dexterity=10,LuckStat=10,QuestId=1,QuestProgress;
        public long OnlineSeconds,Zeny;
        public EHonourWarClass ClassId=EHonourWarClass.Warrior;
        public EHonourWarClassTier ClassTier=EHonourWarClassTier.Tier1;
        public EHonourWarFifthTierArchetype FifthTierArchetype=EHonourWarFifthTierArchetype.AbyssalWarlord;
        public Vector3 PlayerLocation;
        public string GuildName="",GuildRank="Member";
        public bool QuestComplete;
        public string[] InventoryItems=Array.Empty<string>(),Cards=Array.Empty<string>();
        public int[] SkillLevels=new int[8];
        public string SavedAtUtc="";
    }
}