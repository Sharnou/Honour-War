#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;
namespace HonourWar.EditorTools {
 public static class HonourWarBuild {
  public static void BuildWindows() {
   var scene=Path.GetFullPath("Assets/Scenes/HonourWarMain.unity");
   var output=Path.GetFullPath("../Build/Unity/HonourWar.exe");
   Directory.CreateDirectory(Path.GetDirectoryName(output));
   var report=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{scene},locationPathName=output,target=BuildTarget.StandaloneWindows64,options=BuildOptions.None});
   if(report.summary.result!=BuildResult.Succeeded) throw new BuildFailedException($"Honour War Unity build failed: {report.summary.result}");
   Debug.Log($"HONOUR_WAR_UNITY_BUILD_PASS={output}");
  }
 }
}
#endif