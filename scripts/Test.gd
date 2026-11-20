extends Node

@export var runTests: bool = true;
var _warningList: Array[CheckResult.Warning];
var _errorList: Array[CheckResult.Error];
var _result: Array[CheckResult];

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
			["Player", testPlayer, [_player, _ship]],
			["Ship.Trireme", testTrireme, [_player, _ship]]
		];
		
		# Handles the tests; don't need to modify
		print("[Check] Running tests...");
		for t in tests.size():
			_result = [];

			print(
				"[Check] Checking %s... [%0.0f%%]" %
				[tests[t][0], ((t + 1.0) / tests.size()) * 100],
			);
			
			_result = tests[t][1].callv(tests[t][2]);
			for r in _result:
				if (r is CheckResult.Warning):
					_warningList.append(r);
					push_warning("[Warning] ", tests[t][0], ".", r.getContent());
				else:
					_errorList.append(r);
					push_error("[Error] ", tests[t][0], ".", r.getContent());
		
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
	if (player.getName() != "TestPlayer"):
		_result.append(CheckResult.Error.new(
			"getName: Expected \"TestPlayer\", but received \"%s\"." % player.getName()
		));
	
	if (player.getPlayerId() != 0):
		_result.append(CheckResult.Error.new(
			"getPlayerId: Expected 0, but received %d." % player.getPlayerId()
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

# Tests the Trireme class
func testTrireme(player: Player, ship: Ship) -> Array[CheckResult]:
	if (ship.getOwner() != player):
		_result.append(CheckResult.Error.new("getOwner: Failed to return the correct owner player."));

	_checkSize("getDeckCrew", 10, ship.getDeckCrew());
	_checkSize("getBanks", 50, ship.getBanks());
	_checkSize("getReserveRowers", 50, ship.getReserveRowers());
	_checkSize("getActiveRowers", 150, ship.getActiveRowers());
	
	if (ship.getBanks()[0] != ship.getBankFromRower(ship.getBanks()[0].getRowerArray()[0])):
		var rowerBank = ship.getBankFromRower(ship.getBanks()[0].getRowerArray()[0]);
		var bank = ship.getBanks().find(rowerBank);
		_result.append(CheckResult.Error.new("getBankFromRower: Expected the oar bank at index 0, but got %d." % bank));
	
	if (ship.getBanks()[5] != ship.getBankFromRower(ship.getBanks()[5].getRowerArray()[1])):
		var rowerBank = ship.getBankFromRower(ship.getBanks()[5].getRowerArray()[1]);
		var bank = ship.getBanks().find(rowerBank);
		_result.append(CheckResult.Error.new("getBankFromRower: Expected the oar bank at index 5, but got %d." % bank));
	
	if (ship.getBanks()[25] != ship.getBankFromRower(ship.getBanks()[25].getRowerArray()[2])):
		var rowerBank = ship.getBankFromRower(ship.getBanks()[25].getRowerArray()[2]);
		var bank = ship.getBanks().find(rowerBank);
		_result.append(CheckResult.Error.new("getBankFromRower: Expected the oar bank at index 25, but got %d." % bank));

	for i in ship.getBanks()[20].getRowerArray().size():
		ship.getBanks()[20].popRower(0);
	
	for i in ship.getBanks()[30].getRowerArray().size():
		ship.getBanks()[30].popRower(0);

	var vaccantBanks = ship.getVaccantBanks();
	if (vaccantBanks.size() != 2):
		_result.append(CheckResult.Error.new("getVaccantBanks: Expected an array size of 2, but got %d." % ship.getVaccantBanks().size()));
	elif (vaccantBanks[0] != ship.getBanks()[20]):
		_result.append(CheckResult.Error.new("getVaccantBanks: Unexpected bank at index 0."));
	elif (vaccantBanks[1] != ship.getBanks()[30]):
		_result.append(CheckResult.Error.new("getVaccantBanks: Unexpected bank at index 1."));

	_checkSize("getArchers", 3, ship.getArchers());
	_checkSize("getJavelineers", 3, ship.getJavelineers());
	_checkSize("getSoldiers", 7, ship.getSoldiers());
	_checkSize("getEngineers", 3, ship.getEngineers());

	return _result;

#region Shortcut Functions
## Checks if the size of an array matches with the expected result. Returns true if it matches.
## [br][param name]: The name of the function being checked.
## [br][param expected]: The expected size of the array.
## [br][param result]: The array being checked.
func _checkSize(name: String, expected: int, result: Array) -> bool:
	if (expected != result.size()):
		_result.append(CheckResult.Error.new("%s: Expected an array of size %d, but got %d." % [name, expected, result.size()]))
		return false;
	
	return true;
#endregion
