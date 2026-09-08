class_name HeroPetComboHUD
extends CanvasLayer

const HeroPetComboSystem = preload("res://scripts/HeroPetComboSystem.gd")

var game:Node
var combo:Node
var panel:Panel
var count_label:Label
var grade_label:Label
var bond_label:Label
var meter:ProgressBar
var finisher_button:Button
var flash:ColorRect
var flash_timer:float=0.0

func _ready()->void:
    game=get_parent()
    combo=game.get_node_or_null("HeroPetComboSystem") if game else null
    _build()
    if combo and combo.has_signal("combo_changed"):
        combo.combo_changed.connect(_on_combo_changed)
    if combo and combo.has_signal("combo_triggered"):
        combo.combo_triggered.connect(_on_combo_triggered)
    _refresh()

func _process(delta:float)->void:
    if flash_timer>0.0:
        flash_timer=max(0.0,flash_timer-delta)
        if flash: flash.modulate.a=clamp(flash_timer*3.0,0.0,0.75)
    if combo and finisher_button:
        var combo_count_value:int=int(combo.get("combo_count"))
        var cooldown_value:float=float(combo.get("finisher_cooldown"))
        finisher_button.disabled=combo_count_value<5 or cooldown_value>0.0
        if cooldown_value>0.0:
            finisher_button.text="FINISHER %.1fs" % cooldown_value
        else:
            finisher_button.text="BOND FINISHER"

func _build()->void:
    panel=Panel.new()
    panel.position=Vector2(18,235)
    panel.size=Vector2(410,118)
    add_child(panel)
    var margin=MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left",12)
    margin.add_theme_constant_override("margin_top",8)
    margin.add_theme_constant_override("margin_right",12)
    margin.add_theme_constant_override("margin_bottom",8)
    panel.add_child(margin)
    var box=VBoxContainer.new()
    margin.add_child(box)
    var title=Label.new()
    title.text="HERO + PET BOND"
    title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(title)
    count_label=Label.new()
    count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    count_label.add_theme_font_size_override("font_size",26)
    box.add_child(count_label)
    grade_label=Label.new()
    grade_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(grade_label)
    meter=ProgressBar.new()
    meter.min_value=0
    meter.max_value=30
    meter.show_percentage=false
    box.add_child(meter)
    var row=HBoxContainer.new()
    box.add_child(row)
    bond_label=Label.new()
    bond_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    row.add_child(bond_label)
    finisher_button=Button.new()
    finisher_button.text="BOND FINISHER"
    finisher_button.pressed.connect(_on_finisher)
    row.add_child(finisher_button)
    flash=ColorRect.new()
    flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color=Color(1.0,0.8,0.2,0.0)
    add_child(flash)

func _refresh()->void:
    if combo==null: return
    var count:int=int(combo.get("combo_count"))
    var grade:String=combo.get_grade() if combo.has_method("get_grade") else "Building"
    _on_combo_changed(count,grade)

func _on_combo_changed(count:int,grade:String)->void:
    count_label.text="%d HIT" % count
    grade_label.text=grade
    meter.value=count
    bond_label.text="Next bond: %d" % _next_milestone(count)

func _on_combo_triggered(name:String,count:int)->void:
    flash_timer=0.28
    if game and game.has_method("log_message"):
        game.call("log_message","%s — synchronized combat power surges." % name)

func _next_milestone(count:int)->int:
    for milestone in [5,10,15,20,25,30]:
        if count<milestone: return milestone
    return 30

func _on_finisher()->void:
    if combo and combo.has_method("force_finisher"):
        if combo.force_finisher():
            flash_timer=0.55
