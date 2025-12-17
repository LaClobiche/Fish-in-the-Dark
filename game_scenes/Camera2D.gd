extends Camera2D

signal move_camera_finished


# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.move_camera_requested.connect(move_camera)

func move_camera(from: Vector2 = position, to: Vector2 = position, 
			zoom: Vector2 = Vector2.ONE, speed: float = 1.0, stay_enabled: bool = false):
	self.enabled = true
	var cam_tween := create_tween().set_ease(Tween.EASE_OUT).set_parallel(true)
	cam_tween.tween_property(self, "zoom", zoom, speed).from_current()
	cam_tween.tween_property(self, "global_position", to, speed).from(from)
	await cam_tween.finished
	if not stay_enabled:
		self.enabled = false
	move_camera_finished.emit()
