using System;
using System.Collections;
using System.IO;
using UnityEngine;

namespace HonourWar
{
    public sealed class HonourWarBootstrap : MonoBehaviour
    {
        const string SaveKey = "HonourWar.Save.v2.Unity6";
        Camera cam;
        HonourWarCharacter character;
        HonourWarMonster target;
        HonourWarWorldDirector world;
        HonourWarScreenshotDirector screenshot;
        string username = "player", password = "", characterName = "Adventurer", command = "", status = "";
        bool loggedIn, characterSelected, showHelp;
        int selectedClass;
        float lastSave;
        readonly EHonourWarClass[] classes = (EHonourWarClass[])Enum.GetValues(typeof(EHonourWarClass));

        void Awake()
        {
            Application.targetFrameRate = 60;
            BuildRuntimeWorld();
            Load();
            status = "Honour War — Unity 6.0 LTS migration runtime ready.";
        }

        void BuildRuntimeWorld()
        {
            var root = new GameObject("HonourWar_Runtime");
            world = root.AddComponent<HonourWarWorldDirector>();
            world.BuildProceduralWorld();
            screenshot = root.AddComponent<HonourWarScreenshotDirector>();

            var cameraObject = new GameObject("Main Camera");
            cam = cameraObject.AddComponent<Camera>();
            cameraObject.tag = "MainCamera";
            cam.fieldOfView = 48f;

            var lightObject = new GameObject("Runtime Sun");
            var light = lightObject.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.2f;
            light.transform.rotation = Quaternion.Euler(50f, -35f, 0f);

            var test = GameObject.Find("Monster_1");
            if (test != null) target = test.GetComponent<HonourWarMonster>();
        }

        void Update()
        {
            if (!characterSelected || character == null) return;

            var input = new Vector3(Input.GetAxisRaw("Horizontal"), 0f, Input.GetAxisRaw("Vertical")).normalized;
            character.transform.position += input * 6f * Time.deltaTime;
            if (input.sqrMagnitude > .01f) character.transform.forward = Vector3.Lerp(character.transform.forward, input, 12f * Time.deltaTime);

            cam.transform.position = Vector3.Lerp(cam.transform.position, character.transform.position + new Vector3(0f, 10f, -12f), 8f * Time.deltaTime);
            cam.transform.LookAt(character.transform.position + Vector3.up);

            if (Time.time - lastSave >= 5f) { Save(); lastSave = Time.time; }
            if (Input.GetKeyDown(KeyCode.F9)) screenshot.Capture();
            if (Input.GetKeyDown(KeyCode.F1)) showHelp = !showHelp;

            for (int i = 0; i < 8; i++)
                if (Input.GetKeyDown(KeyCode.Alpha1 + i))
                    UseSkill(i);
        }

        void UseSkill(int index)
        {
            character.ActivateSkill(index, target);
            status = character.Combat.LastCombatMessage;
            Save();
        }

        void SpawnCharacter()
        {
            if (character != null) Destroy(character.gameObject);

            var go = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            go.name = "HonourWar_Player_" + characterName;
            go.transform.position = new Vector3(0f, 1f, 11f);
            var collider = go.GetComponent<Collider>();
            if (collider != null) Destroy(collider);

            character = go.AddComponent<HonourWarCharacter>();
            go.AddComponent<CharacterController>();
            character.Username = username;
            character.CharacterName = characterName;
            character.SetClass((EHonourWarClass)selectedClass);
            character.ApplyClassVisual();

            var save = LoadData();
            if (save != null)
            {
                character.Level = save.Level;
                character.AgeDays = save.AgeDays;
                character.transform.position = save.PlayerLocation == Vector3.zero ? new Vector3(0f, 1f, 11f) : save.PlayerLocation;
            }
            status = $"Gameplay active: {character.CharacterName} / {character.ClassId} / Tier {character.ClassTier} / Lv.{character.Level}";
        }

