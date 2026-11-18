extends Node

var neighbor_positions = WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS

func doBoaridingTurn():
	#A new set of ships is called everytime incase a ship has been killed in each action
	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
	for ship in ships:
		ship._boardingPrepped = false
	
	#Archery
	ships = get_tree().get_nodes_in_group("ships")
	#Do the Archery if there is a target and available archers
	for ship in ships:
		if ship._boardingTarget and ship._boardingArchers.size() > 0 and ship._boardingPrepped == false:
			doBoardingArchery(ship)
	#Remove Dead ships and crew
	for ship in ships:
		ship._boardingPrepped = false
		Global.removeDeadCrewAndShip(ship)
	
	#Boarding Action Javelins
	ships = get_tree().get_nodes_in_group("ships")
	#Do the Javelines if there is a target and available archers
	for ship in ships:
		if ship._boardingTarget and ship._boardingJavelins.size() > 0 and ship._boardingPrepped == false:
			doBoardingJaveline(ship)
	#Remove Dead ships and crew
	for ship in ships:
		ship._boardingPrepped = false
		Global.removeDeadCrewAndShip(ship)
	
	#Boarding Action Melee/Victory
	ships = get_tree().get_nodes_in_group("ships")
	#Determine which ships are boarding eachother
	for ship in ships:
		if ship._boardingTarget:
			preBoardingMelee(ship)
	#Remove Dead ships and crew
	for ship in ships:
		ship._boardingPrepped = false
		Global.removeDeadCrewAndShip(ship)
	
	#Boarding Withdrawing
	ships = get_tree().get_nodes_in_group("ships")
	for ship in ships:
		if ship._boardingTarget != null:
			boardingWithdrawing(ship)
	#Remove Dead ships and crew
	for ship in ships:
		ship._boardingPrepped = false
		Global.removeDeadCrewAndShip(ship)


func determineFighting(ship: Ship):
	var target = ship._boardingTarget
	#Can't boarding action same team
	print("A, ", ship, ", ", ship._boardingTarget)
	if ship._owner == target._owner:
		print("Boarding Target is same team!")
		return
	
	ship._boardingPrepped = true
	target._boardingPrepped = true
	
	#Sort fighters so that grabbing them for melee based on type is easier
	#My Fighters
	var my_new_fighters = []
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.Marine.Soldier))
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.Marine.Javelineer))
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.Marine.Archer))
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.Engineer))
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.DeckCrew))
	#Enemy Fighters
	var enemy_new_fighters = []
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.Marine.Soldier))
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.Marine.Javelineer))
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.Marine.Archer))
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.Engineer))
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.DeckCrew))
	
	ship._boardingArchers.clear()
	ship._boardingJavelins.clear()
	ship._boardingMelee.clear()
	target._boardingArchers.clear()
	target._boardingJavelins.clear()
	target._boardingMelee.clear()
	
	#Get my soldiers and enemy soldiers
	var items = my_new_fighters.filter(func(guy): return guy is Character.Marine.Soldier)
	for item in items:
		ship._boardingMelee.append(item)
		my_new_fighters.erase(item)
	items = enemy_new_fighters.filter(func(guy): return guy is Character.Marine.Soldier)
	for item in items:
		target._boardingMelee.append(item)
		my_new_fighters.erase(item)
	
	#See if I need to add Auxiliary to either side
	if ship._boardingMelee.size() < target._boardingMelee.size():
		for item in my_new_fighters:
			ship._boardingMelee.append(item)
			my_new_fighters.erase(item)
			if ship._boardingMelee.size() == target._boardingMelee.size(): break
	if target._boardingMelee.size() < ship._boardingMelee.size():
		for item in enemy_new_fighters:
			target._boardingMelee.append(item)
			enemy_new_fighters.erase(item)
			if target._boardingMelee.size() == ship._boardingMelee.size(): break
	
	#Keep adding to Melee until either X_new_fighters == 0
	while true:
		ship._boardingMelee.append(my_new_fighters[0])
		my_new_fighters.erase(my_new_fighters[0])
		target._boardingMelee.append(enemy_new_fighters[0])
		enemy_new_fighters.erase(enemy_new_fighters[0])
		if my_new_fighters.size() == 0 or enemy_new_fighters.size() == 0: break
		
	#Get Archers that are left
	if ship._boardingCounter == 0:
		ship._boardingArchers.append_array(my_new_fighters.filter(func(guy): return guy is Character.Marine.Archer))
	if target._boardingCounter == 0:
		target._boardingArchers.append_array(enemy_new_fighters.filter(func(guy): return guy is Character.Marine.Archer))
		
	#Get Javelins that are left
	ship._boardingJavelins.append_array(my_new_fighters.filter(func(guy): return guy is Character.Marine.Javelineer))
	target._boardingJavelins.append_array(enemy_new_fighters.filter(func(guy): return guy is Character.Marine.Javelineer))
	print("Boarding Determination Done")


