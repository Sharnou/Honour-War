class_name HDUIStyleDirector
extends CanvasLayer

## Shared UI language: crisp non-diegetic windows, compact icon controls,
## strong readability, and no faux-3D framing over the game world.
const PANEL_BG:=Color("#101722e8")
const PANEL_BORDER:=Color("#d7b96be8")
const TEXT_MAIN:=Color("#f5f1df")
const TEXT_MUTED:=Color("#9eabb8")
const ACCENT:=Color("#e6c45f")

var root:Control
var toolbar:HBoxContainer
var help_label:Label

func _ready()->void:
    root=Control.new()
    root.name="HDMinimalUI"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(root)
    _build_toolbar()
    _build_controls_hint()

func panel_style()->StyleBoxFlat:
    var style:=StyleBoxFlat.new()
    style.bg_color=PANEL_BG
    style.border_color=PANEL_BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    style.shadow_color=Color(0,0,0,0.45)
    style.shadow_size=6
    return style

func button_style(pressed:bool=false)->StyleBoxFlat:
    var style:=panel_style()
    style.bg_color=Color("#273244") if not pressed else Color("#4a3d20")
    style.border_color=ACCENT
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    return style

func _build_toolbar()->void:
    toolbar=HBoxContainer.new()
    toolbar.name="SystemIconToolbar"
    toolbar.position=Vector2(640,18)
    toolbar.add_theme_constant_override("separation",5)
    root.add_child(toolbar)
    var icons:Array[Dictionary]=[
        {"text":"⚔","tip":"Combat / Character"},
        {"text":"♢","tip":"Bonded Pet"},
        {"text":"◆","tip":"Skills"},
        {"text":"▣","tip":"Inventory"},
        {"text":"◇","tip":"Equipment"},
        {"text":"✦","tip":"Refinement"},
        {"text":"☰","tip":"System"}
    ]
    for data in icons:
        var button:=Button.new()
        button.text=str(data["text"])
        button.tooltip_text=str(data["tip"])
        button.custom_minimum_size=Vector2(38,34)
        button.add_theme_font_size_override("font_size",18)
        button.add_theme_color_override("font_color",TEXT_MAIN)
        button.add_theme_stylebox_override("normal",button_style(false))
        button.add_theme_stylebox_override("hover",button_style(true))
        button.add_theme_stylebox_override("pressed",button_style(true))
        button.mouse_filter=Control.MOUSE_FILTER_STOP
        toolbar.add_child(button)

func _build_controls_hint()->void:
    var panel:=PanelContainer.new()
    panel.name="ControlsHint"
    panel.position=Vector2(18,690)
    panel.size=Vector2(470,52)
    panel.add_theme_stylebox_override("panel",panel_style())
    root.add_child(panel)
    help_label=Label.new()
    help_label.text="LMB: move / target    MMB: rotate    W/S: tilt    A/D: rotate    ESC: cancel"
    help_label.add_theme_color_override("font_color",TEXT_MUTED)
    help_label.add_theme_font_size_override("font_size",13)
    help_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    help_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    panel.add_child(help_label)

func create_window(title:String,size:Vector2,pos:Vector2)->PanelContainer:
    var panel:=PanelContainer.new()
    panel.name=title.replace(" ","")
    panel.position=pos
    panel.size=size
    panel.add_theme_stylebox_override("panel",panel_style())
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    panel.add_child(box)
    var heading:=Label.new()
    heading.text=title.to_upper()
    heading.add_theme_color_override("font_color",ACCENT)
    heading.add_theme_font_size_override("font_size",14)
    box.add_child(heading)
    return panel
