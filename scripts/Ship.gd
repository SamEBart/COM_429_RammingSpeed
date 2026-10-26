extends Unit

class_name Ship;

const HEX_DIR = [
	"up",			# ~0 deg
	"right_up",		# ~60deg
	"right_down",	# ~120 deg
	"down",			# ~180 deg
	"left_down",	# ~240 deg
	"left_up"		# ~300 deg
];

var _deckCrew: Array[Character.DeckCrew];
var _activeRowers: Array[Character.Rower];
var _reserveRowers: Array[Character.Rower];
var _marineArchers: Array[Character.Marine.Archer];
var _marineJavelineers: Array[Character.Marine.Javelineer];
var _marineSoldiers: Array[Character.Marine.Soldier];
var _engineers: Array[Character.Engineer];
var _dead: Array[Character];
var _deadOars: Array[OarBank];

var _owner: Player;
var _rowingSpeed: int;
var _canLRF: bool;
var _oarBanks: Array[OarBank];
var _ballista: Ballista;
var _catapult: Catapult;

var _speed: int
var _tile: Tile
var _attacker = self
var _enemyTarget: Ship
var _ballistaTargetRange: int
var _catapultTargetRange: int
var _inCollision: bool = false

## Index into HEX_DIR and the map's neighbor list. 0 is the first neighbor direction.
var _facing: int = 0
## Set when this ship shares a hex with an enemy. Later phases do not move it.
var _phase_move_stopped: bool = false
var _slide: Tween
var _slide_goals: Array[Vector3] = []
var _sliding: bool = false

#region Float, Mast, Beak, Ram, and Hole
var _type: int
var _flotationHits: int;
var _mastHP: int;
var _isMastUp: bool = false
var _isMastDown: bool = false
var _mastTimer: int = 0
var _beakHP: int;
var _beakHPMax: int
var _holes: int
var _ramAction: int = 0					#1 if ram, 2 is avoid
#endregion

#region Boarding
var _boardingCounter: int = 0			#Used to determine if inn first ever boarding action for ths ship
var _inBoarding: bool = false
var _boardingPrepped: bool = false
var _boardingTarget: Ship;
var _fighters = []
var _boardingArchers = []
var _boardingJavelins = []
var _boardingMelee = []
#endregion

## Quadrireme speed changes are +1 or -1.
func get_ship_kind() -> SpeedCalculator.ShipKind:
	return SpeedCalculator.ShipKind.QUADRIREME


## Changes rowing speed when the change is legal for this ship.
## A Quadrireme may change by +1 or -1. A Trireme may change by +1 or -2.
func adjust_rowing_speed(delta: int) -> bool:
	if not SpeedCalculator.adjustment_allowed(delta, get_ship_kind()):
		return false
	_rowingSpeed = SpeedCalculator.apply_rowing_adjustment(_rowingSpeed, delta, get_ship_kind())
	return true


func set_mast_down(down: bool) -> void:
	_isMastDown = down


## Oar speed capped at 4. Mast down can raise overall speed to 6.
func get_overall_speed() -> int:
	return SpeedCalculator.overall_speed(_rowingSpeed, _isMastDown)


func get_facing_name() -> String:
	return HEX_DIR[posmod(_facing, HEX_DIR.size())]


## Steps facing by one hex side. Positive turns left. North turns toward Northwest.
func turn_facing(steps: int) -> void:
	_facing = posmod(_facing + steps, HEX_DIR.size())
	aim_at_facing()


func place_unit(new_position : Vector3, tile):
	var start := global_position
	var first_drop := occupied_tile == null
	super.place_unit(new_position, tile)
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


func _play_slide() -> void:
	if _slide_goals.is_empty():
		_sliding = false
		return
	var goal: Vector3 = _slide_goals.pop_front()
	_slide = create_tween()
	_slide.tween_property(self, "global_position", goal, 0.45).set_trans(Tween.TRANS_LINEAR)
	_slide.finished.connect(_play_slide)


## The hull's bow is the ship's local +X. look_at aims local -Z, then a quarter turn brings the bow onto that hex.
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


func clear_phase_move_stop() -> void:
	_phase_move_stopped = false


func _ready() -> void:
	add_to_group("ships")
	_attacker = self
	_ballista = Ballista.new()
	_catapult = Catapult.new()
	_speed = randi_range(0, 8)
	rotation_degrees.y = Global._hexUp

