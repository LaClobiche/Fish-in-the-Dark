extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.subtitle_requested.connect(set_subtitle)
	Signals.subtitle_closed.connect(close_subtitle)


func set_subtitle(given_text: String):
	text = given_text


func close_subtitle():
	text = ""
