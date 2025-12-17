class_name Luring

extends Node2D

signal sound_node_moved(node)

enum State {
	INTRO,# gives an introduction to the minigame & help with commands
	LURING,# the game sequence
	OUTRO,# the outcome (succeeded/failed)
}

const DIR := {
	"LEFT" = Vector2i.LEFT,
	"RIGHT" = Vector2i.RIGHT,
	"UP" = Vector2i.UP,
	"DOWN" = Vector2i.DOWN,
	"CENTER" = Vector2i.ZERO
}

@export var rod_damage: int = 1
@export var fish_damage: int = 5
@export var fish_hp: int = 100:
	set(value):
		if value < 0:
			value = 0
			current_state = State.OUTRO
			scene_outro()
		fish_hp = value

@export var voice_intro: VoiceResource
@export var voice_help: Resource
@export var sound_succeed: AudioStream

## stock the sound_node currently modified here
var current_sound_node: Sound2D
## state of the scene
var current_state: State = State.INTRO
## if true, inputs are allowed
var inputs: bool = false
## if true, the timing for the minigame is accepted
var timing_succeed: bool = false

@onready var fish_hp_cooldown := $FishHPCooldown
@onready var rod_hp_cooldown := $RodHPCooldown
@onready var player := $Player
@onready var player_listener := $Player/AudioListener2D
@onready var sound_node := {
	"LEFT" : $Sound2DNodes/Sound2DLeft,
	"CENTER" : $Sound2DNodes/Sound2DCenter,
	"RIGHT" : $Sound2DNodes/Sound2DRight,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	set_sound_nodes_position()
	player.position = Global.get_viewport_directed_position(DIR.CENTER)
	scene_intro()


func _unhandled_input(event):
	if event == null:
		return
	elif not inputs:
		return
	if event.is_action_pressed("top") and current_state == State.LURING:
		Signals.scene_requested.emit("toggle_pause")
	else:
		pass


func damage(succeeded: bool):
	if succeeded:
		Sound.play_se(sound_succeed)
		fish_hp -= fish_damage
	else:
		Global.current_fishing_rod.take_damage(rod_damage)


func move_audio_node_to_direction(node: Sound2D, direction: Vector2i, 
		time: float = 1.0, easing: bool = false, ease_type: Tween.EaseType = Tween.EaseType.EASE_OUT):
	var final_position := Global.get_viewport_directed_position(direction)
	var move := create_tween()
	if easing:
		move.set_ease(ease_type)
	move.tween_property(node, "position", final_position, time).from(node.position)
	move.tween_callback(func(): sound_node_moved.emit(node))


func set_sound_nodes_position():
	for key in sound_node.keys():
		set_sound_node_position(sound_node[key], DIR[key])


func set_sound_node_position(node: Sound2D, direction: Vector2i):
	node.position = Global.get_viewport_directed_position(direction)


func scene_intro():
	inputs = false
	Sound.play_voice(voice_intro)
	Sound.play_voice(voice_help)
	Sound.all_voices_finished.connect(scene_luring)
	inputs = true


func scene_luring():
	current_state = State.LURING
	if Sound.all_voices_finished.is_connected(scene_luring):
		Sound.all_voices_finished.disconnect(scene_luring)


func scene_outro():
	inputs = false
	for sound_player in sound_node:
		sound_node[sound_player].stop()
	fish_hp = 100
	Sound.play_se(Sound.effects["luring_catched"])
	Signals.rod_state.emit("idle")
	Sound.play_voice(Sound.voices["pause_0_5_s"])
	Sound.play_voice(load("res://sounds/voice_resources/luring/bite.tres"))
	await Sound.all_voices_finished
	Signals.scene_requested.emit("catching")

