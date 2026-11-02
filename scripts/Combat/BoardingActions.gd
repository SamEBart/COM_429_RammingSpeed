extends Node

var neighbor_positions = WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS

func determineFighting(ship: Ship):
	var target = ship._enemyTarget
	#Can't boarding action same team
	if ship._owner == target._owner:
		print("Boarding Target is same team!")
		return
	
	ship._boardingPrepped = true
	target._boardingPrepped = true
	#Get Correct Fighting Order from Fighters
	var class_priority = [Character.Marine.Soldier, Character.Marine.Javelineer, Character.Marine.Archer, Character.Engineer, Character.DeckCrew]
	
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
	thread2.start(boardingArcherFire.bind(ship._enemyTarget))
	#Wait for each to finish before continuing
	if thread1.is_started():
		thread1.wait_to_finish()
	if thread2.is_started():
		thread2.wait_to_finish()

func boardingArcherFire(ship):
	print("Attempting BAF")
	var target = ship._enemyTarget
	ship._boardingPrepped = true
	for i in ship._baordingArchers.size():
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
	thread2.start(boardingJavelineFire.bind(ship._enemyTarget))
	#Wait for each to finish before continuing
	if thread1.is_started():
		thread1.wait_to_finish()
	if thread2.is_started():
		thread2.wait_to_finish()

func boardingJavelineFire(ship):
	print("Attempting BJF")
	var target = ship._enemyTarget
	ship._boardingPrepped = true
	for i in ship._boardingJavelins.size():
		if randi_range(1, 6) >= 5:
			Charts.singleCrewCasualty(target)
		ship._boardingCounter += 1
#endregion

#region Melee
func preBoardingMelee(ship):
	var target = ship._enemyTarget
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
	var target = ship._enemyTarget
	Charts.multiCrewCasualty(target)

func boardingWithdrawing(ship):
	var target = ship._enemyTarget
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
			ship._inBoarding = false
			ship._inCollision = false
			ship._boardingCounter = 0
			ship._boardingPrepped = false
#endregion

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


func returnLarget(a, b):
	return a if a > b else b

func returnSmallest(a, b):
	return a if a < b else b
