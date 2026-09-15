class_name HDVisualUpgrade
extends Node3D

## Compatibility presentation layer. Keep the authored environment and generated
## GLB actors intact; the legacy procedural hero replacement is intentionally not used.
const CENTER:Vector3 = Vector3(12.925,0.0,12.65)
var root:Node3D

func _ready()->void:
    call_deferred("_build")

func _build()->void:
    var game:Node3D=get_parent() as Node3D
    if game==null: return
    root=game.get_node_or_null("HDPresentationWorld") as Node3D
    if root==null:
        root=Node3D.new()
        root.name="HDPresentationWorld"
        game.add_child(root)
    root.visible=false

# Retained for compatibility with older scene references. Never delete authored
# children from the active Hero node; HWGeneratedAssetRuntime owns visual loading.
func _upgrade_hero(_hero:Node3D,_class_id:String)->void:
    return
