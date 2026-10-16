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
			self.position.y += 3;
			tile.occupier[i]._tile = tile

func leave_tile():
	if occupied_tile:
		occupied_tile.occupier.erase(self)
