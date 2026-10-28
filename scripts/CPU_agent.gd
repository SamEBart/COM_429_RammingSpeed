extends Node
class_name CPU_Manager

#@export var p_finder : Pathfinder

@onready var p_finder: Pathfinder = preload("res://scripts/pathfinder.gd").new()

var player : Node3D
var owned_ships

func _ready() -> void:
	player = get_parent()
	owned_ships = player.getOwnedShips()

func choose_action():
	var chosen_moves = []
	for ship in owned_ships:
		var valid_moves = get_valid_moves(ship)
		#TODO add logic instead of placeholder random
		var move = valid_moves.pick_random()
		
		#debug
		ship._tile = move
		print("Move: ", move)
	

func get_valid_moves(ship : Ship):
	var valid_moves 
	valid_moves = p_finder.find_reachable_tiles(ship.occupied_tile, 2, ship)
	return valid_moves
	
