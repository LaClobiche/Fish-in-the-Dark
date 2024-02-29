class_name Catching

extends Node2D

signal sound_node_moved(node)

enum State {
	INTRO,# gives an introduction to the minigame & help with commands
	SET_SEQUENCE,# the game sequence
	PULLING_RIGHT,
	PULLING_LEFT,
	FIGHTING,
	REELING,
	OUTRO,# the outcome (succeeded/failed)
}

const DIR := {
	"LEFT" = Vector2i.LEFT,
	"RIGHT" = Vector2i.RIGHT,
	"UP" = Vector2i.UP,
	"DOWN" = Vector2i.DOWN,
	"CENTER" = Vector2i.ZERO
}

var state_dic := {
	State.INTRO : Callable(scene_intro),
	State.SET_SEQUENCE : Callable(scene_set_sequence),
	State.PULLING_RIGHT : Callable(scene_angling_right),
	State.PULLING_LEFT : Callable(scene_angling_left),
	State.FIGHTING : Callable(scene_fighting),
	State.REELING : Callable(scene_reeling),
	State.OUTRO : Callable(scene_outro),
}

var state_shortcut := {
	"PR" : State.PULLING_RIGHT,
	"PL" : State.PULLING_LEFT,
	"R" : State.REELING,
	"F" : State.FIGHTING,
}

@export var rod_damage: int
@export var fish_damage: int
@export var fish_max_hp: int = 100
#the volume level associated with fish when the scene starts
@export var fish_min_vol: int

var voice_intro: VoiceResource = load("res://sounds/voice_resources/catching/intro.tres")
var voice_help = load("res://sounds/voice_resources/catching/help_array.tres")
# voice_help_pt1 : If the fish moves towards one direction, press left or right to move your rod in the opposite way. 
# voice_help_pt2 :If the fish is facing you and struggling, do nothing and let it get tired.
# voice_help_pt3 : If the fish doesn't make any noise, you can reel it by alternately pressing left and right.
# voice_help_pt4 :When you're doing right, you can hear bubbles.
# When you're doing wrong, you will hear your rod creak.
var voice_help_flowfish: AudioStream = load("res://sounds/voice_resources/catching/help_flowfish.mp3")
# If the fish doesn't make any noise, you can reel it by alternately pressing left and right.
# Bubbles can be heard if you do this correctly.
var voice_help_bubblefish: VoiceArray = load("res://sounds/voice_resources/catching/help_bubblefish_array.tres")
# If the fish is facing you and struggling, do nothing and let it get tired.
# When it stops making noise, reel it by alternately pressing left and right. 
# + voice_help_pt4
var voice_help_selfish: VoiceArray = load("res://sounds/voice_resources/catching/help_selfish_array.tres")
# If the fish moves towards one direction, press left or right to move your rod in the opposite way.
# + voice_help pt4
var voice_end: AudioStream = load("res://sounds/voice_resources/catching/end.mp3")
#You note your catch in your almanac and prepare to hook another fish.

var fish_catched_soudn: AudioStream = Sound.effects["fish_catched"]
var fish_pulling_sound: AudioStream = Sound.effects["splashes_loop"]
var fish_fighting_sound: AudioStream = Sound.effects["splashes_loop_fast"]
var rod_pulled_sound: AudioStream = Sound.effects["reeling_super_slow"]
var rod_fighted_sound: AudioStream = Sound.effects["splashes_loop"]

## stock the sound_node currently modified here
var current_sound_node: Sound2D
## state of the scene
var current_state: State = State.INTRO:
	set(value):
		previous_state = current_state
		current_state = value
var previous_state: State
## if true, inputs are allowed
var inputs: bool = false
## tween moving the fish
var pull_sound_tween: Tween
## tween moving the fish
var fish_tween: Tween
var fish_hp: int = fish_max_hp:
	set(value):
		if value < 0:
			value = 0
			set_state(State.OUTRO)
		else:
			var target_volume: float = ((float(value)) / 100.0) * fish_min_vol
			fish_tween = create_tween()
			fish_tween.tween_callback(func(): fish.volume_db = target_volume)
		fish_hp = value
## associate the input pressed with a timing, while state == State.REELING. False for left, True for Right.
var reeling_dict: Dictionary = {}
## keep the reeling sound currently played in memory.
var reeling_sound: AudioStream


