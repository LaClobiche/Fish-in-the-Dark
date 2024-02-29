extends Node2D

var intro: VoiceResource = load("res://sounds/voice_resources/intro/intro.tres")
var pause: VoiceArray = load("res://sounds/voice_resources/pause_1_s.tres")


func _ready():
	introduction()


func _unhandled_input(event):
	if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
		Sound.stop_voice_array_and_queue()
		main_menu()


func introduction():
	Sound.play_voice(intro)
	Sound.play_voice(pause)
	Sound.all_voices_finished.connect(main_menu)



func main_menu():
	if Sound.all_voices_finished.is_connected(main_menu):
		Sound.all_voices_finished.disconnect(main_menu)
	Sound.play_ambience(Sound.ambiences["pond_night"])
	var fade_in := create_tween()
	fade_in.tween_property(Sound.ambience, "volume_db", -5.0, 1.0).from_current()
	fade_in.tween_callback(func(): Signals.scene_requested.emit("main_menu"))
	
