class_name HDProgressionWindowController
extends CanvasLayer

## Owns the progression-window chrome. The underlying gameplay controller keeps
## all character/skill/pet/inventory logic; this script only manages presentation.
var game:Node
var panel:Control
var close_button:Button
var minimize_button:Button
var chrome:PanelContainer

func _ready()->void:
    game=get_parent()
    call_deferred("_bind_window")

func _bind_window()->void:
    if game==null: return
    panel=game.get_node_or_null("GameplaySystemsRuntime/GameplayInteractionPanel") as Control
    if panel==null:
        var ui:=game.get_node_or_null("GameplaySystemsRuntime")
        if ui!=null:
            panel=ui.get("panel") as Control
    if panel==null: return
    _add_chrome()

func _add_chrome()->void:
    if panel.has_meta("progression_chrome"): return
    panel.set_meta("progression_chrome",true)
    chrome=PanelContainer.new()
    chrome.name="WindowTitleBar"
    chrome.position=Vector2(0,0)
    chrome.size=Vector2(panel.size.x,36)
    chrome.mouse_filter=Control.MOUSE_FILTER_STOP
    chrome.add_theme_stylebox_override("panel",_style("#0b111be8","#b89959"))
    panel.add_child(chrome)
    var row:=HBoxContainer.new()
    row.add_theme_constant_override("separation",4)
    chrome.add_child(row)
    var title:=Label.new()
    title.text="HONOUR WAR  •  CHARACTER / PROGRESSION"
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color",Color("#f3ead7"))
    row.add_child(title)
    minimize_button=Button.new()
    minimize_button.text="—"
    minimize_button.tooltip_text="Minimize progression window"
    minimize_button.custom_minimum_size=Vector2(34,28)
    minimize_button.pressed.connect(_minimize)
    row.add_child(minimize_button)
    close_button=Button.new()
    close_button.text="X"
    close_button.tooltip_text="Close progression window"
    close_button.custom_minimum_size=Vector2(34,28)
    close_button.pressed.connect(hide_window)
    row.add_child(close_button)
    panel.set_meta("progression_content_top",36)
    _move_existing_content_down()

func _move_existing_content_down()->void:
    for child in panel.get_children():
        if child==chrome: continue
        if child is Control:
            var control:Control=child
            control.position.y=max(control.position.y,42)
            control.size.y=max(40.0,panel.size.y-48.0)

func _style(bg:String,border:String)->StyleBoxFlat:
    var style:=StyleBoxFlat.new()
    style.bg_color=Color(bg)
    style.border_color=Color(border)
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    return style

func _minimize()->void:
    if panel==null: return
    var current:bool=bool(panel.get_meta("progression_minimized",false))
    current=not current
    panel.set_meta("progression_minimized",current)
    var content_top:int=int(panel.get_meta("progression_content_top",36))
    for child in panel.get_children():
        if child==chrome: continue
        if child is Control:
            var control:Control=child
            control.visible=not current
    panel.size.y=46.0 if current else 735.0

func hide_window()->void:
    if panel!=null: panel.visible=false

func show_window()->void:
    if panel==null: _bind_window()
    if panel!=null:
        panel.visible=true
        panel.set_meta("progression_minimized",false)
        for child in panel.get_children():
            if child is Control and child!=chrome: child.visible=true
        panel.size.y=735.0
