extends Node

@export var runTests: bool = true;
var _warningList: CheckResult.Warning;
var _errorList: CheckResult.Error;

func _ready() -> void:
	if (runTests):
		var _player = Player.new("TestPlayer", 0, false);
		var _ship = Ship.Trireme.new(_player);
		var tests = [
			["Player", Callable(testPlayer), [_player, _ship]]
		];
		
		_player.appendShip(_ship);
		
		print("[Check] Running checks...");
		for t in tests.size():
			print(
				"[Check] Checking %s... [%0.0f%]" %
				[tests[t][0], (t + 1) / tests.size()]
			);
			
			tests[t][1].callv(tests[t][2]);

class CheckResult:
	var _content: String;
	
	func getContent() -> String:
		return _content;
	
	class Warning extends CheckResult:
		func _init(content: String) -> void:
			_content = content;
	
	class Error extends CheckResult:
		func _init(content: String) -> void:
			_content = content;

func testPlayer(player: Player, ship: Ship) -> Array[CheckResult]:
	var _result: Array[CheckResult] = [];
	
	if (player.getName() != "TestPlayer"):
		_result.push_back(CheckResult.Error.new(
			"getName: Expected \"TestPlayer\", but received \"%s\"." % player.getName()
		));
	
	if (player.getPlayerId() != 0):
		_result.push_back(CheckResult.Error.new(
			"getPlayerId: Expected 0, but received %d." %  player.getPlayerId()
		));
	
	if (player.getOwnedShips()[0] != ship):
		_result.push_back(CheckResult.Error.new(
			"getOwnedShips: Failed to recieve the expected ship."
		));
	
	if (player.isSpectator() != false):
		_result.push_back(CheckResult.Error.new(
			"isSpectator: Expected false, but got true."
		));
	
	var _newPlayer = Player.new("NewPlayer", 1, false);
	_newPlayer.appendShip(ship);
	_newPlayer.removeShip(ship);
	
	if (_newPlayer.getOwnedShips().size() != 0):
		_result.push_back(CheckResult.Error.new(
			"removeShip: Failed to remove ship from array."
		));
	
	return _result;
