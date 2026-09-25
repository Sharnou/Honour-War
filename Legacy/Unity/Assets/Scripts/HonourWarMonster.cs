using UnityEngine;
namespace HonourWar
{
    public enum EHonourWarMonsterSpecies { Poring,Poporing,Drops,Marin,Orc,Goblin,Plant,Beast,Undead,Dragon,Demon,Construct }

    public sealed class HonourWarMonster : MonoBehaviour
    {
        public string MonsterId, DisplayName;
        public EHonourWarMonsterSpecies Species;
        public int Level=1, MaxHP=100, HP=100;
        public bool IsAlive => HP > 0;

        public void Initialize(string id,string name,EHonourWarMonsterSpecies species,int level)
        {
            MonsterId=id; DisplayName=name; Species=species; Level=Mathf.Clamp(level,1,250);
            MaxHP=100+Level*25; HP=MaxHP;
            gameObject.name=name;
            EnsureCollider();
            EnsureVisual();
        }

        void EnsureCollider()
        {
            if (GetComponent<Collider>() == null)
            {
                var c=gameObject.AddComponent<SphereCollider>();
                c.radius=0.65f;
            }
        }

        void EnsureVisual()
        {
            var r=GetComponent<Renderer>();
            if(r==null)
            {
                var visual=GameObject.CreatePrimitive(PrimitiveType.Sphere);
                visual.name="Visual";
                visual.transform.SetParent(transform,false);
                visual.transform.localScale=Vector3.one*1.3f;
                r=visual.GetComponent<Renderer>();
                var visualCollider=visual.GetComponent<Collider>();
                if(visualCollider!=null) Destroy(visualCollider);
            }
            if(r!=null) r.material.color=new Color(0.85f,0.35f,0.65f);
        }

        public void TakeDamage(int amount){ if(!IsAlive)return; HP=Mathf.Max(0,HP-Mathf.Max(0,amount)); }
        public void Restore(){HP=MaxHP;}
    }
}