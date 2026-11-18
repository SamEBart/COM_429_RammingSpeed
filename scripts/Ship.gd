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
## 0 = archers, 1 = this ship's one siege weapon.
var _lrfMode: int = 0

#region Masts and Moving
## Index into HEX_DIR and the map's neighbor list. 0 is the first neighbor direction.
var _facing: int = 0
var _command_start_facing: int = 0
var _command_start_rowing: int = 0
const STEERING := &"steering"
const MAX_STEERING_CREW := 2
const MAST := &"mast"
const MAX_MAST_CREW := 1
const REPAIR := &"repair"
## Set when this ship shares a hex with an enemy. Later phases do not move it.
var _phase_move_stopped: bool = false
var _slide: Tween
var _slide_goals: Array[Vector3] = []
var _sliding: bool = false
## Set when a ship become stranded
var _stranded = false
var _help_stranded = true
var _stranded_phase: int
var _next_to_stranded_phase: int = 0
#endregion

#region Float, Mast, Beak, Ram, and Hole
var _type: int
var _flotationHits: int = 10
var _mastHP: int;
var _isMastUp: bool = true
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
var _inCollision: bool = false
var _killed_target = false
#endregion

## Reset stranded variables
func unstranded():
	_stranded = false
	_stranded_phase = 0
	_inCollision = false
	_speed = 0

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


## Keep both flags in sync. Combat charts read _isMastUp. Speed bonus reads _isMastDown.
func set_mast_down(down: bool) -> void:
	_isMastDown = down
	_isMastUp = not down


## Oar speed capped at 4. Mast down can raise overall speed to 6.
func get_overall_speed() -> int:
	return SpeedCalculator.overall_speed(_rowingSpeed, _isMastDown)


func get_facing_name() -> String:
	return HEX_DIR[posmod(_facing, HEX_DIR.size())]


## Steps facing by one hex side. Positive turns left. North turns toward Northwest.
func turn_facing(steps: int) -> void:
	_facing = posmod(_facing + steps, HEX_DIR.size())
	aim_at_facing()


## True for a living crew member who can take a job. The commander gives orders and never takes a job.
func _can_work(crew: Character) -> bool:
	if crew._isDead:
		return false
	return not (crew is Character.DeckCrew and crew._isCommander)


## How many members of list are doing job. Use null as the job to count the free ones.
func crew_on(list: Array, job) -> int:
	var count := 0
	for crew in list:
		if _can_work(crew):
			if typeof(crew._allocatedTo) == typeof(job) and crew._allocatedTo == job:
				count += 1
	return count


## Frees members of list from job, or gives job to free members, until count are on it.
## Stops early when nobody free is left.
func assign_crew(list: Array, job, count: int) -> void:
	for crew in list:
		if crew_on(list, job) <= count:
			break
		if _can_work(crew) and typeof(crew._allocatedTo) == typeof(job) and crew._allocatedTo == job:
			crew._allocatedTo = null
	for crew in list:
		if crew_on(list, job) >= count:
			break
		if _can_work(crew) and crew._allocatedTo == null:
			crew._allocatedTo = job


## Deck crew on the steering oars.
func steering_crew() -> int:
	return crew_on(_deckCrew, STEERING)


func set_steering(count: int) -> void:
	assign_crew(_deckCrew, STEERING, clampi(count, 0, MAX_STEERING_CREW))


## Deck crew working the mast. The mast can only go up or down with someone on it.
func mast_crew() -> int:
	return crew_on(_deckCrew, MAST)


func set_mast_crew(count: int) -> void:
	assign_crew(_deckCrew, MAST, clampi(count, 0, MAX_MAST_CREW))


## Engineers repairing the hull. They cannot work a weapon at the same time.
func repair_crew() -> int:
	return crew_on(_engineers, REPAIR)


func set_repair_crew(count: int) -> void:
	assign_crew(_engineers, REPAIR, maxi(count, 0))


## True while a living commander is aboard. Without one the ship cannot change speed, mast, or facing.
func has_commander() -> bool:
	for crew in _deckCrew:
		if crew._isCommander and not crew._isDead:
			return true
	return false


