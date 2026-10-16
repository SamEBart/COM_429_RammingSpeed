extends Node3D

class_name Player;

var _name: String;
var _playerId: int;
# TYPE WILL CHANGE
var _ships: Array[Ship];
var _isSpectator: bool;

#Carter WIP
var _shipClicked: bool;					#Know when Player has a ship selected for an action
var _attacker: Player;					#Know who Player has selected for thier action, i.e. who is doing the firing in LRF
var _isReady: bool;						#Know when player is done with their turn/ready to start turn

func _init(name: String, playerId: int):
	_name = name;
	_playerId = playerId;
	_ships = [];
	_isSpectator = false;
	_shipClicked = false;
	_isReady = false;

func _ready() -> void:
	self.add_to_group("players")

func setName(name: String):
	_name = name;

func getName() -> String:
	return _name;

func getPlayerId() -> int:
	return _playerId;

func getOwnedShips() -> Array[Ship]:
	return _ships;

func appendShip(ship: Object):
	_ships.append(ship)

func removeShip(ship: Object):
	_ships.erase(ship);

func isSpectator() -> bool:
	return _isSpectator;

func becomeSpectator():
	_isSpectator = true;
