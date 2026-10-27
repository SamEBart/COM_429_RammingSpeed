extends Node3D
## During Command, marks every hex the local player's ships will sail through this turn.
## A small dot per hex, a bigger white dot on the last hex, and a red dot where another ship already sits.
## Drifting ships (speed 0) move in a random direction, so they get no path.

const PATH_COLOR := Color(0.4, 0.8, 1.0, 0.85)
const END_COLOR := Color(0.0, 0.87, 0.221, 0.949)
const BLOCKED_COLOR := Color(1.0, 0.3, 0.25, 0.95)
const MARK_HEIGHT := 0.35


func _ready() -> void:
	add_to_group("turn_preview")
	TurnController.phase_changed.connect(func(_phase, _step, _turn): refresh())
	TurnController.mode_changed.connect(func(_test_mode): refresh())
	refresh()


## Clears the old marks and draws a fresh path for each of the local player's ships.
func refresh() -> void:
	for child in get_children():
		child.queue_free()
	if TurnController.phase != TurnController.Phase.COMMAND:
		return
	for node in get_tree().get_nodes_in_group("ships"):
		if node is Ship and node.occupied_tile != null and TurnController.is_local_ship(node):
			_draw_path(node)


## Walks the ship forward (or backward when backing) one hex per move it gets this turn.
## Stops at land or the map edge, and at the first hex that already holds a ship.
func _draw_path(ship: Ship) -> void:
	var speed := ship.get_overall_speed()
	if speed == 0:
		return
	var moves := 0
	for phase in range(1, PhaseSpeedChart.PHASE_COUNT + 1):
		moves += PhaseSpeedChart.hex_count(speed, phase)
	var facing := ship._facing
	if speed < 0:
		facing += 3
	var tile: Tile = ship.occupied_tile
	for move in moves:
		var next := PhaseMovement._neighbor_tile(tile, facing)
		if next == null or not PhaseMovement._is_sailable(next):
			return
		tile = next
		var is_last := move == moves - 1
		if _holds_ship(tile):
			_mark(tile, BLOCKED_COLOR, true)
		else:
			_mark(tile, END_COLOR if is_last else PATH_COLOR, is_last)


func _holds_ship(tile: Tile) -> bool:
	for occupant in tile.occupier:
		if occupant is Ship:
			return true
	return false


func _mark(tile: Tile, color: Color, big: bool) -> void:
	var dot := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	var radius := 0.22 if big else 0.13
	mesh.radius = radius
	mesh.height = radius * 2.0
	dot.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	dot.material_override = material
	add_child(dot)
	dot.global_position = tile.global_position + Vector3.UP * MARK_HEIGHT
