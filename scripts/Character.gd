class_name Character;

var _owner: Player;
var _allocatedTo
var _isDead: bool = false

func setOwner(owner: Player):
	self._owner = owner;

func getOwner() -> Player:
	return _owner;

#region Deck Crew Class
class DeckCrew extends Character:
	var _isCommander;
	
	func _init(owner: Player, isCommander: bool = false):
		_owner = owner;
		_isCommander = isCommander;
	
	func promote():
		_isCommander = true;
	
	func demote():
		_isCommander = false;
#endregion

#region Rower Class
class Rower extends Character:
	var _exhaustion: float;
	
	func _init(owner: Player):
		_owner = owner;
		_exhaustion = 0.0;
	
	func getExaustion() -> float:
		return _exhaustion;
	
	# Might replace
	func setExhaustion(exhaustion: float):
		_exhaustion = exhaustion;
	
	# TODO: Add more functions depending on needs
#endregion

#region Marine Class
class Marine extends Character:
	# Possibly might change
	var _target: Character;
	var _roll: int;
	
	func getTarget() -> Character:
		return _target;
	
	func setTarget(target: Character):
		_target = target;
	
	#region Soldier Class
	class Soldier extends Marine:
		func _init(owner: Player):
			_owner = owner;
			_target = null;
			_roll = 0;
		
		func roll() -> int:
			# TODO: Finish function when dependencies are finished
			var roll = 0;
			
			#roll = Roll 1-6;
			
			_roll = roll;
			return roll;
	#endregion
	
	#region Archer Class
	class Archer extends Marine:
		var _isMelee: bool;
		
		func _init(owner: Player):
			_owner = owner;
			_target = null;
			_isMelee = false;
		
		func roll() -> int:
			var roll = 0;
			
			#if (_isMelee):
			#	roll = Roll 1-8;
			#else:
			#	roll = Roll 1-6;
			
			_roll = roll;
			return roll;
	#endregion
	
	#region Javelineer Class
	class Javelineer extends Marine:
		var _isMelee: bool;
		
		func _init(owner: Player):
			_owner = owner;
			_target = null;
			_isMelee = false;
		
		func roll() -> int:
			var roll = 0;
			
			#if (_isMelee):
			#	roll = Roll 1-8;
			#else
			#	roll = Roll 1-6;
			
			_roll = roll;
			return roll;
	#endregion
#endregion

#region Engineer Class
class Engineer extends Marine:
	var _isMelee: bool;
	
	func _init(owner: Player):
		_owner = owner;
		_target = null;
		_isMelee = false;
	
	func isMelee() -> bool:
		return _isMelee;
	
	func setMelee(isMelee: bool):
		_isMelee = isMelee;
	
	func roll() -> int:
		var roll = 0;
		
		#if (_isMelee):
		#	roll = Roll 1-8;
		
		_roll = roll;
		return roll;
#endregion
