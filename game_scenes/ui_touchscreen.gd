extends CanvasLayer


@onready var buttons := {
	"top" : $MarginContainer/VBoxContainer/TPanel/TButton,
	"left" : $MarginContainer/VBoxContainer/HBoxContainer/LPanel/LButton,
	"right" : $MarginContainer/VBoxContainer/HBoxContainer/RPanel/RButton,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	for button in buttons:
		buttons[button].pressed.connect(send_input_event.bind(true, button))
		buttons[button].released.connect(send_input_event.bind(false, button))
	get_viewport().size_changed.connect(set_buttons_global_transform)
	RenderingServer.frame_post_draw.connect(set_buttons_global_transform)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func send_input_event(pressed: bool, input_name: String):
	var event = InputEventAction.new()
	event.action = input_name
	event.pressed = pressed
	Input.parse_input_event(event)


func set_buttons_global_transform():
	if RenderingServer.frame_post_draw.is_connected(set_buttons_global_transform):
		RenderingServer.frame_post_draw.disconnect(set_buttons_global_transform)
	for button in buttons:
		var rect: Rect2 = buttons[button].get_parent().get_rect()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		buttons[button].position = (rect.size / 2)
		buttons[button].shape = shape
