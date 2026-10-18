extends Node

var game_phase = 2
var action = 0
var sub_action = 1
var ship_clicked = false
var archer_target

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("sh-eneter"):
		action += 1
		match action:
			0:
				action_reset()
				print("Move Ships")
			1:
				action_reset()
				print("Long Range Firing")
			2:
				action_reset()
				print("Boarding Actions")
			3:
				action_reset()
				print("Reset")
				action = -1
				return

	elif Input.is_action_just_pressed("rightArrow"):
		get_tree().call_group("ships", "ship_reset")
		sub_action += 1
	
	elif Input.is_action_just_pressed("leftArrow"):
		var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
		for ship in ships:
			print(ship.name, " Has: ", ship.health, " Health")
	
	elif Input.is_action_just_pressed("c-eneter"):
		#If Archery
		#Add game phase check later for boaridng
		if Global.action == 1 and Global.sub_action == 1:
			get_tree().call_group("ships", "priming_archers")
			get_tree().call_group("ships", "ship_reset")
		
		#If Ballista
		elif Global.action == 1 and Global.sub_action == 2:
			get_tree().call_group("ships", "priming_ballistas")
			get_tree().call_group("ships", "ship_reset")

func action_reset():
	sub_action = 1
	ship_clicked = false
#	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
#	for ship in ships:
#		ship.canMove = false
