class_name Player;

var _name: String;
var _playerId: int;
# TYPE WILL CHANGE
var _ships: Array[Object];
var _isSpectator: bool;

func _init(name: String, playerId: int, ownedShips: Array[Object]):
	_name = name;
	_playerId = playerId;
	_ships = ownedShips;
	_isSpectator = false;

func setName(name: String):
	_name = name;

func getName() -> String:
	return _name;

func getPlayerId() -> int:
	return _playerId;

func getOwnedShips() -> Array[Object]:
	return _ships;

func removeShip(ship: Object):
	_ships.erase(ship);

func isSpectator() -> bool:
	return _isSpectator;

func becomeSpectator():
	_isSpectator = true;
