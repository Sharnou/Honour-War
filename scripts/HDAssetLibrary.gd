class_name HDAssetLibrary
extends RefCounted

const CHARACTER_ROOT:String = "res://assets/3d/characters/"
const PET_ROOT:String = "res://assets/3d/pets/"
const MONSTER_ROOT:String = "res://assets/3d/monsters/"
const MAP_ROOT:String = "res://assets/3d/maps/"

static func find_scene(root:String,name:String)->PackedScene:
	var candidates:Array[String]=[
		root+name+".glb",
		root+name+".gltf",
		root+name+".tscn"
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			var resource:Resource=ResourceLoader.load(path)
			if resource is PackedScene:
				return resource
	return null

static func character_scene(class_id:String)->PackedScene:
	return find_scene(CHARACTER_ROOT,class_id.to_lower())

static func pet_scene(species:String)->PackedScene:
	return find_scene(PET_ROOT,species.to_lower().replace(" ","_"))

static func monster_scene(name:String)->PackedScene:
	return find_scene(MONSTER_ROOT,name.to_lower().replace(" ","_"))

static func map_scene(map_name:String)->PackedScene:
	return find_scene(MAP_ROOT,map_name.to_lower().replace(" ","_"))

static func asset_status()->Dictionary:
	return {
		"characters":_count_files(CHARACTER_ROOT),
		"pets":_count_files(PET_ROOT),
		"monsters":_count_files(MONSTER_ROOT),
		"maps":_count_files(MAP_ROOT)
	}

static func _count_files(path:String)->int:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return 0
	var files:PackedStringArray=DirAccess.get_files_at(path)
	var count:int=0
	for file_name in files:
		var lower:String=str(file_name).to_lower()
		if lower.ends_with(".glb") or lower.ends_with(".gltf") or lower.ends_with(".tscn"):
			count+=1
	return count
