extends CanvasLayer

## Honour War responsive graphics options menu.
## The menu is hidden at startup and toggled with Escape.
## Graphics selection delegates directly to the autoloaded GraphicsManager.

@export_group("Required Links")
@export var graphics_dropdown:OptionButton
@export var graphics_manager:Node

var _updating_selection:bool = false

func _ready()->void:
    if graphics_dropdown == null:
        graphics_dropdown = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/GraphicsDropdown") as OptionButton
    if graphics_manager == null:
        graphics_manager = get_node_or_null("/root/GraphicsManager")
    if graphics_dropdown == null:
        push_error("OptionsMenu: GraphicsDropdown node is not assigned!")
        return
    if graphics_manager == null:
        push_error("OptionsMenu: GraphicsManager autoload could not be resolved!")
        return

    graphics_dropdown.item_selected.connect(_on_graphics_item_selected)
    _sync_selection()
    visible = false

func _input(event:InputEvent)->void:
    if event.is_action_pressed("ui_cancel"):
        visible = not visible
        if visible:
            _sync_selection()
            graphics_dropdown.grab_focus()
        else:
            get_viewport().set_input_as_handled()

func _on_graphics_item_selected(index:int)->void:
    if _updating_selection or graphics_manager == null:
        return
    match index:
        0:
            graphics_manager.apply_preset(graphics_manager.Preset.LOW)
        1:
            graphics_manager.apply_preset(graphics_manager.Preset.MEDIUM)
        2:
            graphics_manager.apply_preset(graphics_manager.Preset.HD)
    _sync_selection()

func _sync_selection()->void:
    if graphics_dropdown == null or graphics_manager == null:
        return
    _updating_selection = true
    var selected:int = 2
    if graphics_manager.current_preset == graphics_manager.Preset.LOW:
        selected = 0
    elif graphics_manager.current_preset == graphics_manager.Preset.MEDIUM:
        selected = 1
    elif graphics_manager.current_preset == graphics_manager.Preset.HD:
        selected = 2
    graphics_dropdown.select(selected)
    _updating_selection = false
