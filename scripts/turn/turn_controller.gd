extends Node
## Steps a match through Setup, Command, Execution 1–6, and Game Over.
##
## loop:
##   Setup --begin_match--> Command --lock_command--> Execution 1
##   Execution 1–5 --complete_execution_phase--> the next execution phase
##   Execution 6 --complete_execution_phase--> Command (turn increases by 1)
##   any active phase --end_match--> Game Over
##   Game Over --begin_match--> Command (a new match)
##
## This script is the whole turn system. It does not need a scene.
## The TurnController Test Window (scenes/test/turn_controller_test_window.tscn)
## is a separate button panel for clicking through phases before the real menus
## exist. Removing that window does not change how this script runs.
##
## Local only. Ready checks, the turn timer, and victory plug into these methods later.
## Phase movement is the main move. Old click-to-hex movement stays available.
## Other UI listens to [signal phase_changed] and reads

signal phase_changed(phase: Phase, execution_step: int, turn_number: int)
signal match_ended(turn_number: int)


const _Log = preload("res://scripts/turn/game_log.gd")


func _ready() -> void:
	get_tree().root.add_child.call_deferred(_Log.new())

enum Phase {
	SETUP,
	COMMAND,
	EXECUTION,
	GAME_OVER,
}

## What players do inside one execution phase, in this order.
enum ActionStep {
	NONE,
	MOVE,
	LONG_RANGE_FIRE,
	BOARDING,
}

const EXECUTION_PHASE_COUNT := 6

var phase: Phase = Phase.SETUP
## 1–6 while [member phase] is [constant Phase.EXECUTION]. 0 in every other phase.
var execution_step: int = 0
## 0 before the first Command phase. 1 on the first turn.
var turn_number: int = 0
## Move, then Long Range Fire, then Boarding while [member phase] is Execution.
var action_step: ActionStep = ActionStep.NONE
## True: Finish Move steps ships from the phase-speed chart.
## False: the old right-click path move is used, and Finish Move does not step ships.
var use_phase_movement: bool = true
## True after a move enters an occupied hex. Boarding runs, then Long Range Fire.
var boarding_before_fire: bool = false


func begin_match() -> bool:
	if phase != Phase.SETUP and phase != Phase.GAME_OVER:
		push_error("begin_match requires Setup or Game Over. Current phase: %s." % get_phase_label())
		return false
	turn_number = 1
	execution_step = 0
	action_step = ActionStep.NONE
	boarding_before_fire = false
	_clear_move_stops()
	_enter(Phase.COMMAND)
	_apply_action_to_game()
	return true


## Command-phase stand-in for every player locking orders. Starts execution phase 1.
func lock_command() -> bool:
	if phase != Phase.COMMAND:
		push_error("lock_command requires Command. Current phase: %s." % get_phase_label())
		return false
	execution_step = 1
	action_step = ActionStep.MOVE
	boarding_before_fire = false
	_clear_move_stops()
	_enter(Phase.EXECUTION)
	_apply_action_to_game()
	return true


## Finishes the current execution phase. After phase 6, opens the next Command phase.
func complete_execution_phase() -> bool:
	if phase != Phase.EXECUTION:
		push_error("complete_execution_phase requires Execution. Current phase: %s." % get_phase_label())
		return false
	if execution_step < 1 or execution_step > EXECUTION_PHASE_COUNT:
		push_error("Execution step %d is outside 1–%d." % [execution_step, EXECUTION_PHASE_COUNT])
		return false
	if execution_step < EXECUTION_PHASE_COUNT:
		execution_step += 1
		action_step = ActionStep.MOVE
		_enter(Phase.EXECUTION)
		_apply_action_to_game()
		return true
	execution_step = 0
	action_step = ActionStep.NONE
	turn_number += 1
	_enter(Phase.COMMAND)
	_apply_action_to_game()
	return true


func end_match() -> bool:
	if phase == Phase.GAME_OVER:
		push_error("end_match was called, but the match is already over.")
		return false
	execution_step = 0
	action_step = ActionStep.NONE
	boarding_before_fire = false
	_enter(Phase.GAME_OVER)
	_apply_action_to_game()
	match_ended.emit(turn_number)
	return true


