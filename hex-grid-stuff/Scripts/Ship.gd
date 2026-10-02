extends Node2D
class_name Ship

@export var tileMap : TileMapLayer
@export var offSet = Vector2(0, 0)
@export var starting_position : Vector2i
@export var movementRange = 2
@export var movementSpeed = 1
@export var angle = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var deck_crew = []
var rowers = []
var marines = []
var engineers = []
var ballista = Ballista.new()
var catapult
const hex_directions = [
	"up",			# ~0 deg
	"right_up",		# ~60 deg
	"right_down",	# ~120 deg
	"down",			# ~180 deg
	"left_down",	# ~240 deg
	"left_up"		# ~300 deg
]
var fighters = []

var rowing_speed
var health = 15

var enemy_target_cell
var enemy_target
var can_action = false
var is_actioning = false
var can_lrf = true

var boarding_target #probably make this an array maybe
var in_boarding = false
var boarding_action = 0
var boarding_prepped = false
var boarding_archers = []
var boarding_javelins = []
var boarding_melee = []

#===============================#
# Starting and Clicking Stuff
#
#Setting Start Position
func _ready() -> void:
	position = tileMap.map_to_local(starting_position) + offSet
	add_to_group("ships")
	
	match angle:
		0.0:
			animated_sprite.play("up")
		60.0:
			animated_sprite.play("right_up")
		120.0:
			animated_sprite.play("right_down")
		180.0:
			animated_sprite.play("down")
		240.0:
			animated_sprite.play("left_down")
		300:
			animated_sprite.play("left_up")
	
	#Each Phase happens after another. So anyone not used up in phase 1 will be used in phase 2 etc


#Detect when Ship is cliked on
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx:int ) -> void:
	if event is InputEventMouseButton and event.is_pressed() and Global.game_phase > 1 :
		if Input.is_action_just_pressed("leftClick") and !Global.ship_clicked:
			#Moving
			if Global.action == 0:
				can_action = true
				Global.ship_clicked = true
				print("Player is in tile: ", tileMap.local_to_map(global_position))
				print(name, " can move!")

			#Firing
			elif Global.action == 1:
				can_action = true
				Global.ship_clicked = true
				print("Ship can Select Firing Target!")
			
			#Boarding Firing
			elif Global.action == 2 and Global.sub_action == 2 and boarding_action == 0:
				can_action = true
				Global.ship_clicked = true
				print("Ship can Select Boarding Firing Target!")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("leftClick") and Global.ship_clicked:
		#Movement
		if Global.action == 0:
			#Can't Move
			if can_action == false:
				print("Ship cannot move!")
				return
			#Can Move
			else:
				await _move()

		#Long Range Firing
		elif Global.action == 1 and Global.ship_clicked:
			#Archery
			if Global.sub_action == 1:
				#Cannot Acrhery Due to not being in Archery Mode
				if can_action == false:
					print("Ship cannot archery!")
					return
				#Can Select Archery Target
				else:
					getting_firing_target(1);
	
			#Ballista
			elif Global.sub_action == 2:
				#Cannot Ballista Due to not being in Ballista Mode
				if can_action == false:
					print("Ship cannot ballista!")
					return
				#Can Select Ballista Target
				else:
					getting_firing_target(4)

		#Boarding Action
		elif Global.action == 2 and Global.ship_clicked:
			#Boarding Archery
			if Global.sub_action == 2:
				#Cannot Acrhery Due to not being in Archery Mode
				if can_action == false:
					print("Ship cannot boarding archery!")
					return
				#Can Select Archery Target
				else:
					getting_firing_target(1);
			
			#Boarding Javelins
			if Global.sub_action == 3:
				if can_action == false:
					print("Ship cannot boarding javelin!")
					return
				#Can Select Archery Target
				else:
					getting_firing_target(1);

#===============================#
# Movement
#
func _move():
	#If Moving don't add new Destination
	if is_actioning: return
	
	var mousePosition = get_global_mouse_position()
	var isTaregtPositionValid = get_tile_global_position(mousePosition)
	var movementArray = _get_route(mousePosition)
	
	#Don't move if invalid position or if out of Movement Range
	if not isTaregtPositionValid:
		print("Invalid position!")
		return
	if movementArray.size() > movementRange:
		print("Outside of current range: ", movementRange)
		return
	
	is_actioning = true
	
	#Move
	for movement in movementArray:
		var playerTilePosition = tileMap.local_to_map(global_position)
		var targetTilePosistion = playerTilePosition + movement
		var targetPosition = tileMap.map_to_local(targetTilePosistion) + offSet
		var global_pos: Vector2 = tileMap.map_to_local(movement)
		
		var tween := create_tween()
		tween.tween_property(self, "global_position", targetPosition, 0.3)
		
		await tween.finished
	
	is_actioning = false
	can_action = false
	Global.ship_clicked = false
	print("Player is in tile: ", tileMap.local_to_map(global_position))

func get_tile_global_position(mousePosition):
	var mouseTilePosition := tileMap.local_to_map(mousePosition)
	var mouseTileData = tileMap.get_cell_atlas_coords(mouseTilePosition)
	
	if mouseTileData == Vector2i(-1, -1): return
	
	var tileGlobalPosition = tileMap.map_to_local(mouseTilePosition)
	
	return Vector2i(tileGlobalPosition)

func _get_route(mousePosition):
	var routeArray = []
	
	var direction = tileMap.local_to_map(mousePosition) - tileMap.local_to_map(global_position)
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


#===============================#
# Long Range Firing
#
func priming_archers():
	var class_is_missing = marines.any(func(item): return item is Archer)
	if !class_is_missing:
		print("Ship does not have any archers")
		return
	else:
		var my_guys = marines.filter(func(guy): return guy is Archer)
		print("Archers: ", my_guys.size())
		_fire(my_guys)

func priming_ballistas():
	if !Ballista:
		print("Ship does not have any ballistas")
		return
	else:
		var my_guys = []
		my_guys.append(Ballista)
		_fire(my_guys)

func _fire(my_guys):
	if is_instance_valid(enemy_target):
#		print("Before: Ship: ", self.name, " (", self.health, ") Attacks: ", enemy_target.name, " (", enemy_target.health, ")")
		for guy in my_guys:
			if health > 0:
				print("Ship: ", self.name, " (", self.health, ") Attacks: ", enemy_target.name, " (", enemy_target.health, ")")
				enemy_target.health -= 1
#		print("After: Ship: ", self.name, " (", self.health, ") Attacked: ", enemy_target.name, " (", enemy_target.health, ")")	

func getting_firing_target(range):
	var mouse_cell = tileMap.local_to_map(tileMap.to_local(get_global_mouse_position()))
	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
	for ship in ships:
		var target_ship_coords = tileMap.local_to_map(tileMap.to_local(ship.position))
		var firing_array = _get_route(get_global_mouse_position())
		if firing_array.size() > range:
			print("Target is outside of Archers Range: ", range)
			return
		
		if self != ship and mouse_cell == target_ship_coords:
			enemy_target_cell = target_ship_coords
			enemy_target = ship
			can_action = true
			Global.ship_clicked = false
			print(self.name, " Targeting: ", self.enemy_target.name)
			break

#===============================#
# Boarding Action
#
func board_check():
	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
	for ship in ships:
		if enemy_target == null:
			if position == ship.position:
				enemy_target = ship
				if ship.enemy_target == null:
					ship.enemy_target = self

func ship_reset():
	enemy_target_cell = null
	enemy_target = null
	can_action = false
	is_actioning = false
