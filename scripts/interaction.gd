extends Node3D

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
	if not tile_cursor or tile_cursor == null:
		tile_cursor = tile_cursor_scene.instantiate()
		add_child(tile_cursor)
	if not unit_cursor:
		unit_cursor = unit_cursor_scene.instantiate()
		add_child(unit_cursor)
	deselect()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()
		var origin = main_camera.project_ray_origin(mouse_pos)
		var dir = main_camera.project_ray_normal(mouse_pos)
		var end = origin + dir * 1000
		var hit_object = raycast_at_mouse(origin, end)
		if not hit_object:
			return
		
		#Movement
		if Global._action == 0:
			if Input.is_action_just_pressed("Click") and event.pressed:
				attempt_select(hit_object)
			elif Input.is_action_just_pressed("RightClick"):
				attempt_move_unit(hit_object)
		
		#Long range firing (Archers and Ballista)
		if Global._action == 1 and Global._subAction >= 0 and hit_object and hit_object._boardingCount == 0:
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
			if hit_object is Unit and event.pressed:
				var objOwner = hit_object._owner
				
				#Select who is doing the targetting
				if Global._lastShipClicked == null and Input.is_action_just_pressed("Click"):
					Global._lastShipClicked = hit_object
					attacker = Global._lastShipClicked
					attacker._owner._shipClicked = true
					print("Clicked: ", attacker._attacker.name, " (", attacker._owner._name,") and can select LRF target!")
					attempt_range_select(hit_object, min_range, max_range)
				
				#Don't fire on self
				elif attacker and attacker._owner._shipClicked and attacker._owner == objOwner and Input.is_action_just_pressed("RightClick"):
					print("Same self bozo. Select new target!")
				
				#Don't select ship to action that you don't own (Multiplayer)
				
				#Select firing target
				elif attacker and attacker._owner._shipClicked and attacker._owner != objOwner and Input.is_action_just_pressed("RightClick"):
					#Range Check (unit_moves is tiles)
					for i in unit_moves.size():
						#If so then in range
						if unit_moves and hit_object == unit_moves[i].occupier:
							attacker._attacker._enemyTarget = hit_object
							print("Shooter: ", attacker._attacker.name, " is targetting: ", attacker._attacker._enemyTarget.name, "\n")
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
							if hit_object._isBoarding:
								hit_object._boardingCounter += 1
						if unit_moves == null:
							print("Target is too far away or doesn't exist!")
			else:
				#Reset
				if attacker:
					attacker._owner._shipClicked = false
				Global._lastShipClicked = null
				deselect()


func raycast_at_mouse(origin, end) -> Node3D:
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var collision = get_world_3d().direct_space_state.intersect_ray(query)
		if collision and collision.has("collider"):
			var hit = collision.collider.get_parent()
			return hit
		else:
			deselect()
			return null


func deselect():
	hide_cursor(tile_cursor)
	hide_cursor(unit_cursor)
	unit_moves.clear()
	selected_unit = null
	p_finder.clear_highlight()


func attempt_select(hit):
	deselect()
	if hit.is_in_group("tiles"):
		highlight_tile(hit)
	elif hit.is_in_group("units"):
		select_unit(hit)


func attempt_move_unit(hit):
	if not selected_unit or not hit.is_in_group("tiles") or hit is not Tile or not unit_moves.has(hit):
		print("Attempted to move to invalid tile")
		return
	selected_unit.place_unit(hit.position, hit)
	deselect()


func select_unit(unit):
	selected_tile = null
	selected_unit = unit
	hide_cursor(tile_cursor)
	if unit is Unit:
		highlight_unit(unit)
		unit_moves = p_finder.find_reachable_tiles(unit.occupied_tile, unit.movement_range)
		p_finder.highlight_tile(unit_moves)


func highlight_tile(tile):
	selected_unit = null
	selected_tile = tile
	hide_cursor(unit_cursor)
	move_cursor(tile_cursor, tile.global_position)
	tile_cursor.visible = true
	animate_cursor(tile_cursor)
	print(tile.biome)


func highlight_unit(unit):
	move_cursor(unit_cursor, unit.position)
	unit_cursor.visible = true


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
