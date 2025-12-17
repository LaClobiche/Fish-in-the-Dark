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

var player_initial_position := Vector2i(400.0, 200.0)

@export var speed := 3600.0
@export var max_aspiration := 360.0
# if weight > 1.7, the player will be aspired even with input to the left
@export var aspiration_weight := 1.0
@export_range(0.0, 1.0) var friction = 0.5
@export_range(0.0 , 1.0) var acceleration = 0.1
@export var gravity = 4000

@onready var breach := $Sound2DNodes/Sound2DCenter
@onready var breach_area := $Sound2DNodes/Sound2DCenter/BreachArea2D
@onready var warning_left := $Sound2DNodes/Sound2DWarningLeft
@onready var warning_left_area := $Sound2DNodes/Sound2DWarningLeft/WarningArea2D
@onready var warning_right := $Sound2DNodes/Sound2DRight
@onready var warning_right_area := $Sound2DNodes/Sound2DRight/WarningArea2D
@onready var water := $Sound2DNodes/Sound2DLeft
@onready var water_area  := $Sound2DNodes/Sound2DLeft/WaterArea2D

@onready var vortex_center_sound := $Sound2DNodes/VortexCenterSound

@onready var animation_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	if Global.debug:
		show()
		Global.current_fish = load("res://places_and_fishes/swallowing_vortex/1_gonnby.tres")
	player.position = player_initial_position
	breach.max_distance = breach_area.global_position.x - (water_area.global_position.x * 2)
	breach.panning_strength = 1.0
	breach.attenuation = 0.9
	breach.volume_db = -5.0
	water.max_distance = water_area.global_position.x * 6
	water.panning_strength = 6.0
	water.attenuation = 1.0
	fish_hp_cooldown.timeout.connect(_on_fish_hp_cooldown_timeout)
	rod_hp_cooldown.timeout.connect(_on_rod_hp_cooldown_timeout)
	warning_left_area.body_entered.connect(_on_warning_left_area_2d_body_entered)
	warning_left_area.body_exited.connect(_on_warning_left_area_2d_body_exited)
	warning_right_area.body_entered.connect(_on_warning_right_area_2d_body_entered)
	warning_right_area.body_exited.connect(_on_warning_right_area_2d_body_exited)
	breach_area.body_entered.connect(_on_damage_area_2d_body_entered)
	breach_area.body_exited.connect(_on_damage_area_2d_body_exited)
	water_area.body_entered.connect(_on_damage_area_2d_body_entered)
	water_area.body_exited.connect(_on_damage_area_2d_body_exited)
	scene_intro()


func _physics_process(delta):
	player_move()


func _unhandled_input(event):
	super._unhandled_input(event)
	if current_state == State.INTRO:
		if event.is_action_pressed("left") or event.is_action_pressed("right"):
			Sound.play_next_voice()
	elif current_state == State.OUTRO:
		pass
	else:#current_state == State.LURING
		play_pulling_rod_sound(event)
		if event.is_action_pressed("left") and not Sound.is_se_playing(load("res://sounds/effects/luring/surf_vortex/whoosh_left_2.wav")):
			Sound.play_se(load("res://sounds/effects/luring/surf_vortex/whoosh_left_2.wav"))
		if event.is_action_pressed("right") and not Sound.is_se_playing(load("res://sounds/effects/luring/surf_vortex/whoosh_right_2.wav")):
			Sound.play_se(load("res://sounds/effects/luring/surf_vortex/whoosh_right_2.wav"))


func get_breach_aspiration(weight: float = 1.0) -> float:
	var aspiration_multiplier: float = player.position.x / breach.position.x
	aspiration_multiplier = clampf(aspiration_multiplier, 0.3, 1.0)
	var aspiration:= log(aspiration_multiplier + weight) * max_aspiration
	if aspiration < 0:
		aspiration = 0
	return aspiration


func get_player_speed() -> float:
	var speed_multiplier: float = (player.position.x / breach.position.x) + 0.7
	speed_multiplier = clampf(speed_multiplier, 0.7, 1.0)
	return speed_multiplier * speed

