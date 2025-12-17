extends MarginContainer

var floating_text_scene := load("res://game_scenes/scene_handler_text/floating_text.tscn")
var instanced_floating_text_scene : Node
@onready var logo := $Logo


# Called when the node enters the scene tree for the first time.
func _ready():
	update_logo()
	Signals.downsize_logo.connect(downsize_logo)
	Signals.update_logo.connect(update_logo)
	Signals.set_floating_text.connect(set_floating_text)
	Signals.set_floating_text_highlighted_label.connect(set_highlighted_label)
	Signals.free_floating_text.connect(free_floating_text)

func downsize_logo():
	#var logo_position_start := Vector2(610, -312)
	var logo_position_end := Vector2(1160, 624)
	#var logo_scale_start := Vector2(5.0, 5.0)
	var logo_scale_end := Vector2(2.0,2.0)
	#var logo_modulate_start := Color.WHITE
	var logo_modulate_end := Color("ffffff96")
	var tween := create_tween()
	tween.set_parallel().set_ease(Tween.EASE_IN)
	tween.tween_property(logo, "position", logo_position_end, 0.5).from_current()
	tween.tween_property(logo, "scale", logo_scale_end, 0.5).from_current()
	tween.tween_property(logo, "modulate", logo_modulate_end, 0.5).from_current()


func update_logo():
	if Saves.data["game_finished"] == true:
		logo.texture = load("res://game_scenes/scene_handler_text/logo_finished.png")
	else:
		pass

## functions for the floating text Signals
func set_floating_text(labels_text: Array[String]):
	if instanced_floating_text_scene != null:
		instanced_floating_text_scene.queue_free()
	instanced_floating_text_scene = floating_text_scene.instantiate()
	add_child(instanced_floating_text_scene)
	instanced_floating_text_scene.set_floating_labels(labels_text)

func set_highlighted_label(label_text):
	if instanced_floating_text_scene != null:
		instanced_floating_text_scene.set_highlighted_label(label_text)

func free_floating_text():
	if instanced_floating_text_scene != null:
		instanced_floating_text_scene.queue_free()
