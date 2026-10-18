extends CanvasLayer
## On-map controls for the phase sequence. Sits in a corner so the hex map still receives clicks.

var _status: Label
var _hint: Label
var _advance: Button
var _end_match: Button
var _legacy: CheckButton


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.add_to_group("screen_menu")
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(280, 0)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

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
	_legacy.text = "Old click movement"
	_legacy.button_pressed = not TurnController.use_phase_movement
	_legacy.toggled.connect(_on_legacy_toggled)
	box.add_child(_legacy)

	TurnController.phase_changed.connect(_refresh)
	_refresh(TurnController.phase, TurnController.execution_step, TurnController.turn_number)


func _refresh(_phase: TurnController.Phase, _execution_step: int, _turn_number: int) -> void:
	_status.text = TurnController.get_phase_label()
	_advance.text = TurnController.get_advance_button_text()
	_end_match.disabled = TurnController.phase == TurnController.Phase.GAME_OVER
	_hint.text = _hint_for(TurnController.phase, TurnController.action_step)


func _on_legacy_toggled(on: bool) -> void:
	TurnController.use_phase_movement = not on
	_refresh(TurnController.phase, TurnController.execution_step, TurnController.turn_number)


func _hint_for(phase: TurnController.Phase, step: TurnController.ActionStep) -> String:
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
			return "Old movement: left click a ship and right click a highlighted hex."
		TurnController.ActionStep.LONG_RANGE_FIRE:
			if TurnController.boarding_before_fire:
				return "Finish Long Range Fire resolves archery, then opens the next execution phase."
			return "Select a shooter and a target. Finish Long Range Fire resolves archery, then opens Boarding."
		TurnController.ActionStep.BOARDING:
			if TurnController.boarding_before_fire:
				return "Finish Boarding resolves ships sharing a hex, then opens Long Range Fire."
			return "Finish Boarding resolves ships sharing a hex, then opens the next execution phase."
	return ""
