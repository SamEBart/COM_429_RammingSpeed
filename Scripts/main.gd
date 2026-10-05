extends Node3D

var myShip = preload("res://Scenes/temp_ship.tscn")
var myPlayer = preload("res://Scenes/temp_player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var playerOne = _inst_player(Vector3(0, 1, 2), "Chris", 1)
	_inst_tri(Vector3(0, 0, 0), playerOne, "Tri 01")
	_inst_tri(Vector3(2, 0, 0), playerOne, "Tri 02")
	
	var playerTwo = _inst_player(Vector3(3, 1, 2), "Bobby", 2)
	_inst_tri(Vector3(0, -2, 0), playerTwo, "Tri 03")
	

func _inst_player(pos, name, id):
	var playerInstance = myPlayer.instantiate()
	playerInstance.position = pos
	playerInstance.initiate(name, id)
	add_child(playerInstance)
#	playerInstance.add_to_group("players")
	return playerInstance

func _inst_tri(pos, owner, name):
	var instance = myShip.instantiate()
	instance.position = pos
	instance.set_script(Ship.Trireme)
	instance._setup(owner)
	instance.name = name
	owner.appendShip(instance)
	add_child(instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
