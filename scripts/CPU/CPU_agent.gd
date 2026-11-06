extends Node
class_name CPU_Manager

#@export var p_finder : Pathfinder

@onready var p_finder: Pathfinder = preload("res://scripts/pathfinder.gd").new()

var player : Node3D
var owned_ships

func _ready() -> void:
	player = get_parent()
	owned_ships = player.getOwnedShips()
	
# chooses the speed and direction for ships
# is currently just random
func choose_action():
	for ship in owned_ships:
		var speed = 0
		var speedOptions = []
		if ship.get_ship_kind() == (SpeedCalculator.ShipKind.QUADRIREME):
			speedOptions = [-1,0,1]
		elif ship.get_ship_kind() == (SpeedCalculator.ShipKind.TRIREME):
			speedOptions = [-2,0,1]
			
		speed = speed + speedOptions.pick_random()
		ship.adjust_rowing_speed(speed)
		
		ship._isMastUp = true
		
		var facingOptions = [-1,0,1]
		ship.turn_facing(facingOptions.pick_random())
		#print("choosing action for", ship)
		
# not currently used
func get_legal_actions(ship : Ship):
	var legal_actions 
	legal_actions = p_finder.find_reachable_tiles(ship.occupied_tile, 2, ship)
	return legal_actions
	
