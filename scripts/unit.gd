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

func _on_detection_area_area_entered(area):
	var target: Ship = area.get_parent()
	if true:
		#Get Ship that goes first
		var firstShip: Ship; var secondShip: Ship
		var result = sort_initiative(self, target)
		if result:
			firstShip = self; secondShip = target
		else:
			firstShip = target; secondShip = self
		
		#Check if Ships are Beak to Beak
		print("Enetred!")
		if ceil(fposmod(firstShip.rotation_degrees.y + 180, 360)) == ceil(secondShip.rotation_degrees.y) or ceil(fposmod(firstShip.rotation_degrees.y - 180, 360)) == ceil(secondShip.rotation_degrees.y):
			#Give first ship a choice of Shear Oppnents Oars, Attempt to Run, Attemp to avoid a ram
			#Allow other ship to Attempt to Ram or Avoid
			#If Shear then immediately do that instead of the above allowed.
				#If they succeeed the other ship may not take that action
					#If ship is an enemy go directly to Boarding Actions
				#If Shearing fails the other ship executes it's declared action from Ramming Results
			
			print("Beak to Beak")
			## Temp auto rng, replace!!
			match randi_range(1, 3):
				#Shear Opponent Oars
				1:
					print("Shear")
					#Get a roll for first ship
					var roll = randi_range(2, 12)
					#If roll above shearers speed then fail
					if roll > self._speed:
						#Prompt secondShip for decision
						#TEMP rng for 2nd Ship
						var roll2 = randi_range(1, 2)
						match roll2:
							#Ram
							1:
								Charts.rammingResults(secondShip, firstShip)
							#Collision
							2:
								Charts.collision(roll2, secondShip, firstShip, 1)
					
					elif roll == self._speed:
						#Half reaming oar banks + rowers equal to those banks are lost
						var banks = target.getBanks()
						for i in int(ceil(banks.size() / 2)):
							banks[i].removeBank(target)
						
					elif roll < self._speed:
						#Collision
						Charts.collision(roll, firstShip, secondShip, 1)
					
					#Both ships are now in a BA
					self._inBoarding = true
					target._inBoarding = true
				
				#Attempt to Ram
				2:
					if firstShip._speed > 0:
						print("Attempt to Ram")
						firstShip._ramAction = 1
						secondShip._ramAction = randi_range(1, 2)
						Charts.rammingResults(firstShip, secondShip)
				
				#Attempt to Avoid
				3:
					print("Attenp to Avoid")
					firstShip._ramAction = 2
					secondShip._ramAction = randi_range(1, 2)
				
		
		#Check if Ships are in Front 1/4th to each other
		#Right to left, Left to Right
		elif ceil(fposmod(firstShip.rotation_degrees.y - 60, 360)) == ceil(fposmod(secondShip.rotation_degrees.y + 60 ,360)) or ceil(fposmod(firstShip.rotation_degrees.y + 60, 360)) == ceil(fposmod(secondShip.rotation_degrees.y - 60 ,360)):
			#Ship One declares Ram or Avoid, then Ship Two
			#TEMP, ask players
			print("Front 1/4th")
			firstShip._ramAction = randi_range(1, 2)
			secondShip._ramAction = randi_range(1, 2)
			if firstShip._ramAction == 1:
				Charts.rammingResults(firstShip, secondShip)
			if secondShip._ramAction == 1:
				Charts.rammingResults(secondShip, firstShip)
		
		#Any other direction combo
		#If ship 1 is between ship 2s back left and back right
		elif ceil(firstShip.rotation_degrees.y) <= ceil(fposmod(secondShip.rotation_degrees.y - 120, 360)) and ceil(firstShip.rotation_degrees.y) >= ceil(fposmod(secondShip.rotation_degrees.y + 120, 360)):
			#Only the ship facing the other can declare Ram or Avoid.
			#Other auto declares avoid action
			print("Other Direction A")
			firstShip._ramAction = randi_range(1, 2)
			secondShip._ramAction = 2
			if firstShip._ramAction == 1:
				Charts.rammingResults(firstShip, secondShip)
		
		#If ship 2 is between ship 1s back left and back right
		elif ceil(secondShip.rotation_degrees.y) <= ceil(fposmod(firstShip.rotation_degrees.y - 120, 360)) and ceil(secondShip.rotation_degrees.y) >= ceil(fposmod(firstShip.rotation_degrees.y + 120, 360)):
			#Only the ship facing the other can declare Ram or Avoid.
			#Other auto declares avoid action
			print("Other Direction B")
			secondShip._ramAction = randi_range(1, 2)
			firstShip._ramAction = 2
			if secondShip._ramAction == 1:
				Charts.rammingResults(secondShip, firstShip)
		
		self._inCollision = true
		target._inCollision = true
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
