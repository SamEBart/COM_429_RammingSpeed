extends Node

const _Log = preload("res://scripts/turn/game_log.gd")

func archerFire(ship: Ship):
	if ship.getArchers() and ship._enemyTarget and !ship._inBoarding:
		var target = ship._enemyTarget
		var archers = ship.getArchers()
		_Log.push("Ship: %s attacks: %s" % [ship.name, ship._enemyTarget.name])
		for i in archers.size():
			if randi_range(1, 6) == 6:
				Charts.singleCrewCasualty(target)

func ballistaFire(ship: Ship):
	if ship._ballista and ship._enemyTarget and !ship._inBoarding:
		var target = ship._enemyTarget
		var temp = true
		while temp:
			if randi_range(1, 4) <= ship._ballistaTargetRange:
				Charts.singleCrewCasualty(target)

func catapultFire(ship: Ship):
	if ship._catapult and ship._enemyTarget and !ship._inBoarding:
		var target = ship._enemyTarget
		#ASSUMING 1-6 with range and same range application as it is not stated
		if randi_range(1, 6) <= ship._catapultTargetRange:
			Charts.catapultHit(target)
