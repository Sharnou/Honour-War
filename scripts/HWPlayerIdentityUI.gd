extends CanvasLayer

## Persistent player/social presentation contract.
## Local hero: no overhead name or player HP/SP bars.
## Other players: name is hidden by default and revealed only on hover,
## chat/social context, party membership or active PvP.
## Player HP/SP is never rendered as a permanent world bar under player feet.
## Player class is never part of normal world UI; it is shown only after right-click -> Equip.
## ESC has exactly three primary actions: Create New Character, Switch Characters, Options.
## C/E opens one combined Status + Equipment window.

const CHARACTER = preload("res://scripts/CharacterProgressionSystem.gd")
const SAVE = preload("res://scripts/SaveSystem.gd")

var scene_root: Node
var legacy: Node
var overlay: Control
var escape_menu: Panel
var combined_window: Panel
var create_window: Panel
var switch_window: Panel
var options_window: Panel
var context_window: Panel
var selected_player: Node
var actor_ui: Dictionary = {}
var name_reveal_until: Dictionary = {}
var hovered_actor: Node = null
var scan_clock := 0

func _ready() -> void:
	layer = 190
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_bind")

func _bind() -> void:
	scene_root = get_tree().current_scene
	if scene_root == null:
		# Headless contract tests may instantiate this CanvasLayer before the
		# gameplay scene is assigned. Avoid recursive deferred binding loops.
		return
	legacy = scene_root.get_node_or_null("LegacyGame")
	overlay = Control.new()
	overlay.name = "HWPlayerIdentityOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_scan()

func _process(_delta: float) -> void:
	scan_clock += 1
	if scan_clock >= 20:
		scan_clock = 0
		_scan()
	hovered_actor = _pick_player(get_viewport().get_mouse_position())
	_refresh_labels()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_handle_escape()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C or event.keycode == KEY_E:
			_open_combined()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var actor := _pick_player(event.position)
		if actor != null and not _is_local(actor):
			_open_context(actor, event.position)
			get_viewport().set_input_as_handled()

func _scan() -> void:
	var seen := {}
	for group in ["player", "remote_player", "enemy", "party_member", "pvp_player"]:
		for actor in get_tree().get_nodes_in_group(group):
			if is_instance_valid(actor):
				# Player avatars never get permanent HP/SP world bars.
				_ensure_actor(actor, group == "enemy")
				seen[actor.get_instance_id()] = true
	if scene_root != null:
		for actor in scene_root.find_children("*", "Node3D", true, false):
			if actor.has_meta("hw_player") or actor.has_meta("hw_remote_player") or actor.has_meta("hw_enemy"):
				_ensure_actor(actor, bool(actor.get_meta("hw_enemy", false)))
				seen[actor.get_instance_id()] = true
		# Game3D always names the local visual Hero; include it even before group scan catches it.
		var hero := scene_root.get_node_or_null("Actors3D/Hero")
		if hero != null and is_instance_valid(hero):
			_ensure_actor(hero, false)
			seen[hero.get_instance_id()] = true
	for id in actor_ui.keys():
		if not seen.has(id):
			var data: Dictionary = actor_ui[id]
			var root_value: Variant = data.get("root", null)
			var root: Node = root_value as Node if is_instance_valid(root_value) and root_value is Node else null
			if root != null and is_instance_valid(root):
				root.queue_free()
			actor_ui.erase(id)

