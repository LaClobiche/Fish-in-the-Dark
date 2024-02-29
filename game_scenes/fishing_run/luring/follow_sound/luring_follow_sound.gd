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

@export var sound_to_follow: AudioStream = load("res://sounds/effects/luring/river_loop.mp3")
@export var speed = 600
@export_range(0.0, 1.0) var friction = 0.3
@export_range(0.0 , 1.0) var acceleration = 0.01

@onready var listener := $Player/AudioListener2D
@onready var anim_player := $AnimationPlayer
@onready var sound_area := $Sound2DNodes/Sound2DCenter/Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	fish_hp_cooldown.timeout.connect(_on_fish_hp_cooldown_timeout)
	rod_hp_cooldown.timeout.connect(_on_rod_hp_cooldown_timeout)
	sound_area.body_entered.connect(_on_area_2d_body_entered)
	sound_area.body_exited.connect(_on_area_2d_body_exited)
	sound_node["CENTER"].set_panning_strength(45.0)


func _physics_process(delta):
	if inputs:
		player.velocity.y += delta
		var dir = Input.get_axis("left", "right")
		if dir != 0:
			player.velocity.x = lerp(player.velocity.x, dir * speed, acceleration)
		else:
			player.velocity.x = lerp(player.velocity.x, 0.0, friction)
		player.move_and_slide()


func _unhandled_input(event):
	super._unhandled_input(event)
	if inputs:
		if current_state == State.INTRO:
			if event.is_action_pressed("left") or event.is_action_pressed("right"):
				Sound.stop_voice_array_and_queue()
				scene_luring()
		elif current_state == State.OUTRO:
			pass
		else:#current_state == State.LURING
			if event.is_action_pressed("left") and not Sound.is_se_playing(Sound.effects["move_left"]):
				Sound.play_se(Sound.effects["move_left"])
			if event.is_action_pressed("right") and not Sound.is_se_playing(Sound.effects["move_right"]):
				Sound.play_se(Sound.effects["move_right"])


func scene_luring():
	super.scene_luring()
	sound_area.monitoring = true
	sound_node["CENTER"].play(sound_to_follow, 0.0)
	anim_player.play(Global.current_fish.name)


func scene_outro():
	if fish_hp_cooldown.timeout.is_connected(_on_fish_hp_cooldown_timeout):
		fish_hp_cooldown.timeout.disconnect(_on_fish_hp_cooldown_timeout)
	if rod_hp_cooldown.timeout.is_connected(_on_rod_hp_cooldown_timeout):
		rod_hp_cooldown.timeout.disconnect(_on_rod_hp_cooldown_timeout)
	if sound_area.body_entered.is_connected(_on_area_2d_body_entered):
		sound_area.body_entered.disconnect(_on_area_2d_body_entered)
	if sound_area.body_exited.is_connected(_on_area_2d_body_exited):
		sound_area.body_exited.disconnect(_on_area_2d_body_exited)
	fish_hp_cooldown.stop()
	rod_hp_cooldown.stop()
	anim_player.play("RESET")
	super.scene_outro()


func _on_area_2d_body_entered(_body):
	_on_fish_hp_cooldown_timeout()
	rod_hp_cooldown.stop()


func _on_area_2d_body_exited(_body):
	fish_hp_cooldown.stop()
	rod_hp_cooldown.start()


func _on_fish_hp_cooldown_timeout():
	fish_hp -= fish_damage
	var sound_tween := create_tween()
	sound_tween.tween_callback(func(): sound_node["CENTER"].play(sound_succeed, randf_range(0.0, 4.0)))
	sound_tween.tween_interval(0.2)
	sound_tween.tween_callback(func(): sound_node["CENTER"].stop_specified(sound_succeed))
	fish_hp_cooldown.start()


func _on_rod_hp_cooldown_timeout():
	Global.current_fishing_rod.take_damage(rod_damage)
