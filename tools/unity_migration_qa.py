from pathlib import Path
root=Path(__file__).resolve().parents[1]
unity=root/"Unity"
assert (unity/"ProjectSettings/ProjectVersion.txt").read_text().strip()=="m_EditorVersion: 6000.6.3f1"
scripts=list((unity/"Assets/Scripts").glob("*.cs"))
required={"HonourWarBootstrap.cs","HonourWarTypes.cs","HonourWarClassProgression.cs","HonourWarContentCatalog.cs","HonourWarLootDatabase.cs","HonourWarCharacter.cs","HonourWarCombatComponent.cs","HonourWarMonster.cs","HonourWarPlayerController.cs","HonourWarScreenshotDirector.cs","HonourWarSaveGame.cs","HonourWarAccountSaveGame.cs","HonourWarWorldDirector.cs"}
missing=required-{p.name for p in scripts}
assert not missing, f"Missing Unity migrations: {sorted(missing)}"
assert not list(root.glob("*.uproject")), "Unreal project file remains active"
assert not (root/"Source").exists(), "Unreal Source directory remains active"
assert not (root/"Config").exists(), "Unreal Config directory remains active"
for p in scripts:
    text=p.read_text(errors="ignore")
    assert "#include" not in text and "UCLASS" not in text and "UFUNCTION" not in text and "FString" not in text
print(f"UNITY_MIGRATION_PASS scripts={len(scripts)} engine=6000.6.3f1")
