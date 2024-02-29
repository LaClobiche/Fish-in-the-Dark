extends Node2D

var voice := {
	true : load("res://sounds/voice_resources/main_menu/enabled.tres"),
	false : load("res://sounds/voice_resources/main_menu/disabled.tres"),
}


func _ready():
	toggle_help()


func toggle_help():
	Saves.data["options"]["helper"] = not Saves.data["options"]["helper"]
	Sound.stop_voice_array_and_queue()
	Sound.play_voice(voice[Saves.data["options"]["helper"]])
	Sound.all_voices_finished.connect(main_menu)


func main_menu():
	Signals.scene_requested.emit("main_menu")
	Sound.all_voices_finished.disconnect(main_menu)

