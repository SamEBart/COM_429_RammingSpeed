extends Control
## TurnController Test Window.
##
## Premade tester only. This scene is not part of the turn system.
## scripts/turn/turn_controller.gd changes the phases by itself.
## These buttons call that script so the loop can be clicked through before
## the real menus exist. Those menus should call TurnController directly.
## This scene can be removed without changing the turn system.

@onready var _status: Label = %Status
@onready var _hint: Label = %Hint
@onready var _log: Label = %Log
@onready var _begin_match: Button = %BeginMatch
@onready var _lock_command: Button = %LockCommand
@onready var _complete_execution: Button = %CompleteExecution
@onready var _end_match: Button = %EndMatch

var _lines: PackedStringArray = PackedStringArray()


func _ready() -> void:
	get_window().title = "TurnController Test Window"
	_begin_match.pressed.connect(TurnController.begin_match)
	_lock_command.pressed.connect(TurnController.lock_command)
	_complete_execution.pressed.connect(TurnController.complete_execution_phase)
	_end_match.pressed.connect(TurnController.end_match)
	TurnController.phase_changed.connect(_on_phase_changed)
	_show_state()


func _on_phase_changed(_phase: TurnController.Phase, _execution_step: int, _turn_number: int) -> void:
	_show_state()


func _show_state() -> void:
	var label := TurnController.get_phase_label()
	_status.text = label
	_append_log(label)
	_begin_match.disabled = (
		TurnController.phase != TurnController.Phase.SETUP
		and TurnController.phase != TurnController.Phase.GAME_OVER
	)
	_lock_command.disabled = TurnController.phase != TurnController.Phase.COMMAND
	_complete_execution.disabled = TurnController.phase != TurnController.Phase.EXECUTION
	_end_match.disabled = TurnController.phase == TurnController.Phase.GAME_OVER
	if TurnController.phase == TurnController.Phase.EXECUTION:
		_complete_execution.text = "Complete execution phase %d" % TurnController.execution_step
	else:
		_complete_execution.text = "Complete execution phase"
	_hint.text = _hint_for(TurnController.phase)


func _hint_for(phase: TurnController.Phase) -> String:
	match phase:
		TurnController.Phase.SETUP:
			return "Begin Match leaves setup and opens Command Phase. Secret planning will happen in that phase later."
		TurnController.Phase.COMMAND:
			return "Command your ships before the Execution Phase"
		TurnController.Phase.EXECUTION:
			return "Each click finishes one execution phase. After phase 6, the match returns to Command and the turn number increases."
		TurnController.Phase.GAME_OVER:
			return "The match is over. Begin Match starts a new one."
	return ""


func _append_log(line: String) -> void:
	_lines.append(line)
	if _lines.size() > 14:
		_lines = _lines.slice(_lines.size() - 14)
	_log.text = "\n".join(_lines)
