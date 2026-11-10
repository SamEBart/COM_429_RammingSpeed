extends Node

@export var mute: bool = false

var sound_library: Dictionary = {
	"combat_music":		preload("res://assets/Audio/CombatMusic.ogg"),
	"main_menu_music":	preload("res://assets/Audio/ram speedd music.ogg"),
#	"___":	preload("res://assets/Audio/___"),
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


func play_sfx(sound_name: String, volume: float) -> void:
	if not mute:
		if sound_library.has(sound_name):
				var player = AudioStreamPlayer.new()
				player.stream = sound_library[sound_name]
				var sound = get_object_from_group(player, "all_sounds")
				#If sound is not in "all_sound" group it may be played. This is to prevent overalpping sound effects
				if !sound:
					add_child(player)
					player.add_to_group("all_sounds")
					player.stream = sound_library[sound_name]
					player.volume_db = volume
					
					#To-do when finishes playing sound
					player.finished.connect(player.remove_from_group.bind("all_sounds"))
					player.finished.connect(player.queue_free)
					player.finished.connect(print.bind("Sound finished. Sound size: ", get_tree().get_nodes_in_group("all_sounds").size() ) )
					
					#Play Sound
					player.play()
				
				#Remove player as it does not need to exist as sound alreayd exists
				else:
					print("Sound has already been added!")
					player.queue_free()
		else:
			print("Sound not found in library: " + sound_name)


func play_music(sound_name: String, volume: float, group_name: String):
	if not mute:
		if sound_library.has(sound_name):
			#If group exists and If player is in "all_music" or new group then don't add it again		
			var player = AudioStreamPlayer.new()
			player.stream = sound_library[sound_name]
			var sound = get_object_from_group(player, group_name)
			if get_tree().has_group(group_name) and sound:
				print(sound_name + " has already been added!")
				player.queue_free()
				return
				
			#If sound is not in group then the make sound and add to the group
			add_child(player)
			player.volume_db = volume
			player.play()
			player.add_to_group(group_name)
			player.add_to_group("all_sounds")
			print("Successfully added " + sound_name + "!")
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
				var sound = get_object_from_group(player, group_name)
				player.queue_free()
				if sound:
					sound.remove_from_group(group_name)
					sound.remove_from_group("all_sounds")
					sound.queue_free()
					print(sound_name + "removed!\n")
				else:
					print(sound_name + " not found in " + group_name + ", please try again!")
			else:
				print(group_name + " could not be found, please try again!")
				
		else:
			print("Sound not found in library: " + sound_name)


func get_object_from_group(target: AudioStreamPlayer, group_name: String) -> Node:
	var members = get_tree().get_nodes_in_group(group_name)
	for member in members:
		if member is AudioStreamPlayer:
			if str(member.stream).get_slice("<", 0) == str(target.stream).get_slice("<", 0):
				return member # Returns the specific matching object
			
	return null # Returns null if no match is found