#region OarBank Class
class OarBank:
	var _maxRowers: int;
	var _activeRowers: Array[Character.Rower];
	var _health: int;
	var _owner: Player;
	var _isDead: bool = false
	
	func _init(owner: Player, maxRowers: int):
		_owner = owner;
		
		_activeRowers = [];
		for i in maxRowers:
			_activeRowers.push_back(Character.Rower.new(_owner));
	
	func getMaxRowers() -> int:
		return _maxRowers;
	
	func getMissingRowers() -> int:
		return _activeRowers.size();
	
	func getRowerArray() -> Array[Character.Rower]:
		return _activeRowers;
	
	func pushRower(rower: Character.Rower):
		assert(_activeRowers.size() < _maxRowers, 
		"Oar Bank already has enough rowers allocated! Check code!")
		
		_activeRowers.push_back(rower);
	
	func popRower(index: int) -> Character.Rower:
		assert(index >= _activeRowers.size(),
		"No Rower exists at index %d. Check code!" % index);
		
		return _activeRowers.pop_at(index);
	
	func isFull() -> bool:
		return _activeRowers.size() == _maxRowers;
	
	func removeBank(target: Ship):
		if !_isDead:
			_isDead = true
			for j in _activeRowers.size():
				var guy = _activeRowers[j]
				guy._isDead = true
				target._dead.append(guy)
#endregion

#region Ballista Class
class Ballista:
	var _isLoaded: bool;
	var _reloadTimer: int;
	var _health: int;
	var _engineers: Array[Character.Engineer];
	
	func _init():
		_isLoaded = true;
		_reloadTimer = 0;
		_health = 5;
	
	func allocateEngineer(ship: Ship):
		for eng in ship._engineers:
			if eng._allocatedTo == null:
				eng._allocatedTo = ship._ballista
				self._engineers.append(eng)
				return
	
	func fire():
		_reloadTimer = 0
		_isLoaded = false
	
	func reload():
		if (!_isLoaded):
			for eng in _engineers:
				if eng._allocatedTo == self:
					_reloadTimer += 1;
			
			if (_reloadTimer >= 8):
				_reloadTimer = 0;
				_isLoaded = true;
	
	func isLoaded() -> bool:
		return _isLoaded;
	
	func getHealth() -> int:
		return _health;
	
	func damage(damage: int) -> int:
		_health -= damage;
		if (_health < 0):
			_health = 0;
		
		return _health;
	
	func isBroken() -> bool:
		return _health == 0;
#endregion

#region Catapult Class
class Catapult:
	var _isLoaded: bool;
	var _reloadTimer: int;
	var _health: int;
	var _engineers: Array[Character.Engineer];
	
	func _init():
		_isLoaded = true;
		_reloadTimer = 0;
		_health = 5;
	
	func allocateEngineer(ship: Ship):
		for eng in ship._engineers:
			if eng._allocatedTo == null:
				eng._allocatedTo = ship._catapult
				self._engineers.append(eng)
				return
	
	func fire():
		_reloadTimer = 0
		_isLoaded = false
	
	func reload():
		if (!_isLoaded):
			for eng in _engineers:
				if eng._allocatedTo == self:
					_reloadTimer += 1;
			
			if (_reloadTimer >= 24):
				_reloadTimer = 0;
				_isLoaded = true;
	
	func isLoaded() -> bool:
		return _isLoaded;
	
	func getHealth() -> int:
		return _health;
	
	func damage(damage: int) -> int:
		_health -= damage;
		if (_health < 0):
			_health = 0;
		
		return _health;
	
	func isBroken() -> bool:
		return _health == 0;
#endregion

#region Parent Functions
func getOwner() -> Player:
	return _owner;
func getDeckCrew() -> Array[Character.DeckCrew]:
	return _deckCrew;
func getReserveRowers() -> Array[Character.Rower]:
	return _reserveRowers;
func getBanks() -> Array[OarBank]:
	return _oarBanks;
func getActiveRowers() -> Array[Character.Rower]:
	var rowers: Array[Character.Rower] = [];
	for b in _oarBanks:
		for r in b.getRowerArray():
			rowers.push_back(r);
	
	return rowers;

