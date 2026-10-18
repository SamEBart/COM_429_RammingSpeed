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
## Local only. Ready checks, the turn timer, movement, and victory plug into
## these methods later. Other UI listens to [signal phase_changed] and reads

signal phase_changed(phase: Phase, execution_step: int, turn_number: int)
signal match_ended(turn_number: int)

enum Phase {
	SETUP,
	COMMAND,
	EXECUTION,
	GAME_OVER,
}

const EXECUTION_PHASE_COUNT := 6

var phase: Phase = Phase.SETUP
## 1–6 while [member phase] is [constant Phase.EXECUTION]. 0 in every other phase.
var execution_step: int = 0
## 0 before the first Command phase. 1 on the first turn.
var turn_number: int = 0


func begin_match() -> bool:
	if phase != Phase.SETUP and phase != Phase.GAME_OVER:
		push_error("begin_match requires Setup or Game Over. Current phase: %s." % get_phase_label())
		return false
	turn_number = 1
	execution_step = 0
	_enter(Phase.COMMAND)
	return true


## Command-phase stand-in for every player locking orders. Starts execution phase 1.
func lock_command() -> bool:
	if phase != Phase.COMMAND:
		push_error("lock_command requires Command. Current phase: %s." % get_phase_label())
		return false
	execution_step = 1
	_enter(Phase.EXECUTION)
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
		_enter(Phase.EXECUTION)
		return true
	execution_step = 0
	turn_number += 1
	_enter(Phase.COMMAND)
	return true


func end_match() -> bool:
	if phase == Phase.GAME_OVER:
		push_error("end_match was called, but the match is already over.")
		return false
	execution_step = 0
	_enter(Phase.GAME_OVER)
	match_ended.emit(turn_number)
	return true


func get_phase_label() -> String:
	match phase:
		Phase.SETUP:
			return "Setup"
		Phase.COMMAND:
			return "Command - turn %d" % turn_number
		Phase.EXECUTION:
			return "Execution %d of %d - turn %d" % [execution_step, EXECUTION_PHASE_COUNT, turn_number]
		Phase.GAME_OVER:
			if turn_number > 0:
				return "Game Over - ended on turn %d" % turn_number
			return "Game Over"
	return "Unknown"


func _enter(next: Phase) -> void:
	phase = next
	print("TurnController: %s" % get_phase_label())
	phase_changed.emit(phase, execution_step, turn_number)
