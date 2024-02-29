class_name Casting

extends Node2D


#2 different way to say to water :
#"It seems"
#"You're now in"


# intro : You should cast your fishing rod. OK
# help : maintain right to raise your fishing rode and strengthen your cast. Release right to cast.
### It seems" "you're now in ...."
### Allow to reel : "you can reel your fishing rod to explore other waters." 
### help : "Press right to reel, press left to fish here."
### if back to 0 : "Alas, you cannot fish yourself. Try casting your rod again." 
# help
# Success : info on where it has landed : "It seems that your lure has fallen into ..." 
# Fail : rod_hp down and go back to help. "You should be fishing, not hurting. Take a deep breath and try again."

enum State {
	PREPARE_TO_CAST,
	INTRO_RUN_CONTINUE,
	CASTING,
	REELING,
}

var damage_if_fail: int = 10
var inputs: bool = false
var places_not_completed: Array[Place.PlaceName] = []
var reeling_time_amplitude: float = 0.5
var state : State = State.PREPARE_TO_CAST

var voice_help = load("res://sounds/voice_resources/casting/help.tres")
var voices := {
	"intro" : load("res://sounds/voice_resources/casting/intro.tres"),
	"intro_run_continue" : load("res://sounds/voice_resources/casting/intro_run_continue.tres"),#
	"intro_help" : load("res://sounds/voice_resources/casting/help.tres"),
	"casting_failed" : load("res://sounds/voice_resources/casting/cast_failed.tres"),
	"casting_succeeded" : load("res://sounds/voice_resources/casting/cast_succeeded.tres"),
	"casting_succeeded_help" : load("res://sounds/voice_resources/casting/cast_succeeded_help.tres"),#
	"lure_moved" : load("res://sounds/voice_resources/casting/lure_moved.tres"),
	"lure_back" : load("res://sounds/voice_resources/casting/lure_back.tres"),
}

@onready var casting_timer := $CastingTimer
@onready var reeling_sound_timer := $ReelingSoundTimer
@onready var reeling_timer := $ReelingTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	casting_timer.timeout.connect(cast_end)
	reeling_timer.timeout.connect(lure_back)
	scene_intro()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _unhandled_input(event):
	if event.is_action_pressed("top"):
		Signals.scene_requested.emit("toggle_pause")
	elif not inputs:
		return
	else:
		if event.is_action_pressed("left") or event.is_action_pressed("right"):
			Sound.stop_voice_array_and_queue()
		if state == State.PREPARE_TO_CAST:
			if event.is_action_pressed("right"):
				cast_start()
		elif state == State.CASTING:
			if event.is_action_released("right"):
				cast_end()
		elif state == State.REELING:
			if event.is_action_pressed("left"):
				Global.set_current_fish()
				Signals.scene_requested.emit("luring")
			if event.is_action_released("right"):
				reeling(false)
			if event.is_action_pressed("right"):
				reeling(true)


func cast_start():
	inputs = true
	state = State.CASTING
	Sound.play_se(Sound.effects["casting_strengthen"])
	Sound.play_se(Sound.effects["casting_whoosh"])
	casting_timer.start()


func cast_end() :
	inputs = false
	Sound.stop_se_specified(Sound.effects["casting_strengthen"])
	var time_left: float = casting_timer.time_left
	# if the timer ends, the casting fails
	if is_zero_approx(time_left):
		casting_timer.stop()
		Global.current_fishing_rod.take_damage(damage_if_fail)
		if Global.current_fishing_rod.hp > 0:
			cast_end_fail_sounds()
			# go back to casting_help
			await Sound.all_voices_finished
			casting_help()
			state = State.PREPARE_TO_CAST
			inputs = true
	# if the timer stops before, the casting succeeds
	else:
		# get place_resource associated with CastingTimer timing.
		Global.current_place = Global.get_place_resource(get_place_name_from_timer(casting_timer))
		casting_timer.stop()
		cast_end_succeed_sounds(time_left)
		await reeling_sound_timer.timeout
		cast_new_place_sounds()
		reeling_timer.wait_time = reeling_sound_timer.wait_time * 3
		reeling_timer.start()
		reeling_timer.paused = true
		state = State.REELING
		inputs = true


