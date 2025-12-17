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

#func is_timing_succeed(damage_on: bool = true) -> bool:


@export var speed = 70
@export_range(0.0, 1.0) var friction = 0.5
@export_range(0.0 , 1.0) var acceleration = 0.5

var gaze_sound: AudioStream = load("res://sounds/effects/luring/avoid_gaze/gaze.mp3")
var sound_interval := load("res://sounds/effects/bubbles_loop_low.wav")
var underwater_sound := load("res://sounds/effects/luring/avoid_gaze/underwater.wav")

# used only for the distinctuna tips (see _on_rod_hp_cooldown)
var retry_index := 0

var muffled_effect := AudioEffectLowPassFilter.new()
var bus_numbers := [AudioServer.get_bus_index("SoundEffects"), AudioServer.get_bus_index("Ambience")]

@onready var listener := $Player/AudioListener2D
@onready var anim_player := $AnimationPlayer
@onready var gaze_area := $Sound2DNodes/Sound2DCenter/Area2D
@onready var safe_areas: Array = $SafeAreas.get_children()
@onready var hitbox := $Player/Hitbox
@onready var goal_area := $Goal/GoalArea
@onready var bubble_sound_timer := $BubbleSoundTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	player.position = Global.get_viewport_directed_position(DIR.CENTER)
	voice_intro = load("res://sounds/voice_resources/luring/avoid_gaze/voice_intro.tres")
	if Global.debug:
		show()
#		Global.current_fish = load("res://places_and_fishes/everwatching_cove/3_raybellion.tres")
#		Sound.play_ambience(load("res://sounds/ambience/pond_night_loop.wav"))
	rod_hp_cooldown.timeout.connect(_on_rod_hp_cooldown_timeout)
	for area in safe_areas:
		area.body_entered.connect(_on_safe_area_2d_body_entered)
		area.body_exited.connect(_on_safe_area_2d_body_exited)
	gaze_area.area_entered.connect(_on_gaze_area_2d_area_entered)
	gaze_area.area_exited.connect(_on_gaze_area_2d_area_exited)
	goal_area.body_entered.connect(_on_goal_area_2d_body_entered)
	sound_node["CENTER"].position.x = 0.0
	sound_node["CENTER"].max_distance = 400.0
	sound_node["CENTER"].set_panning_strength(60.0)
	scene_intro()


func _physics_process(delta):
	if inputs and current_state == State.LURING:
		player.velocity.y += delta
		var dir = Input.get_axis("left", "right")
		if dir != 0:
			player.velocity.x = lerp(player.velocity.x, dir * speed, acceleration)
		else:
			player.velocity.x = lerp(player.velocity.x, 0.0, friction)
		player.move_and_slide()
		Signals.lure_position.emit(Vector2(320 + (player.global_position.x / 2), 570))
#		set_bubble_sound_timer(player, 640.0, goal_area.position.x, 4.0)


func _unhandled_input(event):
	super._unhandled_input(event)
	if inputs:
		if current_state == State.INTRO:
			if event.is_action_pressed("left") or event.is_action_pressed("right"):
				Sound.play_next_voice()
		elif current_state == State.OUTRO:
			pass
		else:#current_state == State.LURING
			if event.is_action_pressed("left") and not Sound.is_se_playing(Sound.effects["move_left"]):
				Sound.play_se(Sound.effects["move_left"])
				Signals.rod_state.emit("left")
			if event.is_action_pressed("right") and not Sound.is_se_playing(Sound.effects["move_right"]):
				Sound.play_se(Sound.effects["move_right"])
				Signals.rod_state.emit("right")


# wait_time decreasing when getting from strat_post_x to end_pos_x
func set_bubble_sound_timer(player_node: Node2D, start_pos_x: float, end_pos_x: float, first_time_interval: float):
#	var distance_adjustement := 100.0
	var total_distance := end_pos_x - start_pos_x
	var progression := (player_node.position.x - start_pos_x) / total_distance
	var frequency = ease((1 - progression), 2.0) * first_time_interval
	frequency = clampf(frequency, 0.2, first_time_interval)
	bubble_sound_timer.wait_time = frequency


func play_bubble_success():
	var tween = create_tween()
	tween.tween_callback(func(): Sound.play_se(sound_succeed))
	tween.tween_interval(0.5)
	tween.tween_callback(func(): Sound.stop_se_specified(sound_succeed))


func scene_intro():
	inputs = false
	for bus_idx in bus_numbers:
		AudioServer.set_bus_mute(bus_idx, true)
	Sound.play_voice(voice_intro)
	Sound.play_voice(voice_help)
	Sound.all_voices_finished.connect(scene_luring)
	inputs = true


