class_name SpeedCalculator
extends RefCounted
## Turns a ship's rowing speed and mast state into the speed used for movement.
##
## Rowing speed is the ordered oar speed. It stays in the range -1 to 4.
## -1 is backing up. 4 is the fastest the oars alone can go.
## During the Command phase a ship may only change rowing speed by a set amount:
## Quadrireme +1 or -1, Trireme +1 or -2.
## Overall speed is that rowing speed, plus 2 when the mast is down.
## Overall speed never goes above 6. The mast bonus is not added while backing up.


enum ShipKind {
	QUADRIREME,
	TRIREME,
}

const MIN_SPEED := -1
const MAX_BASE_SPEED := 4
const MAX_OVERALL_SPEED := 6
const MAST_DOWN_BONUS := 2


## True when delta is a legal Command-phase change for this ship type.
## Zero is always legal and means "leave the speed where it is."
static func adjustment_allowed(delta: int, kind: ShipKind) -> bool:
	return delta >= -max_decrease(kind) and delta <= max_increase(kind)


## Largest increase allowed in one Command phase. Both ship types may only go up by 1.
static func max_increase(_kind: ShipKind) -> int:
	return 1


## Largest decrease allowed in one Command phase.
## Quadrireme can drop by 1. Trireme can drop by 2.
static func max_decrease(kind: ShipKind) -> int:
	if kind == ShipKind.TRIREME:
		return 2
	return 1


## Applies a Command-phase change and keeps the result inside -1 to 4.
## An illegal delta is ignored and the current speed is returned unchanged.
static func apply_rowing_adjustment(current: int, delta: int, kind: ShipKind) -> int:
	if not adjustment_allowed(delta, kind):
		return current
	return clampi(current + delta, MIN_SPEED, MAX_BASE_SPEED)


## Movement speed for this order.
## Rowing speed is clamped to -1..4 first. A lowered mast then adds 2, up to 6.
## Backing up (rowing speed below 0) does not receive the mast bonus.
static func overall_speed(rowing_speed: int, mast_down: bool) -> int:
	var base_speed := clampi(rowing_speed, MIN_SPEED, MAX_BASE_SPEED)
	if mast_down and base_speed >= 0:
		return mini(base_speed + MAST_DOWN_BONUS, MAX_OVERALL_SPEED)
	return base_speed
