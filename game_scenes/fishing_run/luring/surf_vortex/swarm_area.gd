extends Area2D

@export var speed: float = 300.0
@export var distance_max: float = 300
@export var pitch_scale: float = 1.0:
	set(value):
		value = clampf(value, 0.01, 4.0)
		pitch_scale = value
		sound2d.set_pitch_scale(value)
		sound2d2.set_pitch_scale(value)

var distance := 0.0

@onready var sound2d := $Sound2D
@onready var sound2d2 := $Sound2D2

# Called when the node enters the scene tree for the first time.
func _ready():
	sound2d2.play(load("res://sounds/effects/luring/surf_vortex/insects.wav"))
	sound2d.play(load("res://sounds/effects/luring/surf_vortex/insects.wav"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var velocity := Vector2.ZERO
	velocity.y = speed * delta
	position = position + velocity
	distance += velocity.y
	if distance > distance_max:
		queue_free()
