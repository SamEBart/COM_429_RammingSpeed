extends Node
class_name Pathfinder

var neighbor_positions = WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS
@export var highlight_marker : PackedScene
var markers = []


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

	#Filer out tiles that have a ship that is on the origin ships team
	var targetable_tiles : Array[Node3D]
	for tile in reachable_tiles:
		#Limiting Ships per tile at 2 for now and hopefull forever
		if tile != start and tile.occupier.size() < 2:
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


func clear_highlight():
	if markers and markers.size() > 0:
		for m in markers:
			m.visible = false


func highlight_tile(selected_nodes: Array[Node3D]):
	#Ensure correct marker count
	var marker_diff = selected_nodes.size() - markers.size()
	for m in range(marker_diff):
		var new_marker = highlight_marker.instantiate()
		add_child(new_marker)
		markers.append(new_marker)
	clear_highlight() # turn all markers invisible
	# Iterate over selected tiles
	for i in range(selected_nodes.size()):
		var marker = markers[i]
		var tile : Tile = selected_nodes[i]
		marker.position = tile.position
		marker.visible = true


func find_targetable_units(start : Tile, min_range: int, max_range: int, origin_ship) -> Array[Node3D]:
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
		
		if current_distance > max_range:
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
			if not is_tile_valid_range(neighbor_coords) or visited.has(neighbor_coords):
				continue
			var neighbor_tile = WorldMap.map_as_dict[neighbor_coords]
			queue.append({"tile": neighbor_tile, "distance": current_distance + 1})
			visited.append(neighbor_coords)
	
	#Get tile that are occupied and not own team
	var targetable_tiles : Array[Node3D]
	for tile in reachable_tiles:
		for i in tile.occupier.size():
			if tile.occupier.size() > 0 and tile != start and tile.occupier[i]._owner != origin_ship._owner:
				#Check if tiles are within range
				if tile.range <= max_range and tile.range >= min_range:
					targetable_tiles.append(tile)
	
	#Returns tiles that a ship that is withing range specifications, not on the same team, and not self
	return targetable_tiles


func is_tile_valid_range(coords : Vector2) -> bool:
	var valid = false
	if not WorldMap.map_as_dict.has(coords):
		push_warning("Tile not in map!")
		return false
	var tile = WorldMap.map_as_dict[coords]
	if tile and tile.mesh_data and tile.mesh_data.type == Tile.biome_type.Ocean:
		valid = true
	return valid
