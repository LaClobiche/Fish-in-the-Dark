extends Node2D

var voice_credits := [
	load("res://sounds/voice_resources/credits/credits_pt1_author.tres"),
	load("res://sounds/voice_resources/credits/credits_pt2_engine.tres"),
	load("res://sounds/voice_resources/credits/credits_pt3_narrator.tres"),
	load("res://sounds/voice_resources/credits/credits_pt4_soundeffects.tres"),
	load("res://sounds/voice_resources/credits/credits_pt5_fonts.tres"),
	load("res://sounds/voice_resources/credits/credits_pt6_thanks.tres"),
]
# Game made by LaClobiche 
# Created with GodotEngine
# Narrator voices made with elevenlabs
# Sound effects by Pixabay, SoundReality, Floraphonic and Zapslat
# Fonts: LanaPixel by Eishiya and TinyRPG by Tiopalada
# Thank you for playing Fish in the Dark

var inputs = false

func _ready():
	credits()


func _unhandled_input(event):
	if not inputs:
		pass
	else:
		if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("top"):
			Sound.play_next_voice()


func credits():
	inputs = false
	Sound.play_se(Sound.effects["cassette_in"])
	await Sound.all_se_finished
	Sound.play_se(Sound.effects["cassette_motor"])
	for voice in voice_credits:
		Sound.play_voice(voice)
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.all_voices_finished.connect(main_menu)
	inputs = true


func main_menu():
	if Sound.all_voices_finished.is_connected(main_menu):
		Sound.all_voices_finished.disconnect(main_menu)
	inputs = false
	Sound.stop_se()
	Sound.play_se(Sound.effects["cassette_out"])
	await Sound.all_se_finished
	Sound.play_voice(Sound.voices["pause_1_s"])
	await Sound.all_voices_finished
	inputs = true
	Signals.scene_requested.emit("main_menu")


