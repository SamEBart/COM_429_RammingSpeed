class_name Character;

# TYPE WILL CHANGE
var _owner: String;

func setOwner(owner: String):
	self._owner = owner;

func getOwner():
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
