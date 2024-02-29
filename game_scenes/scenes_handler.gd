class_name ScenesHandler

extends Node2D

# list of scenes or callables
var scenes = {
	# main menu scenes
	"intro" : load("res://game_scenes/intro/intro.tscn"),
	"main_menu" : load("res://game_scenes/main_menu.tscn"),
	"fishing_run" : load("res://game_scenes/fishing_run/fishing_run.tscn"),# initialize the variables for a run
	"score_board" : load("res://game_scenes/score_board/score_board.tscn"),
	"toggle_help" : load("res://game_scenes/toggle_help/toggle_help.tscn"),
	"fish_almanac" : load("res://game_scenes/fish_almanac/fish_almanac.tscn"),
	"audio_settings" : load("res://game_scenes/audio_settings/audio_settings.tscn"),
	"credits" : load("res://game_scenes/credits/credits.tscn"),
	"quit" : Callable(quit_game),
	# pause scene
	"toggle_pause" : Callable(toggle_pause),
	# fishing run scenes
	"casting" : load("res://game_scenes/fishing_run/casting/casting.tscn"),# launched in "fishing_run"
	"luring" : Callable(set_luring_scene), # launched in "casting"
	"catching" : load("res://game_scenes/fishing_run/catching/catching.tscn"),# launched in "luring"
	"run_finished" : load("res://game_scenes/fishing_run/run_finished/run_finished.tscn"),# launched in "catching"
}

@onready var current_scene := $CurrentScene
@onready var ui_touchscreen := $UITouchscreen
@onready var pause := $Pause


# Called when the node enters the scene tree for the first time.
func _ready():
	var current_os := OS.get_name()
	if current_os == "Android" or current_os == "iOS":
		Global.touchscreen = true
	if Global.touchscreen:
		ui_touchscreen.show()
	Signals.scene_requested.connect(set_scene)
	Signals.game_over_requested.connect(set_scene.bind("run_finished", "game_over"))
	set_scene("intro")
	


# delete SceneHandler child, set a new scene as a child.
func set_scene(scene_name: String, optional_argument: String = ""):
	# TODO place fade out anim #
	var scene = scenes[scene_name]
	if scene is PackedScene:
		var scene_instance: Node = scene.instantiate()
		for child in current_scene.get_children():
			child.queue_free()
		if optional_argument != "":
			scene_instance.scene_handler_argument(optional_argument)
		current_scene.add_child(scene_instance)
	elif scene is Callable:
		scene.call()


func set_luring_scene():
	if Global.current_fish == null:
		assert(false, "scenes_handler.gd, set_luring_scene: error, no Fish resource in Global.current_fish")
	else:
		var luring_scene_instance: Node = Global.current_fish.luring_scene.instantiate()
		for child in current_scene.get_children():
			child.queue_free()
		current_scene.add_child(luring_scene_instance)


func get_current_scene_node() -> Node:
	var nodes := current_scene.get_children()
	if nodes.is_empty() or nodes.size() > 1:
		assert(false, "scenes_handler.gd, get_current_scene_node(): no node or more than one")
	return nodes[0]


func toggle_pause():
	pause.toggle()


func quit_game():
	Saves.save_game()
	var quit: Callable = get_tree().quit
	Sound.stop_voice_array_and_queue()
	Sound.play_se(Sound.effects["walk_out"])
	Sound.sound_effects.finished.connect(quit)
