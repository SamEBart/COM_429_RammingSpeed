class_name PhaseSpeedChart
extends RefCounted
## Spreads overall speed across the six execution phases.
##
## Speed is the number of hexes covered this turn. A phase assigns 0, 1, or 2 of them.
## The split is (speed * phase) / 6 minus the same value for the previous phase.
## That keeps a slow ship moving late in the turn.
##
## Speed 1 moves on phase 6.
## Speed 2 moves on phases 3 and 6.
## Speed 3 moves on phases 2, 4, and 6.
## Speed 4 moves on phases 2, 3, 5, and 6.
## Speed 5 moves on phases 2, 3, 4, 5, and 6.
## Speed 6 moves on every phase, one hex each.
## Speed below 1 is not a forward move. Backing is one hex. Drifting is one hex on phase 4.


const PHASE_COUNT := 6
const MAX_HEXES_PER_PHASE := 2
const DRIFT_PHASE := 4


## Forward hexes on this phase for a positive overall speed.
static func hexes_on_phase(overall_speed: int, phase: int) -> int:
	if overall_speed <= 0 or phase < 1 or phase > PHASE_COUNT:
		return 0
	var moves := mini(overall_speed, PHASE_COUNT * MAX_HEXES_PER_PHASE)
	var through := (moves * phase) / PHASE_COUNT
	var before := (moves * (phase - 1)) / PHASE_COUNT
	return mini(through - before, MAX_HEXES_PER_PHASE)


## Hexes this phase, including backing and drifting.
static func hex_count(overall_speed: int, phase: int) -> int:
	if overall_speed > 0:
		return hexes_on_phase(overall_speed, phase)
	if overall_speed < 0 and hexes_on_phase(1, phase) > 0:
		return 1
	if overall_speed == 0 and phase == DRIFT_PHASE:
		return 1
	return 0