func scene_luring():
	for bus_idx in bus_numbers:
		AudioServer.set_bus_mute(bus_idx, false)
	super.scene_luring()
	gaze_area.monitoring = true
	sound_node["CENTER"].play(gaze_sound, 0.0)
	anim_player.play(Global.current_fish.name)
	gaze_area.set_deferred("monitoring", true)



func scene_outro():
	anim_player.call_deferred("stop")
	if rod_hp_cooldown.timeout.is_connected(_on_rod_hp_cooldown_timeout):
		rod_hp_cooldown.timeout.disconnect(_on_rod_hp_cooldown_timeout)
	if gaze_area.area_entered.is_connected(_on_gaze_area_2d_area_entered):
		gaze_area.area_entered.disconnect(_on_gaze_area_2d_area_entered)
	if gaze_area.area_exited.is_connected(_on_gaze_area_2d_area_exited):
		gaze_area.area_exited.disconnect(_on_gaze_area_2d_area_exited)
	for area in safe_areas:
		if area.body_entered.is_connected(_on_safe_area_2d_body_entered):
			area.body_entered.disconnect(_on_safe_area_2d_body_entered)
			area.body_exited.disconnect(_on_safe_area_2d_body_exited)
		area.set_deferred("monitoring", false)
	gaze_area.set_deferred("monitoring", false)
	set_audio_effect(false)
	rod_hp_cooldown.stop()
	bubble_sound_timer.stop()
	Sound.stop_se()
	Sound.play_ambience(Sound.ambiences["pond_night"])
	play_bubble_success()
	super.scene_outro()


func set_audio_effect(on: bool):
	for bus_idx in bus_numbers:
		if AudioServer.get_bus_effect_count(bus_idx) == 0:
			print(AudioServer.get_bus_effect_count(bus_idx))
			muffled_effect.set_cutoff(500.0)
			muffled_effect.resonance = 0.8
#			muffled_effect.set_db(AudioEffectLowPassFilter.FILTER_24DB)
			AudioServer.add_bus_effect(bus_idx, muffled_effect, 0)
	if on:
		for bus_idx in bus_numbers:
			AudioServer.set_bus_effect_enabled(bus_idx, 0, true)
	if not on:
		for bus_idx in bus_numbers:
			AudioServer.set_bus_effect_enabled(bus_idx, 0, false)


func _on_bubble_sound_timer_timeout():
	var bubble_sound_time := 0.2
	if bubble_sound_timer.wait_time <= bubble_sound_time:
		if not Sound.is_se_playing(sound_interval):
			Sound.play_se(sound_interval)
	else:
		var bubble_tween = create_tween()
		bubble_tween.tween_callback(func(): Sound.play_se(sound_interval, randf_range(0.0, 4.0)))
		bubble_tween.tween_interval(bubble_sound_time)
		bubble_tween.tween_callback(func(): Sound.stop_se_specified(sound_interval))


func _on_safe_area_2d_body_entered(body):
	if body is CharacterBody2D:
		set_audio_effect(true)
		Sound.play_se(underwater_sound)
		Sound.stop_ambience()
		hitbox.set_deferred("monitorable", false)


func _on_safe_area_2d_body_exited(body):
	if body is CharacterBody2D:
		print("gaze_on")
		set_audio_effect(false)
		Sound.play_ambience(Sound.ambiences["pond_night"])
		Sound.stop_se_specified(underwater_sound)
		hitbox.set_deferred("monitorable", true)


func _on_gaze_area_2d_area_entered(area):
	if area == hitbox:
		_on_rod_hp_cooldown_timeout()
		rod_hp_cooldown.start()


func _on_gaze_area_2d_area_exited(_area):
	rod_hp_cooldown.stop()


func _on_goal_area_2d_body_entered(_body):
	scene_outro()


func _on_rod_hp_cooldown_timeout():
	Global.current_fishing_rod.take_damage(rod_damage)
	var wait := create_tween()
	inputs = false
	wait.tween_interval(0.5)
	await wait.finished
	_on_safe_area_2d_body_entered(player)
	## tip enabler for distinctuna
	if Global.current_fish.name == "Distinctuna":
		retry_index += 1
		if retry_index == 4 and not Sound.is_voices_playing():
			Sound.play_voice(load("res://sounds/voice_resources/luring/avoid_gaze/path_tip1.tres"))
		if retry_index > 8 and not Sound.is_voices_playing():
			Sound.play_voice(load("res://sounds/voice_resources/luring/avoid_gaze/path_tip2.tres"))
	inputs = true
	player.position = Vector2(640, 360)
