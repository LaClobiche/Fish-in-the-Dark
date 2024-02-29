extends Node2D

# Creak sound. "Suddenly, your rod shatters into fragments. You feel yourself drift away and..." #falling sound.

var game_over_voice: AudioStream = load("res://sounds/voice_resources/run_finished/run_finished_game_over.mp3")
var game_over: bool = false
var demo_over_voice: AudioStream = load("res://sounds/voice_resources/run_finished/run_finished_demo_over.mp3")
var game_finished: bool = false 

# Called when the node enters the scene tree for the first time.
func _ready():
	if game_over or game_finished:
		end_sequence()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func end_sequence():
	Sound.stop_voice_array_and_queue()
	Sound.stop_se()
	Sound.play_se(Sound.effects["glass_breaking"])
	Sound.play_voice(Sound.voices["pause_0_5_s"])
	if game_over:
		Sound.play_voice(game_over_voice)
	elif game_finished:
		Sound.play_voice(demo_over_voice)
	await Sound.all_voices_finished
	var fade_out_in := create_tween()
	fade_out_in.tween_property(Sound.ambience, "volume_db", -80.0, 1.0).from(-5.0)
	fade_out_in.tween_callback(func(): Sound.play_se(Sound.effects["body_falling"]))
	fade_out_in.tween_interval(3.0)
	fade_out_in.tween_property(Sound.ambience, "volume_db", -5.0, 1.0).from(-80.0)
	await fade_out_in.finished
	Signals.scene_requested.emit("main_menu", "game_over")


func scene_handler_argument(argument: String):
	if argument == "game_over":
		game_over = true
	if argument == "game_finished":
		game_finished = true
	else:
		print("run_finished.gd, scene_handler_argument(), unknown argument: " + argument)
		pass
