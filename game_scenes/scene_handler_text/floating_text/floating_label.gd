extends Label

var initial_position: Vector2
var self_variation: float

# Called when the node enters the scene tree for the first time.
func _ready():
	highlight(false)
	set_label("")
	initial_position = position
	self_variation = position.y + position.x


func set_label(given_text: String):
	text = given_text

func highlight(is_true: bool):
	if is_true:
		self_modulate = Color.WHITE
	else:
		self_modulate = Color.hex(0xffffff28)
