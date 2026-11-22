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
	for i in ship._dead.size():
		#Get a count for each type of character killed for informaton purposes
		var archers = 0; var javs = 0; var soldiers = 0; var engs = 0; var deck = 0
		if ship._dead[i] is Character.Marine.Archer:
			archers += 1
		if ship._dead[i] is Character.Marine.Javelineer:
			javs += 1
		if ship._dead[i] is Character.Marine.Soldier:
			soldiers += 1
		if ship._dead[i] is Character.Engineer:
			engs += 1
		if ship._dead[i] is Character.DeckCrew:
			deck += 1
		
		#Print the death results
		var line := ""
		if archers > 0: line += str(archers) + " Archers, "
		if javs > 0: line += str(javs) + " Javelineers, "
		if soldiers > 0: line += str(soldiers) + " Soldiers, "
		if engs > 0: line += str(engs) + " Engineers, "
		if deck > 0: line += str(deck) + " Deck Crew "
		if line != "":
			_Log.push("%s %s lost: %s" % [ship._owner._name, ship.name, line])
		
		#Remove Characters
		ship.kill(ship._dead[i])
		if ship._fighters.has(ship._dead[i]):
			ship._fighters.erase(ship._dead[i])
	ship._dead.clear()


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
			_Log.push("%ss %s has been captured or sunk and removed from the game!" % [ship._owner._name, boat.name])
			break
	
	#Remove Ship from Ships list
	ship.remove_from_group("ships")
	
	#Remove Ship
	ship.queue_free()
	
	#Remove and Playes that have 0 Ships
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	for j in range(players.size() - 1, -1, -1):
		if players[j]._ships.size() == 0:
			_Log.push("%s has 0 ships left and has been removed from the game!" % [players[j]._name])
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
