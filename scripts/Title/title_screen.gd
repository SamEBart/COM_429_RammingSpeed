extends Control
@onready var soq: VBoxContainer = $SOQ
@onready var options: Panel = $Options
@onready var setup: Panel = $SetUp
@onready var army_count: SpinBox = $SetUp/ArmyCount
@onready var player_count: SpinBox = $SetUp/PlayerCount


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	soq.visible = true
	options.visible = false
	setup.visible = false


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
		get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
	else:
		print("Illegal")
