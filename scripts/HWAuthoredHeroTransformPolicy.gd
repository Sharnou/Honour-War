extends Node

## Permanent visual policy for production HD heroes.
## Authored GLB root scale and grounding are source-of-truth. The runtime must
## never normalize hero height or replace the imported transform with a preset.
const HERO_TARGET_HEIGHT_DISABLED:float = 0.0

func _ready()->void:
    process_priority = 200
    _disable_runtime_hero_normalization()

func _process(_delta:float)->void:
    _disable_runtime_hero_normalization()

func _disable_runtime_hero_normalization()->void:
    var runtime:Node = get_node_or_null("/root/HDAssetRuntime")
    if runtime == null:
        return
    if "hero_target_height" in runtime:
        runtime.set("hero_target_height", HERO_TARGET_HEIGHT_DISABLED)
