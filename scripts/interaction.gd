extends Node3D

const _Log = preload("res://scripts/turn/game_log.gd")

@export var tile_cursor_scene : PackedScene
@export var unit_cursor_scene : PackedScene
@export var main_camera : Camera3D
@export var p_finder : Pathfinder
var selected_tile : Node3D
var selected_unit : Unit
var unit_moves : Array[Node3D]
# Cursors
var tile_cursor : Node3D
var unit_cursor : Node3D


func _ready() -> void:
	add_to_group("interaction")
	if not tile_cursor or tile_cursor == null:
		tile_cursor = tile_cursor_scene.instantiate()
		add_child(tile_cursor)
	if not unit_cursor:
		unit_cursor = unit_cursor_scene.instantiate()
		add_child(unit_cursor)
	deselect()
	TurnController.phase_changed.connect(_on_phase_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# A click inside the phase panel or the ship stats panel is a menu click.
		if _pointer_is_over_menu():
			return
		var mouse_pos = get_viewport().get_mouse_position()
		var origin = main_camera.project_ray_origin(mouse_pos)
		var dir = main_camera.project_ray_normal(mouse_pos)
		var end = origin + dir * 1000
		var hit_object = raycast_at_mouse(origin, end)
		if not hit_object:
			return
		if not TurnController.use_phase_movement:
			if Input.is_action_just_pressed("Click"):
				attempt_select(hit_object)
			elif Input.is_action_just_pressed("RightClick"):
				attempt_move_unit(hit_object)
			return
		if Input.is_action_just_pressed("Click") and hit_object.is_in_group("units"):
			var shooter_locked := Global._action == 1 and Global._lastShipClicked != null
			if not shooter_locked:
				get_tree().call_group("ship_stats", "show_ship", hit_object)
			if TurnController.use_phase_movement and Global._action != 0 and Global._action != 1 and Global._action != 2:
				preview_phase_step(hit_object)
		
		#Movement
		if Global._action == 0:
			if Input.is_action_just_pressed("Click") and event.pressed:
				attempt_select(hit_object)
			elif Input.is_action_just_pressed("RightClick"):
				attempt_move_unit(hit_object)
		
		#Long range firing (Archers and Ballista)
		if Global._action == 1 and Global._subAction >= 0 and hit_object:
			#Range
			var max_range = 1
			var min_range = 1
			#Ballista has more range than archers
			if Global._subAction == 1:
				max_range = 4
			#Catapult has more range than archers
			if Global._subAction == 2:
				max_range = 6
				min_range = 2
			
			var attacker = Global._lastShipClicked
			if hit_object is Unit and event.pressed and hit_object._boardingCounter == 0:
				var objOwner = hit_object._owner
				
				#Select who is doing the targetting
				if Global._lastShipClicked == null and Input.is_action_just_pressed("Click"):
					Global._lastShipClicked = hit_object
					attacker = Global._lastShipClicked
					attacker._owner._shipClicked = true
					_Log.push("Selected: %s (%s) and can select LRF target!" % [attacker._attacker.name, attacker._owner._name])
					attempt_range_select(hit_object, min_range, max_range)
					get_tree().call_group("ship_stats", "show_ship", hit_object)
				
				#Don't fire on self
				elif attacker and attacker._owner._shipClicked and attacker._owner == objOwner and Input.is_action_just_pressed("RightClick"):
					_Log.push("Same self bozo. Select new target!")
				
				#Don't select ship to action that you don't own (Multiplayer)
				
				#Select firing target
				elif attacker and attacker._owner._shipClicked and attacker._owner != objOwner and Input.is_action_just_pressed("RightClick"):
					#Range Check (unit_moves is tiles)
					if unit_moves.size() > 0:
						for i in unit_moves.size():
							#If so then in range
							if unit_moves[i].occupier:
								for j in unit_moves[i].occupier.size():
									if unit_moves and hit_object == unit_moves[i].occupier[j]:
										attacker._attacker._enemyTarget = hit_object
										_Log.push("Shooter: %s is targetting: %s" % [attacker._attacker.name, attacker._attacker._enemyTarget.name])
										#Ballista damage chance is based on range value
										if Global._subAction == 1:
											attacker._ballistaTargetRange = unit_moves[i].range
										#Catapult damage chance is based on range value (assuming)
										if Global._subAction == 2:
											attacker._catapultTargetRange = unit_moves[i].range
										
										#Reset
										attacker._owner._shipClicked = false
										Global._lastShipClicked = null
										deselect()
									if unit_moves == null:
										_Log.push("Target is too far away or doesn't exist!")
			else:
				#Reset
				if attacker or selected_unit != null:
					_Log.push("LRF Cancelled")
				if attacker:
					attacker._owner._shipClicked = false
				Global._lastShipClicked = null
				deselect()


func _pointer_is_over_menu() -> bool:
	var mouse := get_viewport().get_mouse_position()
	for node in get_tree().get_nodes_in_group("screen_menu"):
		if node is Control and _scaled_rect_has_point(node, mouse):
			return true
	return false


func _scaled_rect_has_point(control: Control, point: Vector2) -> bool:
	var xform := control.get_global_transform()
	var card_size := control.size
	var min_point: Vector2 = xform * Vector2.ZERO
	var max_point := min_point
	for corner in [Vector2(card_size.x, 0), Vector2(0, card_size.y), card_size]:
		var placed: Vector2 = xform * corner
		min_point = min_point.min(placed)
		max_point = max_point.max(placed)
	return Rect2(min_point, max_point - min_point).has_point(point)


func raycast_at_mouse(origin, end) -> Node3D:
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var collision = get_world_3d().direct_space_state.intersect_ray(query)
		if collision and collision.has("collider"):
			var hit = collision.collider.get_parent()
			return hit
		else:
			if Global._action == 1 and (Global._lastShipClicked != null or selected_unit != null):
				var attacker = Global._lastShipClicked
				if attacker:
					attacker._owner._shipClicked = false
				Global._lastShipClicked = null
				_Log.push("LRF Cancelled")
			deselect()
			return null


func deselect():
	hide_cursor(tile_cursor)
	hide_cursor(unit_cursor)
	unit_moves.clear()
	selected_unit = null
	p_finder.clear_highlight()
	get_tree().call_group("ship_stats", "clear_ship")


func _on_phase_changed(_phase: TurnController.Phase, _execution_step: int, _turn_number: int) -> void:
	if TurnController.action_step != TurnController.ActionStep.LONG_RANGE_FIRE:
		return
	if selected_unit == null or not is_instance_valid(selected_unit) or selected_unit is not Ship:
		return
	_Log.push("Selected: %s (%s). Select a target." % [selected_unit._attacker.name, selected_unit._owner._name])


func attempt_select(hit):
	deselect()
	if hit.is_in_group("tiles"):
		highlight_tile(hit)
	elif hit.is_in_group("units"):
		select_unit(hit)


func attempt_move_unit(hit):
	if TurnController.use_phase_movement:
		_Log.push("Phase movement is on. Finish Move steps the ships.")
		return
	if not selected_unit or not hit.is_in_group("tiles") or hit is not Tile or not unit_moves.has(hit):
		_Log.push("Attempted to move to invalid tile")
		return
	var moved := selected_unit
	moved.place_unit(hit.position, hit)
	_highlight_creative_range(moved)
	get_tree().call_group("ship_stats", "show_ship", moved)


func select_unit(unit):
	selected_tile = null
	selected_unit = unit
	hide_cursor(tile_cursor)
	if unit is Unit:
		highlight_unit(unit)
		if TurnController.use_phase_movement and unit is Ship:
			unit.aim_at_facing()
			unit_moves = PhaseMovement.command_preview(unit)
			p_finder.highlight_tile(unit_moves)
		else:
			_highlight_creative_range(unit)
		get_tree().call_group("ship_stats", "show_ship", unit)


func follow_selected_ship(unit: Node) -> void:
	if unit is not Ship or not is_instance_valid(unit):
		return
	selected_tile = null
	selected_unit = unit
	hide_cursor(tile_cursor)
	if not TurnController.use_phase_movement:
		_highlight_creative_range(unit)
		return
	if _in_long_range_fire():
		preview_lrf_range(unit)
		return
	unit.aim_at_facing()
	highlight_unit(unit)
	p_finder.clear_highlight()
	unit_moves = PhaseMovement.command_preview(unit)
	p_finder.highlight_tile(unit_moves)


func _highlight_creative_range(unit: Unit) -> void:
	if unit.occupied_tile == null:
		return
	selected_unit = unit
	highlight_unit(unit)
	p_finder.clear_highlight()
	unit_moves = p_finder.find_reachable_tiles(unit.occupied_tile, 2, unit)
	p_finder.highlight_tile(unit_moves)


func preview_phase_step(unit: Node) -> void:
	if unit is not Ship:
		return
	p_finder.clear_highlight()
	unit_moves.clear()
	selected_unit = unit
	unit.aim_at_facing()
	highlight_unit(unit)
	unit_moves = PhaseMovement.command_preview(unit)
	p_finder.highlight_tile(unit_moves)


func highlight_tile(tile):
	selected_unit = null
	selected_tile = tile
	hide_cursor(unit_cursor)
	move_cursor(tile_cursor, tile.global_position)
	tile_cursor.visible = true
	animate_cursor(tile_cursor)
	_Log.push(tile.biome)


func _process(_delta: float) -> void:
	if unit_cursor == null or not unit_cursor.visible:
		return
	if selected_unit == null or not is_instance_valid(selected_unit):
		return
	unit_cursor.global_position = selected_unit.global_position


func highlight_unit(unit):
	unit_cursor.global_position = unit.global_position
	unit_cursor.visible = true


func _lrf_range() -> Vector2i:
	var min_range := 1
	var max_range := 1
	if Global._subAction == 1:
		max_range = 4
	elif Global._subAction == 2:
		max_range = 6
		min_range = 2
	return Vector2i(min_range, max_range)


func _in_long_range_fire() -> bool:
	return TurnController.phase == TurnController.Phase.EXECUTION and TurnController.action_step == TurnController.ActionStep.LONG_RANGE_FIRE


func preview_lrf_range(unit: Node) -> void:
	if unit is not Ship or not is_instance_valid(unit) or unit.occupied_tile == null:
		return
	selected_tile = null
	selected_unit = unit
	hide_cursor(tile_cursor)
	highlight_unit(unit)
	var ranges := _lrf_range()
	p_finder.clear_highlight()
	unit_moves = p_finder.find_targetable_units(unit.occupied_tile, ranges.x, ranges.y, unit)
	p_finder.highlight_tile(unit_moves)


func attempt_range_select(hit, min_range: int, max_range: int):
	deselect()
	if hit.is_in_group("tiles"):
		highlight_tile(hit)
	elif hit.is_in_group("units"):
		selected_tile = null
		selected_unit = hit
		hide_cursor(tile_cursor)
		if hit is Unit:
			highlight_unit(hit)
			unit_moves = p_finder.find_targetable_units(hit.occupied_tile, min_range, max_range, hit)
			p_finder.highlight_tile(unit_moves)


## move cursor with optional height difference
func move_cursor(cursor : Node3D, pos : Vector3, height : float = 0):
	cursor.position = pos
	if height != 0:
		tile_cursor.position.y += height


func animate_cursor(cursor : Node3D):
	var tween = get_tree().create_tween()
	var initial_scale = cursor.scale
	var target_scale = initial_scale * 1.15
	tween.set_trans(Tween.TRANS_SPRING)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cursor, "scale", target_scale, 0.175)
	tween.tween_property(cursor, "scale", initial_scale, 0.2)


func hide_cursor(cursor : Node3D):
	if cursor:
		move_cursor(cursor, Vector3.ZERO, -10)
		cursor.visible = false
