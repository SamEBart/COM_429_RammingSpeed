extends Node
class_name CPU_Manager

@onready var p_finder: Pathfinder = preload("res://scripts/pathfinder.gd").new()

var player : Node3D
var owned_ships
var neighbor_directions = WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS

# heuristic values
var ram_var
var avoid_var
var ranged_var

var action

func _ready() -> void:
	player = get_parent()
	owned_ships = player.getOwnedShips()
	get_values(player._profile)

func choose_action(phase, action_step):
	
	# On command phase
	if phase == 1:
		for ship in owned_ships:
			get_target(ship)
			print(target_ship_ram(ship))
			
	if action_step == 2:
		for ship in owned_ships:
			target_ship_LRF(ship)

# sets nearby enemy ship as LRF target
func target_ship_LRF(owned_ship):
	var targetable_ships = []
	var lrf_range = owned_ship.lrf_range()
	targetable_ships = p_finder.find_targetable_units(
									owned_ship._tile, 
									lrf_range.x, 
									lrf_range.y, 
									owned_ship)
	if not targetable_ships.is_empty():
		var target = targetable_ships.pick_random()
		owned_ship.set_enemy_target(target.occupier[0])
		
func get_target(owned_ship):
	var targetable_ships = []
	targetable_ships = p_finder.find_targetable_units(
								owned_ship._tile, 
								1, 
								20, 
								owned_ship)
	if not targetable_ships.is_empty():
		var target = targetable_ships.pick_random()
		owned_ship.aiTarget = target.occupier[0]

func target_ship_ram(owned_ship):
	if owned_ship.aiTarget == null:
		get_target(owned_ship)
	
	var goal = owned_ship.aiTarget._tile
	var start = owned_ship._tile
	var goal_direction
		
	# gets direction that target to ram is in
	for direction in neighbor_directions:
		var tile = start
		for i in range(20):
			var neighbor_coords = Vector2(tile.pos_data.grid_position.x + int(direction.x), tile.pos_data.grid_position.y + int(direction.y)) 
			if neighbor_coords in WorldMap.map_as_dict:
				if tile == goal:
					goal_direction = direction
				else:
					tile = WorldMap.map_as_dict[neighbor_coords]
					
	# changes direction of ship and makes it speed up
	if goal_direction:
		owned_ship.turn_facing(int(goal_direction.x))
	else: 
		var facingOptions = [-1,0,1]
		owned_ship.turn_facing(facingOptions.pick_random())
		
		owned_ship.adjust_rowing_speed(++1)
		
		owned_ship._isMastUp = true
	

func get_values(profile : String):
	if profile == "Baseline":
		ram_var = 5
		avoid_var = 5
		ranged_var = 4
	if profile == "Rammer":
		ram_var = 9
		avoid_var = 2
		ranged_var = 1
	if profile == "Marksman":
		ram_var = 1
		avoid_var = 9
		ranged_var = 9
