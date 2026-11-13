extends Node
class_name ObjectPlacer

func place_terrain(tiles: Array[Tile], spacing: int, object_to_place: PackedScene, biome: String):
	var tiles_copy = tiles.duplicate(true) #copy tiles and leave original unaffected
	var placed_positions = []
	var current_index = 0	
	tiles_copy.shuffle()
	
	while current_index < tiles_copy.size():
		# Select random tile from array
		var candidate : Tile = tiles_copy[current_index]
		current_index += 1
		
		if not candidate.placeable:
			continue
		var valid = true
		
		# check against previous villages
		for previous : Vector2 in placed_positions:
			var c_diff = abs(previous.x - candidate.pos_data.grid_position.x)
			var r_diff = abs(previous.y - candidate.pos_data.grid_position.y)
			var delta = abs((previous.x + previous.y) - (candidate.pos_data.grid_position.x + candidate.pos_data.grid_position.y))
			var ring_distance = max(c_diff, r_diff, delta)
			if ring_distance <= spacing:
				valid = false
				break
				
		if valid:
			placed_positions.append(Vector2(candidate.pos_data.grid_position.x, candidate.pos_data.grid_position.y))
			determine_placeability(candidate, object_to_place, biome)
			
#			for n in WorldMap.get_tile_neighbors(candidate):
#				n.placeable = false
	print("placed " + str(placed_positions.size()) + " in " + str(current_index) + " attempts")


func determine_placeability(tile : Tile, scene : PackedScene, biome: String):
	#Get random orientation and set base tile rotation
	var rotation = randi_range(0, 5)
	
	#Since some terrain tiles span multiple hexes check to see if those hexes are empty
	if biome != "Beach":
		#Put tiles neighbors into an array
		var neighbs = WorldMap.get_tile_neighbors_02(tile)
		var new_neighbs = []
		
		#Reverse said array to line up with terrain rotation
			#Origin tile and the Outer tile(s) are off by 3 values between arrays.
			#So the Origin tile arrays back end is the Outer arrays start. Both go counterclockwise
		for n in range(neighbs.size() -1, -1, -1):
			new_neighbs.append(neighbs[n])
		
		#If Making a Rock
		if biome == "Rock":
			if new_neighbs[rotation].biome == "Ocean":
				spawn_terrain_tile(tile, scene, biome, rotation * 60)
		
		#If Making an Island
		if biome == "Island":
			#Set the back of the front of the island to new biome
				#An Island tile is 1x2 so the tile behind it needs to be an island tile as well.
				#Make sure terrain doe snot overlap with other terrain.
			if new_neighbs[rotation].biome == "Ocean":
				new_neighbs[rotation].biome = biome
				new_neighbs[rotation].placeable = false
				spawn_terrain_tile(tile, scene, biome, rotation * 60)
		
		#If Making a Mountain
		elif biome == "Big Rock":
			#Set the back of the front of the island to new biome
				#An Island tile is 1x2 so the tile behind it needs to be an island tile as well.
				#Make sure terrain doe snot overlap with other terrain.
			if new_neighbs[rotation].biome == "Ocean" and new_neighbs[(rotation + 1) % 6].biome == "Ocean":
				new_neighbs[rotation].biome = biome
				new_neighbs[rotation].placeable = false
				new_neighbs[(rotation + 1) % 6].biome = biome
				new_neighbs[(rotation + 1) % 6].placeable = false
				spawn_terrain_tile(tile, scene, biome, rotation * 60)
	
	#If Making a Beach
	else:
		spawn_terrain_tile(tile, scene, biome, rotation * 60)

# Spawn an object on a tile
func spawn_terrain_tile(tile: Tile, scene: PackedScene, biome: String, rotation: int):
	if not tile or not scene:
		push_warning("tile not found!")
		return

	var instance = scene.instantiate()
	add_child(instance)
	call_deferred("position_object", instance, tile.global_position)
	
	#Make Islands face random rotation
	instance.global_rotation_degrees = Vector3(0, rotation, 0)
	
	tile.biome = biome
	tile.placeable = false


func place_villages(tiles : Array[Tile], spacing : int, object: PackedScene):
	var tiles_copy = tiles.duplicate(true) #copy tiles and leave original unaffected
	var placed_positions = []
	var current_index = 0	
	tiles_copy.shuffle()
	
	while current_index < tiles_copy.size():
		# Select random tile from array
		var candidate : Tile = tiles_copy[current_index]
		current_index += 1
		
		if not candidate.placeable:
			continue
		var valid = true
		
		# check against previous villages
		for previous : Vector2 in placed_positions:
			var c_diff = abs(previous.x - candidate.pos_data.grid_position.x)
			var r_diff = abs(previous.y - candidate.pos_data.grid_position.y)
			var delta = abs((previous.x + previous.y) - (candidate.pos_data.grid_position.x + candidate.pos_data.grid_position.y))
			var ring_distance = max(c_diff, r_diff, delta)
			if ring_distance <= spacing:
				valid = false
				break
				
		if valid and candidate.biome != "Village":
			placed_positions.append(Vector2(candidate.pos_data.grid_position.x, candidate.pos_data.grid_position.y))
			spawn_on_tile(candidate, object)
#			for n in WorldMap.get_tile_neighbors(candidate):
#				n.placeable = false
	print("placed " + str(placed_positions.size()) + " in " + str(current_index) + " attempts")


# Spawn an object on a tile
func spawn_on_tile(tile : Tile, scene : PackedScene):
	if not tile or not scene:
		push_warning("tile not found!")
		return

	var instance = scene.instantiate()
	add_child(instance)
	call_deferred("position_object", instance, tile.global_position)


func position_object(object : Node3D, target_location : Vector3):
	object.position = target_location
