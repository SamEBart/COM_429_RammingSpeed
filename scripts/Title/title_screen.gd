extends Control
@onready var soq: VBoxContainer = $SOQ
@onready var options: Panel = $Options
@onready var setup: Panel = $SetUp
@onready var army_count: SpinBox = $SetUp/ArmyCount
@onready var player_count: SpinBox = $SetUp/PlayerCount
@onready var turn_limit: CheckButton = $SetUp/TurnLimit
@onready var turn_count: SpinBox = $SetUp/TurnLimit/TurnCount
@onready var difficulty: OptionButton = $SetUp/Difficulty


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	soq.visible = true
	options.visible = false
	setup.visible = false
	player_count.value = Global.humanPlayers
	army_count.value = Global.totalPlayers


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	soq.visible = false
	setup.visible = true


func _on_options_pressed() -> void:
	soq.visible = false
	options.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	soq.visible = true
	options.visible = false
	setup.visible = false


func _on_begin_pressed() -> void:
	if army_count.value >= player_count.value:
		Global.humanPlayers = player_count.value
		Global.totalPlayers = army_count.value
		Global.difficulty = difficulty.selected
		if turn_limit.button_pressed == true:
			Global.turnCap = turn_count.value
		get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
	else:
		print("Illegal")
