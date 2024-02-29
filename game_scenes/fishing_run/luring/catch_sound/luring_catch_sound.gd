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

var sound_to_catch: SoundEffectResource = load("res://sounds/effects/luring/catch_sound/chant.tres")
var sound_interval := load("res://sounds/effects/bubbles_loop_low.wav")
@export var speed = 800
@export_range(0.0, 1.0) var friction = 0.1
@export_range(0.0 , 1.0) var acceleration = 0.08

@onready var listener := $Player/AudioListener2D
@onready var anim_player := $AnimationPlayer
@onready var sound_areas := [$Sound2DNodes/Sound2DCenter/Area2D, $Sound2DNodes/Sound2DRight/Area2D, $Sound2DNodes/Sound2DLeft/Area2D]
@onready var nodes_to_catch := [$Sound2DNodes/Sound2DCenter, $Sound2DNodes/Sound2DRight, $Sound2DNodes/Sound2DLeft]



## to stock bubble sound tween used in progressive_bubbles_play()
var bubble_tween: Tween
## dictionary of sound sequences according to fish name, used in set_sequence
var sequences_dict := {
	"Warmseeker" : [[Callable(play.bind(300.0, 7.0)), Callable(play.bind(900.0, 7.0))], Callable(set_fish_damage.bind(30)), "single"],
	"Receiveel" : [[Callable(play.bind(100.0, 5.0, 2.0)), Callable(play.bind(1100.0, 5.0, 2.0)), Callable(play.bind(640.0, 5.0, 2.0))],Callable(set_fish_damage.bind(30)), "single"],
	"Preacheel" : [[],Callable(set_fish_damage.bind(15)), "parallel"],
	"Enlighteel" : [[],Callable(set_fish_damage.bind(15)), "parallel"]
}
var sequence_index := 0


# Called when the node enters the scene tree for the first time.
func _ready():
#	Global.current_fish = load("res://places_and_fishes/lonely_waters/4_enlighteel.tres")
	fish_hp_cooldown.timeout.connect(_on_fish_hp_cooldown_timeout)
#	rod_hp_cooldown.timeout.connect(_on_rod_hp_cooldown_timeout)
	voice_help = load("res://sounds/voice_resources/luring/catch_sound/voice_help.mp3")
	voice_intro = load("res://sounds/voice_resources/luring/catch_sound/voice_intro.mp3")
	for node in nodes_to_catch:
		node.max_distance = 1000.0
		node.set_panning_strength(60.0)
	for area in sound_areas:
		area.body_exited.connect(_on_area_2d_body_exited)
		area.body_entered.connect(_on_area_2d_body_entered)
	super._ready()


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


func set_sequence():
	var sequences: Array = sequences_dict[Global.current_fish.name]
	sequences[1].call()
	if sequences[2] == "parallel":
		anim_player.play(Global.current_fish.name) 
	else:
		if sequence_index >= sequences[0].size():
			sequence_index = 0
		sequences[0][sequence_index].call()
		sequence_index += 1


func set_fish_damage(number: int):
	fish_damage = number


func scene_luring():
	super.scene_luring()
#	anim_player.play(Global.current_fish.name)
	set_sequence()


func scene_outro():
	if fish_hp_cooldown.timeout.is_connected(_on_fish_hp_cooldown_timeout):
		fish_hp_cooldown.timeout.disconnect(_on_fish_hp_cooldown_timeout)
	if anim_player.is_playing():
		anim_player.stop()
	for area in sound_areas:
		if area.body_entered.is_connected(_on_area_2d_body_entered):
			area.body_entered.disconnect(_on_area_2d_body_entered)
		if area.body_exited.is_connected(_on_area_2d_body_exited):
			area.body_exited.disconnect(_on_area_2d_body_exited)
		area.set_deferred("monitoring", false)
	for node in nodes_to_catch:
		node.stop()
	fish_hp_cooldown.stop()
	rod_hp_cooldown.stop()
	super.scene_outro()


