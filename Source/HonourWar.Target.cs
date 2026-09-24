using UnrealBuildTool;
using System.Collections.Generic;

public class HonourWarTarget : TargetRules
{
    public HonourWarTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        ExtraModuleNames.Add("HonourWar");
    }
}
