extends Node2D


var noise := FastNoiseLite.new()
var amplitude_offset: float = 10
var self_variation: float

@onready var floating_labels := [$FloatingLabel1, $FloatingLabel2, $FloatingLabel3, $FloatingLabel4]

# Called when the node enters the scene tree for the first time.
func _ready():
	noise.frequency = 0.01


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	apply_noise()


func apply_noise():
	var time_elapsed := Time.get_ticks_msec() / 200.0
	for label in floating_labels:
		var noise_value1: float = noise.get_noise_2d(time_elapsed * 2, time_elapsed + label.self_variation)
		var noise_value2: float = noise.get_noise_2d(time_elapsed + label.self_variation, time_elapsed * 2)
		# noise offset
		var random_direction := Vector2(noise_value1, 
				noise_value2).normalized()
		label.position = label.initial_position + (random_direction * amplitude_offset)

func set_floating_labels(labels_text: Array[String]):
	if labels_text.size() != 4:
		print("floating_text.gd; set_floating_labels; must be an array of 4 strings")
	else:
		var counter:= 0
		for label in floating_labels:
			label.set_label(labels_text[counter])
			counter += 1

func set_highlighted_label(label_text: String):
	for label in floating_labels:
		if label.text == label_text:
			label.highlight(true)
		else:
			label.highlight(false)