func _ensure_actor(actor: Node, bars: bool) -> void:
	var id := actor.get_instance_id()
	var data: Dictionary = actor_ui.get(id, {})
	var root_value: Variant = data.get("root", null)
	var root: Node3D = root_value as Node3D if is_instance_valid(root_value) and root_value is Node3D else null
	if root == null or not is_instance_valid(root):
		root = Node3D.new()
		root.name = "HWPlayerIdentity"
		actor.add_child(root)
		root.position = Vector3(0, -1.35, 0)
		data["root"] = root
	var name_label_value: Variant = data.get("name_label", null)
	var name_label: Label3D = name_label_value as Label3D if is_instance_valid(name_label_value) and name_label_value is Label3D else null
	if name_label == null or not is_instance_valid(name_label):
		name_label = Label3D.new()
		name_label.name = "CharacterRealName"
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label.font_size = 28
		name_label.outline_size = 7
		root.add_child(name_label)
		data["name_label"] = name_label
	name_label.text = _real_name(actor)
	name_label.position = Vector3(0, 0.0, 0)
	name_label.visible = not _is_local(actor)
	var hp_label_value: Variant = data.get("hp_label", null)
	var hp_label: Label3D = hp_label_value as Label3D if is_instance_valid(hp_label_value) and hp_label_value is Label3D else null
	if hp_label == null or not is_instance_valid(hp_label):
		hp_label = _make_bar("HP", Color("#e45b68"), root)
		data["hp_label"] = hp_label
	var sp_label_value: Variant = data.get("sp_label", null)
	var sp_label: Label3D = sp_label_value as Label3D if is_instance_valid(sp_label_value) and sp_label_value is Label3D else null
	if sp_label == null or not is_instance_valid(sp_label):
		sp_label = _make_bar("SP", Color("#59a6ee"), root)
		data["sp_label"] = sp_label
	hp_label.position = Vector3(0, -0.28, 0)
	sp_label.position = Vector3(0, -0.53, 0)
	hp_label.visible = bars and not _is_local(actor)
	sp_label.visible = hp_label.visible
	data["actor"] = actor
	data["bars"] = bars
	actor_ui[id] = data
	_update_bars(actor, data)

func _make_bar(caption: String, tint: Color, parent: Node3D) -> Label3D:
	var label := Label3D.new()
	label.name = "Visible" + caption
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 21
	label.outline_size = 6
	label.modulate = tint
	parent.add_child(label)
	return label

func _refresh_labels() -> void:
	for id in actor_ui.keys():
		var data: Dictionary = actor_ui[id]
		var actor_value: Variant = data.get("actor", null)
		if not is_instance_valid(actor_value) or not actor_value is Node:
			continue
		var actor: Node = actor_value as Node
		var local := _is_local(actor)
		var name_label_value: Variant = data.get("name_label", null)
		var hp_label_value: Variant = data.get("hp_label", null)
		var sp_label_value: Variant = data.get("sp_label", null)
		var name_label: Label3D = name_label_value as Label3D if is_instance_valid(name_label_value) and name_label_value is Label3D else null
		var hp_label: Label3D = hp_label_value as Label3D if is_instance_valid(hp_label_value) and hp_label_value is Label3D else null
		var sp_label: Label3D = sp_label_value as Label3D if is_instance_valid(sp_label_value) and sp_label_value is Label3D else null
		if name_label != null and is_instance_valid(name_label):
			name_label.visible = _world_name_visible(actor)
			name_label.text = _real_name(actor)
		if hp_label != null and is_instance_valid(hp_label):
			hp_label.visible = bool(data.get("bars", false)) and not local
		if sp_label != null and is_instance_valid(sp_label):
			sp_label.visible = hp_label != null and hp_label.visible
		_update_bars(actor, data)

func _update_bars(actor: Node, data: Dictionary) -> void:
	var hp := _number(actor, ["hp", "current_hp"], 0.0)
	var max_hp := _number(actor, ["max_hp", "hp_max"], maxf(hp, 1.0))
	var sp := _number(actor, ["sp", "current_sp"], 0.0)
	var max_sp := _number(actor, ["max_sp", "sp_max"], maxf(sp, 1.0))
	var hp_label_value: Variant = data.get("hp_label", null)
	var sp_label_value: Variant = data.get("sp_label", null)
	var hp_label: Label3D = hp_label_value as Label3D if is_instance_valid(hp_label_value) and hp_label_value is Label3D else null
	var sp_label: Label3D = sp_label_value as Label3D if is_instance_valid(sp_label_value) and sp_label_value is Label3D else null
	if hp_label != null and is_instance_valid(hp_label):
		hp_label.text = "HP " + _bar(hp, max_hp)
	if sp_label != null and is_instance_valid(sp_label):
		sp_label.text = "SP " + _bar(sp, max_sp)

