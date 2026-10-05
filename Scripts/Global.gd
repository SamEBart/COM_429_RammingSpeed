extends Node

var game_phase = 2
var action = 0
var sub_action = 1
var ship_clicked = false
var archer_target

var threads: Array[Thread] = []

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
		print("New Sub Action is: ", sub_action)
	
	elif Input.is_action_just_pressed("leftArrow"):
		var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
		for ship in ships:
			print(ship.name, " Has: ", ship.health, " Health")
	
	elif Input.is_action_just_pressed("c"):
		var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
		for ship in ships:
#			print(ship.name, "s Angle: ", ship.angle)
			print(ship.name, "s Target is: ", ship.enemy_target)
	
	elif Input.is_action_just_pressed("c-eneter"):
		#If Archery
		if Global.action == 1 and Global.sub_action == 1:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				var thread: Thread = Thread.new()
				thread.start(LongRangeFiring.archer_fire.bind(ship))
				threads.append(thread)
			for t in threads:
				t.wait_to_finish()
			get_tree().call_group("ships", "ship_reset")
		
		#If Ballista
		elif Global.action == 1 and Global.sub_action == 2:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				var thread: Thread = Thread.new()
				thread.start(LongRangeFiring.ballista_fire.bind(ship))
			for t in threads:
				t.wait_to_finish()
			get_tree().call_group("ships", "ship_reset")
		
		#If Boarding Action Determine Fighting
		elif Global.action == 2 and Global.sub_action == 1:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				#Check if ship has already been a previous ships boarding target
					#Activate a flag that makes a ship that already been part of a boading action skip the melee allocation in the determine function
				if !ship.boarding_prepped and ship.boarding_target:
					BoardingActions.determine_fighting(ship)
#			for ship in ships:
#				print("Name: ", ship.name, " A: ", ship.boarding_archers.size(), " J: ", ship.boarding_javelins.size(), " M: ", ship.boarding_melee.size())

		#If Boarding Archery
		if Global.action == 2 and Global.sub_action == 2:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				if ship.boarding_action == 0:
					var thread: Thread = Thread.new()
					thread.start(BoardingActions.boarding_archer_fire.bind(ship))
					threads.append(thread)
			for t in threads:
				t.wait_to_finish()
			get_tree().call_group("ships", "ship_reset")



func action_reset():
	sub_action = 1
	ship_clicked = false
#	var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
#	for ship in ships:
#		ship.canMove = false
