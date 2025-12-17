extends Luring
#signal sound_node_moved(node)
#State.INTRO/LURING/OUTRO
#DIR.LEFT/RIGHT/UP/DOWN/CENTER
#var current_sound_node: Sound2D
#var inputs: bool = false
#var timing_succeed: bool = false
#var current_state: State = State.INTRO
#var player = $Player
#var sound_node = {"LEFT","CENTER","RIGHT"}

#func is_timing_succeed(damage_on: bool = true):

var enter_input: bool = false


var sound_wood_insects := load("res://sounds/effects/luring/surf_vortex/wood_insects.wav")
var sound_congo_insects := load("res://sounds/effects/luring/surf_vortex/congo_insects.wav")
var sound_wood := load("res://sounds/effects/luring/surf_vortex/wood.wav")
var sound_congo := load("res://sounds/effects/luring/surf_vortex/congo.wav")

@onready var rythm_sound := $Sound2DNodes/Sound2DCenter
@onready var vortex_sound := $VortexSound
@onready var animation_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	if Global.debug:
		show()
		#Global.current_fish = load("res://places_and_fishes/swallowing_vortex/1_gonnby.tres")
	scene_intro()


func _unhandled_input(event):
	super._unhandled_input(event)
	if current_state == State.INTRO:
		if event.is_action_pressed("left") or event.is_action_pressed("right"):
			Sound.play_next_voice()
	elif current_state == State.OUTRO:
		pass
	else:#current_state == State.LURING
		if event.is_action_pressed("left") or event.is_action_pressed("right"):
			play_rod_sound(event)
			if not is_input_correct(event) and rod_hp_cooldown.is_stopped():
				damage_get()
				print("input : bad timing")
			elif is_input_correct(event):
				damage_give()
				Sound.play_se(Sound.effects["casting_whoosh"])
				enter_input = false
				print("input : good timing")
			else:
				pass


func scene_intro():
	inputs = false
	if Global.current_fish.name == "Gonnby":
		fish_damage = 34
	elif Global.current_fish.name == "Worthita":
		fish_damage = 17
	elif Global.current_fish.name == "Ogurnard":
		fish_damage = 13
	elif Global.current_fish.name == "Magnimahi":
		fish_damage = 9
	else:
		pass
	Sound.play_ambience(load("res://sounds/ambience/vortex_ambience.wav"))
	Sound.play_voice(voice_intro)
	Sound.play_voice(voice_help)
	Sound.play_voice(Sound.voices["pause_1_s"])
	Sound.all_voices_finished.connect(scene_luring)
	inputs = true


# launched when intro is over/skipped
func scene_luring():
	super.scene_luring()
	rod_hp_cooldown.start()
	animation_player.play(Global.current_fish.name)
	#breach.play(load("res://sounds/effects/luring/surf_vortex/insects.wav"))
	#water.play(load("res://sounds/effects/luring/surf_vortex/insects.wav"))


# launched when fish_hp == 0
func scene_outro():
	player.position = Vector2(640,360)
	if animation_player.is_playing():
		animation_player.stop()
	fish_hp_cooldown.stop()
	rod_hp_cooldown.stop()
	Sound.stop_ambience()
	Sound.play_ambience(Sound.ambiences["pond_night"])
	super.scene_outro()

func set_enter_input(bool):
	enter_input = bool

func time_out():
	# if is_input_correct returns true, enter_input is set to false.
	# At the time_out, enter_input is true means that the player didn't give any inputs.
	if enter_input == true and rod_hp_cooldown.is_stopped():
		damage_get()
	enter_input = false

# return true if pulling inputs are correct
func is_input_correct(event: InputEvent) -> bool:
	if event == null:
		return false
	if (event.is_action_pressed("right") or event.is_action_pressed("left")) and enter_input:
		return true
	else:
		return false


func play_rod_sound(event: InputEvent):
	if event == null:
		return
	if event.is_action_pressed("left") and not Sound.is_se_playing(Sound.effects["move_right"]):
		Sound.play_se(Sound.effects["move_left"])
		Signals.rod_state.emit("left")
	if event.is_action_pressed("right") and not Sound.is_se_playing(Sound.effects["move_left"]):
		Sound.play_se(Sound.effects["move_right"])
		Signals.rod_state.emit("right")

func play_wood():
	Sound.play_se(sound_wood)


func play_congo():
	Sound.play_se(sound_congo)


func play_wood_insects():
	Sound.play_se(sound_wood_insects)


func play_congo_insects():
	Sound.play_se(sound_congo_insects)


func damage_give():
	Sound.play_se(load("res://sounds/effects/luring/surf_vortex/success.wav"))
	var sound_tween := create_tween()
	sound_tween.tween_callback(func(): player.get_node("Sound2D").play(sound_succeed, randf_range(0.0, 4.0)))
	sound_tween.tween_interval(0.2)
	sound_tween.tween_callback(func(): player.get_node("Sound2D").stop_specified(sound_succeed))
	fish_hp -= fish_damage
	# we start the cooldown for the player's rod to avoid accidental double inputs.
	rod_hp_cooldown.start()


func damage_get():
	Global.current_fishing_rod.take_damage(rod_damage)
	Sound.play_se(load("res://sounds/effects/luring/surf_vortex/crunch.wav"))
	rod_hp_cooldown.start()


func _on_fish_hp_cooldown_timeout():
	fish_hp -= fish_damage
	var sound_tween := create_tween()
	sound_tween.tween_callback(func(): player.get_node("Sound2D").play(sound_succeed, randf_range(0.0, 4.0)))
	sound_tween.tween_interval(0.2)
	sound_tween.tween_callback(func(): player.get_node("Sound2D").stop_specified(sound_succeed))
	fish_hp_cooldown.start()