# NEEDS TESTING: MIGHT NOT WORK.
func getBankFromRower(rower: Character.Rower) -> OarBank:
	for b in _oarBanks:
		if (b.getRowerArray().find(rower) >= 0):
			return b;
	
	push_warning("Ship.getBankFromRower: Failed to retrieve OarBank from specified Rower.");
	return null;

func getVaccantBanks() -> Array[OarBank]:
	var banks: Array[OarBank] = [];
	for b in _oarBanks:
		if (!b.isFull()):
			banks.push_back(b);
	
	return banks;

func getArchers() -> Array[Character.Marine.Archer]:
	return _marineArchers;
func getJavelineers() -> Array[Character.Marine.Javelineer]:
	return _marineJavelineers;
func getSoldiers() -> Array[Character.Marine.Soldier]:
	return _marineSoldiers;
func getEngineers() -> Array[Character.Engineer]:
	return _engineers;
func getFloatationHits() -> int:
	return _flotationHits;
func damageShip(damage: int):
	_flotationHits -= damage;
	if (_flotationHits < 0):
		_flotationHits = 0;

func hasBallista() -> bool:
	return _ballista == null;
func getBallista() -> Ballista:
	return _ballista;
func hasCatapult() -> bool:
	return _catapult == null;
func getCatapult() -> Catapult:
	return _catapult;

# NEEDS TESTING: NOT CONFIDENT IF THIS WILL WORK.
# KILLING ACTIVE ROWERS NOT SUPPORTED YET.
func kill(target: Character):
	if (target is Character.DeckCrew):
		_dead.push_back(target);
		_deckCrew.erase(target);
	elif (target is Character.Rower):
		_dead.push_back(target);
		_reserveRowers.erase(target);
	elif (target is Character.Marine.Archer):
		_dead.push_back(target);
		_marineArchers.erase(target);
	elif (target is Character.Marine.Javelineer):
		_dead.push_back(target);
		_marineJavelineers.erase(target);
	elif (target is Character.Marine.Soldier):
		_dead.push_back(target);
		_marineSoldiers.erase(target);
	elif (target is Character.Engineer):
		_dead.push_back(target);
		_engineers.erase(target);
		_ballista._engineers.erase(target)
		_catapult._engineers.erase(target)
	else:
		assert(false, "Ship.kill: Function broke. Wow, such a suprise.");
func cleanup():
	_dead.clear();
#endregion

#region Trireme Class
class Trireme extends Ship:
	func _setup(owner: Player, numOfDeckCrew: int = 10, numOfReserveRowers: int = 50,
	numOfArchers: int = 3, numOfJavelineers: int = 3, numOfSoldiers: int = 7,
	numOfEngineers: int = 3, numOfOarBanks: int = 50, rowersPerBank: int = 3,
	floatationHits: int = 12, mastHP: int = 4, beakHP: int = 1, beakHPMax: int = 1,
	hasBallista: bool = true, hasCatapult: bool = true, _type: int = 1):
		_owner = owner;
		
		for i in numOfDeckCrew:
			_deckCrew.push_back(Character.DeckCrew.new(owner));
		for i in numOfReserveRowers:
			_reserveRowers.push_back(Character.Rower.new(owner));
		for i in numOfArchers:
			_marineArchers.push_back(Character.Marine.Archer.new(owner));
		for i in numOfJavelineers:
			_marineJavelineers.push_back(Character.Marine.Javelineer.new(owner));
		for i in numOfSoldiers:
			_marineSoldiers.push_back(Character.Marine.Soldier.new(owner));
		for i in numOfEngineers:
			_engineers.push_back(Character.Engineer.new(owner));
		for i in numOfOarBanks:
			_oarBanks.push_back(OarBank.new(owner, rowersPerBank));
		
		_fighters.append_array(_marineSoldiers)
		_fighters.append_array(_marineJavelineers)
		_fighters.append_array(_marineArchers)
		_fighters.append_array(_engineers)
		_fighters.append_array(_deckCrew)
		
		_flotationHits = floatationHits;
		_mastHP = mastHP;
		_beakHP = beakHP;
		_dead = [];
		
		_ballista = null;
		if (hasBallista):
			_ballista = Ballista.new();
		_catapult = null;
		if (hasCatapult):
			_catapult = Catapult.new();
#endregion
