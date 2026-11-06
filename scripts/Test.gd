extends Node

@export var runTests: bool = true;
var _warningList: Array[CheckResult.Warning];
var _errorList: Array[CheckResult.Error];

func _ready() -> void:
	if (runTests):
		# Initializes required objects
		var _player = Player.new();
		_player.initiate("TestPlayer", 0, false);
		var _ship = Ship.Trireme.new();
		_ship._setup(_player);
		
		_player.appendShip(_ship);
		
		# Declares the tests to be run.
		# Format: [
		#	 [name, callable for desired function, [...args]]
		# ]
		var tests = [
			["Player", Callable(testPlayer), [_player, _ship]]
		];
		
		# Handles the tests; don't need to modify
		print("[Check] Running tests...");
		for t in tests.size():
			var result: Array[CheckResult] = [];
			
			print(
				"[Check] Checking %s... [%0.0f%%]" %
				[tests[t][0], ((t + 1) / tests.size()) * 100]
			);
			
			result = tests[t][1].callv(tests[t][2]);
			for r in result:
				if (r is CheckResult.Warning):
					_warningList.append(r);
				else:
					_errorList.append(r);
			
			for w in _warningList:
				push_warning("[Warning] ", w.getContent());
			for e in _errorList:
				push_error("[Error] ", e.getContent());
		
		if (_warningList.size() == 0):
			assert(_errorList.size() == 0,
			"Tests failed with %d errors." % _errorList.size());
			print("All tests completed successfully.")
		else:
			assert(_errorList.size() == 0,
			"Tests failed with %d errors and %d warnings." % [_errorList.size(), _warningList.size()]);
			print("Tests completed successfully with %d warnings." % _warningList.size());
		
		
# CheckResult.Warning.new(content) for warning
# CheckResult.Error.new(content) for error
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

# Tests the Player class
func testPlayer(player: Player, ship: Ship) -> Array[CheckResult]:
	var _result: Array[CheckResult] = [];
	
	if (player.getName() != "TestPlayer"):
		_result.append(CheckResult.Error.new(
			"getName: Expected \"TestPlayer\", but received \"%s\"." % player.getName()
		));
	
	if (player.getPlayerId() != 0):
		_result.append(CheckResult.Error.new(
			"getPlayerId: Expected 0, but received %d." %  player.getPlayerId()
		));
	
	if (player.getOwnedShips()[0] != ship):
		_result.append(CheckResult.Error.new(
			"getOwnedShips: Failed to recieve the expected ship."
		));
	
	if (player.isSpectator() != false):
		_result.append(CheckResult.Error.new(
			"isSpectator: Expected false, but got true."
		));
	
	var _newPlayer = Player.new();
	_newPlayer.initiate("NewPlayer", 1, false);
	_newPlayer.appendShip(ship);
	_newPlayer.removeShip(ship);
	
	if (_newPlayer.getOwnedShips().size() != 0):
		_result.append(CheckResult.Error.new(
			"removeShip: Failed to remove ship from array."
		));
	
	return _result;
