# meta-name: LuringScene
# meta-description: Predefined functions for Luring scene
# meta-default: true
# meta-space-indent: 4

extends Luring
#signal sound_node_moved(node)
#State.INTRO/LURING/OUTRO
#DIR.LEFT/RIGHT/UP/DOWN/CENTER
#var current_sound_node: Sound2D
#var inputs: bool = false
#var timing_succeed: bool = false
#var current_state: State = State.INTRO
#var player := $Player
#var sound_node := {"LEFT","CENTER","RIGHT"}

#func is_timing_succeed(damage_on: bool = true) -> bool:

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()


func _unhandled_input(event):
	super._unhandled_input(event)
	if current_state == State.INTRO:
		if event.is_action_pressed("left") or event.is_action_pressed("right"):
			Sound.play_next_voice()
	elif current_state == State.OUTRO:
		pass
	else:#current_state == State.LURING
		if event.is_action_pressed("left") and not Sound.is_se_playing(Sound.effects["move_left"]):
			Sound.play_se(Sound.effects["move_left"])
		if event.is_action_pressed("right") and not Sound.is_se_playing(Sound.effects["move_right"]):
			Sound.play_se(Sound.effects["move_right"])


# launched when intro is over.skipped
func scene_luring():
	super.scene_luring()
	pass


# launched when fish_hp == 0
func scene_outro():
	super.scene_outro()
	pass
