class_name GraphicsProfiles
extends Node

const PROFILES:Dictionary = {
	"LOW": {"effects": 0, "environment_objects": 14, "shadows": false, "scale": 0.75},
	"BALANCED": {"effects": 1, "environment_objects": 24, "shadows": true, "scale": 0.90},
	"HIGH": {"effects": 2, "environment_objects": 36, "shadows": true, "scale": 1.0}
}

static func profile_for_name(name:String)->Dictionary:
	return PROFILES.get(name.to_upper(), PROFILES["BALANCED"])

static func recommended_for_hardware()->String:
	var video_memory:int = int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	if video_memory > 0 and video_memory < 180000000:
		return "LOW"
	return "BALANCED"
