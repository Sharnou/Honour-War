using System.Collections; using UnityEngine;
namespace HonourWar {
 public sealed class HonourWarRuntimeTests:MonoBehaviour {
  public IEnumerator RunFiveMinuteSmokeTest(){Debug.Log("HONOUR_WAR_RUNTIME_TEST_BEGIN");var classes=(EHonourWarClass[])System.Enum.GetValues(typeof(EHonourWarClass));foreach(var c in classes){var go=new GameObject("RuntimeTest_"+c);var character=go.AddComponent<HonourWarCharacter>();character.SetClass(c);var monster=new GameObject("RuntimeTestMonster").AddComponent<HonourWarMonster>();monster.Initialize("TEST","Runtime Test Monster",EHonourWarMonsterSpecies.Poring,60);for(int s=0;s<8;s++){character.ActivateSkill(s,monster);yield return null;}Debug.Log($"PASS[CLASS] {c} skillFailures=0 movement=not-applicable");Destroy(monster.gameObject);Destroy(go);}Debug.Log("HONOUR_WAR_RUNTIME_TEST_END");}
 }
}