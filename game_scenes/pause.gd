@tool
extends Node2D

enum Menu {
	CONTINUE,
	TIPS,
	MAIN_MENU,
	QUIT,
}

var menu_callable := {
	Menu.CONTINUE : Callable(select_continue),
	Menu.TIPS : Callable(select_tips),
	Menu.MAIN_MENU : Callable(select_main_menu),
	Menu.QUIT : Callable(select_quit),
}

var voice_describe := {
	Menu.CONTINUE : load("res://sounds/voice_resources/pause_menu/select_continue.mp3"),# You want to keep on fishing
	Menu.TIPS : load("res://sounds/voice_resources/pause_menu/tips.tres"),#you want some advice
	Menu.MAIN_MENU : load("res://sounds/voice_resources/pause_menu/select_main_menu.mp3"),# You want to put down your rod and rethink your options.
	Menu.QUIT : load("res://sounds/voice_resources/pause_menu/select_quit.mp3"),# You think about leaving.
}

# current_scene getter require to have "ScenesHandler" as a parent.
var current_scene: Node:
	get:
		return get_parent().get_current_scene_node()
var current_menu: Menu = Menu.CONTINUE
var menu_size: int:
	get:
		return get_menu_size()

var voice_intro := load("res://sounds/voice_resources/pause_menu/intro.mp3") # You take a break. You wonder if you're going to continue fishing.
var voice_help := load("res://sounds/voice_resources/pause_menu/help.mp3") # Press "left" to follow this thought. Press "right" to explore other ideas.

var intro := true

@onready var sound := $Sound


func _ready():
	update_configuration_warnings()


func _unhandled_input(event):
	# if it's the main menu intro, only stop the voice and explain the current menu.
	if intro and (event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top")):
		sound.stop_voice_array_and_queue()
		sound.all_voices_finished.emit()
		describe_menu_item(current_menu)
	# after the intro played/skipped, use those inputs.
	else:
		if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
			sound.stop_voice_array_and_queue()
		if event.is_action_pressed("top"):
			get_viewport().set_input_as_handled()
			toggle()
		if event.is_action_pressed("left"):
			get_viewport().set_input_as_handled()
			select_menu_item(current_menu)
		if event.is_action_pressed("right"):
			get_viewport().set_input_as_handled()
			iterate_through_menu()
			describe_menu_item(current_menu)


func _get_configuration_warnings():
	if not get_parent() is ScenesHandler:
		return ["Need ScenesHandler as a parent node"]
	else:
		return []


func select_main_menu():
	toggle()
	# TODO SAVE GAME HERE
	Signals.scene_requested.emit("main_menu")


func select_tips():
	sound.play_voice(current_scene.voice_help, true)


func select_quit():
	toggle()
	Signals.scene_requested.emit("quit")


func select_continue():
	toggle()


func toggle():
	var paused: bool = visible
	get_tree().paused = not paused
	if paused:
		hide()
	else:
		current_menu = Menu.CONTINUE
		intro = true
		show()
		scene_intro()


func scene_intro():
	sound.play_voice(voice_intro)
	sound.play_voice(sound.voices["pause_1_s"])
	sound.play_voice(voice_help)
	sound.all_voices_finished.connect(set_intro.bind(false))


func describe_menu_item(item: Menu):
	sound.play_voice(voice_describe[item])
	sound.play_voice(sound.voices["pause_1_s"])
	sound.play_voice(voice_help)


func select_menu_item(item: Menu):
	var callable: Callable = menu_callable[item]
	callable.call()


func set_intro(setter: bool):
	if sound.all_voices_finished.is_connected(set_intro.bind(false)):
		sound.all_voices_finished.disconnect(set_intro.bind(false))
	intro = setter


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
