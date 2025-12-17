@tool
extends Node2D

enum Menu {
	CONTINUE,
	TIPS,
	ALMANAC,
	MAIN_MENU,
	QUIT,
}

var menu_callable := {
	Menu.CONTINUE : Callable(select_continue),
	Menu.TIPS : Callable(select_tips),
	Menu.ALMANAC : Callable(select_almanac),
	Menu.MAIN_MENU : Callable(select_main_menu),
	Menu.QUIT : Callable(select_quit),
}

var voice_describe := {
	Menu.CONTINUE : load("res://sounds/voice_resources/pause_menu/select_continue.tres"),# You want to keep on fishing
	Menu.TIPS : load("res://sounds/voice_resources/pause_menu/tips.tres"),#you want some advice
	Menu.ALMANAC : load("res://sounds/voice_resources/main_menu/main_menu_select_fish_almanac.tres"),
	Menu.MAIN_MENU : load("res://sounds/voice_resources/pause_menu/select_main_menu.tres"),# You want to put down your rod and rethink your options.
	Menu.QUIT : load("res://sounds/voice_resources/pause_menu/select_quit.tres"),# You think about leaving.
}


var text_menu := {
	Menu.CONTINUE : "continue fishing",
	Menu.TIPS : "get advice",
	Menu.ALMANAC : "fish almanac",
	Menu.MAIN_MENU : "stop fishing",
	Menu.QUIT : "quit game",
}


var _toggling := false
var _voices_connected := false


# current_scene getter require to have "ScenesHandler" as a parent.
var current_scene: Node:
	get:
		return get_parent().get_current_scene_node()
var current_menu: Menu = Menu.CONTINUE
var menu_size: int:
	get:
		return get_menu_size()

var voice_intro := load("res://sounds/voice_resources/pause_menu/intro.tres") # You take a break. You wonder if you're going to continue fishing.
var voice_help := load("res://sounds/voice_resources/pause_menu/help.tres") # Press "left" to follow this thought. Press "right" to explore other ideas.

var inputs := false:
	set(value):
		inputs = value
		if value == true:
			print("pause inputs true")
		else:
			print("pause inputs false")
var intro := true

@onready var sound := $Sound
@onready var almanac := $FishAlmanac
@onready var pause_image := $PauseImage


func _ready():
	update_configuration_warnings()


func _unhandled_input(event):
	if not inputs or not visible:
		return

	# Intro : on autorise seulement left/right/top pour passer
	if intro and (event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top")):
		inputs = false
		sound.stop_voice_array_and_queue()
		sound.all_voices_finished.emit()
		describe_menu_item(current_menu)
		inputs = true
	else:
		if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
			sound.stop_voice_array_and_queue()
			sound.all_voices_finished.emit()

		if event.is_action_pressed("top"):
			# NE PAS réactiver inputs ici
			inputs = false
			get_viewport().set_input_as_handled()
			current_menu = Menu.CONTINUE
			Signals.menu_index_changed.emit(int(current_menu))
			await get_tree().create_timer(0.5).timeout
			Signals.menu_selected.emit()
			await Signals.menu_closed
			select_menu_item(current_menu)

		if event.is_action_pressed("left"):
			inputs = false
			get_viewport().set_input_as_handled()
			Signals.menu_selected.emit()
			await Signals.menu_closed
			select_menu_item(current_menu)

		if event.is_action_pressed("right"):
			inputs = false
			get_viewport().set_input_as_handled()
			iterate_through_menu()
			Signals.menu_index_changed.emit(int(current_menu))
			describe_menu_item(current_menu)
			inputs = true


func _get_configuration_warnings():
	if not get_parent() is ScenesHandler:
		return ["Need ScenesHandler as a parent node"]
	else:
		return []


func select_main_menu():
	toggle()
	Signals.free_floating_text.emit()
	Signals.scene_requested.emit("main_menu")


func select_tips():
	sound.play_voice(current_scene.voice_help, true)
	set_text_menu()
	inputs = true


func select_almanac():
	almanac.launch()


func select_quit():
	Signals.scene_requested.emit("quit")
	toggle()

func select_continue():
	toggle()


func toggle():
	if _toggling:
		return
	_toggling = true

	var closing := visible
	if closing:
		# --- Fermeture ---
		inputs = false
		intro = false
		get_tree().paused = false
		hide()
		pause_image.hide()

		sound.stop_voice_array_and_queue()
		_disconnect_voices_finished()
	else:
		# --- Ouverture ---
		get_tree().paused = true
		current_menu = Menu.CONTINUE
		intro = true
		show()
		pause_image.show()
		scene_intro()

	_toggling = false


func scene_intro():
	_disconnect_voices_finished()
	sound.play_voice(voice_intro)
	sound.play_voice(sound.voices["pause_1_s"])
	sound.play_voice(voice_help)
	sound.all_voices_finished.connect(_on_all_voices_finished, CONNECT_ONE_SHOT)
	_voices_connected = true
	inputs = true


func describe_menu_item(item: Menu):
	sound.play_voice(voice_describe[item])
	sound.play_voice(sound.voices["pause_1_s"])
	sound.play_voice(voice_help)


func select_menu_item(item: Menu):
	var callable: Callable = menu_callable[item]
	callable.call()


func set_intro(setter: bool):
	# plus besoin de disconnect ici, on le fait centralisé
	intro = setter
	set_text_menu()


func set_text_menu():
	var text_menu_array: Array[String] = []
	for item in text_menu:
		text_menu_array.append(text_menu[item])
	print(str(text_menu_array) + " " + str(current_menu))
	Signals.menu_requested.emit(text_menu_array, current_menu)
	await Signals.menu_opened


func iterate_through_menu():
	current_menu = (current_menu + 1) % menu_size
	# enabler for TIPS menu
	if current_menu == Menu.TIPS:
		# enable this menu for specified current_scene class_name
		if current_scene is Casting or current_scene is Luring or current_scene is Catching:
			pass
		else:
			iterate_through_menu()


func get_menu_size() -> int:
	var index = 0
	for item in Menu:
		index += 1
	return index


func _disconnect_voices_finished():
	if _voices_connected and sound.all_voices_finished.is_connected(_on_all_voices_finished):
		sound.all_voices_finished.disconnect(_on_all_voices_finished)
	_voices_connected = false


func _on_all_voices_finished():
	# appelé une seule fois grâce à CONNECT_ONE_SHOT
	set_intro(false)







