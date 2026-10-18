extends Node3D

var _action = 0
var _subAction = 0
var threads: Array[Thread] = []

## TEMPORARAY until we figure out multiplayer
var _lastShipClicked = null

func _input(event: InputEvent) -> void:
	# Temporary to designate current main action
	if Input.is_action_just_pressed("ShiftEnter"):
		_action += 1
		match _action:
			0:
				action_reset()
				print("Now on Move Ships ", _action)
			1:
				action_reset()
				print("Now on Long Range Firing ", _action)
			2:
				action_reset()
				print("Now on Boarding Actions ", _action)
			3:
				action_reset()
				print("Reset ", _action)
				_action = -1
				return
	
	# Temporary to go to next sub action
	elif Input.is_action_just_pressed("NextSubAction"):
		get_tree().call_group("ships", "ship_reset")
		_subAction += 1
		print("New Sub Action: ", _subAction, " on Global: ", _action)
	
	# Temporary to  induce action truns/events manually
	elif Input.is_action_just_pressed("CtrlEnter"):
		#If Archery
		if Global._action == 1 and Global._subAction == 0:
			resolve_long_range_fire()
		
		#If Ballista
		if Global._action == 1 and Global._subAction == 1:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				if ship._ballista and !ship.getBallista().isBroken() and ship._boardingCounter == 0:
					var ballista = ship.getBallista()
					if ballista.isLoaded() and ship.getEngineers() and ship._enemyTarget:
						# (TEMP) If ballista does not have an eng and one is available, assign eng to ballista
						if ballista._engineers.size() == 0:
							ballista.allocateEngineer(ship)
						if ballista._engineers.size() >= 1:
							LRF.ballistaFire(ship)
							ship._ballista.fire()
							print("Fired ", ship.name, "s Ballista!")
					elif !ballista.isLoaded() and ship.getEngineers():
						# (TEMP) If ballista does not have an eng and one is available, assign eng to ballista
						if ballista._engineers.size() == 0:
							ballista.allocateEngineer(ship)
						if ballista._engineers.size() >= 1:
							ballista.reload()
							print("Reloading ", ship.name, "s Ballista now at (", ship._ballista._reloadTimer, ")")
			#Reset Ship
			for ship in ships:
				ship._enemyTarget = null
				ship._owner._shipClicked = false
				if ship._dead.size() > 0:
					purgeTheDead(ship)
		
		#If Catapult
		elif Global._action == 1 and Global._subAction == 2:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				if ship._catapult and !ship.getCatapult().isBroken() and ship._boardingCounter == 0:
					var catapult = ship.getCatapult()
					if catapult.isLoaded() and ship.getEngineers() and ship._enemyTarget:
						# (TEMP) If catapult does not have an eng and one is available, assign eng to catapult
						if catapult._engineers.size() == 0:
							catapult.allocateEngineer(ship)
						if catapult._engineers.size() >= 1:
							LRF.catapultFire(ship)
							ship._catapult.fire()
							print("Fired ", ship.name, "s Catapult!")
					elif !catapult.isLoaded() and ship.getEngineers():
						# (TEMP) If catapult does not have an eng and one is available, assign eng to catapult
						if catapult._engineers.size() == 0:
							catapult.allocateEngineer(ship)
						if catapult._engineers.size() >= 1:
							catapult.reload()
							print("Reloading ", ship.name, "s Catapult now at (", ship._catapult._reloadTimer, ")")
			#Reset Ship
			for ship in ships:
				ship._enemyTarget = null
				ship._owner._shipClicked = false
				if ship._dead.size() > 0:
					purgeTheDead(ship)
		
		#Boarding Action Fighting Determinating
		elif Global._action == 2 and Global._subAction == 0:
			resolve_boarding()
		
		#Boarding Action Archery
		elif Global._action == 2 and Global._subAction == 1:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			#Determine which ships are boarding eachother
			for ship in ships:
				if ship._enemyTarget and ship._boardingArchers.size() > 0 and ship._boardingCounter == 0 and ship._boardingPrepped == false:
					var thread1: Thread = Thread.new()
					thread1.start(BoardingActions.boardingArcherFire.bind(ship))
					var thread2: Thread = Thread.new()
					thread2.start(BoardingActions.boardingArcherFire.bind(ship._enemyTarget))
					if thread1.is_started():
						thread1.wait_to_finish()
					if thread2.is_started():
						thread2.wait_to_finish()
			for ship in ships:
				ship._boardingPrepped = false
				if ship._dead.size() > 0:
					purgeTheDead(ship)
		
		#Boarding Action Javelins
		elif Global._action == 2 and Global._subAction == 2:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			#Determine which ships are boarding eachother
			for ship in ships:
				if ship._enemyTarget and ship._boardingJavelins.size() > 0 and ship._boardingCounter == 0 and ship._boardingPrepped == false:
					var thread1: Thread = Thread.new()
					thread1.start(BoardingActions.boardingJavelineFireFire.bind(ship))
					var thread2: Thread = Thread.new()
					thread2.start(BoardingActions.boardingJavelineFire.bind(ship._enemyTarget))
					if thread1.is_started():
						thread1.wait_to_finish()
					if thread2.is_started():
						thread2.wait_to_finish()
			for ship in ships:
				ship._boardingPrepped = false
				if ship._dead.size() > 0:
					purgeTheDead(ship)
		
		#Boarding Action Melee
		elif Global._action == 2 and Global._subAction == 3:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			#Determine which ships are boarding eachother
			for ship in ships:
				if ship:
					BoardingActions.preBoardingMelee(ship)
			for ship in ships:
				ship._boardingPrepped = false
				if ship._dead.size() > 0:
					purgeTheDead(ship)


