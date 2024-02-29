extends Node2D

var voice_intro = load("res://sounds/voice_resources/main_menu/main_menu_selected_start.tres")
var help: VoiceResource = load("res://sounds/voice_resources/main_menu/main_menu_help_pt2.tres")
var pause: VoiceArray = load("res://sounds/voice_resources/pause_1_s.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.current_fishing_rod = FishingRod.new()
	introduction()


func _unhandled_input(event):
	if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
		Sound.stop_voice_array_and_queue()
		casting()


func introduction():
	Sound.stop_voice_array_and_queue()
	Sound.play_voice(voice_intro)
	Sound.play_voice(pause)
	Sound.play_voice(help)
	Sound.play_voice(pause)
	Sound.all_voices_finished.connect(casting)
	


func casting():
	if Sound.all_voices_finished.is_connected(casting):
		Sound.all_voices_finished.disconnect(casting)
	Signals.scene_requested.emit("casting")