## Moves rowers between the reserve and the oar benches. Positive puts reserve rowers on empty seats,
## negative takes rowers off the benches back to the reserve. No rowers are created or removed.
func move_rowers(delta: int) -> void:
	for _i in absi(delta):
		if delta > 0:
			var bank := _bank_with_free_seat()
			if bank == null or _reserveRowers.is_empty():
				return
			bank._activeRowers.append(_reserveRowers.pop_back())
		else:
			var bank := _bank_with_rowers()
			if bank == null:
				return
			_reserveRowers.append(bank._activeRowers.pop_back())


## Seats on all living oar benches.
func rower_seats() -> int:
	var seats := 0
	for bank in _oarBanks:
		if not bank._isDead:
			seats += bank._maxRowers
	return seats


func _bank_with_free_seat() -> OarBank:
	for bank in _oarBanks:
		if not bank._isDead and not bank.isFull():
			return bank
	return null


func _bank_with_rowers() -> OarBank:
	for i in range(_oarBanks.size() - 1, -1, -1):
		var bank := _oarBanks[i]
		if not bank._isDead and bank._activeRowers.size() > 0:
			return bank
	return null


## Saves the facing and rowing speed this Command phase started with. Turning and speed limits are measured from them.
func begin_command() -> void:
	_command_start_facing = _facing
	_command_start_rowing = _rowingSpeed


## Rowing speed may only end Command inside this hull's band around the speed Command started with.
## Quadrireme: 1 up or 1 down. Trireme: 1 up or 2 down.
func can_change_speed_to(next_rowing: int) -> bool:
	var kind := get_ship_kind()
	var lowest := _command_start_rowing - SpeedCalculator.max_decrease(kind)
	var highest := _command_start_rowing + SpeedCalculator.max_increase(kind)
	return next_rowing >= lowest and next_rowing <= highest


## 2 steering crew turn freely. 1 may end Command one side away from the start facing. 0 cannot turn.
func can_turn_to(next_facing: int) -> bool:
	var crew := steering_crew()
	if crew >= MAX_STEERING_CREW:
		return true
	var away := posmod(next_facing - _command_start_facing, HEX_DIR.size())
	away = mini(away, HEX_DIR.size() - away)
	return away <= crew


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
	await _slide.finished
	#If Beach or Island modify ships position to fit on terrain
	if _tile.biome == "Beach" or _tile.biome == "Island":
		position.y += 0.35
		rotation_degrees.z += 10


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
	#If collision
	if _tile.occupier.size() > 1:
		occupier_placement(self, _tile, .75)


func help_stranded_ally(ship: Ship, phase: int):
	for tile in WorldMap.get_tile_neighbors(ship._tile):
		for boat in tile.occupier:
			print("\n%s is maybe helping %s" % [ship.name, boat.name])	
			print("%s| BP: %s | CP: %s" % [ship.name, boat._stranded_phase, phase])
			if boat._stranded and boat._owner == ship._owner and tile.occupier.size() == 1 and boat._stranded_phase != phase:
				#When a ship comes next to a stranded ship save it the next turn, not this one
				if ship._next_to_stranded_phase == 0:
					ship._next_to_stranded_phase = phase
				if ship._next_to_stranded_phase != phase:
					print("Helping")
					for newTile in WorldMap.get_tile_neighbors(boat._tile):
						if newTile.biome == "Ocean" and newTile.occupier.size() == 0:
							boat.place_unit(newTile.position, newTile)
							boat.unstranded()
							ship._speed = 0
							print("Helped!\n")
							return false


func clear_phase_move_stop() -> void:
	_phase_move_stopped = false


func _ready() -> void:
	add_to_group("ships")
	_attacker = self
	_speed = randi_range(0, 8)
	rotation_degrees.y = Global._hexUp


## Hex range for the LRF pick on the card. Archers 1. Ballista 1-4. Catapult 2-6.
func lrf_range() -> Vector2i:
	if _lrfMode == 0:
		return Vector2i(1, 1)
	if _ballista:
		return Vector2i(1, 4)
	if _catapult:
		return Vector2i(2, 6)
	return Vector2i(1, 1)


func has_living_engineer() -> bool:
	return _engineers.size() > 0


## Called after an LRF phase if this ship did not shoot its siege weapon.
func tick_weapon_reload() -> void:
	if _ballista:
		_ballista.tick_reload()
	elif _catapult:
		_catapult.tick_reload()

