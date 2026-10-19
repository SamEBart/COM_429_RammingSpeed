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

func occupy_tile(tile : Tile):
	occupied_tile = tile
	tile.occupier.append(self)
	#TEMP way to put multiple ships on one hex
	if tile.occupier.size() > 1:
		for i in tile.occupier.size() - 1:
			self.position.y += 1;
			tile.occupier[i]._tile = tile

func leave_tile():
	if occupied_tile:
		occupied_tile.occupier.erase(self)

func _on_detection_area_area_entered(area):
	var target: Ship = area.get_parent()
	if !self._inCollision and !target._inCollision:
		#Get Ship that goes first
		var firstShip: Ship; var secondShip: Ship
		var result = sort_initiative(self, target)
		if result:
			firstShip = self; secondShip = target
		else:
			firstShip = target; secondShip = self
		
		#Check if Ships are Beak to Beak
		if fposmod(firstShip.rotation_degrees.y + 180, 360) == secondShip.rotation_degrees.y or fposmod(firstShip.rotation_degrees.y - 180, 360) == secondShip.rotation_degrees.y:
			#Give first ship a choice of Shear Oppnents Oars, Attempt to Run, Attemp to avoid a ram
			#Allow other ship to Attempt to Ram or Avoid
			#If Shear then immediately do that instead of the above allowed.
				#If they succeeed the other ship may not take that action
					#If ship is an enemy go directly to Boarding Actions
				#If Shearing fails the other ship executes it's declared action from Ramming Results
			## Temp auto rng, replace!!
			match randi_range(1, 3):
				#Shear Opponent Oars
				1:
					pass
				
				#Attempt to Ram
				2:
					if firstShip._speed > 0:
						pass
				
				#Attempt to Avoid
				3:
					pass
				
		
		#Check if Ships are both in Front Quarter
		else:
			#Ship One declares Ram or Avoid, then Ship Two
			pass
		
		#Any other direction combo
#		else:
			#Only the ship facing the other can declare Ram or Avoid.
			#Other auto declares avoid action
#			pass


func sort_initiative(a, b) -> bool:
	#Set order of attack by checking speed, then ship type, deck crew size, then dice roll
	#Speed
	if a._speed > b._speed:
		return true
	elif a._speed < b._speed:
		return false
	
	#Type
	if a.type > b.type:
		return true
	elif a.type < b.type:
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
