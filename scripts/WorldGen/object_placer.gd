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
			spawn_on_tile(candidate, object_to_place, biome)
			
			#Temp rotation to "front"/"north"/"up"
			candidate.global_rotation_degrees = Vector3(0, 0, 0)
			
#			for n in WorldMap.get_tile_neighbors(candidate):
#				n.placeable = false
	print("placed " + str(placed_positions.size()) + " in " + str(current_index) + " attempts")

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
			spawn_on_tile(candidate, object, "Village")
#			for n in WorldMap.get_tile_neighbors(candidate):
#				n.placeable = false
	print("placed " + str(placed_positions.size()) + " in " + str(current_index) + " attempts")


# Spawn an object on a tile
func spawn_on_tile(tile : Tile, scene : PackedScene, biome: String):
	if not tile or not scene:
		push_warning("tile not found!")
		return

	var instance = scene.instantiate()
	add_child(instance)
	call_deferred("position_object", instance, tile.global_position)
	
	tile.biome = biome


func position_object(object : Node3D, target_location : Vector3):
	object.position = target_location