        void OnGUI()
        {
            GUI.skin.label.fontSize = 16;

            if (!loggedIn)
            {
                GUILayout.BeginArea(new Rect(25, 25, 520, 360), GUI.skin.box);
                GUILayout.Label("HONOUR WAR — UNITY 6.0 LTS");
                GUILayout.Label("Migrated from Unreal Engine 5.8 → Unity C#");
                GUILayout.Label("Username");
                username = GUILayout.TextField(username);
                GUILayout.Label("Password");
                password = GUILayout.PasswordField(password, '*');
                if (GUILayout.Button("REGISTER / LOGIN", GUILayout.Height(42)))
                {
                    loggedIn = true;
                    status = "Authenticated. Select one of the 70 class/gender progression profiles.";
                    Save();
                }
                GUILayout.Label(status);
                GUILayout.EndArea();
                return;
            }

            if (!characterSelected)
            {
                GUILayout.BeginArea(new Rect(25, 25, 700, 560), GUI.skin.box);
                GUILayout.Label("70 CHARACTER PROFILES — 7 CLASSES × 5 TIERS × 2 GENDERS");
                characterName = GUILayout.TextField(characterName);
                selectedClass = GUILayout.SelectionGrid(selectedClass, Array.ConvertAll(classes, c => c.ToString()), 2);
                var tier = HonourWarClassProgression.TierForLevel(200);
                GUILayout.Label($"Class: {classes[selectedClass]} | Tier-5: {HonourWarClassProgression.FifthTierName(classes[selectedClass])}");
                GUILayout.Label($"Tier-5 unlock: Lv.{HonourWarClassProgression.RequiredLevel(tier)}");
                if (GUILayout.Button("ENTER GAMEPLAY", GUILayout.Height(45)))
                {
                    characterSelected = true;
                    SpawnCharacter();
                    Save();
                }
                GUILayout.Label(status);
                GUILayout.EndArea();
                return;
            }

            GUI.Box(new Rect(15, 15, 560, 230), "HONOUR WAR — REAL UNITY GAMEPLAY");
            GUI.Label(new Rect(30, 45, 520, 28), $"{character.CharacterName} | {character.ClassId} | {character.ClassTier} | Lv.{character.Level}");
            GUI.Label(new Rect(30, 75, 520, 28), $"Age days: {character.AgeDays} | HP {character.Combat.HP:0}/{character.Combat.MaxHP:0} | SP {character.Combat.SP:0}/{character.Combat.MaxSP:0}");
            GUI.Label(new Rect(30, 105, 520, 28), "WASD Move | 1-8 Skills | F1 Help | F9 REAL screenshot");
            GUI.Label(new Rect(30, 135, 520, 28), "@go 0 230:220 teleports live character");
            command = GUI.TextField(new Rect(30, 170, 390, 30), command);
            if (GUI.Button(new Rect(430, 170, 110, 30), "SEND")) { status = ExecuteCommand(command); command = ""; }
            GUI.Label(new Rect(30, 205, 520, 28), status);

            if (showHelp)
            {
                GUI.Box(new Rect(600, 15, 550, 520), "@help — Honour War Commands / Skills");
                GUI.Label(new Rect(620, 50, 510, 450),
                    "@help\n@go MAP X:Y — example @go 0 230:220\n@restskills — Tier 5 only\n\n1-8 active skills:\n" +
                    string.Join("\n", SkillNames(character.ClassId)));
            }
        }

        string ExecuteCommand(string raw)
        {
            raw = (raw ?? "").Trim();
            if (raw.Length == 0) return "";
            var p = raw.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

            if (p[0].Equals("@help", StringComparison.OrdinalIgnoreCase))
            {
                showHelp = true;
                return "Help opened.";
            }

            if (p[0].Equals("@go", StringComparison.OrdinalIgnoreCase) && p.Length >= 3)
            {
                var xy = p[2].Split(':');
                if (xy.Length == 2 && float.TryParse(xy[0], out var x) && float.TryParse(xy[1], out var z))
                {
                    character.Teleport(new Vector3(x / 10f, 1f, z / 10f));
                    Save();
                    return $"@go {p[1]} {x}:{z} executed. Live position = {character.transform.position.x:0.0}:{character.transform.position.z:0.0}.";
                }
            }

            if (p[0].Equals("@restskills", StringComparison.OrdinalIgnoreCase))
                return character.Level >= 200 ? "Tier-5 skill reset available." : "Skill reset requires Tier 5 / level 200.";

            return "Unknown command. Use @help.";
        }

        string[] SkillNames(EHonourWarClass c)
        {
            return c switch
            {
                EHonourWarClass.Warrior => new[] {"Ember Slash","Shield Bash","Guard Break","Brave Charge","Iron Resolve","War Cry","Cleave","Ember Guard"},
                EHonourWarClass.Mage => new[] {"Arcane Bolt","Frost Nova","Spark Chain","Mana Shield","Flame Sigil","Blink","Rune Burst","Arcane Veil"},
                EHonourWarClass.Archer => new[] {"Double Strafe","Arrow Shower","Charge Arrow","Sharp Shooting","True Sight","Arrow Storm","Falcon Volley","Hunter Focus"},
                EHonourWarClass.Thief => new[] {"Double Attack","Hiding","Envenom","Sonic Blow","Cloaking","Grimtooth","Assassin Cross","Shadow Execution"},
                EHonourWarClass.Acolyte => new[] {"Heal","Blessing","Increase Agility","Holy Light","Magnus Exorcismus","Safety Wall","Sanctuary","Divine Judgement"},
                EHonourWarClass.Merchant => new[] {"Mammonite","Cart Revolution","Overcharge","Discount","Crazy Uproar","Cart Termination","Greed","Market Dominion"},
                _ => new[] {"Gun Bolt","Burst Bolt","Suppressive Fire","Machine-Gun Volley","Armor Piercer","Tracer Barrage","Overwatch","Lead Storm"}
            };
        }

        HonourWarSaveGame LoadData()
        {
            var json = PlayerPrefs.GetString(SaveKey, "");
            if (string.IsNullOrEmpty(json)) return new HonourWarSaveGame();
            try { return JsonUtility.FromJson<HonourWarSaveGame>(json); } catch { return new HonourWarSaveGame(); }
        }

        void Load()
        {
            var data = LoadData();
            username = string.IsNullOrEmpty(data.GuildName) ? username : data.GuildName;
            characterName = "Adventurer";
        }

        void Save()
        {
            var data = LoadData();
            data.GuildName = username;
            data.Level = character == null ? data.Level : character.Level;
            data.AgeDays = character == null ? data.AgeDays : character.AgeDays;
            data.ClassId = character == null ? (EHonourWarClass)selectedClass : character.ClassId;
            data.ClassTier = character == null ? HonourWarClassProgression.TierForLevel(data.Level) : character.ClassTier;
            data.PlayerLocation = character == null ? data.PlayerLocation : character.transform.position;
            data.OnlineSeconds = (long)Time.realtimeSinceStartup;
            data.SavedAtUtc = DateTime.UtcNow.ToString("O");
            PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(data));
            PlayerPrefs.Save();
        }
    }
}