func reveal_player_name(actor: Node, seconds: float = 4.0) -> void:
	if actor == null or _is_local(actor):
		return
	name_reveal_until[actor.get_instance_id()] = Time.get_ticks_msec() / 1000.0 + maxf(seconds, 0.1)

func reveal_player_name_for_social(actor: Node, seconds: float = 8.0) -> void:
	reveal_player_name(actor, seconds)

func _world_name_visible(actor: Node) -> bool:
	if actor == null or _is_local(actor):
		return false
	if actor == hovered_actor:
		return true
	if actor.is_in_group("party_member") or actor.is_in_group("pvp_player"):
		return true
	if actor.has_meta("chat_reveal_until"):
		var until_value := float(actor.get_meta("chat_reveal_until"))
		if until_value > Time.get_ticks_msec() / 1000.0:
			return true
	var until := float(name_reveal_until.get(actor.get_instance_id(), 0.0))
	return until > Time.get_ticks_msec() / 1000.0

func _number(actor: Node, keys: Array[String], fallback: float) -> float:
	for key in keys:
		var value: Variant = actor.get(key)
		if value is int or value is float:
			return float(value)
		if actor.has_meta(key):
			value = actor.get_meta(key)
			if value is int or value is float:
				return float(value)
	return fallback

func _bar(value: float, maximum: float) -> String:
	var width := 14
	var filled := int(round(clampf(value / maxf(maximum, 1.0), 0.0, 1.0) * width))
	return "[" + "█".repeat(filled) + "·".repeat(width - filled) + "]"

func _real_name(actor: Node) -> String:
	if actor == null:
		return "Adventurer"
	if actor.has_meta("character_name"):
		var meta_name := str(actor.get_meta("character_name"))
		if not meta_name.is_empty():
			return meta_name
	for key in ["character_name", "player_name", "real_name"]:
		var value: Variant = actor.get(key)
		if value != null and not str(value).is_empty():
			return str(value)
	var actor_name := str(actor.name)
	if actor_name.to_lower() not in ["player", "hero", "remoteplayer", "remote_player"] and not actor_name.is_empty():
		return actor_name
	return "Adventurer"

func _is_local(actor: Node) -> bool:
	if actor.has_meta("local_player"):
		return bool(actor.get_meta("local_player"))
	if actor.is_in_group("local_player"):
		return true
	if multiplayer.has_multiplayer_peer() and actor.is_in_group("player"):
		return actor.get_multiplayer_authority() == multiplayer.get_unique_id()
	return str(actor.name).to_lower() in ["hero", "player", "localplayer", "local_player"]

func _is_player(actor: Node) -> bool:
	return actor.is_in_group("player") or actor.is_in_group("remote_player") or actor.has_meta("hw_player") or actor.has_meta("hw_remote_player")

func _pick_player(screen: Vector2) -> Node:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var from := camera.project_ray_origin(screen)
	var to := from + camera.project_ray_normal(screen) * 1000.0
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	var collider: Object = hit.get("collider")
	if collider is Node:
		var node: Node = collider
		while node != null:
			if _is_player(node):
				return node
			node = node.get_parent()
	return null

func _open_context(actor: Node, position: Vector2) -> void:
	_close_context()
	selected_player = actor
	context_window = Panel.new()
	context_window.position = position + Vector2(8, 8)
	context_window.size = Vector2(250, 160)
	context_window.add_theme_stylebox_override("panel", _style(Color("#07101cf7"), Color("#d5b86e")))
	overlay.add_child(context_window)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	context_window.add_child(box)
	var name := Label.new()
	name.text = _real_name(actor)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name)
	# Class is intentionally exposed only inside this explicit right-click context.
	var class_label := Label.new()
	class_label.text = "CLASS: " + str(_actor_value(actor, "class", "Unknown"))
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(class_label)
	_button(box, "EQUIP", _show_equipment)
	_button(box, "CLOSE", _close_context)

