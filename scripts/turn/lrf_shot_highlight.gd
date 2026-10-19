extends Node

const _Log = preload("res://scripts/turn/game_log.gd")


func _ready() -> void:
	add_to_group("lrf_shot_highlight")


func show_for(unit: Node) -> void:
	if Global._action != 1 or not TurnController.use_phase_movement:
		return
	var shooter: Node = unit
	if Global._lastShipClicked != null and is_instance_valid(Global._lastShipClicked):
		shooter = Global._lastShipClicked
	if shooter == null or not is_instance_valid(shooter) or shooter.occupied_tile == null:
		return
	var interaction = _interaction()
	if interaction == null:
		return
	interaction.p_finder.highlight_tile(_tiles_in_range(shooter.occupied_tile, interaction))


func _input(event: InputEvent) -> void:
	if Global._action != 1 or not TurnController.use_phase_movement:
		return
	if event is not InputEventMouseButton or not event.pressed or not event.is_action_pressed("RightClick"):
		return
	var interaction = _interaction()
	if interaction == null or interaction._pointer_is_over_menu():
		return
	var shooter = Global._lastShipClicked
	if shooter == null or not is_instance_valid(shooter) or not shooter._owner._shipClicked:
		return
	var mouse: Vector2 = interaction.get_viewport().get_mouse_position()
	var origin: Vector3 = interaction.main_camera.project_ray_origin(mouse)
	var aim: Vector3 = interaction.main_camera.project_ray_normal(mouse)
	var hit = interaction.raycast_at_mouse(origin, origin + aim * 1000.0)
	if hit == null or not hit.is_in_group("units") or hit._boardingCounter != 0:
		return
	if hit._owner == shooter._owner:
		return
	if shooter.occupied_tile and _tile_in_range(shooter.occupied_tile, hit.occupied_tile, interaction):
		return
	_Log.push("%s is too far away to do long range fire." % hit.name)


func _tiles_in_range(start: Tile, interaction) -> Array[Node3D]:
	var minimum := 1
	var maximum := 1
	if Global._subAction == 1:
		maximum = 4
	if Global._subAction == 2:
		minimum = 2
		maximum = 6
	var found: Array[Node3D] = []
	var queue: Array[Dictionary] = [{"tile": start, "distance": 0}]
	var visited: Array[Vector2] = [Vector2(start.pos_data.grid_position.x, start.pos_data.grid_position.y)]
	var neighbors: Array = WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS
	while queue.size() > 0:
		var current: Dictionary = queue.pop_front()
		var current_tile: Tile = current["tile"]
		var current_distance: int = int(current["distance"])
		if current_distance > maximum:
			continue
		if current_tile != start and current_distance >= minimum:
			found.append(current_tile)
		var current_pos = current_tile.pos_data.grid_position
		if WorldMap.is_map_staggered:
			if int(current_pos.x) % 2 == 0:
				neighbors = WorldMap.NEIGHBOR_DIRECTIONS_EVEN
			else:
				neighbors = WorldMap.NEIGHBOR_DIRECTIONS_ODD
		for direction in neighbors:
			var neighbor_coords := Vector2(current_pos.x + int(direction.x), current_pos.y + int(direction.y))
			if visited.has(neighbor_coords) or not interaction.p_finder.is_tile_valid_range(neighbor_coords):
				continue
			visited.append(neighbor_coords)
			queue.append({"tile": WorldMap.map_as_dict[neighbor_coords], "distance": current_distance + 1})
	return found


func _tile_in_range(start: Tile, tile: Tile, interaction) -> bool:
	if start == null or tile == null:
		return false
	for candidate in _tiles_in_range(start, interaction):
		if candidate == tile:
			return true
	return false


func _interaction():
	return get_tree().get_first_node_in_group("interaction")
