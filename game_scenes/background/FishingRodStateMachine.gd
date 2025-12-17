extends TextureRect

enum State {
	HIDDEN,
	IDLE,
	LEFT,
	RIGHT,
}

var current_state := State.HIDDEN:
	set(target):
		if target == current_state:
			pass
		else:
			if target == State.HIDDEN:
				if current_state == State.IDLE:
					animation_player.play("rod_catch")
				elif current_state == State.RIGHT:
					animation_player.play_backwards("rod_right_from_idle")
					animation_player.queue("rod_catch")
				elif current_state == State.LEFT:
					animation_player.play_backwards("rod_left_from_idle")
					animation_player.queue("rod_catch")
				else:
					pass
			elif target == State.IDLE:
				if current_state == State.HIDDEN:
					animation_player.play("rod_launch")
				elif current_state == State.RIGHT:
					animation_player.play_backwards("rod_right_from_idle")
				elif current_state == State.LEFT:
					animation_player.play_backwards("rod_left_from_idle")
				else:
					pass
			elif target == State.RIGHT:
				if current_state == State.HIDDEN:
					animation_player.play("rod_launch")
					animation_player.queue("rod_right_from_idle")
				elif current_state == State.IDLE:
					animation_player.play("rod_right_from_idle")
				elif current_state == State.LEFT:
					animation_player.play("rod_right_from_left")
				else:
					pass
			elif target == State.LEFT:
				if current_state == State.HIDDEN:
					animation_player.play("rod_launch")
					animation_player.queue("rod_left_from_idle")
				elif current_state == State.IDLE:
					animation_player.play("rod_left_from_idle")
				elif current_state == State.RIGHT:
					animation_player.play("rod_left_from_right")
				else:
					pass
			current_state = target
			

@onready var animation_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.rod_state.connect(set_rod_state)


func set_rod_state(state:String):
	if state == "hidden":
		current_state = State.HIDDEN
	elif state == "idle":
		current_state = State.IDLE
	elif state == "right":
		current_state = State.RIGHT
	elif state == "left":
		current_state = State.LEFT
	else:
		pass
	
