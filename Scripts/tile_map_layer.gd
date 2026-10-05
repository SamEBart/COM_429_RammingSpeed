extends TileMapLayer

## How to keep track of currently hightlighted or selectd hex cell
var target_cell: Vector2i = Vector2i.ZERO

func _ready() -> void:
	# Ensure processing is enabled for mouse updates
	set_process(true)
	

func _process(_delta: float) -> void:
	# 1. Fetch global mouse position
	var mouse_pos = get_global_mouse_position()
	
	# 2. Automatically convert pixel/world positions into the corresponding hex map coordinates
	var current_cell: Vector2i = local_to_map(to_local(mouse_pos))
	
	# 3. Detect when the mouse enters a new hex cell
	if current_cell != target_cell:
		target_cell = current_cell
		
		# Optional: Convert map coordinate back into the exact pixel center of the hexagon
		var hex_center_pixel: Vector2i = map_to_local(target_cell)

## Example: Get all 6 immediate neighbors surrounding a specific hex cell
func get_hex_neighbors(cell: Vector2i) -> Array[Vector2i]:
	# 1. Godot 4 native function calculates neighbors automatically based on your TileSet configuration
	var neighbors: Array[Vector2i] = []
	
	# 2. Hexagon grids feature 6 structural directions (numbered 0 through 5 internally)
	for i in range(6):
		var neighbor_cords = get_neighbor_cell(cell, i as TileSet.CellNeighbor)
		neighbors.append(neighbor_cords)
		
	return neighbors

## Example: Safely place a tile programmatically onto the hex grid
func set_hex_tile(cell: Vector2i, source_id: int, atlas_cords: Vector2i) -> void:
	# source_id refers to your TileSet ID (usually 0 for the first texture map)
	set_cell(cell, source_id, atlas_cords)
