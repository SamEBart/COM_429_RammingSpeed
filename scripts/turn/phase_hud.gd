extends CanvasLayer
## On-map controls for the phase sequence. Sits in a corner so the hex map still receives clicks.

const _DESERT_TILE := preload("res://Resources/Tiles/Desert.tres")
const _WATER_MATERIAL := preload("res://assets/Materials/Shaders/water_shader.tres")
const _ScaleHandle := preload("res://scripts/turn/menu_scale_handle.gd")

var _panel: PanelContainer
var _status: Label
var _hint: Label
var _advance: Button
var _end_match: Button
var _legacy: CheckButton
var _flat_tiles: StandardMaterial3D


func _ready() -> void:
	_flat_tiles = StandardMaterial3D.new()
	_flat_tiles.albedo_color = _DESERT_TILE.color

	var host := Control.new()
	host.position = Vector2(16, 16)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_to_group("screen_menu")
	add_child(host)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(280, 0)
	_panel.add_theme_constant_override("margin_right", 6)
	_panel.add_theme_constant_override("margin_bottom", 16)
	host.add_child(_panel)
	_panel.resized.connect(func(): host.size = _panel.size)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "Phase Sequence"
	box.add_child(title)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint)

	_advance = Button.new()
	box.add_child(_advance)
	_advance.pressed.connect(TurnController.advance)

	_end_match = Button.new()
	_end_match.text = "End Match"
	box.add_child(_end_match)
	_end_match.pressed.connect(TurnController.end_match)

	_legacy = CheckButton.new()
	_legacy.text = "Test Movement"
	_legacy.button_pressed = not TurnController.use_phase_movement
	_legacy.toggled.connect(_on_legacy_toggled)
	box.add_child(_toggle_row(_legacy))

	var water := CheckButton.new()
	water.text = "Water toggle"
	water.button_pressed = true
	water.toggled.connect(_on_water_toggled)
	box.add_child(_toggle_row(water))

	var handle = _ScaleHandle.new()
	handle.pivot_corner = Vector2.ZERO
	handle.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	handle.offset_left = -14
	handle.offset_top = -14
	handle.offset_right = 0
	handle.offset_bottom = 0
	host.add_child(handle)

	TurnController.phase_changed.connect(_refresh)
	_refresh(TurnController.phase, TurnController.execution_step, TurnController.turn_number)
	_lock_layout.call_deferred()


func _lock_layout() -> void:
	var width := maxf(280.0, _widest_button() + 24.0)
	_panel.custom_minimum_size.x = width
	var inner := width - 28.0
	_status.custom_minimum_size = Vector2(inner, _wrapped_height(_status, "Execution 6 of 6 - Long Range Fire - turn 999", inner))
	var hint_height := 0.0
	for text in _every_hint():
		hint_height = maxf(hint_height, _wrapped_height(_hint, text, inner))
	_hint.custom_minimum_size = Vector2(inner, hint_height)


func _widest_button() -> float:
	var font := _advance.get_theme_font("font")
	var font_size := _advance.get_theme_font_size("font_size")
	var widest := 0.0
	for label in ["Begin Match", "Lock Command", "Finish Move", "Finish Long Range Fire", "Finish Boarding", "End Match"]:
		widest = maxf(widest, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return widest


func _wrapped_height(label: Label, text: String, width: float) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	return font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y


func _every_hint() -> Array[String]:
	return [
		"Test Movement: left click a ship, then right click any highlighted hex within 2 tiles.",
		"Begin Match opens Command. Set speed and facing on a ship before locking.",
		"Lock Command starts execution phase 1 at the Move step.",
		"Begin Match starts a new match.",
		"Finish Move steps every ship the chart allows. Entering an occupied hex opens Boarding before Long Range Fire.",
		"Test Movement: left click a ship and right click a highlighted hex.",
		"Finish Long Range Fire resolves archery, then opens the next execution phase.",
		"Select a shooter and a target. Finish Long Range Fire resolves archery, then opens Boarding.",
		"Boarding already started for the ships that share a hex. Finish Boarding opens Long Range Fire.",
		"Finish Boarding resolves ships sharing a hex, then opens the next execution phase.",
	]


func _refresh(_phase: TurnController.Phase, _execution_step: int, _turn_number: int) -> void:
	_status.text = TurnController.get_phase_label()
	_advance.text = TurnController.get_advance_button_text()
	_end_match.disabled = TurnController.phase == TurnController.Phase.GAME_OVER
	_hint.text = _hint_for(TurnController.phase, TurnController.action_step)


func _toggle_row(check: CheckButton) -> HBoxContainer:
	var row := HBoxContainer.new()
	check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(check)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(36, 0)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pad)
	return row


func _on_legacy_toggled(on: bool) -> void:
	TurnController.use_phase_movement = not on
	_refresh(TurnController.phase, TurnController.execution_step, TurnController.turn_number)


func _on_water_toggled(on: bool) -> void:
	var surface = _WATER_MATERIAL if on else _flat_tiles
	for node in get_tree().get_nodes_in_group("tiles"):
		if node is Tile and node.mesh_data and node.mesh_data.type == Tile.biome_type.Ocean:
			var mesh := node.get_child(0) as MeshInstance3D
			if mesh:
				mesh.material_override = surface


func _hint_for(phase: TurnController.Phase, step: TurnController.ActionStep) -> String:
	if not TurnController.use_phase_movement:
		return "Test Movement: left click a ship, then right click any highlighted hex within 2 tiles."
	if phase == TurnController.Phase.SETUP:
		return "Begin Match opens Command. Set speed and facing on a ship before locking."
	if phase == TurnController.Phase.COMMAND:
		return "Lock Command starts execution phase 1 at the Move step."
	if phase == TurnController.Phase.GAME_OVER:
		return "Begin Match starts a new match."
	match step:
		TurnController.ActionStep.MOVE:
			if TurnController.use_phase_movement:
				return "Finish Move steps every ship the chart allows. Entering an occupied hex opens Boarding before Long Range Fire."
			return "Test Movement: left click a ship and right click a highlighted hex."
		TurnController.ActionStep.LONG_RANGE_FIRE:
			if TurnController.boarding_before_fire:
				return "Finish Long Range Fire resolves archery, then opens the next execution phase."
			return "Select a shooter and a target. Finish Long Range Fire resolves archery, then opens Boarding."
		TurnController.ActionStep.BOARDING:
			if TurnController.boarding_before_fire:
				return "Boarding already started for the ships that share a hex. Finish Boarding opens Long Range Fire."
			return "Finish Boarding resolves ships sharing a hex, then opens the next execution phase."
	return ""
