extends Node3D
class_name Unit

@export var unit_name : String = "Unit"
@export var max_health: int = 10
var current_health: int = 10
@export var movement_range: int = 2
@export var model: PackedScene

var occupied_tile : Tile
var team # which "team" does this unit belong to


func _ready() -> void:
	current_health = max_health


## Put this unit on a tile at position
func place_unit(new_position : Vector3, tile):
	position = new_position
	leave_tile()
	occupy_tile(tile)
	for i in tile.occupier.size():
		tile.occupier[i]._tile = tile
	
	#Reset Boarding Counter when moving to an empty hex
	if self.occupied_tile.occupier.size() == 1:
		self._boardingCounter = 0
		self._inBoarding = false
		self._inCollision = false

func occupy_tile(tile : Tile):
	occupied_tile = tile
	tile.occupier.append(self)
	#TEMP way to put multiple ships on one hex
	#temp comment
	if tile.occupier.size() > 1:
		for i in tile.occupier.size() - 1:
			self.position.y += 1;
			tile.occupier[i]._tile = tile

func leave_tile():
	if occupied_tile:
		occupied_tile.occupier.erase(self)

#When two ships eneter the same hex collide
func _on_detection_area_area_entered(area):
	var self_ship = self
	var target: Ship = area.get_parent()
	BoardingActions.ship_area_entered(self_ship, target)
	print("Close\n")


func sort_initiative(a: Ship, b: Ship) -> bool:
	#Set order of attack by checking speed, then ship type, deck crew size, then dice roll
	#Speed
	if a._speed > b._speed:
		return true
	elif a._speed < b._speed:
		return false
	
	#Type
	if a._type > b._type:
		return true
	elif a._type < b._type:
		return false
	
	#Deck Crew
	if a._deckCrew.size() > b._deckCrew.size():
		return true
	elif a._deckCrew.size() < b._deckCrew.size():
		return false
	
	#Dice
	var rollA; var rollB; var temp = true
	#Get Different Dice Values
	while temp:
		rollA = randi_range(1, 6)
		rollB = randi_range(1, 6)
		if rollA != rollB:
			temp = false
	#Exit
	if rollA > rollB:
		return true
	else:
		return false


func _on_detection_area_area_exited(area: Area3D) -> void:
	#Reset Boarding Counter when moving to an empty hex
	if self.occupied_tile.occupier.size() == 1:
		self._boardingCounter = 0
		self._inBoarding = false
		self._inCollision = false
