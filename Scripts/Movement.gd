extends Node2D

@export var tileMap : TileMapLayer
@export var offSet = Vector2(0, -6)
@export var starting_position : Vector2i
@export var movementRange = 2

var isMoving = false

func _ready() -> void:
	get_parent().position = tileMap.map_to_local(starting_position)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("leftClick"):
		if get_parent().canMove == false:
			print("Ship cannot move!")
			return
		
		else:
			await _move()
			var playerTile = tileMap.local_to_map(global_position)
			print("Player is in tile: ", playerTile)
			
			#Detect if Player has moved into an Enemy
			var all_enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in all_enemies:
				var enemy_position: Vector2i = tileMap.local_to_map(enemy.global_position)
				if enemy_position == playerTile:
					print("Arrrrg get borded ye salty land loverrr!")

func _move():
	#If Moving don't add new Destination
	if isMoving: return
	
	var mousePosition = get_global_mouse_position()
	var isTaregtPositionValid = get_tile_global_position(mousePosition)
	var movementArray = _get_route(mousePosition)
	
	#Don't move if invalid position or if out of Movement Range
	if not isTaregtPositionValid: return
	if movementArray.size() > movementRange: return
	
	isMoving = true
	
	#Move
	for movement in movementArray:
		var playerTilePosition = tileMap.local_to_map(global_position)
		var targetTilePosistion = playerTilePosition + movement
		var targetPosition = tileMap.map_to_local(targetTilePosistion) + offSet
		
		var tween := create_tween()
		tween.tween_property(get_parent(), "global_position", targetPosition, 0.3)
		
		await tween.finished
	
	isMoving = false

func get_tile_global_position(mousePosition):

	var mouseTilePosition := tileMap.local_to_map(mousePosition)
	var mouseTileData = tileMap.get_cell_atlas_coords(mouseTilePosition)
	
	if mouseTileData == Vector2i(-1, -1): return
	
	var tileGlobalPosition = tileMap.map_to_local(mouseTilePosition)
	
	return Vector2i(tileGlobalPosition)

func _get_route(targetPosition):
	var routeArray = []
	
	var direction = tileMap.local_to_map(targetPosition) - tileMap.local_to_map(global_position)
	var currentTilePosition = tileMap.local_to_map(global_position)
	
	while direction:
		var newPoint = snap(direction, 1)
		
		#forbid running directly up or down
		#forbid (1,1) and (-1,-1)
		if newPoint.x and newPoint.y and newPoint.x == newPoint.y:
			var checkPoint = Vector2i(0, newPoint.y)
			
			if not _has_tile(currentTilePosition + checkPoint):
				newPoint.y = 0
			else:
				newPoint.x = 0
		
		#handle border
		if not _has_tile(currentTilePosition + newPoint):
			var points = [Vector2i(0, newPoint.y), Vector2i(newPoint.x, 0)]
			
			for point in points:
				if point == Vector2i.ZERO: continue
				
				if _has_tile(currentTilePosition + point):
					newPoint = point
				
		routeArray.append(newPoint)
		direction -= newPoint
		currentTilePosition += newPoint
	
	return routeArray

func snap(vector, step: int):
	if vector.x > 0: vector.x = 1
	elif vector.x < 0: vector.x = -1
	
	if vector.y > 0: vector.y = 1
	elif vector.y < 0: vector.y = -1
	
	return vector

func _has_tile(tilePosition):
	var tileData = tileMap.get_cell_atlas_coords(tilePosition)
	return tileData != Vector2i(-1, -1)