func player_move():
	if inputs and current_state == State.LURING:
		var dir = Input.get_axis("left", "right")
		if dir != 0:
			player.velocity.x = lerp(player.velocity.x, dir * get_player_speed(), acceleration)
		else:
			player.velocity.x = lerp(player.velocity.x, 0.0, friction)
		player.velocity.x += get_breach_aspiration(aspiration_weight)
		if player.velocity.x < 0 and dir == 0:
			player.velocity.x = 30.0
#		elif player.velocity.x > 0 and dir == -1:
#			player.velocity.x = - 20.0
		elif player.velocity.x > 0 and dir == 1:
			player.velocity.x = get_breach_aspiration(aspiration_weight) + lerp(player.velocity.x, 0.0, friction)
		else:
			pass
		player.move_and_slide()


func play_pulling_rod_sound(event: InputEvent):
	if event.is_action_pressed("left"):
		Sound.play_se(Sound.effects["move_left"])
		if not Sound.is_se_playing(Sound.effects["pull_left"]):
			Sound.play_se(Sound.effects["pull_left"])
	if event.is_action_pressed("right"):
		Sound.play_se(Sound.effects["move_right"])
		if not Sound.is_se_playing(Sound.effects["pull_right"]):
			Sound.play_se(Sound.effects["pull_right"])
	if event.is_action_released("left") and Sound.is_se_playing(Sound.effects["pull_left"]):
		Sound.stop_se_specified(Sound.effects["pull_left"])
	if event.is_action_released("right") and Sound.is_se_playing(Sound.effects["pull_right"]):
		Sound.stop_se_specified(Sound.effects["pull_right"])

func scene_intro():
	inputs = false
	Sound.play_voice(voice_intro)
	Sound.play_voice(voice_help)
	Sound.all_voices_finished.connect(scene_luring)
	inputs = true

# launched when intro is over/skipped
func scene_luring():
	super.scene_luring()
	fish_hp_cooldown.start()
	animation_player.play(Global.current_fish.name)
	breach.play(load("res://sounds/effects/luring/surf_vortex/vortex.mp3"))
	water.play(load("res://sounds/effects/luring/surf_vortex/insects.wav"))
	vortex_center_sound.play()


# launched when fish_hp == 0
func scene_outro():
	player.position = player_initial_position
	if fish_hp_cooldown.timeout.is_connected(_on_fish_hp_cooldown_timeout):
		fish_hp_cooldown.timeout.disconnect(_on_fish_hp_cooldown_timeout)
	if animation_player.is_playing():
		animation_player.stop()
	fish_hp_cooldown.stop()
	rod_hp_cooldown.stop()
	super.scene_outro()
	

func _on_damage_area_2d_body_entered(body: PhysicsBody2D):
	if body == player:
		_on_rod_hp_cooldown_timeout()
		rod_hp_cooldown.start()

func _on_damage_area_2d_body_exited(body: PhysicsBody2D):
	if body == player:
		rod_hp_cooldown.stop()

func _on_warning_left_area_2d_body_entered(body: PhysicsBody2D):
	if body == player:
		warning_left.play(load("res://sounds/effects/luring/surf_vortex/warning_left.wav"))

func _on_warning_left_area_2d_body_exited(body: PhysicsBody2D):
	if body == player:
		warning_left.stop()

func _on_warning_right_area_2d_body_entered(body: PhysicsBody2D):
	if body == player:
		warning_right.play(load("res://sounds/effects/luring/surf_vortex/warning_right.wav"))

func _on_warning_right_area_2d_body_exited(body: PhysicsBody2D):
	if body == player:
		warning_right.stop()

func _on_rod_hp_cooldown_timeout():
	Global.current_fishing_rod.take_damage(rod_damage)

func _on_fish_hp_cooldown_timeout():
	if warning_left_area.overlaps_body(player) or warning_right_area.overlaps_body(player):
		fish_hp_cooldown.start()
		return 
	fish_hp -= fish_damage
	var sound_tween := create_tween()
	sound_tween.tween_callback(func(): sound_node["CENTER"].play(sound_succeed, randf_range(0.0, 4.0)))
	sound_tween.tween_interval(0.2)
	sound_tween.tween_callback(func(): sound_node["CENTER"].stop_specified(sound_succeed))
	fish_hp_cooldown.start()