func get_phase_label() -> String:
	match phase:
		Phase.SETUP:
			return "Setup"
		Phase.COMMAND:
			return "Command - turn %d" % turn_number
		Phase.EXECUTION:
			return "Execution %d of %d - %s - turn %d" % [execution_step, EXECUTION_PHASE_COUNT, get_action_label(), turn_number]
		Phase.GAME_OVER:
			if turn_number > 0:
				return "Game Over - ended on turn %d" % turn_number
			return "Game Over"
	return "Unknown"


## One button on the map uses this.
## Setup and Game Over start a match. Command locks orders.
## During Execution the usual order is Move, Long Range Fire, Boarding.
## A move into an occupied hex opens Boarding first, then Long Range Fire.
func advance() -> bool:
	if phase == Phase.SETUP or phase == Phase.GAME_OVER:
		return begin_match()
	if phase == Phase.COMMAND:
		return lock_command()
	if phase != Phase.EXECUTION:
		return false
	var entered_occupied := _resolve_current_action()
	match action_step:
		ActionStep.MOVE:
			if entered_occupied:
				boarding_before_fire = true
				action_step = ActionStep.BOARDING
				_Log.push("A ship entered an occupied hex. Boarding opens before Long Range Fire.")
			else:
				action_step = ActionStep.LONG_RANGE_FIRE
			_apply_action_to_game()
			phase_changed.emit(phase, execution_step, turn_number)
			return true
		ActionStep.LONG_RANGE_FIRE:
			if boarding_before_fire:
				boarding_before_fire = false
				return _finish_execution_phase()
			action_step = ActionStep.BOARDING
			_apply_action_to_game()
			phase_changed.emit(phase, execution_step, turn_number)
			return true
		_:
			if boarding_before_fire:
				action_step = ActionStep.LONG_RANGE_FIRE
				_apply_action_to_game()
				phase_changed.emit(phase, execution_step, turn_number)
				return true
			return _finish_execution_phase()


func get_action_label() -> String:
	match action_step:
		ActionStep.MOVE:
			return "Move"
		ActionStep.LONG_RANGE_FIRE:
			return "Long Range Fire"
		ActionStep.BOARDING:
			return "Boarding"
		_:
			return "None"


func get_advance_button_text() -> String:
	match phase:
		Phase.SETUP, Phase.GAME_OVER:
			return "Begin Match"
		Phase.COMMAND:
			return "Lock Command"
		Phase.EXECUTION:
			match action_step:
				ActionStep.MOVE:
					return "Finish Move"
				ActionStep.LONG_RANGE_FIRE:
					return "Finish Long Range Fire"
				_:
					return "Finish Boarding"
	return "Next"


func _finish_execution_phase() -> bool:
	var finished_phase_six := execution_step >= EXECUTION_PHASE_COUNT
	if not complete_execution_phase():
		return false
	if not finished_phase_six:
		action_step = ActionStep.MOVE
		_apply_action_to_game()
	return true


func _resolve_current_action() -> bool:
	if action_step == ActionStep.MOVE and use_phase_movement:
		return PhaseMovement.apply(get_tree(), execution_step)
	if action_step == ActionStep.LONG_RANGE_FIRE:
		Global.resolve_long_range_fire()
	elif action_step == ActionStep.BOARDING:
		Global.resolve_boarding()
	return false


func _clear_move_stops() -> void:
	for node in get_tree().get_nodes_in_group("ships"):
		if node is Ship:
			node.clear_phase_move_stop()


func _apply_action_to_game() -> void:
	if phase == Phase.EXECUTION and action_step == ActionStep.MOVE:
		Global.set_turn_action(0)
	elif phase == Phase.EXECUTION and action_step == ActionStep.LONG_RANGE_FIRE:
		Global.set_turn_action(1)
	elif phase == Phase.EXECUTION and action_step == ActionStep.BOARDING:
		Global.set_turn_action(2)
	else:
		Global.set_turn_action(-1)


func _enter(next: Phase) -> void:
	phase = next
	_Log.push("TurnController: %s" % get_phase_label())
	phase_changed.emit(phase, execution_step, turn_number)
