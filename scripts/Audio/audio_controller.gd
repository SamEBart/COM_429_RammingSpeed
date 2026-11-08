extends Node

@export var mute: bool = false

var sound_library: Dictionary = {
	"combat_music":		preload("res://assets/Audio/CombatMusic.ogg"),
	"main_menu_music":	preload("res://assets/Audio/ram speedd music.ogg"),
	"500":				preload("res://assets/Audio/500_Cigarettes.mp3"),
}

var single = AudioStreamPlayer			#A single music track that will not loop
var looping = AudioStreamPlayer			#A single music track that will loop
var main = AudioStreamPlayer			#Main music, menu music

func _ready():
	single = AudioStreamPlayer.new()
	looping = AudioStreamPlayer.new()
	main = AudioStreamPlayer.new()

	add_child(single)
	add_child(looping)
	add_child(main)

func stop_sound(type: String, sound_name: String):
	match type:
		"single":
			single.stop()
		"looping":
			looping.stop()
		"main":
			main.stop()

func play_sound(type: String, sound_name: String, volume: float) -> void:
	if not mute:
		if sound_library.has(sound_name):
			match type:
				"single":
					_play(single, sound_name, volume)
				"looping":
					_play(looping, sound_name, volume)
				"main":
					_play(main, sound_name, volume)
		else:
			print("Sound not found in library: " + sound_name)

func play_sfx(sound_name: String, volume: float) -> void:
	if not mute:
		var player = AudioStreamPlayer.new()
		if sound_library.has(sound_name):
				_play(player, sound_name, volume)
		else:
			print("Sound not found in library: " + sound_name)

func _play(stream: AudioStreamPlayer, sound_name: String, volume: float):
	add_child(stream)
	stream.stream = sound_library[sound_name]
	stream.volume_db = volume
	stream.play()

func play_music(sound_name: String, volume: float, group_name: String):
	if not mute:
		if sound_library.has(sound_name):
			#If group exists and If player is in "all_music" or new group then don't add it again		
			var player = AudioStreamPlayer.new()
			player.stream = sound_library[sound_name]
			var sound = get_object_by_name_from_group(player, group_name)
			print("Sound was: ", sound)
			if get_tree().has_group(group_name) and sound:
				print("Sound has already been added!")
				player.queue_free()
				return
				
			#If sound is not in group then the make sound and add to the group
			add_child(player)
			player.volume_db = volume
			player.play()
			player.add_to_group(group_name)
			print("Successfully added!")
		else:
			print("Sound not found in library: " + sound_name)

func stop_music(sound_name: String, group_name: String):
	if not mute:
		if sound_library.has(sound_name):
			#If group exists
			if get_tree().has_group(group_name):
				#If sound is in group remove it
				var player = AudioStreamPlayer.new()
				player.stream = sound_library[sound_name]
				var sound = get_object_by_name_from_group(player, group_name)
				player.queue_free()
				if sound:
					sound.remove_from_group(group_name)
					sound.queue_free()
					print("Sound removed!\n")
				else:
					print(sound_name + " not found in " + group_name + ", please try again!")
			else:
				print(group_name + " could not be found, please try again!")
				
		else:
			print("Sound not found in library: " + sound_name)


func get_object_by_name_from_group(target: AudioStreamPlayer, group_name: String) -> Node:
	var members = get_tree().get_nodes_in_group(group_name)
	for member in members:
		if member is AudioStreamPlayer:
			print(str(member.stream) + " =? " + str(target.stream))
			if str(member.stream).get_slice("<", 0) == str(target.stream).get_slice("<", 0):
				return member # Returns the specific matching object
			
	return null # Returns null if no match is found
