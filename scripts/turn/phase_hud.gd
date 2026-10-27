extends CanvasLayer
## On-map controls for the phase sequence. Sits in a corner so the hex map still receives clicks.

const _DESERT_TILE := preload("res://Resources/Tiles/Desert.tres")
const _WATER_MATERIAL := preload("res://assets/Materials/Shaders/water_shader.tres")
const _MenuFrame := preload("res://scripts/turn/menu_frame.gd")
const _TurnPathPreview := preload("res://scripts/turn/turn_path_preview.gd")

var _panel: PanelContainer
var _status: Label
var _hint: Label
var _advance: Button
var _end_match: Button
var _legacy: CheckButton
var _legacy_row: HBoxContainer
var _mode: Label
var _flat_tiles: StandardMaterial3D


func _ready() -> void:
	_flat_tiles = StandardMaterial3D.new()
	_flat_tiles.albedo_color = _DESERT_TILE.color

	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_to_group("screen_menu")
	add_child(host)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(280, 0)
	_panel.add_theme_constant_override("margin_right", 6)
	_panel.add_theme_constant_override("margin_bottom", 16)
	host.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "Phase Sequence"
	box.add_child(title)

	_mode = Label.new()
	_mode.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_mode)

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
	_legacy_row = _toggle_row(_legacy)
	box.add_child(_legacy_row)

	var water := CheckButton.new()
	water.text = "Water toggle"
	water.button_pressed = true
	water.toggled.connect(_on_water_toggled)
	box.add_child(_toggle_row(water))

	_MenuFrame.new().setup(host, _panel, Vector2.ZERO, 16.0)

	get_tree().root.add_child.call_deferred(_TurnPathPreview.new())
	TurnController.phase_changed.connect(_refresh)
	TurnController.mode_changed.connect(_on_mode_changed)
	_refresh(TurnController.phase, TurnController.execution_step, TurnController.turn_number)
	_lock_layout.call_deferred()


func _lock_layout() -> void:
	var width := maxf(280.0, _widest_button() + 24.0)
	_panel.custom_minimum_size.x = width
	var inner := width - 28.0
	_status.custom_minimum_size = Vector2(inner, _wrapped_height(_status, "Execution 6 of 6 - Long Range Fire - turn 999", inner))
	var mode_height := maxf(_wrapped_height(_mode, _mode_text(false), inner), _wrapped_height(_mode, _mode_text(true), inner))
	_mode.custom_minimum_size = Vector2(inner, mode_height)
	_mode.text = _mode_text(TurnController.test_mode)
	var hint_height := 0.0
	for text in _every_hint():
		hint_height = maxf(hint_height, _wrapped_height(_hint, text, inner))
	_hint.custom_minimum_size = Vector2(inner, hint_height)


func _widest_button() -> float:
	var font := _advance.get_theme_font("font")
	var font_size := _advance.get_theme_font_size("font_size")
	var widest := 0.0
	for label in ["Begin Match", "Lock Command", "Ready", "Finish Move", "Finish Long Range Fire", "Finish Boarding", "End Match"]:
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
		"Set each ship's crew, speed, mast, and facing. Ready locks your orders until next turn.",
		"Orders locked. Waiting for the other players.",
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
	_advance.disabled = TurnController.phase == TurnController.Phase.COMMAND and TurnController.local_ready
	_hint.text = _hint_for(TurnController.phase, TurnController.action_step)
	_mode.text = _mode_text(TurnController.test_mode)
	_legacy_row.visible = TurnController.test_mode
	_legacy.set_pressed_no_signal(not TurnController.use_phase_movement)


func _on_mode_changed(_test_mode: bool) -> void:
	_refresh(TurnController.phase, TurnController.execution_step, TurnController.turn_number)


func _mode_text(test_mode: bool) -> String:
	if test_mode:
		return "Mode: Test. Shift+T to switch."
	return "Mode: Normal (%s). Shift+T to switch." % _local_player_name()


func _local_player_name() -> String:
	for node in get_tree().get_nodes_in_group("players"):
		if node is Player and node.getPlayerId() == TurnController.local_player_id:
			return node.getName()
	return "Player %d" % TurnController.local_player_id


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
		if TurnController.test_mode:
			return "Lock Command starts execution phase 1 at the Move step."
		if TurnController.local_ready:
			return "Orders locked. Waiting for the other players."
		return "Set each ship's crew, speed, mast, and facing. Ready locks your orders until next turn."
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
