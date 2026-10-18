class_name PhaseMovement
extends RefCounted
## Steps ships one hex at a time from the phase-speed chart.
## Every ship that moves this phase takes its first hex, then any ship with a second hex takes that one.


static func apply(tree: SceneTree, phase: int) -> bool:
	var entered_occupied := false
	for pass_index in PhaseSpeedChart.MAX_HEXES_PER_PHASE:
		for node in tree.get_nodes_in_group("ships"):
			if node is Ship and _step(node, phase, pass_index):
				entered_occupied = true
	return entered_occupied


## During Command, highlight only the hex the ship is facing.
static func command_preview(ship: Ship) -> Array[Node3D]:
	var shown: Array[Node3D] = []
	if ship.occupied_tile == null:
		return shown
	var ahead := _neighbor_tile(ship.occupied_tile, ship._facing)
	if ahead:
		shown.append(ahead)
	return shown


## Tiles to highlight for the selected ship. Drift shows every open neighbor on phase 4.
static func preview_tiles(ship: Ship, phase: int, in_execution: bool) -> Array[Node3D]:
	var shown: Array[Node3D] = []
	if ship.occupied_tile == null:
		return shown
	var speed := ship.get_overall_speed()
	if speed == 0 and in_execution and phase == PhaseSpeedChart.DRIFT_PHASE:
		for tile in _open_neighbors(ship.occupied_tile):
			shown.append(tile)
		return shown
	if in_execution and PhaseSpeedChart.hex_count(speed, phase) == 0:
		return shown
	var dest := _step_tile(ship, speed)
	if dest:
		shown.append(dest)
	return shown


const _Log = preload("res://scripts/turn/game_log.gd")


static func _step(ship: Ship, phase: int, pass_index: int) -> bool:
	if ship._phase_move_stopped or ship.occupied_tile == null:
		return false
	if _shares_hex_with_enemy(ship):
		ship._phase_move_stopped = true
		_Log.push("Phase %d: %s is already in contact. Movement stops." % [phase, ship.name])
		return false
	var speed := ship.get_overall_speed()
	if pass_index >= PhaseSpeedChart.hex_count(speed, phase):
		return false
	var dest: Tile = null
	if speed == 0:
		var choices := _open_neighbors(ship.occupied_tile)
		if choices.size() > 0:
			dest = choices[randi() % choices.size()]
	else:
		dest = _step_tile(ship, speed)
	if dest == null:
		_Log.push("Phase %d: %s stayed. The next hex is blocked." % [phase, ship.name])
		return false
	var entered_occupied := dest.occupier.size() > 0
	ship.place_unit(dest.position, dest)
	var verb := "forward"
	if speed < 0:
		verb = "backward"
	elif speed == 0:
		verb = "adrift"
	_Log.push("Phase %d: %s moved %s onto %s." % [phase, ship.name, verb, dest.biome])
	if entered_occupied:
		ship._phase_move_stopped = true
		_Log.push("Phase %d: %s entered an occupied hex. Movement stops for the turn." % [phase, ship.name])
		return true
	return false


static func _step_tile(ship: Ship, speed: int) -> Tile:
	var facing := ship._facing
	if speed < 0:
		facing += 3
	return _tile_in_direction(ship.occupied_tile, facing)


## Flat world step from this tile toward the facing hex. Used to aim the hull.
static func facing_world_delta(origin: Tile, facing: int) -> Vector3:
	var neighbor := _neighbor_tile(origin, facing)
	if neighbor:
		var delta := neighbor.position - origin.position
		delta.y = 0.0
		return delta
	var dirs := _dirs_for(origin)
	var offset: Vector2 = dirs[posmod(facing, dirs.size())]
	var span := 0.0
	for i in dirs.size():
		var sample: Tile = _neighbor_tile(origin, i)
		if sample == null:
			continue
		var sample_delta := sample.position - origin.position
		sample_delta.y = 0.0
		span = sample_delta.length()
		break
	if span <= 0.0:
		return Vector3.ZERO
	return _grid_to_world_delta(origin, offset, span)


static func _grid_to_world_delta(origin: Tile, offset: Vector2, neighbor_span: float) -> Vector3:
	var spacing := neighbor_span / sqrt(3.0)
	var column_step := float(offset.x)
	var row_step := float(offset.y)
	var sqrt3 := sqrt(3.0)
	if WorldMap.is_map_staggered:
		var column := int(origin.pos_data.grid_position.x)
		var next_column := column + int(offset.x)
		var z_step := row_step * sqrt3 * spacing
		z_step += float(posmod(next_column, 2) - posmod(column, 2)) * sqrt3 * 0.5 * spacing
		return Vector3(1.5 * column_step * spacing, 0.0, z_step)
	return Vector3(1.5 * column_step * spacing, 0.0, sqrt3 * (row_step + column_step * 0.5) * spacing)


static func _neighbor_tile(origin: Tile, facing: int) -> Tile:
	var dirs := _dirs_for(origin)
	var offset: Vector2 = dirs[posmod(facing, dirs.size())]
	var coords := Vector2(
		origin.pos_data.grid_position.x + int(offset.x),
		origin.pos_data.grid_position.y + int(offset.y)
	)
	if not WorldMap.map_as_dict.has(coords):
		return null
	return WorldMap.map_as_dict[coords]


static func _tile_in_direction(origin: Tile, facing: int) -> Tile:
	var tile := _neighbor_tile(origin, facing)
	if tile == null or not _can_enter(tile):
		return null
	return tile


static func _open_neighbors(origin: Tile) -> Array[Tile]:
	var open: Array[Tile] = []
	var dirs := _dirs_for(origin)
	for facing in dirs.size():
		var tile := _tile_in_direction(origin, facing)
		if tile:
			open.append(tile)
	return open


static func _can_enter(tile: Tile) -> bool:
	if tile.mesh_data == null or tile.mesh_data.type == Tile.biome_type.Ocean:
		return false
	return tile.occupier.size() < 2


static func _shares_hex_with_enemy(ship: Ship) -> bool:
	if ship.occupied_tile == null:
		return false
	for occ in ship.occupied_tile.occupier:
		if occ == ship or occ is not Ship:
			continue
		if occ._owner != ship._owner:
			return true
	return false


static func _dirs_for(tile: Tile) -> Array:
	if WorldMap.is_map_staggered:
		if int(tile.pos_data.grid_position.x) % 2 == 0:
			return WorldMap.NEIGHBOR_DIRECTIONS_EVEN
		return WorldMap.NEIGHBOR_DIRECTIONS_ODD
	return WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS
