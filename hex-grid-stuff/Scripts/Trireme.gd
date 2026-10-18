extends Ship
class_name Trireme

func _ready() -> void:
	super()
	
	#Active Rower
	for i in range(150):
		rowers.append(Rower.new())
	#Reserve Rowers
	for i in range(140):
		rowers.append(Rower.new())
		rowers[i].change_rower_status(false)
	#Archers
	for i in range(3):
		marines.append(Archer.new())
	#Engineers
	for i in range(3):
		engineers.append(Engineer.new())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
