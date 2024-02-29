extends Node2D

enum Menu {
	VOICES,
#	MUSIC,
	AMBIENCE,
	SOUND_EFFECTS,
	DEFAULT,
	QUIT,
}

var menu_callable := {
	Menu.VOICES : Callable(change_volume.bind("Voices")),
#	Menu.MUSIC : Callable(change_volume.bind("Music")),
	Menu.AMBIENCE : Callable(change_volume.bind("Ambience")),
	Menu.SOUND_EFFECTS : Callable(change_volume.bind("SoundEffects")),
	Menu.DEFAULT : Callable(select_default),
	Menu.QUIT : Callable(select_return),
}

var voice_describe := {
	"Ambience" : load("res://sounds/voice_resources/audio_settings/ambience_volume.mp3"),# Change my voice volume.
#	"Music" : load("res://sounds/voice_resources/audio_settings/music_volume.mp3"),# Change the music volume
	"SoundEffects" : load("res://sounds/voice_resources/audio_settings/sound_effects_volume.mp3"),# Change the ambience volume
	"Voices" : load("res://sounds/voice_resources/audio_settings/voice_volume.mp3"), # Change the sound effects volume
	"Default" : load("res://sounds/voice_resources/audio_settings/default.mp3"), # Reset the volume level for all sounds.
	"Quit" : load("res://sounds/voice_resources/audio_settings/return.mp3"),# go back to fishing
}


var sound_selected := {
	"Ambience" : load("res://sounds/ambience/pond_night_2sec.mp3"),
	"SoundEffects" : load("res://sounds/effects/rod_damage_crack.tres"),
	"Voices" : load("res://sounds/voice_resources/audio_settings/voice_volume.mp3"),
#	"Music" : load(),
}


var default := {
	"Ambience" : -5.0,
	"Music" : 0.0,
	"SoundEffects" : 0.0,
	"Voices" : 0.0,
	"Misc" : 0.0,
}

var menu_to_string := {
	Menu.VOICES : "Voices",
#	Menu.MUSIC : "Music",
	Menu.AMBIENCE : "Ambience",
	Menu.SOUND_EFFECTS : "SoundEffects",
	Menu.DEFAULT : "Default",
	Menu.QUIT : "Quit",
}

var current_menu: Menu = Menu.VOICES
var menu_size: int:
	get:
		return get_menu_size()

var voice_intro := load("res://sounds/voice_resources/audio_settings/intro.mp3") # Here, you can adjust the volume of my voice.
var voice_help := load("res://sounds/voice_resources/audio_settings/help.mp3") # Press "left" to change the volume, press "right" to choose other options.
var voice_default_selected := load("res://sounds/voice_resources/audio_settings/default_selected.mp3") # Every volume level is reset.

var intro := true

func _ready():
	Sound.stop_ambience()
	scene_intro()


func _unhandled_input(event):
	# if it's the main menu intro, only stop the voice and explain the current menu.
	if intro and (event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top")):
		Sound.stop_voice_array_and_queue()
		Sound.all_voices_finished.emit()
		describe_menu_item(current_menu)
	# after the intro played/skipped, use those inputs.
	else:
		if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
			Sound.stop_voice_array_and_queue()
		if event.is_action_pressed("left"):
			select_menu_item(current_menu)
		if event.is_action_pressed("right"):
			iterate_through_menu()
			describe_menu_item(current_menu)


func change_volume(bus_name: String):
	for child in Sound.get_children():
		child.stop()
	var levels := [-20.0,-10.0, -5.0, 0.0, 5.0]
	var index = AudioServer.get_bus_index(bus_name)
	if index != -1:
		var current_volume := AudioServer.get_bus_volume_db(index)
		var levels_index := levels.find(current_volume)
		# if the current volume is in the index and not the higher value, increment the volume
		if levels_index != -1 and levels_index + 1 < levels.size():
			AudioServer.set_bus_volume_db(index, levels[levels_index + 1])
			if levels_index + 1 == levels.size() - 1:
				Sound.play_voice(load("res://sounds/voice_resources/audio_settings/set_to_max.mp3"))
				await Sound.all_voices_finished
			if levels_index + 1 == 3:
				Sound.play_voice(load("res://sounds/voice_resources/audio_settings/set_to_def.mp3"))
				await Sound.all_voices_finished
		# if the current volume is in the index and the higher value, go back to lowest value.
		elif levels_index != -1 and levels_index + 1 == levels.size():
			AudioServer.set_bus_volume_db(index, levels[0])
			Sound.play_voice(load("res://sounds/voice_resources/audio_settings/set_to_min.mp3"))
			await Sound.all_voices_finished
		# if the current volume is not in the index, set it to delfault.
		else:
			AudioServer.set_bus_volume_db(index, default[bus_name])
	else:
		assert(false, "audio_settings.gd, change _volume(), error unknown bus_name: " + bus_name)
	if current_menu == Menu.AMBIENCE:
		Sound.stop_ambience()
		Sound.play_ambience(sound_selected[bus_name])
	elif current_menu == Menu.SOUND_EFFECTS:
		Sound.stop_se()
		Sound.play_se(sound_selected[bus_name])
#	elif current_menu == Menu.MUSIC:
#		Sound.play_music(sound_selected[bus_name])
	else: #current_menu == Menu.VOICE:
		Sound.stop_voice_array_and_queue()
		Sound.play_voice(sound_selected[bus_name])
	Saves.audio = AudioServer.generate_bus_layout()
	Saves.save_game()


func select_default():
	for bus_name in default.keys():
		var index = AudioServer.get_bus_index(bus_name)
		if index != -1:
			AudioServer.set_bus_volume_db(index, default[bus_name])
		else:
			assert(false, "audio_settings.gd, select_default(), error unknown bus_name: " + bus_name)
	Sound.play_voice(voice_default_selected)
	Saves.audio = AudioServer.generate_bus_layout()
	Saves.save_game()


func select_return():
	Signals.scene_requested.emit("main_menu")


func scene_intro():
	Sound.play_voice(voice_intro)
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(voice_help)
	Sound.all_voices_finished.connect(set_intro.bind(false))


func describe_menu_item(item: Menu):
	var item_string: String = menu_to_string[item]
	Sound.play_voice(voice_describe[item_string])
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(voice_help)


func select_menu_item(item: Menu):
	var callable: Callable = menu_callable[item]
	callable.call()


func set_intro(setter: bool):
	if Sound.all_voices_finished.is_connected(set_intro.bind(false)):
		Sound.all_voices_finished.disconnect(set_intro.bind(false))
	intro = setter

func iterate_through_menu():
	current_menu = (current_menu + 1) % menu_size


func get_menu_size() -> int:
	var index = 0
	for item in Menu:
		index += 1
	return index
