extends Node3D

class_name ShipUnit;

var object: Ship;
var _slide: Tween;
var _slide_goals: Array[Vector3] = [];
var _sliding: bool = false;
var occupied_tile : Tile;
var _tile: Tile;
var _boardingCounter: int = 0;
var _facing: int = 0;

func _ready() -> void:
	add_to_group("ships")
	object._attacker = self
	object._ballista = Ship.Ballista.new()
	object._catapult = Ship.Catapult.new()
	object._speed = randi_range(0, 8)

func place_unit(new_position : Vector3, tile):
	var start := global_position
	var first_drop := object.occupied_tile == null
	
	#region unit logic
	position = new_position
	leave_tile()
	occupy_tile(tile)
	for i in tile.occupier.size():
		tile.occupier[i]._tile = tile
	
	#Reset Boarding Counter when moving to an empty hex
	if self.occupied_tile.occupier.size() == 1:
		self._boardingCounter = 0
	#endregion
	
	var goal := global_position
	if first_drop or start.distance_squared_to(goal) < 0.01:
		aim_at_facing()
		return
	global_position = start
	aim_at_facing()
	_slide_goals.append(goal)
	if _sliding:
		return
	_sliding = true
	_play_slide()

func aim_at_facing() -> void:
	if occupied_tile == null:
		return
	var ahead := PhaseMovement.facing_world_delta(occupied_tile, _facing)
	if ahead.length_squared() < 0.001:
		return
	var target := global_position + ahead
	target.y = global_position.y
	look_at(target, Vector3.UP)
	rotate_object_local(Vector3.UP, PI * 0.5)

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

func _play_slide() -> void:
	if _slide_goals.is_empty():
		_sliding = false
		return
	var goal: Vector3 = _slide_goals.pop_front()
	_slide = create_tween()
	_slide.tween_property(self, "global_position", goal, 0.45).set_trans(Tween.TRANS_LINEAR)
	_slide.finished.connect(_play_slide)

func isTrireme() -> bool:
	if (object is Ship.Trireme):
		return true;
	
	return false;

func initialize(owner: Player, numOfDeckCrew: int = 10, numOfReserveRowers: int = 50,
	numOfArchers: int = 3, numOfJavelineers: int = 3, numOfSoldiers: int = 7,
	numOfEngineers: int = 3, numOfOarBanks: int = 50, rowersPerBank: int = 3,
	floatationHits: int = 12, mastHP: int = 4, beakHP: int = 1,
	hasBallista: bool = true, hasCatapult: bool = true, type: int = 1):
		object = Ship.Trireme.new(owner, numOfDeckCrew, numOfReserveRowers,
		numOfArchers, numOfJavelineers, numOfSoldiers, numOfEngineers,
		numOfOarBanks, rowersPerBank, floatationHits, mastHP, beakHP,
		hasBallista, hasCatapult, type);
