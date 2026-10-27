extends Node

@export var p_finder : Pathfinder

var player : Node3D
var owned_ships = player.getOwnedShips()

func _ready() -> void:
	player = get_parent()

func choose_action():
	var chosen_moves = []
	for ship in owned_ships:
		var valid_moves = get_valid_moves(ship)
		#TODO add logic instead of placeholder random
		var move = valid_moves.pick_random()
		chosen_moves.append([ship, move])
	return chosen_moves
	
func execute_action():
	var actions = choose_action()
	#debug
	print("Chosen moves:", actions)
	return


func get_valid_moves(ship : Ship):
	var valid_moves = p_finder.find_reachable_tiles(ship.occupied_tile, 2, ship)
	return valid_moves
	
