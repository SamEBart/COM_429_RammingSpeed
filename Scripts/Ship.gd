extends Node3D

class_name Ship;

const HEX_DIR = [
	"up",			# ~0 deg
	"right_up",		# ~60 deg
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

var _owner: Player;
var _flotationHits: int;
var _mastHP: int;
var _beakHP: int;
var _rowingSpeed: int;
var _canLRF: bool;
var _boardingTarget: Ship;
var _isBoarding: bool;
var _oarBanks: Array[OarBank];
var _ballista: Ballista;
# TODO Catapult

var _attacker = self
var _enemyTarget: Ship

func _ready() -> void:
	pass

#region UNKNOWN IF NECESSARY
#fighters
#enemy_target_cell
#enemy_target
#boarding_action
#boarding_prepped
#boarding_archers
#boarding_javelins
#boarding_melee
#endregion

#region OarBank Class
class OarBank:
	var _maxRowers: int;
	var _activeRowers: Array[Character.Rower];
	var _health: int;
	var _owner: Player;
	
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
#endregion

#region Ballista Class
class Ballista:
	var _isLoaded: bool;
	var _reloadTimer: int;
	var _health: int;
	
	func _init():
		_isLoaded = true;
		_reloadTimer = 0;
		_health = 5;
	
	func reload():
		if (!_isLoaded):
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
func getMarines() -> Array[Character.Marine]:
	var array = []
	array.append(getArchers())
	array.append(getJavelineers())
	array.append(getSoldiers())
	return array

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
	else:
		assert(false, "Ship.kill: Function broke. Wow, such a suprise.");
func cleanup():
	_dead.clear();
#endregion

func _on_area_3d_input_event(camera, event, event_position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if ship has archers to use
		var clicker = get_viewport().get_camera_3d().get_parent().get_parent().get_parent().get_parent()
#		print(clicker._name, " and ", _owner._name)
		
		# Select who is doing firing
		if Global._action == 1 and clicker._shipClicked == false and clicker == _owner:
			clicker._shipClicked = true
			clicker._attacker = self
			print("Clicked: ", clicker._attacker.name, " (", clicker._name,") and can select LRF target!")
		
		#Don't fire onself
		elif Global._action == 1 and clicker._shipClicked == true and clicker == _owner:
			print("Same self bozo. Select new target to kill")
		
		#Don't select ship to action that you don't own
		elif Global._action == 1 and clicker._shipClicked == false and clicker != _owner:
			print("Not your ship to delegate!")
		
		#Select firing target
		elif Global._action == 1 and clicker._shipClicked == true and clicker != _owner:
			# Once the tiles are in check if enemy target is outside firing range
			clicker._attacker._enemyTarget = self
			print("Shooter: ", clicker._attacker.name, " is targetting: ", clicker._attacker._enemyTarget.name)
			# Reset
			clicker._shipClicked = false
			


#region Trireme Class
class Trireme extends Ship:
	func _setup(owner: Player, numOfDeckCrew: int = 10, numOfReserveRowers: int = 50,
	numOfArchers: int = 3, numOfJavelineers: int = 3, numOfSoldiers: int = 7,
	numOfEngineers: int = 3, numOfOarBanks: int = 50, rowersPerBank: int = 3,
	floatationHits: int = 12, mastHP: int = 4, beakHP: int = 1, hasBallista: bool = true):
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
		
		_flotationHits = floatationHits;
		_mastHP = mastHP;
		_beakHP = beakHP;
		_dead = [];
		
		_ballista = null;
		if (hasBallista):
			_ballista = Ballista.new();
#endregion
