extends Node3D

class_name Player;

var _name: String;
var _playerId: int;
# TYPE WILL CHANGE
var _ships: Array[Object];
var _isSpectator: bool;

#Carter WIP
var _shipClicked = false
var _attacker

func initiate(name: String, playerId: int):
	_name = name;
	_playerId = playerId;
	_isSpectator = false;

func setName(name: String):
	_name = name;

func getName() -> String:
	return _name;

func getPlayerId() -> int:
	return _playerId;

func getOwnedShips() -> Array[Object]:
	return _ships;

func appendShip(ship: Object):
	_ships.append(ship)

func removeShip(ship: Object):
	_ships.erase(ship);

func isSpectator() -> bool:
	return _isSpectator;

func becomeSpectator():
	_isSpectator = true;