func cast_end_fail_sounds():
	Sound.stop_se()
	Sound.play_se(Sound.effects["casting_exhausted"])
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.play_voice(voices["casting_failed"])


func cast_end_succeed_sounds(time_left: float):
	Sound.stop_se()
	# get reeling_timer wait_time, start the timer and the sound effect
	reeling_sound_timer.wait_time = get_reeling_sound_time(time_left)
	reeling_sound_timer.start()
	Sound.play_se(Sound.effects["casting_swish"])
	Sound.play_se(Sound.effects["reeling_super_fast"])
	await reeling_sound_timer.timeout
	Sound.stop_se_specified(Sound.effects["reeling_super_fast"])
	Sound.play_se(Sound.effects["casting_lure_in"])


func cast_new_place_sounds():
	if state == State.CASTING:
		Sound.play_voice(Sound.voices["pause_1_s"])
		Sound.play_voice(voices["casting_succeeded"])
	elif state == State.REELING:
		Sound.stop_voice_array_and_queue()
		Sound.play_voice(voices["lure_moved"])
	else:
		return
	Sound.play_voice(Global.current_place.voice_name)
	if state == State.CASTING:
		voice_help = voices["casting_succeeded_help"]
		Sound.play_voice(voice_help)


func casting_help():
	Sound.play_voice(Sound.voices["pause_1_s"])
	voice_help = voices["intro_help"]
	Sound.play_voice(voice_help)


## returns a non-completed place_name corresponding to timing
func get_place_name_from_timer(timer: Timer) -> Place.PlaceName:
	var place_to_return : Place.PlaceName
	var time: float = timer.wait_time
	var time_left: float = timer.time_left
	# get the non completed places
	places_not_completed = Global.get_places_not_completed()
	# if the tuto zone (flowing waters) not completed, only choose this one.
	if Place.PlaceName.FLOWING_WATERS_TUTO in places_not_completed and not Saves.data["game_finished"]:
		return Place.PlaceName.FLOWING_WATERS_TUTO
	# else get the place from time_left
	else:
		# if the almanac is completed, add every places in places_not_completed
		if places_not_completed.is_empty():
			for key in Place.PlaceName:
				places_not_completed.append(Place.PlaceName[key])
		var time_step := time / places_not_completed.size()
		var step_starts: float = 0.0
		var step_ends: float = time_step
		for place_name in places_not_completed:
			if step_starts <= time_left and time_left < step_ends:
				place_to_return = place_name
			step_starts = step_ends
			step_ends = step_ends + time_step
		return place_to_return


## gives a time to play the reeling sound effect
func get_reeling_sound_time(time_left: float) -> float:
	var reeling_time: float = (casting_timer.wait_time - time_left)
	reeling_time *= reeling_time_amplitude
	return reeling_time


func lure_back():
	inputs = false
	state = State.PREPARE_TO_CAST
	Sound.stop_se()
	Sound.play_voice(voices["lure_back"])
	await Sound.all_voices_finished
	inputs = true
	casting_help()


## reel to change Global.current_place:
func reeling(toggle: bool):
	print("reeling: " + str(toggle)) 
	if toggle:
		Sound.play_se(Sound.effects["reeling_normal"])
		print("time left: " + str(reeling_timer.time_left) + str(reeling_timer.paused))
		if reeling_timer.paused:
			reeling_timer.paused = false
		else:
			reeling_timer.paused = true
		print(reeling_timer.paused)
		print("time left: " + str(reeling_timer.time_left) + str(reeling_timer.paused))
	else:
		reeling_timer.paused = true
		Sound.stop_se_specified(Sound.effects["reeling_normal"])
		Global.current_place = Global.get_place_resource(get_place_name_from_timer(reeling_timer))
		cast_new_place_sounds()


func scene_intro():
	if state == State.INTRO_RUN_CONTINUE:
		Sound.play_voice(voices["intro"])
	else:
		Sound.play_voice(voices["intro"])
	state = State.PREPARE_TO_CAST
	casting_help()
	inputs = true


func scene_handler_argument(argument: String):
	if argument == "run_continue":
		state = State.INTRO_RUN_CONTINUE
	else:
		print("casting.gd, scene_handler_argument(), unknown argument: " + argument)
		pass