func compare_ship_initiatives(a: Ship, b: Ship):
	#Highest Speed (Highest Wins)
	if a.speed != b.speed:
		return a.speed > b.speed
	#Type (Tri v/s Quad) (Tri wins becasue small)
	if a.type != a.type:
		return a.type < b.type
	#Deck Crew Count (Highest Wins)
	if a._engineers.size() != b._engineers.size():
		return a._engineers.size() > b._engineers.size()
	#Dice
	var rolling = true;
	while rolling:
		var rollOne = randi_range(1, 6)
		var rollTwo = randi_range(1, 6)
		if rollOne != rollTwo:
			return rollOne > rollTwo
			rolling = false

#region Parent Functions
func addToDead(ship, deadGuys):
	var guy = deadGuys.pick_random()
	guy._isDead = true
	ship._dead.append(guy)

func purgeTheDead(ship):
	print(ship.name, "s Dead: ", ship._dead.size())
	print("Before: ", ship.name, " has A: ", ship._marineArchers.size(), ", J: ", ship._marineJavelineers.size(), ", S: ", ship._marineSoldiers.size(), 
	", E: ", ship._engineers.size(), ", D: ", ship._deckCrew.size() )
	for i in ship._dead.size():
		ship.kill(ship._dead[i])
		if ship._fighters.has(ship._dead[i]):
			ship._fighters.erase(ship._dead[i])
	ship._dead.clear()
	print("After: ", ship.name, " has A: ", ship._marineArchers.size(), ", J: ", ship._marineJavelineers.size(), ", S: ", ship._marineSoldiers.size(), 
	", E: ", ship._engineers.size(), ", D: ", ship._deckCrew.size() )
#endregion

func action_reset():
	_subAction = 0


## The phase sequence sets this so clicks match the current step.
## 0 is Move, 1 is Long Range Fire, 2 is Boarding. Any other value ignores those clicks.
func set_turn_action(action: int) -> void:
	_action = action
	action_reset()


func resolve_long_range_fire() -> void:
	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
	for ship in ships:
		if ship._boardingCounter == 0:
			LRF.archerFire(ship)
	for ship in ships:
		ship._enemyTarget = null
		ship._owner._shipClicked = false
		if ship._dead.size() > 0:
			purgeTheDead(ship)


func resolve_boarding() -> void:
	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
	for ship in ships:
		for boat in ships:
			if ship._tile == boat._tile and ship != boat and ship._enemyTarget == null and boat._enemyTarget == null:
				ship._enemyTarget = boat
				boat._enemyTarget = ship
	for ship in ships:
		if !ship._boardingPrepped and ship._enemyTarget:
			BoardingActions.determineFighting(ship)
	for ship in ships:
		if ship._boardingPrepped:
			ship._boardingPrepped = false
