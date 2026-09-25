using System; using UnityEngine;
namespace HonourWar {
 public sealed class HonourWarCharacter:MonoBehaviour {
  public string CharacterName="Adventurer",Username="player"; public EHonourWarClass ClassId=EHonourWarClass.Warrior; public EHonourWarClassTier ClassTier=EHonourWarClassTier.Tier1; public int Level=1,AgeDays; public HonourWarCombatComponent Combat;
  double onlineSeconds; public event Action<string> StatusChanged;
  void Awake(){Combat=GetComponent<HonourWarCombatComponent>()??gameObject.AddComponent<HonourWarCombatComponent>();}
  void Update(){onlineSeconds+=Time.deltaTime;if(onlineSeconds>=86400){AgeDays++;onlineSeconds-=86400;} ApplyAgeVisuals();}
  public void SetClass(EHonourWarClass c){ClassId=c;ClassTier=HonourWarClassProgression.TierForLevel(Level);ApplyClassVisual();}
  public void Teleport(Vector3 position){transform.position=position;StatusChanged?.Invoke($"Teleported to {position.x:0},{position.z:0}");}
  public void ActivateSkill(int index,HonourWarMonster target){Combat.ActivateSkill(index,target);}
  public void ApplyClassVisual(){var r=GetComponent<Renderer>();if(r)r.material.color=HonourWarTypes.Style(ClassId).Primary;}
  void ApplyAgeVisuals(){var s=1f+Mathf.Min(AgeDays,1000)*.00005f;transform.localScale=new Vector3(1f,s,1f);}
 }
}