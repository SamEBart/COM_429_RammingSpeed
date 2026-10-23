extends Node

class_name PlayerUnit;

var object: Player;

func _ready() -> void:
	self.add_to_group("players")

func initiate(name: String, playerId: int) -> void:
	object = Player.new(name, playerId);
