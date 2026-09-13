class_name HDUIStyleDirector
extends CanvasLayer

## Shared HD UI language: crisp non-diegetic windows, compact icon controls,
## strong readability, and no runtime dependency on external SVG importers.
const PANEL_BG:=Color("#101722e8")
const PANEL_BORDER:=Color("#d7b96be8")
const TEXT_MAIN:=Color("#f5f1df")
const TEXT_MUTED:=Color("#9eabb8")
const ACCENT:=Color("#e6c45f")
const ICONS:Array[Dictionary]=[
    {"icon":"FIGHT","tip":"Combat / Character"},
    {"icon":"PET","tip":"Bonded Pet"},
    {"icon":"SKL","tip":"Skills"},
    {"icon":"INV","tip":"Inventory"},
    {"icon":"EQP","tip":"Equipment"},
    {"icon":"REF","tip":"Refinement"},
    {"icon":"SYS","tip":"System"}
]
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
    for data in ICONS:
        var button:=Button.new()
        button.tooltip_text=str(data["tip"])
        button.custom_minimum_size=Vector2(58,34)
        button.add_theme_stylebox_override("normal",button_style(false))
        button.add_theme_stylebox_override("hover",button_style(true))
        button.add_theme_stylebox_override("pressed",button_style(true))
        var label:=Label.new()
        label.text=str(data["icon"])
        label.add_theme_color_override("font_color",TEXT_MAIN)
        label.add_theme_font_size_override("font_size",11)
        label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        label.mouse_filter=Control.MOUSE_FILTER_IGNORE
        button.add_child(label)
        toolbar.add_child(button)

func _build_controls_hint()->void:
    var panel:=PanelContainer.new()
    panel.name="ControlsHint"
    panel.position=Vector2(18,690)
    panel.size=Vector2(600,52)
    panel.add_theme_stylebox_override("panel",panel_style())
    root.add_child(panel)
    help_label=Label.new()
    help_label.text="LMB: move / target    W/S: camera distance    A/D: camera orbit    RMB: cancel    ESC: cancel"
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
