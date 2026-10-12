extends Node3D

var _action = 0
var _subAction = 0
var threads: Array[Thread] = []

## TEMPORARAY until we figure out multiplayer
var _lastShipClicked = null

func _input(event: InputEvent) -> void:
	# Temporary to designate current main action
	if Input.is_action_just_pressed("ShiftEnter"):
		_action += 1
		match _action:
			0:
				action_reset()
				print("Now on Move Ships ", _action)
			1:
				action_reset()
				print("Now on Long Range Firing ", _action)
			2:
				action_reset()
				print("Now on Boarding Actions ", _action)
			3:
				action_reset()
				print("Reset ", _action)
				_action = -1
				return
	
	# Temporary to go to next sub action
	elif Input.is_action_just_pressed("NextSubAction"):
		get_tree().call_group("ships", "ship_reset")
		_subAction += 1
		print("New Sub Action is: ", _subAction, " on Gloal: ", _action)
	
	# Temporary to  induce action truns/events manually
	elif Input.is_action_just_pressed("CtrlEnter"):
		#If Archery
		if Global._action == 1 and Global._subAction == 0:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				LRF.archerFire(ship)
			get_tree().call_group("ships", "ship_reset")
		
		#If Ballista
		if Global._action == 1 and Global._subAction == 1:
			var ships: Array[Node] = get_tree().get_nodes_in_group("ships")
			for ship in ships:
				if ship._ballista and !ship.getBallista().isBroken():
					var ballista = ship.getBallista()
					if ballista.isLoaded() and ship.getEngineers() and ship._enemyTarget:
						LRF.ballistaFire(ship)
						ship._ballista.fire()
						print("Firing ", ship.name, "s Ballista!")
					elif !ballista.isLoaded() and ship.getEngineers():
						ballista.reload()
						print("Reloading ", ship.name, "s Ballista now at (", ship._ballista._reloadTimer, ")")
			get_tree().call_group("ships", "ship_reset")


func action_reset():
	_subAction = 0
