extends Ship
class_name Trireme

## Trireme oars may rise by 1 or drop by 2 in a Command phase.
func get_ship_kind() -> SpeedCalculator.ShipKind:
	return SpeedCalculator.ShipKind.TRIREME


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
	for i in range(randi_range(1, 10)):
		marines.append(Archer.new())
	#Javelineers
	for i in range(randi_range(1, 10)):
		marines.append(Javelineer.new())
	#Soldiers
	for i in range(randi_range(1, 10)):
		marines.append(Soldier.new())
	fighters.append_array(marines)
	#Engineers
	for i in range(randi_range(1, 10)):
		engineers.append(Engineer.new())
	fighters.append_array(engineers)
	#Deck Crew
	for i in range(randi_range(1, 10)):
		deck_crew.append(DeckCrew.new())
	fighters.append_array(deck_crew)
	
	print("Fighters: ", fighters.size())


func _on_detection_area_area_entered(area):
	boarding_target = area.get_parent()			#Make this a list later for multiple ships in one spot, or select another ship somehow
	#Stop movement
	#Do checks
	#Check the ships that are in that hex, their angle(direction), and speed