#region OarBank Class
class OarBank:
	var _maxRowers: int;
	var _activeRowers: Array[Character.Rower];
	var _health: int;
	var _owner: Player;
	var _isDead: bool = false
	
	func _init(owner: Player, maxRowers: int):
		_owner = owner;
		_maxRowers = maxRowers;
		
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
	
	func removeEngineer():
		if not _engineers.is_empty():
			var eng = _engineers.pop_back()
			if eng and is_instance_valid(eng):
				eng._allocatedTo = null
	
	func fire():
		_isLoaded = false
		_reloadTimer = 2
	
	func tick_reload() -> void:
		if _isLoaded:
			return
		_reloadTimer -= 1
		if _reloadTimer <= 0:
			_reloadTimer = 0
			_isLoaded = true
	
	func reload():
		tick_reload()
	
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
	
	func removeEngineer():
		if not _engineers.is_empty():
			var eng = _engineers.pop_back()
			if eng and is_instance_valid(eng):
				eng._allocatedTo = null
	
	func fire():
		_isLoaded = false
		_reloadTimer = 1
	
	func tick_reload() -> void:
		if _isLoaded:
			return
		_reloadTimer -= 1
		if _reloadTimer <= 0:
			_reloadTimer = 0
			_isLoaded = true
	
	func reload():
		tick_reload()
	
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
	return _ballista != null;
func getBallista() -> Ballista:
	return _ballista;
func hasCatapult() -> bool:
	return _catapult != null;
func getCatapult() -> Catapult:
	return _catapult;

# NEEDS TESTING: NOT CONFIDENT IF THIS WILL WORK.
# KILLING ACTIVE ROWERS NOT SUPPORTED YET.
func kill(target: Character):
	if target != null:
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
			if _ballista:
				_ballista._engineers.erase(target)
			if _catapult:
				_catapult._engineers.erase(target)
		else:
			assert(false, "Ship.kill: Function broke. Wow, such a suprise.");
func cleanup():
	_dead.clear();
#endregion

#region Trireme Class
## Placeholder until weapons are bought with points: Trireme spawns a ballista, no catapult.
class Trireme extends Ship:
	func get_ship_kind() -> SpeedCalculator.ShipKind:
		return SpeedCalculator.ShipKind.TRIREME
	
	func _setup(owner: Player, numOfDeckCrew: int = 10, numOfReserveRowers: int = 50,
	numOfArchers: int = 3, numOfJavelineers: int = 3, numOfSoldiers: int = 7,
	numOfEngineers: int = 5, numOfOarBanks: int = 50, rowersPerBank: int = 3,
	floatationHits: int = 12, mastHP: int = 4, beakHP: int = 1, beakHPMax: int = 1,
	hasBallista: bool = true, hasCatapult: bool = false, _type: int = 1):
		_owner = owner;
		
		for i in numOfDeckCrew:
			_deckCrew.push_back(Character.DeckCrew.new(owner, i == 0));
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
		
		## Only one siege weapon is created. The other stays null.
		_ballista = null;
		if (hasBallista):
			_ballista = Ballista.new();
		_catapult = null;
		if (hasCatapult):
			_catapult = Catapult.new();
		set_steering(MAX_STEERING_CREW)
		set_mast_crew(MAX_MAST_CREW)
#endregion

#region Quadrireme Class
## Same crew setup as a Trireme, bigger numbers. Placeholder weapon: catapult, no ballista.
class Quadrireme extends Trireme:
	func get_ship_kind() -> SpeedCalculator.ShipKind:
		return SpeedCalculator.ShipKind.QUADRIREME
	
	func _setup(owner: Player, numOfDeckCrew: int = 15, numOfReserveRowers: int = 50,
	numOfArchers: int = 4, numOfJavelineers: int = 4, numOfSoldiers: int = 12,
	numOfEngineers: int = 7, numOfOarBanks: int = 60, rowersPerBank: int = 4,
	floatationHits: int = 16, mastHP: int = 4, beakHP: int = 1, beakHPMax: int = 1,
	hasBallista: bool = false, hasCatapult: bool = true, _type: int = 1):
		super(owner, numOfDeckCrew, numOfReserveRowers, numOfArchers, numOfJavelineers,
		numOfSoldiers, numOfEngineers, numOfOarBanks, rowersPerBank, floatationHits, mastHP,
		beakHP, beakHPMax, hasBallista, hasCatapult, _type)
#endregion
