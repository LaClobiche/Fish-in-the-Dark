extends Node2D

# Creak sound. "Suddenly, your rod shatters into fragments. You feel yourself drift away and..." #falling sound.

var inputs: bool = false
var game_over_voice: Resource = load("res://sounds/voice_resources/run_finished/run_finished_game_over.tres")
var game_over: bool = false
var game_finished: bool = false 

# Called when the node enters the scene tree for the first time.
func _ready():
	if game_over or game_finished:
		end_sequence()

func _unhandled_input(event):
	if inputs:
		if event.is_action_pressed("left") or event.is_action_pressed("right"):
			Sound.stop_se()
			Sound.play_next_voice()
	else:
		pass


func end_sequence():
	Sound.stop_voice_array_and_queue()
	Sound.stop_se()
	if game_over:
		Signals.flash.emit()
		Signals.rod_state.emit("hidden")
		Sound.play_se(Sound.effects["glass_breaking"])
		Sound.play_voice(Sound.voices["pause_0_5_s"])
		Sound.play_voice(game_over_voice)
		inputs = true
		await Sound.all_voices_finished
		inputs = false
		Signals.fade_in_black.emit()
		var fade_out_in := create_tween()
		fade_out_in.tween_callback(func() : Sound.fade_out_ambience())
		fade_out_in.tween_interval(1.0)
		fade_out_in.tween_callback(func(): Sound.play_se(Sound.effects["body_falling"]))
		fade_out_in.tween_interval(3.0)
		await fade_out_in.finished
		Signals.fade_out_black.emit()
	elif game_finished:
		pass
	Signals.scene_requested.emit("main_menu", "game_over")


func scene_handler_argument(argument: String):
	if argument == "game_over":
		game_over = true
	elif argument == "game_finished":
		game_finished = true
	else:
		print("run_finished.gd, scene_handler_argument(), unknown argument: " + argument)
		pass
