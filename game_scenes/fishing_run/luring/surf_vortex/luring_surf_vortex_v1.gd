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


@export var speed := 750.0
@export_range(0.0, 1.0) var friction = 0.5
@export_range(0.0 , 1.0) var acceleration = 0.1

var swarm_scene: PackedScene = load("res://game_scenes/fishing_run/luring/surf_vortex/swarm_area.tscn")

@onready var breach := $Sound2DNodes/Sound2DCenter
@onready var breach_area := $Sound2DNodes/Sound2DCenter/BreachArea2D
@onready var water := $Sound2DNodes/Sound2DLeft
@onready var water_area  := $Sound2DNodes/Sound2DLeft/WaterArea2D
@onready var vortex_sound := $VortexSound

@onready var animation_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	if Global.debug:
		show()
#		Global.current_fish = load("res://places_and_fishes/swallowing_vortex/4_magnimahi.tres")
	fish_hp_cooldown.timeout.connect(_on_fish_hp_cooldown_timeout)
	rod_hp_cooldown.timeout.connect(_on_rod_hp_cooldown_timeout)
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


func player_move():
	if inputs and current_state == State.LURING:
		var dir = Input.get_axis("left", "right")
		if dir != 0:
			player.velocity.x = lerp(player.velocity.x, dir * speed, acceleration)
		else:
			player.velocity.x = lerp(player.velocity.x, 0.0, friction)
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
	breach.play(load("res://sounds/effects/luring/surf_vortex/insects.wav"))
	water.play(load("res://sounds/effects/luring/surf_vortex/insects.wav"))
	vortex_sound.play()


# launched when fish_hp == 0
func scene_outro():
	player.position = Vector2(640,360)
	if fish_hp_cooldown.timeout.is_connected(_on_fish_hp_cooldown_timeout):
		fish_hp_cooldown.timeout.disconnect(_on_fish_hp_cooldown_timeout)
	var swarms_array := get_node("Swarms").get_children()
	swarms_array.append_array([breach_area, water_area])
	print(swarms_array)
	for swarm in swarms_array:
		if swarm.body_entered.is_connected(_on_damage_area_2d_body_entered):
			swarm.body_entered.disconnect(_on_damage_area_2d_body_entered)
		if swarm.body_exited.is_connected(_on_damage_area_2d_body_exited):
			swarm.body_exited.disconnect(_on_damage_area_2d_body_exited)
		swarm.set_deferred("monitoring", false)
	if animation_player.is_playing():
		animation_player.stop()
	fish_hp_cooldown.stop()
	rod_hp_cooldown.stop()
	super.scene_outro()


func new_swarm(dict_position: String, speed: float = 300.0):
	var swarm_properties := {
	"left" : [get_node("Player").position.x - 150.0, 1.3],
	"center" : [get_node("Player").position.x, 1.0],
	"right" : [get_node("Player").position.x + 150.0, 0.7],
	"player" :[get_node("Player").position.x, 1.0],
	}
	
	var swarm := swarm_scene.instantiate()
	get_node("Swarms").add_child(swarm)
	swarm.position = Vector2(swarm_properties[dict_position][0], 0.0)
	swarm.speed = speed
	swarm.pitch_scale = swarm_properties[dict_position][1]
	swarm.body_entered.connect(_on_damage_area_2d_body_entered)
	swarm.body_exited.connect(_on_damage_area_2d_body_exited)


func _on_damage_area_2d_body_entered(body: PhysicsBody2D):
	if body == player:
		_on_rod_hp_cooldown_timeout()
		rod_hp_cooldown.start()
		body.get_node("Sound2D").play(Sound.effects["insects_eating"])
		body.get_node("Sound2D").play(Sound.effects["crunch"])
		var swarms_array := get_node("Swarms").get_children()
		if not swarms_array.is_empty():
			for swarm in swarms_array:
				swarm.queue_free()

func _on_damage_area_2d_body_exited(body: PhysicsBody2D):
	if body == player:
		rod_hp_cooldown.stop()


func _on_rod_hp_cooldown_timeout():
	Global.current_fishing_rod.take_damage(rod_damage)


func _on_fish_hp_cooldown_timeout():
#	if warning_left_area.overlaps_body(player) or warning_right_area.overlaps_body(player):
#		fish_hp_cooldown.start()
#		return 
	fish_hp -= fish_damage
	var sound_tween := create_tween()
	sound_tween.tween_callback(func(): player.get_node("Sound2D").play(sound_succeed, randf_range(0.0, 4.0)))
	sound_tween.tween_interval(0.2)
	sound_tween.tween_callback(func(): player.get_node("Sound2D").stop_specified(sound_succeed))
	fish_hp_cooldown.start()