#region Archery
func doBoardingArchery(ship):
	#Call two threads so that each ship is doing firing at the same time
	var thread1: Thread = Thread.new()
	thread1.start(boardingArcherFire.bind(ship))
	var thread2: Thread = Thread.new()
	thread2.start(boardingArcherFire.bind(ship._boardingTarget))
	#Wait for each to finish before continuing
	if thread1.is_started():
		thread1.wait_to_finish()
	if thread2.is_started():
		thread2.wait_to_finish()

func boardingArcherFire(ship):
	print("Attempting BAF")
	var target = ship._boardingTarget
	ship._boardingPrepped = true
	for i in ship._boardingArchers.size():
		if randi_range(1, 6) == 6:
			Charts.singleCrewCasualty(target)
		ship._boardingCounter += 1
#endregion

#region Javeline
func doBoardingJaveline(ship):
	#Call two threads so that each ship is doing firing at the same time
	var thread1: Thread = Thread.new()
	thread1.start(boardingJavelineFire.bind(ship))
	var thread2: Thread = Thread.new()
	thread2.start(boardingJavelineFire.bind(ship._boardingTarget))
	#Wait for each to finish before continuing
	if thread1.is_started():
		thread1.wait_to_finish()
	if thread2.is_started():
		thread2.wait_to_finish()

func boardingJavelineFire(ship):
	print("Attempting BJF")
	var target = ship._boardingTarget
	ship._boardingPrepped = true
	for i in ship._boardingJavelins.size():
		if randi_range(1, 6) >= 5:
			Charts.singleCrewCasualty(target)
		ship._boardingCounter += 1
#endregion

#region Melee
func preBoardingMelee(ship):
	var target = ship._boardingTarget
	var myRoll
	var targetRoll
	if target:
		var total = returnLarget(ship._boardingMelee.size(), target._boardingMelee.size())
		for num in total:
			#If Ship Melee is Soldier
			if ship._boardingMelee[num] is Character.Marine.Soldier:
				myRoll = randi_range(1, 6)
				#If Soldier v Soldier
				if target._boardingMelee[num] is Character.Marine.Soldier:
					targetRoll = randi_range(1, 6)
					#Ship Hits
					if myRoll == 6:
						#If both hit then skip
						if targetRoll == 6:
							continue
						#Ship hits only
						boardingMelee(ship)
					
					#Target Hits Only
					elif targetRoll == 6:
						boardingMelee(ship)
					
				#Else Soldier v Aux
				else:
					targetRoll = randi_range(1, 8)
					#Ship Hits
					if myRoll >= 5:
						#If both hit then skip
						if targetRoll == 8:
							continue
						#Ship hits only
						boardingMelee(ship)
					
					#Target Hits Only
					elif targetRoll == 8:
						boardingMelee(ship)
			
			#Else Ship Melee is Aux
			else:
				myRoll = randi_range(1, 8)
				#If Aux v Soldier
				if target._boardingMelee[num] is Character.Marine.Soldier:
					targetRoll = randi_range(1, 6)
					#Ship Hits
					if myRoll == 8:
						#If both hit then skip
						if targetRoll >= 5:
							continue
						#Ship hits only
						boardingMelee(ship)
					
					#Target Hits Only
					elif targetRoll >= 5:
						boardingMelee(ship)
				
				#Else Aux v Aux
				else:
					targetRoll = randi_range(1, 8)
					#Ship Hits
					if myRoll >= 7:
						#If both hit then skip
						if targetRoll >= 7:
							continue
						#Ship hits only
						boardingMelee(ship)
					
					#Target Hits Only
					elif targetRoll >= 7:
						boardingMelee(ship)

func boardingMelee(ship):
	var target = ship._boardingTarget
	Charts.multiCrewCasualty(target)
	
	#Check if ship died in order to give attacking ship a kill point so that if they are...
	#...ramming on a terrain tile they can be put back in the water
	if Global.isShipDead(ship.target) and ship._tile.biome != "Ocean":
		Global.baRemoveShip(target)
		for n in WorldMap.get_tile_neighbors(ship._tile):
			if n.biome == "Ocean" and n.occupier.size() == 0:
				ship.place_unit(n.position, n)
				ship.unstranded()
				break

