using UnrealBuildTool;
using System.Collections.Generic;

public class HonourWarEditorTarget : TargetRules
{
    public HonourWarEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        ExtraModuleNames.Add("HonourWar");
    }
}
