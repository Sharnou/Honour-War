extends Node

## Adds authored HD item/refinement icons to the existing command windows
## without changing inventory, equipment, loot, card, or refinement data.

const ATLAS_PATH:String = "res://assets/ui/item_icons_atlas.svg"
const POLL:float = 0.25
var elapsed:float = 0.0
var atlas_texture:Texture2D
var seen:Dictionary = {}

func _ready()->void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Headless/dummy renderer validation does not need UI textures. Avoid
    # repeatedly asking the dummy resource loader for SVGs; real Forward+
    # sessions retain the authored atlas.
    if DisplayServer.get_name() == "headless":
        return
    atlas_texture = load(ATLAS_PATH) as Texture2D

func _process(delta:float)->void:
    elapsed += delta
    if elapsed < POLL:
        return
    elapsed = 0.0
    if atlas_texture == null:
        if DisplayServer.get_name() == "headless":
            return
        atlas_texture = load(ATLAS_PATH) as Texture2D
        if atlas_texture == null:
            return
    var scene:Node = get_tree().current_scene
    if scene == null:
        return
    var root:Node = scene.get_node_or_null("HWMainInterface")
    if root == null:
        root = get_node_or_null("/root/HWMainInterface")
    if root == null:
        return
    _visit(root)

func _visit(node:Node)->void:
    if node is Button:
        _decorate(node as Button)
    for child:Node in node.get_children():
        _visit(child)

func _decorate(button:Button)->void:
    var text:String = button.text
    if text.is_empty():
        return
    var lower:String = text.to_lower()
    var key:String = str(button.get_instance_id()) + ":" + text
    if seen.has(key):
        return
    var atlas_index:int = _icon_index(lower)
    if atlas_index < 0:
        return
    var icon := AtlasTexture.new()
    icon.atlas = atlas_texture
    icon.region = Rect2(float(atlas_index * 64),0.0,64.0,64.0)
    button.icon = icon
    button.expand_icon = true
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size", max(9,int(button.get_theme_font_size("font_size"))))
    seen[key] = true

func _icon_index(text:String)->int:
    if text.contains("zeny") or text.contains("gold") or text.contains("coin"):
        return 4
    if text.contains("card") or text.contains("rare card"):
        return 2
    if text.contains("refine") or text.contains("upgrade") or text.contains("oridecon") or text.contains("emveretarcon") or text.contains("phracon"):
        return 3
    if text.contains("potion") or text.contains("heal") or text.contains("mana") or text.contains("consumable"):
        return 7
    if text.contains("armor") or text.contains("helmet") or text.contains("garment") or text.contains("shield"):
        return 1
    if text.contains("weapon") or text.contains("sword") or text.contains("bow") or text.contains("dagger") or text.contains("staff") or text.contains("hammer"):
        return 0
    if text.contains("crystal") or text.contains("material") or text.contains("ore") or text.contains("jewel"):
        return 5
    if text.contains("use / equip") or text.contains("equipment") or text.contains("item"):
        return 6
    return -1