func boardingWithdrawing(ship):
	var target = ship._boardingTarget
	## Temp rng for player input, 1 is withdrawal
	var roll = randi_range(1, 2)
	#Ship Withdrawls
	if roll == 1:
		#Get available tiles that are not occupied by a ship and move there
		var avialableTiles = find_reachable_tiles(ship._tile, 1, ship)
		if avialableTiles.size() > 0:
			#Remove ship from tile occupier list
			var jndex = ship._tile.occupier.find(ship)
			ship._tile.occupier.remove_at(jndex)
			
			#Move Ship to new Tile
			var index = randi_range(1, avialableTiles.size()) - 1
			ship._tile = avialableTiles[index]
			ship._tile.occupier.append(ship)
			ship.position = ship._tile.position
			ship.occupied_tile = ship._tile
			
			#Rest Ship Varuiables
			ship._enemyTarget = null
			ship._boardingTarget = null
			ship._inBoarding = false
			ship._inCollision = false
			ship._boardingCounter = 0
			ship._boardingPrepped = false
#endregion

func ship_area_entered(self_ship: Ship, target: Ship):
	self_ship._boardingTarget = target
	target._boardingTarget = self_ship
	if true:
		#Get Ship that goes first
		var firstShip: Ship; var secondShip: Ship
		var result = sort_initiative(self_ship, target)
		if result:
			firstShip = self_ship; secondShip = target
		else:
			firstShip = target; secondShip = self_ship
		var direction = 0
		var firstY = snapped(firstShip.rotation_degrees.y, 10)
		var secondY = snapped(secondShip.rotation_degrees.y, 10)
		
		#Check if Ships are Beak to Beak
		if ceil(fposmod(firstY + 180, 360)) == secondY or ceil(fposmod(firstY - 180, 360)) == secondY:
			print("Beak to Beak")
			## Temp auto rng, replace!!
			match randi_range(1, 3):
				#Shear Opponent Oars
				1:
					Charts.shear(self_ship, target, firstShip, secondShip)
				
				#Attempt to Ram
				2:
					if firstShip._speed > 0:
						print("Attempt to Ram")
						firstShip._ramAction = 1
						secondShip._ramAction = randi_range(1, 2)
						Charts.rammingResults(firstShip, secondShip)
				
				#Attempt to Avoid
				3:
					print("Attenp to Avoid")
					firstShip._ramAction = 2
					secondShip._ramAction = randi_range(1, 2)
		
		
		#Check Beak to front 1/4ths
		elif firstY == fposmod(secondY + 60 ,360) or firstY == fposmod(secondY - 60 ,360):
			print("Beak to 1/4th")
			firstShip._ramAction = randi_range(1, 2)
			secondShip._ramAction = randi_range(1, 2)
			if firstShip._ramAction == 1:
				Charts.rammingResults(firstShip, secondShip)
			if secondShip._ramAction == 1:
				Charts.rammingResults(secondShip, firstShip)
		
		#Check if Ships are in Front 1/4th to each other
		#Right to left, Left to Right
		elif fposmod(firstY - 60, 360) == fposmod(secondY + 60 ,360) or fposmod(firstY + 60, 360) == fposmod(secondY - 60 ,360):
			#Ship One declares Ram or Avoid, then Ship Two
			#TEMP, ask players
			print("Front 1/4th")
			firstShip._ramAction = randi_range(1, 2)
			secondShip._ramAction = randi_range(1, 2)
			if firstShip._ramAction == 1:
				Charts.rammingResults(firstShip, secondShip)
			if secondShip._ramAction == 1:
				Charts.rammingResults(secondShip, firstShip)
		
		#Because of the nature of how 360 dge works I cannnot simply do a range check from back left to back right
		#I have to go to each ships back sections
		#Because ceil may round up to a 1 and not down to a 0 I have to have a slight tange on every side check
		
		#If Ship 1 is at Ship 2s back left
		elif firstY == fposmod(secondY - 60 ,360):
			direction = 1
		#If Ship 1 is at Ship 2s back right
		elif firstY == fposmod(secondY + 60 ,360):
			direction = 1
		#If Ship 1 is at Ships 2s back
		elif firstY == secondY:
			direction = 1
		
		#If Ship 2 is at Ship 1s back left
		elif secondY == fposmod(firstY - 60 ,360):
			direction = 2
		#If Ship 2 is at Ship 1s back right
		elif secondY == fposmod(firstY + 60 ,360):
			direction = 2
		#If Ship 2 is at Ships 1s back
		elif secondY == firstY:
			direction = 2
		
		
		#If ship 1 is between ship 2s back left and back right
		if direction == 1:
			print("D1")
			#Only the ship facing the other can declare Ram or Avoid.
			#Other ship awlays declares avoid action
			firstShip._ramAction = randi_range(1, 2)
			secondShip._ramAction = 2
			if firstShip._ramAction == 1:
				Charts.rammingResults(firstShip, secondShip)
		
		#If ship 2 is between ship 1s back left and back right
		if direction == 2:
			print("D2")
			#Only the ship facing the other can declare Ram or Avoid.
			#Other ship always declares avoid action
			secondShip._ramAction = randi_range(1, 2)
			firstShip._ramAction = 2
			if secondShip._ramAction == 1:
				Charts.rammingResults(secondShip, firstShip)
		
		#Clean up
		self_ship._inCollision = true
		target._inCollision = true
		
		#Remove Dead Ships that has no Aux or Soldiers
		var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
		for j in range(ships.size() - 1, -1, -1):
			if ships[j]._fighters.size() == 0 or ships[j]._flotationHits == 0:
				Global.baRemoveShip(ships[j])
				print("Ship removed")
	
		print(firstShip._speed, " | ", secondShip._speed)


