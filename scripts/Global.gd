extends Node3D

const _Log = preload("res://scripts/turn/game_log.gd")

var _action = 0
var _subAction = 0
var threads: Array[Thread] = []
var humanPlayers : int = 2
var totalPlayers : int = 4
var turnCap : int = 999
var difficulty : int = 1

## Currently setup for prototype_unit rotation (block part as head)
var _hexUp: int = 270
var _hexUpRight: int = 210
var _hexDownRight: int = 150
var _hexDown: int = 90
var _hexDownLeft: int = 30
var _hexUpLeft: int = 330
## TEMPORARAY until we figure out multiplayer
var _lastShipClicked = null

func _input(event: InputEvent) -> void:
	# Temporary to designate current main action
	if Input.is_action_just_pressed("ShiftEnter"):
		_action += 1
		match _action:
			0:
				#See if there is only one Player left
				Global.determineWinner(1)
				action_reset()
				_Log.push("Now on Move Ships %d" % _action)
			1:
				#See if there is only one Player left
				Global.determineWinner(1)
				action_reset()
				_Log.push("Now on Long Range Firing %d" % _action)
			2:
				#See if there is only one Player left
				Global.determineWinner(1)
				action_reset()
				_Log.push("Now on Boarding Actions %d" % _action)
			3:
				#See if there is only one Player left
				Global.determineWinner(1)
				action_reset()
				_Log.push("Reset %d" % _action)
				_action = -1
				return
	
	# Temporary to go to next sub action
	elif Input.is_action_just_pressed("NextSubAction"):
		#See if there is only one Player left
		Global.determineWinner(1)
		get_tree().call_group("ships", "ship_reset")
		_subAction += 1
		_Log.push("New Sub Action: %d on Global: %d" % [_subAction, _action])
	
	# Temporary to  induce action truns/events manually
	elif Input.is_action_just_pressed("CtrlEnter"):
		#If Archery
		if Global._action == 1 and Global._subAction == 0:
			LRF.resolve_long_range_fire()
		
		#If Ballista
		if Global._action == 1 and Global._subAction == 1:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				if ship._ballista and !ship.getBallista().isBroken() and !ship._inBoarding:
					LRF.determineBallistaAction(ship)
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
				if ship._catapult and !ship.getCatapult().isBroken() and !ship._inBoarding:
					LRF.determineCatapultAction(ship)
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
			#Do the Archery if there is a target and available archers
			for ship in ships:
				if ship._boardingTarget and ship._boardingArchers.size() > 0 and ship._boardingPrepped == false:
					BoardingActions.doBoardingArchery(ship)
			for ship in ships:
				ship._boardingPrepped = false
				if ship._dead.size() > 0:
					purgeTheDead(ship)
		
		#Boarding Action Javelins
		elif Global._action == 2 and Global._subAction == 2:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			#Do the Javelines if there is a target and available archers
			for ship in ships:
				if ship._boardingTarget and ship._boardingJavelins.size() > 0 and ship._boardingPrepped == false:
					BoardingActions.doBoardingJaveline(ship)
			for ship in ships:
				ship._boardingPrepped = false
				if ship._dead.size() > 0:
					purgeTheDead(ship)
		
		#Boarding Action Melee/Victory
		elif Global._action == 2 and Global._subAction == 3:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			#Determine which ships are boarding eachother
			for ship in ships:
				if ship._boardingTarget:
					BoardingActions.preBoardingMelee(ship)
			#Reset Ships
			for ship in ships:
				ship._boardingPrepped = false
				if ship._dead.size() > 0:
					purgeTheDead(ship)
			#Remove Dead Ships that has no Aux or Soldiers
			for j in range(ships.size() - 1, -1, -1):
				if ships[j]._fighters.size() == 0 or ships[j]._flotationHits == 0:
					baRemoveShip(ships[j])
		
		#Boarding Withdrawing
		elif Global._action == 2 and Global._subAction == 4:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				if ship._boardingTarget != null:
					BoardingActions.boardingWithdrawing(ship)
			#Remove Dead Ships that has no Aux or Soldiers
			for j in range(ships.size() - 1, -1, -1):
				if ships[j]._fighters.size() == 0 or ships[j]._flotationHits == 0:
					baRemoveShip(ships[j])


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

#region Dead Functions
func removeDeadCrewAndShip(ship: Ship):
	if ship._dead.size() > 0:
		purgeTheDead(ship)
	if isShipDead(ship):
		baRemoveShip(ship)

func addToDead(ship, deadGuys):
	var guy = deadGuys.pick_random()
	guy._isDead = true
	ship._dead.append(guy)

func purgeTheDead(ship):
	_Log.push("%s's Dead: %d" % [ship.name, ship._dead.size()])
	_Log.push("Before: %s has A: %d, J: %d, S: %d, E: %d, D: %d" % [ship.name, ship._marineArchers.size(), ship._marineJavelineers.size(), ship._marineSoldiers.size(), ship._engineers.size(), ship._deckCrew.size()])
	for i in ship._dead.size():
		ship.kill(ship._dead[i])
		if ship._fighters.has(ship._dead[i]):
			ship._fighters.erase(ship._dead[i])
	ship._dead.clear()
	_Log.push("After: %s has A: %d, J: %d, S: %d, E: %d, D: %d" % [ship.name, ship._marineArchers.size(), ship._marineJavelineers.size(), ship._marineSoldiers.size(), ship._engineers.size(), ship._deckCrew.size()])