func play_parallel(x_position: float, time: float, from: float = 0.0):
	var node
	for node_to_catch in nodes_to_catch:
		if not node_to_catch.is_playing():
			node = node_to_catch
	node.get_node("Area2D").set_deferred("monitoring", true)
	node.position = Vector2(x_position, 360.0)
	node.play(sound_to_catch, from, false, time)
	node.wait = create_tween()
	node.wait.tween_interval(time)
	node.wait.tween_callback(func(): print("stop by tween wait"))
	node.wait.tween_callback(stop_parallel.bind(node))


func play(x_position: float, time: float, from: float = 0.0):
	var node = nodes_to_catch[0]
	node.get_node("Area2D").set_deferred("monitoring", true)
	node.position = Vector2(x_position, 360.0)
	node.play(sound_to_catch, from, false, time)
	node.wait = create_tween()
	node.wait.tween_interval(time)
	node.wait.tween_callback(func(): print("stop by tween wait"))
	node.wait.tween_callback(stop.bind(node))


func stop(node: Node2D):
	print("stop")
	if node.wait != null:
		node.wait.kill()
	node.stop()
	fish_hp_cooldown.stop()
	var bodies_array = node.get_node("Area2D").get_overlapping_bodies()
	var succeed = false
	for body in bodies_array:
		if body is CharacterBody2D:
			succeed = true
	damage(succeed)
	var interval := create_tween()
	interval.tween_interval(randf_range(0.5,2))
	interval.tween_callback(func(): node.stop())
	interval.tween_callback(set_sequence)
	node.get_node("Area2D").set_deferred("monitoring", false)
	node.position = Vector2.ZERO


func stop_parallel(node: Node2D):
	print("stop parallel")
	if node.wait != null:
		node.wait.kill()
	node.stop()
	fish_hp_cooldown.stop()
	var bodies_array = node.get_node("Area2D").get_overlapping_bodies()
	var succeed = false
	for body in bodies_array:
		if body is CharacterBody2D:
			succeed = true
	damage(succeed)
	node.get_node("Area2D").set_deferred("monitoring", false)
	node.position = Vector2.ZERO


func _on_area_2d_body_entered(_body):
	print("body in")
	var time: float = fish_hp_cooldown.wait_time
	play_bubble_until(time, 0.6)
	fish_hp_cooldown.start()


func _on_area_2d_body_exited(_body):
	print("body out")
	fish_hp_cooldown.stop()
	stop_bubble_until()


func damage(succeeded: bool):
	if succeeded:
		play_bubble()
		fish_hp -= fish_damage
	else:
		Global.current_fishing_rod.take_damage(rod_damage)


func play_bubble():
	var tween = create_tween()
	tween.tween_callback(func(): Sound.play_se(sound_succeed))
	tween.tween_interval(0.5)
	tween.tween_callback(func(): Sound.stop_se_specified(sound_succeed))



func play_bubble_until(time: float, first_interval: float):
	if bubble_tween != null:
		bubble_tween.kill()
	var bubble_time := 0.2
	var remaining := time - bubble_time
	bubble_tween = create_tween()
	bubble_tween.tween_interval(bubble_time)
	while remaining > 0.0:
		bubble_tween.tween_callback(func(): Sound.play_se(sound_interval, randf_range(0.0, 4.0)))
		bubble_tween.tween_interval(bubble_time)
		bubble_tween.tween_callback(func(): Sound.stop_se_specified(sound_interval))
		bubble_tween.tween_interval(first_interval)
		remaining =  remaining - first_interval - bubble_time
		first_interval= first_interval/2


func stop_bubble_until():
	bubble_tween.kill()
	Sound.stop_se_specified(sound_interval)


func _on_fish_hp_cooldown_timeout():
	print("stop by fish timer")
	var node: Node2D
	for area in sound_areas:
		if area.overlaps_body(player):
			node = area.get_parent()
	if sequences_dict[Global.current_fish.name][2] == "parallel":
		stop_parallel(node)
	else:
		stop(node)