func find_reachable_tiles(start : Tile, movement_range: int, origin_ship) -> Array[Node3D]:
	var queue = []
	var visited = []
	var reachable_tiles : Array[Node3D]

	# Start from the initial tile
	queue.append({"tile": start, "distance": 0})
	visited.append(Vector2(start.pos_data.grid_position.x, start.pos_data.grid_position.y))

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_tile : Tile = current["tile"]
		var current_distance : int = current["distance"]
		
		if current_distance > movement_range:
			continue
		
		# Add the current tile to the reachable list
		reachable_tiles.append(current_tile)
		current_tile.range = current_distance

		var current_pos = current_tile.pos_data.grid_position
		
		if WorldMap.is_map_staggered:
			if current_pos.x % 2 == 0:
				neighbor_positions = WorldMap.NEIGHBOR_DIRECTIONS_EVEN
			else:
				neighbor_positions = WorldMap.NEIGHBOR_DIRECTIONS_ODD
		
		# Explore neighbors
		for direction in neighbor_positions:
			var neighbor_coords = Vector2(current_pos.x + int(direction.x), current_pos.y + int(direction.y))
			if not is_tile_valid(neighbor_coords) or visited.has(neighbor_coords):
				continue
			var neighbor_tile = WorldMap.map_as_dict[neighbor_coords]
			queue.append({"tile": neighbor_tile, "distance": current_distance + 1})
			visited.append(neighbor_coords)

	#Filer out tiles that have a ship on them
	var targetable_tiles : Array[Node3D]
	for tile in reachable_tiles:
		if tile != start and tile.occupier.size() == 0 and tile.range == movement_range:
			targetable_tiles.append(tile)
	
	return targetable_tiles


func is_tile_valid(coords : Vector2) -> bool:
	var valid = false
	if not WorldMap.map_as_dict.has(coords):
		push_warning("Tile not in map!")
		return false
	var tile = WorldMap.map_as_dict[coords]
	if tile and tile.mesh_data and tile.mesh_data.type == Tile.biome_type.Ocean:
		valid = true
	return valid


func sort_initiative(a: Ship, b: Ship) -> bool:
	#Set order of attack by checking speed, then ship type, deck crew size, then dice roll
	#Speed
	if a._speed > b._speed:
		return true
	elif a._speed < b._speed:
		return false
	
	#Type
	if a._type > b._type:
		return true
	elif a._type < b._type:
		return false
	
	#Deck Crew
	if a._deckCrew.size() > b._deckCrew.size():
		return true
	elif a._deckCrew.size() < b._deckCrew.size():
		return false
	
	#Dice
	var rollA; var rollB; var temp = true
	#Get Different Dice Values
	while temp:
		rollA = randi_range(1, 6)
		rollB = randi_range(1, 6)
		if rollA != rollB:
			temp = false
	#Exit
	if rollA > rollB:
		return true
	else:
		return false


func is_target_dead(ship: Ship, target: Ship):
	pass


func returnLarget(a, b):
	return a if a > b else b


func returnSmallest(a, b):
	return a if a < b else b
