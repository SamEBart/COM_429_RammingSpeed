extends Node
const _Log = preload("res://scripts/turn/game_log.gd")

#region Archery
func archerFire(ship: Ship):
	if ship.getArchers() and ship._enemyTarget and !ship._inBoarding:
		var target = ship._enemyTarget
		var archers = ship.getArchers()
		_Log.push("Ship: %s attacks: %s" % [ship.name, ship._enemyTarget.name])
		for i in archers.size():
			if randi_range(1, 6) == 6:
				Charts.singleCrewCasualty(target)
#endregion

#region Ballista
func determineBallistaAction(ship: Ship):
	var ballista = ship.getBallista()
	#Fire Ballista if it can be fired and has allocated Engineer(s)
	if ballista.isLoaded() and ship.getEngineers() and ship._enemyTarget and ballista._engineers.size() > 0:
		ballistaFire(ship)
		_Log.push("Fired %s's Ballista!" % ship.name)
	#Reload Ballista if it has allocated Engineer(s)
	elif !ballista.isLoaded() and ship.getEngineers() and ballista._engineers.size() > 0:
		ballista.reload()
		_Log.push("Reloading %s's Ballista now at (%s)" % [ship.name, ship._ballista._reloadTimer])

func ballistaFire(ship: Ship):
	if ship._ballista and ship._enemyTarget and !ship._inBoarding:
		var target = ship._enemyTarget
		if randi_range(1, 4) <= ship._ballistaTargetRange:
			Charts.singleCrewCasualty(target)
		ship._ballista.fire()
#endregion

#region Catapult
func determineCatapultAction(ship: Ship):
	var catapult = ship.getCatapult()
	#Fire Catapult if it can be fired and has allocated Engineer(s)
	if catapult.isLoaded() and ship.getEngineers() and ship._enemyTarget and catapult._engineers.size() > 0:
		catapultFire(ship)
		_Log.push("Fired %s's Catapult!" % ship.name)
	#Reload Catapult if it has allocated Engineer(s)
	elif !catapult.isLoaded() and ship.getEngineers() and catapult._engineers.size() > 0:
		catapult.reload()
		_Log.push("Reloading %s's Catapult now at (%s)" % [ship.name, ship._catapult._reloadTimer])

func catapultFire(ship: Ship):
	if ship._catapult and ship._enemyTarget and !ship._inBoarding:
		var target = ship._enemyTarget
		#ASSUMING 1-6 with range and same range application as it is not stated
		if randi_range(1, 6) <= ship._catapultTargetRange:
			Charts.catapultHit(target)
		ship._catapult.fire()
#endregion
