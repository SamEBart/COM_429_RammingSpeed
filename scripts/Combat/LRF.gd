extends Node
## Long Range Fire. Each ship shoots once: archers (_lrfMode 0) or its one siege weapon (1).
const _Log = preload("res://scripts/turn/game_log.gd")

#region Archery
## Called when the phase HUD finishes the LRF step. Group lookup returns Node, so skip anything that is not a Ship.
func resolve_long_range_fire() -> void:
	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
	for ship in ships:
		if ship is not Ship:
			continue
		var fired := false
		if _can_lrf(ship) and ship._enemyTarget:
			if ship._lrfMode == 0:
				archerFire(ship)
				fired = true
			elif _fire_siege(ship):
				fired = true
		## No shot this phase: still tick ballista/catapult cooldown.
		if not fired:
			ship.tick_weapon_reload()
	## Second pass: clear targeting so the next LRF starts clean.
	for ship in ships:
		if ship is not Ship:
			continue
		ship._enemyTarget = null
		if ship._owner:
			ship._owner._shipClicked = false
		if ship._dead.size() > 0:
			Global.purgeTheDead(ship)


func _can_lrf(ship: Ship) -> bool:
	return ship._boardingCounter == 0 and not ship._inBoarding


## Uses whichever weapon this hull spawned with. Needs a living engineer on the piece.
func _fire_siege(ship: Ship) -> bool:
	if not ship.has_living_engineer():
		return false
	if ship._ballista and ship._ballista.isLoaded() and not ship._ballista.isBroken():
		ballistaFire(ship)
		_Log.push("Fired %s's Ballista!" % ship.name)
		return true
	if ship._catapult and ship._catapult.isLoaded() and not ship._catapult.isBroken():
		catapultFire(ship)
		_Log.push("Fired %s's Catapult!" % ship.name)
		return true
	return false


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
	if ballista == null:
		return
	if ballista.isLoaded() and ship._enemyTarget and ship.has_living_engineer():
		ballistaFire(ship)
		_Log.push("Fired %s's Ballista!" % ship.name)
	elif !ballista.isLoaded():
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
	if catapult == null:
		return
	if catapult.isLoaded() and ship._enemyTarget and ship.has_living_engineer():
		catapultFire(ship)
		_Log.push("Fired %s's Catapult!" % ship.name)
	elif !catapult.isLoaded():
		catapult.reload()
		_Log.push("Reloading %s's Catapult now at (%s)" % [ship.name, ship._catapult._reloadTimer])

func catapultFire(ship: Ship):
	if ship._catapult and ship._enemyTarget and !ship._inBoarding:
		var target = ship._enemyTarget
		if randi_range(1, 6) <= ship._catapultTargetRange:
			Charts.catapultHit(target)
		ship._catapult.fire()
#endregion