func isShipDead(ship: Ship):
	if ship._fighters.size() == 0 or ship._flotationHits == 0:
		return true
	else:
		return false

func baRemoveShip(ship):
	#Remove Ship from Tile Occupir List
	for boat in ship._tile.occupier:
		if boat == ship:
			ship._tile.occupier.erase(boat)
	
	#Remove Ship from other Ships Target variable(s)
	var boats: Array[Node] = get_tree().get_nodes_in_group("ships")
	for boat in boats:
		if boat._enemyTarget == ship:
			boat._enemyTarget = null
			boat._inBoarding = false
			boat._inCollision = false
		#Remove from ship boarding target
		if boat._boardingTarget == ship:
			boat._boardingTarget = null
			boat._inBoarding = false
			boat._inCollision = false
	
	#Remove Ship from Owner
	for boat in ship._owner._ships:
		if boat == ship:
			ship._owner._ships.erase(boat)
			break
	
	#Remove Ship from Ships list
	ship.remove_from_group("ships")
	
	#Remove Ship
	ship.queue_free()
	
	#Remove and Playes that have 0 Ships
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	for j in range(players.size() - 1, -1, -1):
		if players[j]._ships.size() == 0:
			players[j].remove_from_group("players")
	
	#See if there is only one Player left
	Global.determineWinner(1)
#endregion

#region Winning Functions
func determineWinner(choice: int):
	if choice == 1 or choice == 2:
		if isLastOneStanding():
			var players: Array[Node] = get_tree().get_nodes_in_group("players")
			choice = 0
			_Log.push("%s Wins the Game!" % players[0]._name)
	if choice == 2:
		chooseWinner()

func isLastOneStanding() -> bool:
	#Check if there is only one Player left
	var answer = true
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	if players.size() != 1:
		answer = false
		
	return answer

func chooseWinner():
	#Get Player(s) with the most ships
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	var maxValue = null
	for player in players:
		if maxValue == null or player._ships.size() > maxValue:
			maxValue = player._ships.size()
	var mostShipsArray = []
	for player in players:
		if player._ships.size() == maxValue:
			mostShipsArray.append(player)
	
	#If only 1 Player has the most ships they win
	if mostShipsArray.size() == 1:
		#Print win
		_Log.push("%s Wins the Game!" % mostShipsArray[0]._name)
	#More conditions to win if more than 1 Player has the most ships
	else:
		#Get how many fighters each player has
		for player in mostShipsArray:
			for ship in player._ships:
				player._totalFighters += ship._deckCrew.size() + ship._marineArchers.size() + ship._marineJavelineers.size() + ship._marineSoldiers.size() + ship._engineers.size()
		
		#Get list of Players with the most fighters
		maxValue = null
		for player in mostShipsArray:
			if maxValue == null or player._totalFighters > maxValue:
				maxValue = player._totalFighters
		var mostFightersArray = []
		for player in players:
			if player._totalFighters == maxValue:
				mostFightersArray.append(player)
		
		#Determine if it is a win or to check more conditions
		if mostFightersArray.size() == 1:
			#Print win
			_Log.push("%s Wins the Game!" % mostFightersArray[0]._name)
		
		#More conditions to win; check total flotation points. Player with most wins (least hit player)
		else:
			#Get how many flotation points each player has
			for player in mostShipsArray:
				player._totalFlotationHits = 0
				for ship in player._ships:
					player._totalFlotationHits += ship._flotationHits
			
			#Get list of Players with the most flotation hits
			maxValue = null
			for player in mostShipsArray:
				if maxValue == null or player._totalFlotationHits > maxValue:
					maxValue = player._totalFlotationHits
			var mostFloatersArray = []
			for player in players:
				if player._totalFlotationHits == maxValue:
					mostFloatersArray.append(player)
			
			#Determine if it is a win or draw
			if mostFloatersArray.size() == 1:
				#Print win
				_Log.push("%s Wins the Game!" % mostFloatersArray[0]._name)
			
			else:
				#Print draw
				_Log.push("DRAW!")
#endregion

func action_reset():
	_subAction = 0


## The phase sequence sets this so clicks match the current step.
## 0 is Move, 1 is Long Range Fire, 2 is Boarding. Any other value ignores those clicks.
func set_turn_action(action: int) -> void:
	_action = action
	action_reset()


## TurnController calls this. Real work is in Combat/LRF.gd so SceneTree scripts can still use Global.
func resolve_long_range_fire() -> void:
	LRF.resolve_long_range_fire()


func resolve_boarding() -> void:
	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
	for ship in ships:
			ship._boardingPrepped = false
	for ship in ships:
		if !ship._boardingPrepped and ship._boardingTarget:
			BoardingActions.determineFighting(ship)
	for ship in ships:
		if ship._boardingPrepped:
			ship._boardingPrepped = false