func _show_equipment() -> void:
	if selected_player == null:
		return
	var dialog := AcceptDialog.new()
	dialog.title = _real_name(selected_player) + " • EQUIP + STATUS"
	var equipment: Variant = _actor_value(selected_player, "equipment", {})
	var text := "CLASS: " + str(_actor_value(selected_player, "class", "Unknown")) + "\n\n"
	text += _equipment_text(equipment)
	dialog.dialog_text = text
	overlay.add_child(dialog)
	dialog.popup_centered(Vector2i(520, 500))
	dialog.confirmed.connect(dialog.queue_free)

func _actor_value(actor: Node, key: String, fallback: Variant) -> Variant:
	if actor == null:
		return fallback
	var value: Variant = actor.get(key)
	if value != null:
		return value
	if actor.has_meta(key):
		return actor.get_meta(key)
	return fallback

func _equipment_text(value: Variant) -> String:
	if not value is Dictionary or value.is_empty():
		return "No equipment data available."
	var text := "EQUIPMENT\n"
	for key in value.keys():
		text += str(key).to_upper() + ": " + str(value[key]) + "\n"
	return text

func _close_context() -> void:
	if context_window != null:
		context_window.queue_free()
	context_window = null
	selected_player = null

func _handle_escape() -> void:
	if create_window != null or switch_window != null or options_window != null:
		_close_subpages()
	elif combined_window != null:
		_close_combined()
	elif escape_menu != null:
		_close_escape()
	elif context_window != null:
		_close_context()
	else:
		_open_escape()

func _open_escape() -> void:
	_close_context()
	escape_menu = _menu_panel("HONOUR WAR")
	var box := escape_menu.get_child(0) as VBoxContainer
	_button(box, "CREATE NEW CHARACTER", _open_create)
	_button(box, "SWITCH CHARACTERS", _open_switch)
	_button(box, "OPTIONS", _open_options)

func _menu_panel(caption: String) -> Panel:
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(460, 360)
	panel.position -= panel.size / 2.0
	panel.add_theme_stylebox_override("panel", _style(Color("#07101cf9"), Color("#d5b86e")))
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = caption
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	return panel

func _button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 54)
	button.pressed.connect(callback)
	parent.add_child(button)

func _close_escape() -> void:
	if escape_menu != null:
		escape_menu.queue_free()
	escape_menu = null

func _open_combined() -> void:
	_close_escape()
	if combined_window != null:
		combined_window.queue_free()
	combined_window = _menu_panel("CHARACTER • STATUS + EQUIPMENT")
	combined_window.size = Vector2(780, 700)
	combined_window.position = (get_viewport().get_visible_rect().size - combined_window.size) / 2.0
	var box := combined_window.get_child(0) as VBoxContainer
	var value: Variant = legacy.get("hero") if legacy != null else null
	if not value is Dictionary:
		return
	var hero: Dictionary = value
	CHARACTER.ensure_state(hero)
	var stats: Dictionary = CHARACTER.stats(hero)
	var top := Label.new()
	top.text = "%s   •   Level %d   •   Stat Points %d" % [str(hero.get("class", "Warrior")), int(hero.get("level", 1)), int(hero.get("stat_points", 0))]
	box.add_child(top)
	var vitals := Label.new()
	vitals.text = "HP %d / %d    SP %d / %d    ATK %d    MATK %d    DEF %d    MDEF %d" % [int(hero.get("hp", 0)), int(stats.get("max_hp", 0)), int(hero.get("sp", 0)), int(stats.get("max_sp", 0)), int(stats.get("atk", 0)), int(stats.get("matk", 0)), int(stats.get("def", 0)), int(stats.get("mdef", 0))]
	box.add_child(vitals)
	var stat_title := Label.new()
	stat_title.text = "STAT POINTS"
	box.add_child(stat_title)
	var stat_data: Dictionary = hero.get("stats", {})
	for stat in CHARACTER.STAT_NAMES:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = stat.to_upper() + "  " + str(int(stat_data.get(stat, 1)))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var add := Button.new()
		add.text = "+1"
		add.disabled = int(hero.get("stat_points", 0)) < 1
		add.pressed.connect(_add_stat.bind(stat))
		row.add_child(add)
		box.add_child(row)
	var eq_title := Label.new()
	eq_title.text = "EQUIPMENT"
	box.add_child(eq_title)
	var equipment: Dictionary = hero.get("equipment", {})
	for slot in ["weapon", "armor", "helmet", "cloak", "shoes", "shield", "accessory_1", "accessory_2"]:
		var row := Label.new()
		row.text = slot.to_upper() + "   " + str(equipment.get(slot, "EMPTY"))
		box.add_child(row)
	_button(box, "CLOSE", _close_combined)