@onready var anim_player := $AnimationPlayer
@onready var rod_hp_cooldown := $RodHPCooldown
@onready var reeling_sound_timer := $ReelingSoundTimer
@onready var reeling_input_timer := $ReelingInputTimer
@onready var pulling_input_timer := $PullingInputTimer
@onready var player := $Player
@onready var player_listener := $Player/AudioListener2D
@onready var fish := $Sound2DNodes/Sound2DFish
@onready var sound_node := {
	"LEFT" : $Sound2DNodes/Sound2DLeft,
	"CENTER" : $Sound2DNodes/Sound2DFish,
	"RIGHT" : $Sound2DNodes/Sound2DRight,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
#	Global.current_fish = load("res://places_and_fishes/everwatching_cove/4_distinctuna.tres") #debug
	set_sound_nodes_position()
	player.position = Global.get_viewport_directed_position(DIR.CENTER)
	for sound_player in sound_node:
		sound_node[sound_player].set_panning_strength(15.0)
	fish.set_panning_strength(20.0)
	fish.volume_db = fish_min_vol
	set_tuto_help()
	set_state(current_state)


func _physics_process(delta):
	pass


func _unhandled_input(event):
	if event.is_action_pressed("top"):
		Signals.scene_requested.emit("toggle_pause")
	elif not inputs:
		return
	else:
		var reeling = is_reeling_input()
		if current_state == State.INTRO:
			if event.is_action_pressed("left") or event.is_action_pressed("right"):
				Sound.stop_voice_array_and_queue()
				set_state(State.SET_SEQUENCE)
		elif current_state == State.PULLING_LEFT or current_state == State.PULLING_RIGHT:
			# the input is checked in the on_rog_hp_cooldown_time_out() func.
			play_pulling_rod_sound(event)
		elif current_state == State.REELING:
			if reeling:
				play_success_sound()
				fish_hp -= fish_damage
		elif current_state == State.FIGHTING:
			if not is_fighting_input_correct() and rod_hp_cooldown.is_stopped():
				Global.current_fishing_rod.take_damage(rod_damage)
				print("fighting -> damage")
				rod_hp_cooldown.start()
		elif current_state == State.OUTRO:
			pass


func move_audio_node_to_direction(node: Sound2D, direction: Vector2i, 
		time: float = 1.0, easing: bool = false, ease_type: Tween.EaseType = Tween.EaseType.EASE_OUT):
	var final_position := Global.get_viewport_directed_position(direction)
	var move := create_tween()
	if easing:
		move.set_ease(ease_type)
	move.tween_property(node, "position", final_position, time).from(node.position)
	move.tween_callback(func(): sound_node_moved.emit(node))


# return true if pulling inputs are correct
func is_pulling_input_correct() -> bool:
	if current_state == State.PULLING_LEFT:
		if Input.is_action_pressed("left"):
			return true
		else:
			return false
	else:# current_state == State.PULLING_RIGHT:
		if Input.is_action_pressed("right"):
			return true
		else:
			return false


# return true if pulling inputs are correct
func is_fighting_input_correct() -> bool:
	if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
		return false
	else:
		return true


## return true if the player has alternately pressed left and right.
## call play_reeling_sound with the input timing.
func is_reeling_input() -> bool:
	var bool_to_return: bool = false
	if reeling_input_timer.is_stopped() and (Input.is_action_pressed("left") or Input.is_action_pressed("right")):
		# pair a bool (false = left or true = right) with a timing
		var key_to_erase: bool = false
		if Input.is_action_pressed("left"):
			# if the same input is pressed, keep the previous timing.
			if reeling_dict.has(false):
				pass
			else:
				reeling_dict[false] = Time.get_ticks_msec()
			key_to_erase = true
		else:
			if reeling_dict.has(true):
				pass
			else:
				reeling_dict[true] = Time.get_ticks_msec()
			key_to_erase = false
		# if the reeling_dict contain both bool, get the relative timing and clear the dict.
		if reeling_dict.keys() == [false, true] or reeling_dict.keys() == [true, false]:
			var timing: int = absi(reeling_dict[true]-reeling_dict[false])
			reeling_dict.erase(key_to_erase)
			if timing <= 800:
				play_reeling_sound(timing)
				bool_to_return = true
		reeling_input_timer.start()
	return bool_to_return


func play_reeling_sound(timing_msec: int):
	reeling_sound_timer.start()
	if timing_msec > 500:
		reeling_sound = Sound.effects["reeling_super_slow"]
	elif timing_msec > 350:
		reeling_sound = Sound.effects["reeling_slow"]
	elif timing_msec > 250:
		reeling_sound = Sound.effects["reeling_normal"]
	elif timing_msec > 150:
		reeling_sound = Sound.effects["reeling_fast"]
	else:
		reeling_sound = Sound.effects["reeling_super_fast"]
	if not Sound.is_se_playing(reeling_sound):
		Sound.stop_se()
		Sound.play_se(reeling_sound)
		print("play reeling sound: " + reeling_sound.resource_path)



func play_reeling_intermittent(play: bool):
	if pull_sound_tween != null:
		pull_sound_tween.kill()
	if play:
		pull_sound_tween = create_tween().set_loops(0)
		pull_sound_tween.tween_callback(func():Sound.play_se(Sound.effects["reeling_super_slow"]))
		pull_sound_tween.tween_interval(0.3)
		pull_sound_tween.tween_callback(func():Sound.stop_se_specified(Sound.effects["reeling_super_slow"]))
		pull_sound_tween.tween_interval(0.3)
	else:
		Sound.stop_se_specified(Sound.effects["reeling_super_slow"])


func play_success_sound():
	if fish.is_playing_specific(Sound.effects["bubbles_loop_low"]):
		return
	else:
		var sound_tween := create_tween()
		sound_tween.tween_callback(func(): fish.play(Sound.effects["bubbles_loop_super_low"], randf_range(0.0, 4.0)))
		sound_tween.tween_interval(0.2)
		sound_tween.tween_callback(func(): fish.stop_specified(Sound.effects["bubbles_loop_super_low"]))


func play_pulling_rod_sound(event: InputEvent):
	if event.is_action_pressed("left"):
		Sound.stop_se_specified(reeling_sound)
		Sound.play_se(Sound.effects["move_left"])
		if not Sound.is_se_playing(Sound.effects["pull_left"]):
			Sound.play_se(Sound.effects["pull_left"])
	if event.is_action_pressed("right"):
		Sound.stop_se_specified(reeling_sound)
		Sound.play_se(Sound.effects["move_right"])
		if not Sound.is_se_playing(Sound.effects["pull_right"]):
			Sound.play_se(Sound.effects["pull_right"])
	if event.is_action_released("left") and Sound.is_se_playing(Sound.effects["pull_left"]):
		Sound.stop_se_specified(Sound.effects["pull_left"])
	if event.is_action_released("right") and Sound.is_se_playing(Sound.effects["pull_right"]):
		Sound.stop_se_specified(Sound.effects["pull_right"])


func set_sound_nodes_position():
	for key in sound_node.keys():
		set_sound_node_position(sound_node[key], DIR[key])


func set_sound_node_position(node: Sound2D, direction: Vector2i):
	node.position = Global.get_viewport_directed_position(direction)


func set_state(state):
	# prevent from changing state as soon as State.OUTRO is setted.
	if current_state == State.OUTRO:
		print("catching.gd, set_state(), State." + str(state) + " not setted because current_state is State.OUTRO" )
		return
	if state is State:
		current_state = state
	elif state is String and state in state_shortcut:
		current_state = state_shortcut[state]
	elif state is String and state in State.keys():
		current_state = State[state]
	else:
		assert(false, "Catching.gd, set_state: error, argument " + str(state) + " not supported.")
	var callable: Callable = state_dic[current_state]
	callable.call()





func scene_intro():
	print("intro")
	inputs = false
	Sound.play_voice(voice_intro)
	Sound.play_voice(voice_help)
	Sound.all_voices_finished.connect(set_state.bind(State.SET_SEQUENCE))
	inputs = true


func scene_set_sequence():
	print("set sequence")
	inputs = false
	
	# disconnect the all_voices_finished signal from this function.
	if Sound.all_voices_finished.is_connected(set_state.bind(State.SET_SEQUENCE)):
		Sound.all_voices_finished.disconnect(set_state.bind(State.SET_SEQUENCE))
	
	# loading the catching_sequence animation 
	# retrieving "catching_sequences_library_ingame", should be an empty library
	var anim_library: AnimationLibrary = anim_player.get_animation_library("catching_sequences_library_ingame")
	# if present, remove the current animation "catching_sequence" that is attached to the library.
	if anim_library.has_animation("catching_sequence"):
		anim_library.remove_animation("catching_sequence")
	# add the animation attached to the current Fish resource
	anim_library.add_animation("catching_sequence", Global.current_fish.catching_sequence)
	anim_player.play("catching_sequences_library_ingame/catching_sequence")
	
	inputs = true


func scene_angling_right():
	print("angling right")
	stop_se_and_timers()
	pulling_input_timer.start()
	fish_tween = create_tween()
	fish_tween.tween_callback(func(): fish.play(fish_pulling_sound))
	fish_tween.tween_property(fish, "position", Vector2(Global.get_viewport_directed_position(DIR.LEFT).x, fish.position.y), 0.1).from_current()


func scene_angling_left():
	print("angling left")
	stop_se_and_timers()
	pulling_input_timer.start()
	fish_tween = create_tween()
	fish_tween.tween_callback(func(): fish.play(fish_pulling_sound))
	fish_tween.tween_property(fish, "position", Vector2(Global.get_viewport_directed_position(DIR.RIGHT).x, fish.position.y), 0.1).from_current()


func scene_fighting():
	print("fighting")
	stop_se_and_timers()
	Sound.stop_se_specified(reeling_sound)
	inputs = false
	fish_tween = create_tween()
	fish_tween.tween_callback(func(): fish.play(fish_fighting_sound))
	fish_tween.tween_property(fish, "position", Vector2(Global.get_viewport_directed_position(DIR.CENTER).x, fish.position.y), 0.1).from_current()
	fish_tween.tween_callback(func(): inputs = true)
	fish_tween.tween_callback(func(): rod_hp_cooldown.start())


func scene_reeling():
	print("reeling")
	stop_se_and_timers()
	fish_tween = create_tween()
	fish_tween.tween_property(fish, "position", Vector2(Global.get_viewport_directed_position(DIR.CENTER).x, fish.position.y), 0.1).from_current()


func scene_outro():
	print("outro")
	anim_player.stop()
	stop_se_and_timers()
	inputs = false
	Global.add_to_fish_almanac(Global.current_place.name, Global.current_fish.name)
	for sound_player in sound_node:
		sound_node[sound_player].stop()
	fish_hp = 100
	Sound.play_voice(Sound.voices["pause_0_5_s"])
	await Sound.all_voices_finished
	Sound.play_se(Sound.effects["fish_catched"])
	Sound.play_se(Sound.effects["voice_catching"])
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(Global.current_fish.voice_name_caught)
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(Global.current_fish.voice_description)
	Sound.play_voice(Sound.voices["pause_1_s"])
	await Sound.all_voices_finished
	Sound.play_se(Sound.effects["write"])
	Sound.play_voice(voice_end)
	await Sound.all_voices_finished
	inputs = true
	scene_handler_emit()



func scene_handler_emit():
	# if all the fish are caught & the demo wasn't finished:
	if Global.get_places_not_completed().is_empty() and not Saves.data["game_finished"]:
		Saves.data["game_finished"] = true
		Saves.save_game()
		Signals.scene_requested.emit("run_finished", "game_finished")
	# else, continue fishing
	else:
		Signals.scene_requested.emit("casting", "run_continue")


func stop_se_and_timers():
	pulling_input_timer.stop()
	fish.stop()
	if previous_state != State.PULLING_LEFT and previous_state != State.PULLING_RIGHT:
		Sound.stop_se_specified(Sound.effects["pull_right"])
		Sound.stop_se_specified(Sound.effects["pull_left"])


## stops the reeling sound after 1 sec without reeling input.
func _on_reeling_sound_timer_timeout():
	Sound.stop_se_specified(reeling_sound)


## checks if the input is pressed.
func _on_pulling_input_timer_timeout():
	if is_pulling_input_correct():
		play_success_sound()
		print("success pull")
	else:
		Global.current_fishing_rod.take_damage(rod_damage)
		print("pulling -> damage")
	if current_state == State.PULLING_LEFT or current_state == State.PULLING_RIGHT:
		pulling_input_timer.start()


## change the help voice according to the fishes. The fish in flowing water (tuto zone) progressively gives the help instruction.
func set_tuto_help():
	if Global.current_place.name == Place.PlaceName.FLOWING_WATERS_TUTO:
		if Global.current_fish.name == "Flowfish":
			voice_help = voice_help_flowfish
		elif Global.current_fish.name == "Bubblefish":
			voice_help = voice_help_bubblefish
		elif Global.current_fish.name == "Selfish":
			voice_help = voice_help_selfish
		else:
			pass
	else:
		pass
