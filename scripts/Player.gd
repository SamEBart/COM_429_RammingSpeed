extends Node3D

class_name Player;

var _name: String;
var _playerId: int;
# TYPE WILL CHANGE
var _ships: Array[Object];
var _isSpectator: bool;

#Carter WIP
var _shipClicked = false				#Know when Player has a ship selected for an action
var _attacker							#Know who Player has selected for thier action, i.e. who is doing the firing in LRF
var _isReady = false					#Know when player is done with their turn/ready to start turn

func _ready() -> void:
	self.add_to_group("players")

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