func _add_stat(stat: String) -> void:
	if legacy == null:
		return
	var value: Variant = legacy.get("hero")
	if value is Dictionary and CHARACTER.allocate(value, stat, 1):
		SAVE.save_game(value)
	_open_combined()

func _close_combined() -> void:
	if combined_window != null:
		combined_window.queue_free()
	combined_window = null

func _open_create() -> void:
	_close_escape()
	create_window = _menu_panel("CREATE NEW CHARACTER")
	create_window.size = Vector2(620, 520)
	create_window.position = (get_viewport().get_visible_rect().size - create_window.size) / 2.0
	var box := create_window.get_child(0) as VBoxContainer
	var info := Label.new()
	info.text = "Enter the real character name other players will see, then choose a class."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Real character name"
	name_edit.max_length = 24
	box.add_child(name_edit)
	var classes := OptionButton.new()
	for cls in ["Warrior", "Mage", "Archer", "Thief", "Acolyte", "Merchant"]:
		classes.add_item(cls)
	box.add_child(classes)
	_button(box, "CREATE CHARACTER", _create_character.bind(name_edit, classes))
	_button(box, "BACK", _close_subpages)

func _create_character(name_edit: LineEdit, classes: OptionButton) -> void:
	var character_name := name_edit.text.strip_edges()
	if character_name.is_empty():
		name_edit.placeholder_text = "Enter a real character name"
		return
	var new_hero := {"name": character_name, "character_name": character_name, "class": classes.get_item_text(classes.selected), "level": 1, "hp": 100, "sp": 40, "age": 18, "stat_points": 0, "stats": {"str": 1, "agi": 1, "vit": 1, "int": 1, "dex": 1, "luk": 1}, "inventory": {}, "equipment": {}, "cards": [], "pet": {}}
	CHARACTER.ensure_state(new_hero)
	if legacy != null:
		legacy.set("hero", new_hero)
	SAVE.save_game(new_hero)
	_close_subpages()

func _open_switch() -> void:
	_close_escape()
	switch_window = _menu_panel("SWITCH CHARACTERS")
	switch_window.size = Vector2(620, 420)
	switch_window.position = (get_viewport().get_visible_rect().size - switch_window.size) / 2.0
	var box := switch_window.get_child(0) as VBoxContainer
	var current := Label.new()
	current.text = "CURRENT CHARACTER: " + _real_name(legacy)
	box.add_child(current)
	_button(box, "LOAD SAVED CHARACTER", _load_saved)
	_button(box, "BACK", _close_subpages)

func _load_saved() -> void:
	if legacy == null:
		return
	var current: Variant = legacy.get("hero")
	if current is Dictionary:
		legacy.set("hero", SAVE.load_game(current))
	_close_subpages()

func _open_options() -> void:
	_close_escape()
	options_window = _menu_panel("OPTIONS")
	options_window.size = Vector2(620, 500)
	options_window.position = (get_viewport().get_visible_rect().size - options_window.size) / 2.0
	var box := options_window.get_child(0) as VBoxContainer
	for text in ["HD Graphics", "Combat VFX", "Music", "Sound Effects", "Show Damage Numbers"]:
		var toggle := CheckButton.new()
		toggle.text = text
		toggle.button_pressed = true
		box.add_child(toggle)
	_button(box, "BACK", _close_subpages)

func _close_subpages() -> void:
	for panel in [create_window, switch_window, options_window]:
		if panel != null:
			panel.queue_free()
	create_window = null
	switch_window = null
	options_window = null
	_open_escape()

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
