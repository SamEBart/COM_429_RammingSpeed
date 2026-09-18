class_name Character;

# TYPE WILL CHANGE
var _owner: String;

func setOwner(owner: String):
	self._owner = owner;

func getOwner() -> String:
	return _owner;

#region Deck Crew Class
class DeckCrew extends Character:
	var _isCommander;
	
	func _init(owner: String, isCommander: bool = false):
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
	
	func _init(owner: String):
		_owner = owner;
		_exhaustion = 0.0;
	
	func getExaustion() -> float:
		return _exhaustion;
#endregion
