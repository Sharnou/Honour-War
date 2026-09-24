using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace HonourWar
{
    public enum HWClass { Warrior, Mage, Archer, Thief, Acolyte, Merchant, Ranger }

    [Serializable]
    public sealed class HWSaveData
    {
        public string username;
        public string characterName = "Adventurer";
        public HWClass classId = HWClass.Warrior;
        public int level = 1;
        public int ageDays = 0;
        public float x;
        public float y;
        public float z;
    }

    public sealed class HonourWarBootstrap : MonoBehaviour
    {
        const string SaveKey = "HonourWar.Save.v1";
        readonly Dictionary<HWClass, string[]> skills = new Dictionary<HWClass, string[]>
        {
            { HWClass.Warrior, new[]{"Bash","Magnum Break","Provoke","Bowling Bash","Aura Blade","Guard Stance","Grand Cross","War Cry"} },
            { HWClass.Mage, new[]{"Fire Bolt","Cold Bolt","Lightning Bolt","Fire Wall","Storm Gust","Meteor Storm","Arcane Surge","Elemental Rupture"} },
            { HWClass.Archer, new[]{"Double Strafe","Arrow Shower","Charge Arrow","Sharp Shooting","True Sight","Arrow Storm","Falcon Volley","Hunter's Focus"} },
            { HWClass.Thief, new[]{"Double Attack","Hiding","Envenom","Sonic Blow","Cloaking","Grimtooth","Assassin Cross","Shadow Execution"} },
            { HWClass.Acolyte, new[]{"Heal","Blessing","Increase Agility","Holy Light","Magnus Exorcismus","Safety Wall","Sanctuary","Divine Judgement"} },
            { HWClass.Merchant, new[]{"Mammonite","Cart Revolution","Overcharge","Discount","Crazy Uproar","Cart Termination","Greed","Market Dominion"} },
            { HWClass.Ranger, new[]{"Gun Bolt","Burst Bolt","Suppressive Fire","Machine-Gun Volley","Armor Piercer","Tracer Barrage","Overwatch","Lead Storm"} }
        };

        Camera cam;
        CharacterController player;
        GameObject playerObject;
        HWSaveData save;
        Vector2 move;
        string loginName = "player";
        string password = "";
        string command = "";
        string status = "";
        bool loggedIn;
        bool characterSelected;
        bool showHelp;
        int selectedClass;
        float lastAutoSave;
        readonly List<GameObject> monsters = new List<GameObject>();

        void Awake()
        {
            Application.targetFrameRate = 60;
            Load();
            BuildWorld();
            cam = new GameObject("Main Camera").AddComponent<Camera>();
            cam.tag = "MainCamera";
            cam.transform.position = new Vector3(0, 8, -10);
            cam.transform.rotation = Quaternion.Euler(28, 0, 0);
            status = "Honour War Unity 6.0 LTS prototype ready. Register/login to begin.";
        }

        void Update()
        {
            if (!characterSelected || player == null) return;
            float h = Input.GetAxisRaw("Horizontal");
            float v = Input.GetAxisRaw("Vertical");
            Vector3 dir = new Vector3(h, 0, v).normalized;
            player.Move(dir * 5f * Time.deltaTime);
            if (dir.sqrMagnitude > 0.01f) playerObject.transform.forward = Vector3.Lerp(playerObject.transform.forward, dir, 0.2f);
            cam.transform.position = Vector3.Lerp(cam.transform.position, playerObject.transform.position + new Vector3(0, 7, -9), 8f * Time.deltaTime);
            cam.transform.LookAt(playerObject.transform.position + Vector3.up * 1.2f);
            if (Time.time - lastAutoSave > 10f) { Save(); lastAutoSave = Time.time; }
            if (Input.GetKeyDown(KeyCode.F9)) CaptureRealGameplayScreenshot();
            if (Input.GetKeyDown(KeyCode.F1)) showHelp = !showHelp;
        }

        void BuildWorld()
        {
            RenderSettings.ambientLight = new Color(0.35f, 0.38f, 0.45f);
            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "HonourWar_TestTown_Ground";
            ground.transform.localScale = new Vector3(8, 1, 8);
            ground.GetComponent<Renderer>().material.color = new Color(0.20f, 0.24f, 0.20f);
            for (int i = 0; i < 10; i++)
            {
                var m = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                m.name = "Monster_" + i;
                m.transform.position = new Vector3((i % 5) * 5 - 10, 1, (i / 5) * 5 + 4);
                m.transform.localScale = Vector3.one * 0.8f;
                m.GetComponent<Renderer>().material.color = new Color(0.65f, 0.12f, 0.10f);
                monsters.Add(m);
            }
        }

        void SpawnPlayer()
        {
            if (playerObject != null) Destroy(playerObject);
            playerObject = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            playerObject.name = "Player_" + save.characterName;
            playerObject.transform.position = new Vector3(save.x, Math.Max(1, save.y), save.z);
            playerObject.GetComponent<Renderer>().material.color = ClassColor(save.classId);
            Destroy(playerObject.GetComponent<Collider>());
            player = playerObject.AddComponent<CharacterController>();
            player.height = 2f;
            player.radius = 0.45f;
            status = $"Logged in as {save.username}. {save.characterName} / {save.classId} Lv.{save.level}";
        }

        Color ClassColor(HWClass c)
        {
            switch (c)
            {
                case HWClass.Warrior: return new Color(0.65f,0.15f,0.12f);
                case HWClass.Mage: return new Color(0.18f,0.35f,0.85f);
                case HWClass.Archer: return new Color(0.20f,0.65f,0.25f);
                case HWClass.Thief: return new Color(0.35f,0.18f,0.40f);
                case HWClass.Acolyte: return new Color(0.90f,0.85f,0.35f);
                case HWClass.Merchant: return new Color(0.85f,0.55f,0.15f);
                default: return new Color(0.25f,0.55f,0.60f);
            }
        }

        void OnGUI()
        {
            GUI.skin.label.fontSize = 18;
            if (!loggedIn)
            {
                GUILayout.BeginArea(new Rect(30,30,480,330), GUI.skin.box);
                GUILayout.Label("HONOUR WAR — UNITY 6.0 LTS");
                GUILayout.Label("Register / Login");
                loginName = GUILayout.TextField(loginName);
                password = GUILayout.PasswordField(password, '*');
                if (GUILayout.Button("Register + Login", GUILayout.Height(42))) { loggedIn = true; save.username = loginName; Save(); status = "Account registered. Select your character."; }
                GUILayout.Label(status);
                GUILayout.EndArea();
                return;
            }
            if (!characterSelected)
            {
                GUILayout.BeginArea(new Rect(30,30,600,500), GUI.skin.box);
                GUILayout.Label("CHARACTER / CLASS SELECTION");
                save.characterName = GUILayout.TextField(save.characterName);
                selectedClass = GUILayout.SelectionGrid(selectedClass, Enum.GetNames(typeof(HWClass)), 2);
                if (GUILayout.Button("Enter Gameplay", GUILayout.Height(45))) { save.classId = (HWClass)selectedClass; characterSelected = true; SpawnPlayer(); Save(); }
                GUILayout.Label(status);
                GUILayout.EndArea();
                return;
            }

            GUI.Box(new Rect(15,15,390,190), "HONOUR WAR — LIVE GAMEPLAY");
            GUI.Label(new Rect(30,45,350,30), $"{save.characterName} | {save.classId} | Lv.{save.level}");
            GUI.Label(new Rect(30,75,350,30), "F1 Help   F9 Capture REAL gameplay screenshot");
            GUI.Label(new Rect(30,105,350,30), "Move: WASD   Command: @go 0 230:220");
            command = GUI.TextField(new Rect(30,135,250,30), command);
            if (GUI.Button(new Rect(290,135,90,30), "Send")) ExecuteCommand(command);
            GUI.Label(new Rect(30,170,350,30), status);
            if (showHelp)
            {
                GUI.Box(new Rect(420,15,520,430), "@help / SYSTEM");
                GUI.Label(new Rect(440,50,480,370), "@help ITEM_ID\nSearches item/card information.\n\n@go MAP X:Y\nExample: @go 0 230:220\n\n@restskills\nAvailable after reaching Tier 5.\n\nF9\nCaptures the actual Unity gameplay window.\n\nSkills:\n" + string.Join("\n", skills[save.classId]));
            }
        }

        void ExecuteCommand(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return;
            var p = raw.Trim().Split(' ');
            if (p[0].Equals("@go", StringComparison.OrdinalIgnoreCase) && p.Length >= 3)
            {
                var xy = p[2].Split(':');
                if (xy.Length == 2 && float.TryParse(xy[0], out var x) && float.TryParse(xy[1], out var z))
                {
                    playerObject.transform.position = new Vector3(x / 100f, 1, z / 100f);
                    status = $"@go {p[1]} {x}:{z} executed. Live player moved.";
                    Save();
                    return;
                }
            }
            if (p[0].Equals("@help", StringComparison.OrdinalIgnoreCase)) { showHelp = true; status = "Help opened."; return; }
            if (p[0].Equals("@restskills", StringComparison.OrdinalIgnoreCase)) { status = save.level >= 50 ? "Skills reset." : "Skill rest requires Tier 5 / level 50."; return; }
            status = "Unknown command. Press F1 for @help.";
        }

        void CaptureRealGameplayScreenshot()
        {
            string dir = Path.Combine(Application.persistentDataPath, "HonourWarScreenshots");
            Directory.CreateDirectory(dir);
            string path = Path.Combine(dir, "HonourWar-REAL-GAMEPLAY-" + DateTime.Now.ToString("yyyyMMdd-HHmmss") + ".png");
            ScreenCapture.CaptureScreenshot(path, 2);
            status = "REAL GAMEPLAY screenshot captured: " + path;
            Debug.Log("HONOUR_WAR_REAL_GAMEPLAY_SCREENSHOT=" + path);
        }

        void Save()
        {
            if (save == null) save = new HWSaveData();
            if (playerObject != null) { var p = playerObject.transform.position; save.x = p.x; save.y = p.y; save.z = p.z; }
            PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(save));
            PlayerPrefs.Save();
        }

        void Load()
        {
            string json = PlayerPrefs.GetString(SaveKey, "");
            save = string.IsNullOrEmpty(json) ? new HWSaveData() : JsonUtility.FromJson<HWSaveData>(json);
            if (save == null) save = new HWSaveData();
            if (save.username == null) save.username = "player";
        }
    }
}
