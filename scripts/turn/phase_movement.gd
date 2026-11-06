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


## During Command, highlight the hex this order will step into.
## Speed -1 paints the hex behind the bow. Every other speed paints the hex in front.
static func command_preview(ship: Ship) -> Array[Node3D]:
	var shown: Array[Node3D] = []
	if ship.occupied_tile == null:
		return shown
	var facing := ship._facing
	if ship.get_overall_speed() < 0:
		facing += 3
	var ahead := _neighbor_tile(ship.occupied_tile, facing)
	if ahead and _is_sailable(ahead):
		shown.append(ahead)
	return shown


const _Log = preload("res://scripts/turn/game_log.gd")


static func _step(ship: Ship, phase: int, pass_index: int) -> bool:
	if ship._phase_move_stopped or ship.occupied_tile == null:
		return false
	var sharing := _other_ship_here(ship)
	if sharing != null:
		_stop_pair(ship, sharing)
		_Log.push("Phase %d: %s is sharing a hex with %s. Both stop for the rest of the turn." % [phase, ship.name, sharing.name])
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
		var blocked := _neighbor_tile(ship.occupied_tile, ship._facing if speed >= 0 else ship._facing + 3)
		if blocked and not _is_sailable(blocked):
			_Log.push("Phase %d: %s stayed. The next hex is land." % [phase, ship.name])
		else:
			_Log.push("Phase %d: %s stayed. The next hex is blocked." % [phase, ship.name])
		return false
	var already_there: Ship = null
	for occ in dest.occupier:
		if occ is Ship:
			already_there = occ
			break
	ship.place_unit(dest.position, dest)
	var verb := "forward"
	if speed < 0:
		verb = "backward"
	elif speed == 0:
		verb = "adrift"
	_Log.push("Phase %d: %s moved %s onto %s." % [phase, ship.name, verb, dest.biome])
	if already_there == null:
		return false
	_stop_pair(ship, already_there)
	_Log.push("Phase %d: %s and %s collided. Both stop for the rest of the turn." % [phase, ship.name, already_there.name])
	_call_boarding(ship, already_there)
	return true


static func _stop_pair(ship: Ship, other: Ship) -> void:
	ship._phase_move_stopped = true
	other._phase_move_stopped = true


static func _call_boarding(ship: Ship, other: Ship) -> void:
	ship._enemyTarget = other
	other._enemyTarget = ship
	_Log.push("%s calls BoardingActions.determineFighting on %s." % [ship.name, other.name])
	# Ramming is not written yet. Develop that function next to determineFighting in
	# BoardingActions.gd, and call it here before the boarding setup.
	BoardingActions.determineFighting(ship)


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


static func _is_sailable(tile: Tile) -> bool:
	return tile != null and tile.mesh_data != null and tile.mesh_data.type == Tile.biome_type.Ocean


static func _can_enter(tile: Tile) -> bool:
	if not _is_sailable(tile):
		return false
	return tile.occupier.size() < 2


static func _other_ship_here(ship: Ship) -> Ship:
	if ship.occupied_tile == null:
		return null
	for occ in ship.occupied_tile.occupier:
		if occ != ship and occ is Ship:
			return occ
	return null


## The odd-column neighbors in the same order as WorldMap.NEIGHBOR_DIRECTIONS_EVEN
## (SE, NE, N, NW, SW, S), so a ship's facing index points the same way on every column.
## Odd columns sit half a hex lower, so their side neighbors are one row further down.
const ODD_COLUMN_DIRECTIONS := [
	Vector2(1, 1),
	Vector2(1, 0),
	Vector2(0, -1),
	Vector2(-1, 0),
	Vector2(-1, 1),
	Vector2(0, 1),
]


static func _dirs_for(tile: Tile) -> Array:
	if WorldMap.is_map_staggered:
		if int(tile.pos_data.grid_position.x) % 2 == 0:
			return WorldMap.NEIGHBOR_DIRECTIONS_EVEN
		return ODD_COLUMN_DIRECTIONS
	return WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS
