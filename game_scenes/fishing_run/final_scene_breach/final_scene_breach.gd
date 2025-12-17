extends Node2D

enum State {
	INTRO,# gives an introduction to the minigame & help with commands
	CHOOSE,
	REACT,
	OUTRO,# the outcome (succeeded/failed)
}

## state of the scene
var current_state: State = State.INTRO
## if true, inputs are allowed
var inputs: bool = false

## the number of steps in the scene:
const SCENE_STEPS := 4
## the order of navigation through the choices of each step
var choice_range := [1, 2, 3, 4]
## index for progress into the scene steps, max is scene_steps
var scene_steps_index := 1
## keep track of the current index of the choice_range, from 0 to 3
var choice_index := 0

var ambience_underwater := load("res://sounds/ambience/underwater.wav")
var ambience_dark := load("res://sounds/ambience/underwater_dark.wav")
var ambience_darker := load("res://sounds/ambience/underwater_darker.wav")

@onready var debug_label := $DebugLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	if Global.debug:
		show()
	scene_intro()


func _process(delta):
	if Global.debug:
		debug()


func _unhandled_input(event):
	if event.is_action_pressed("top"):
		Signals.scene_requested.emit("toggle_pause")
	if inputs:
		if current_state == State.INTRO or current_state == State.REACT:
			if event.is_action_pressed("left") or event.is_action_pressed("right"):
				Sound.play_next_voice()
				Sound.sound_effects.stop()
		elif current_state == State.CHOOSE:
			if event.is_action_pressed("left"):
				Sound.stop_voice_array_and_queue()
				scene_react()
			if event.is_action_pressed("right"):
				choice_index = (choice_index + 1) % 4 
				Sound.stop_voice_array_and_queue()
				scene_choose()
		else:
			pass


func debug():
	debug_label.text = "State: " + str(State.keys()[current_state]) + " | scene_step_index: " + str(scene_steps_index) + " | Playing voice: " + Sound.voice.stream.resource_path


func scene_intro():
	inputs = false
	current_state = State.INTRO
	choice_range.shuffle()
	if Sound.all_voices_finished.is_connected(scene_intro):
		Sound.all_voices_finished.disconnect(scene_intro)
	if scene_steps_index == 1:
		Global.current_fish = load("res://places_and_fishes/breach/1_wholefish.tres")
		Global.current_place = load("res://places_and_fishes/breach.tres")
	Sound.play_se(load("res://sounds/effects/final_scene_breach/%d_intro.wav" % scene_steps_index))
	Sound.play_voice(load("res://sounds/voice_resources/final_scene/%d_intro.tres" % scene_steps_index))
	if scene_steps_index == 1:
		Signals.rod_state.emit("idle")
		var tween := create_tween()
		tween.tween_interval(12.5)
		tween.tween_callback(func(): Signals.rod_state.emit("hidden"))
		tween.tween_callback(func(): Signals.flash.emit())
		tween.tween_callback(func(): Signals.fade_in_black.emit())
		tween.tween_interval(0.5)
		tween.tween_callback(func(): Sound.play_ambience(ambience_underwater))
		await get_tree().create_timer(17.0).timeout
	if scene_steps_index == 3:
		Sound.play_ambience(ambience_dark)
		Signals.vortex_particle_show.emit()
		Signals.fade_out_black.emit()
		Signals.breach_panel_show.emit()
	if scene_steps_index == 4:
		Sound.play_ambience(ambience_darker)
		Signals.glitch_show.emit()
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(load("res://sounds/voice_resources/final_scene/ask_reaction.tres"))
	if scene_steps_index == 1:
		Sound.play_voice(Sound.voices["pause_0_5_s"])
		Sound.play_voice(load("res://sounds/voice_resources/final_scene/ask_reaction_help.tres"))
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.all_voices_finished.connect(scene_choose)
	inputs = true


func scene_choose():
	inputs = false
	current_state = State.CHOOSE
	if Sound.all_voices_finished.is_connected(scene_choose):
		Sound.all_voices_finished.disconnect(scene_choose)
	var voice_choice: Resource = load("res://sounds/voice_resources/final_scene/%d_%d_thought.tres" % [scene_steps_index, choice_range[choice_index]])
	set_floating_text()
	set_highlighted_text(voice_choice)
	Sound.play_voice(voice_choice)
	print("you choose: " + str(choice_range[choice_index]) + "choice, relative to index number " + str(choice_index))
	inputs = true

func scene_react():
	inputs = false
	current_state = State.REACT
	Signals.free_floating_text.emit()
	if scene_steps_index == 4:
		Sound.play_se(load("res://sounds/ambience/underwater_void.wav"))
		Sound.stop_ambience()
	Sound.play_voice(load("res://sounds/voice_resources/final_scene/%d_%d_reaction.tres" % [scene_steps_index, choice_range[choice_index]]))
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(Sound.voices["pause_1_s"])
	choice_index = 0
	if scene_steps_index < SCENE_STEPS:
		scene_steps_index += 1
		choice_index = 0
		Sound.all_voices_finished.connect(scene_intro)
	else:
		Sound.all_voices_finished.connect(scene_outro)
	inputs = true

func scene_outro():
	print("outro")
	inputs = false
	current_state = State.OUTRO
	if Sound.all_voices_finished.is_connected(scene_outro):
		Sound.all_voices_finished.disconnect(scene_outro)
	
	# also add the magnimahi that weren't added when catched to avoid a bug if the game is closed between the magni-mahi & the wholefish
	Global.add_to_fish_almanac(Global.current_place.name, Global.current_fish.name)
	Global.add_to_fish_almanac(Place.PlaceName.SWALLOWING_VORTEX, "Magnimahi")
	
	Signals.fish_show.emit(Global.current_fish)
	
	Sound.play_voice(Sound.voices["pause_0_5_s"])
	await Sound.all_voices_finished
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(Global.current_fish.voice_name_caught)
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(Global.current_fish.voice_description)
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(Sound.voices["pause_1_s"])
	if Saves.data["game_finished"] == false:
		Sound.play_voice(load("res://sounds/voice_resources/credits/credits_pt6_thanks.tres"))
	await Sound.all_voices_finished
	
	Sound.play_se(load("res://sounds/effects/warp.mp3"))
	Signals.fish_hide.emit()
	Signals.glitch_hide.emit()
	Signals.vortex_particle_hide.emit()

	await get_tree().create_timer(2.0).timeout

	Signals.fade_in_black.emit()

	await get_tree().create_timer(2.0).timeout
	
	Signals.breach_panel_hide.emit()
	inputs = true
	
	scene_handler_emit()


func scene_handler_emit():
	Saves.data["game_finished"] = true
	Saves.save_game()
	Signals.update_logo.emit()
	Signals.scene_requested.emit("run_finished", "game_finished")


func set_floating_text():
	var array_of_choice: Array[String] = []
	for choice in choice_range:
		var voice_resource: Resource = load("res://sounds/voice_resources/final_scene/%d_%d_thought.tres" % [scene_steps_index, choice_range[choice - 1]])
		array_of_choice.append(voice_resource.subtitle)
	Signals.set_floating_text.emit(array_of_choice)

func set_highlighted_text(voice_resource: Resource):
	Signals.set_floating_text_highlighted_label.emit(voice_resource.subtitle)
