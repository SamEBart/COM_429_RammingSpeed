extends Node

var map : Array[Tile]
var map_as_dict : Dictionary = {}
var is_map_staggered = false

## Shorthand for different layout/neighbor configurations depending on map-shape
const HEXAGONAL_NEIGHBOR_DIRECTIONS = [
	Vector2(1, 0),
	Vector2(1, -1),
	Vector2(0, -1), 
	Vector2(-1, 0),
	Vector2(-1, 1),
	Vector2(0, 1)
]
# Neighbor directions for even/odd rows
const NEIGHBOR_DIRECTIONS_EVEN = [
	Vector2(1, 0),   # Bottom-right
	Vector2(1, -1),  # Top-right
	Vector2(0, -1),  # Top
	Vector2(-1, -1), # Top-left
	Vector2(-1, 0),  # Bottom-left
	Vector2(0, 1)    # Bottom
]
const NEIGHBOR_DIRECTIONS_ODD = [
	Vector2(1, 0),   # Bottom-right
	Vector2(0, -1),  # Top-right
	Vector2(-1, 0),  # Top
	Vector2(-1, 1),  # Top-left
	Vector2(0, 1),   # Bottom-left
	Vector2(1, 1)    # Bottom
]
var neighbor_positions = HEXAGONAL_NEIGHBOR_DIRECTIONS

# Distances to neighbors assuming tile_size of 1
const NEIGHBOR_WORLD_OFFSET = [
	Vector3(0, 0, -1),        # Top
	Vector3(0.866, 0, -0.5),  # Top-right
	Vector3(0.866, 0, 0.5),   # Bottom-right
	Vector3(0, 0, 1),         # Bottom
	Vector3(-0.866, 0, 0.5),  # Bottom-left
	Vector3(-0.866, 0, -0.5)  # Top-left
]


func set_map(all_tiles):
	map = all_tiles
	for t in all_tiles:
		map_as_dict[Vector2(t.pos_data.grid_position.x, t.pos_data.grid_position.y)] = t


## Handy function for finding all neigbors of a tile
func get_tile_neighbors(tile : Tile) -> Array[Tile]:
	var neighbors : Array[Tile] = []
	if is_map_staggered:
		if tile.pos_data.grid_position.x % 2 == 0:
			neighbor_positions = NEIGHBOR_DIRECTIONS_EVEN
		else:
			neighbor_positions = NEIGHBOR_DIRECTIONS_ODD
			
	for direction in neighbor_positions:
		var neighbor_coords = Vector2(tile.pos_data.grid_position.x + int(direction.x), tile.pos_data.grid_position.y + int(direction.y)) 
		if neighbor_coords in map_as_dict:
			neighbors.append(map_as_dict[neighbor_coords])
	return neighbors

## Carter getting neighbors for terrain tiling because the above way was not starting in a constant spot!
const EVEN_COL_DIRS: Array[Vector2i] = [
	Vector2i(0, -1),  # North
	Vector2i(1, -1),  # North-East
	Vector2i(1, 0),   # South-East
	Vector2i(0, 1),   # South
	Vector2i(-1, 0),  # South-West
	Vector2i(-1, -1)  # North-West
]

const ODD_COL_DIRS: Array[Vector2i] = [
	Vector2i(0, -1),  # North
	Vector2i(1, 0),   # North-East
	Vector2i(1, 1),   # South-East
	Vector2i(0, 1),   # South
	Vector2i(-1, 1),  # South-West
	Vector2i(-1, 0)   # North-West
]
func get_tile_neighbors_02(tile: Tile) -> Array[Tile]:
	var neighbors : Array[Tile] = []
	if is_map_staggered:
		if tile.pos_data.grid_position.x & 1 == 1:
			neighbor_positions = ODD_COL_DIRS
		else:
			neighbor_positions = EVEN_COL_DIRS
			
	for direction in neighbor_positions:
		var neighbor_coords = Vector2(tile.pos_data.grid_position.x + int(direction.x), tile.pos_data.grid_position.y + int(direction.y)) 
		if neighbor_coords in map_as_dict:
			neighbors.append(map_as_dict[neighbor_coords])
	return neighbors
