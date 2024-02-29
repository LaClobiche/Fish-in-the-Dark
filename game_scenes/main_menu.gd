extends Node2D


enum Menu { # "Night has fallen and you're sitting in front of a mysterious pond. You intend to start fishing. You want to start fishing.You're ready to/ You're eager to/ You're set to/ You're prepared to start fishing"
	START_FISHING,  # "start fishing" -> (help) -> "let's get some fish in the dark!"
	FISH_ALMANAC, # "Open your fish almanac" -> (help) -> open fish_alamanac_scene -> open_book sound effect 
	SCORE_BOARD, # "Open your score board" -> (help)  -> open score_board_scene -> open_book sound effect
	TOGGLE_HELP, # "Enable/disable game controls & contextual help." -> (help) ->  open toggle_help_scene ->Disabled/Enabled
	AUDIO_SETTINGS, # "Adjust the audio for the best fishing experience." -> (help) -> open audio_settings_scene -> open_book sound effect 
	CREDITS, # "Listen to the credits" -> (help) -> open credits_scene -> open_book sound effect 
	QUIT, # "Leave" -> (help) -> # sound effect "walk_out" -> quit_game
}

var scenes :={
	Menu.START_FISHING : "fishing_run",
	Menu.SCORE_BOARD : "score_board",
	Menu.FISH_ALMANAC : "fish_almanac",
	Menu.TOGGLE_HELP : "toggle_help",
	Menu.AUDIO_SETTINGS : "audio_settings",
	Menu.CREDITS : "credits",
	Menu.QUIT : "quit",
}

var voice_describe := {
	Menu.START_FISHING : load("res://sounds/voice_resources/main_menu/main_menu_select_start.tres"),
	Menu.SCORE_BOARD : load("res://sounds/voice_resources/main_menu/main_menu_select_score_board.tres"),
	Menu.FISH_ALMANAC : load("res://sounds/voice_resources/main_menu/main_menu_select_fish_almanac.tres"),
	Menu.TOGGLE_HELP : load("res://sounds/voice_resources/main_menu/main_menu_select_help_disabler.tres"),# if Saves.data["options"]["helper"] else load("res://sounds/voice_resources/main_menu/main_menu_select_help_enabler.tres"),
	Menu.AUDIO_SETTINGS : load("res://sounds/voice_resources/main_menu/main_menu_select_audio_settings.tres"),
	Menu.CREDITS : load("res://sounds/voice_resources/main_menu/main_menu_select_credits.tres"),
	Menu.QUIT : load("res://sounds/voice_resources/main_menu/main_menu_select_quit.tres"),
}

var voice_intro: VoiceArray = load("res://sounds/voice_resources/main_menu/main_menu_intro_array.tres")
var voice_help: VoiceArray = load("res://sounds/voice_resources/main_menu/main_menu_help.tres")
var pause: VoiceArray = load("res://sounds/voice_resources/pause_1_s.tres")

var current_menu := Menu.START_FISHING
var menu_size: int:
	get:
		return get_menu_size()
var intro := true

# Called when the node enters the scene tree for the first time.
func _ready():
	Sound.stop_voice_array_and_queue()
	get_last_menu_item()
	if current_menu == Menu.START_FISHING:
		scene_intro()
	else: 
		intro = false
		describe_menu_item(current_menu)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


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
		if event.is_action_pressed("top"):
			current_menu = Menu.START_FISHING
			describe_menu_item(current_menu)


func scene_intro():
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(voice_intro)
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(voice_help)
	Sound.all_voices_finished.connect(set_intro.bind(false))


func describe_menu_item(item: Menu):
	Sound.play_voice(voice_describe[item])
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(voice_help)


func select_menu_item(item: Menu):
	var scene_string: String = scenes[item]
	Global.last_menu_item = current_menu
	Signals.scene_requested.emit(scene_string)

func set_intro(setter: bool):
	if Sound.all_voices_finished.is_connected(set_intro.bind(false)):
		Sound.all_voices_finished.disconnect(set_intro.bind(false))
	intro = setter


func iterate_through_menu():
	current_menu = (current_menu + 1) % menu_size
	# enabler for SCORE_BOARD menu
	if current_menu == Menu.SCORE_BOARD:
		# enable this menu for specified current_scene class_name
		if Saves.data["game_finished"]:
			pass
		else:
			iterate_through_menu()


func get_menu_size() -> int:
	var index = 0
	for item in Menu:
		index += 1
	return index


func get_last_menu_item():
	current_menu = Global.last_menu_item


func scene_handler_argument(argument: String):
	if argument == "game_over":
		voice_intro = load("res://sounds/voice_resources/main_menu/main_menu_intro_game_over_array.tres")
	elif argument == "with_intro":
		current_menu = Menu.START_FISHING
	else:
		print("main_menu.gd, scene_handler_argument(), unknown argument: " + argument)
		pass
