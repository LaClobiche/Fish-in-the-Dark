extends Node

signal finished

var sounds_queue := []

@onready var se :=$SE
@onready var se_parallel := [
	$SEParallel1,
	$SEParallel2,
	$SEParallel3,
	$SEParallel4,
	$SEParallel5,
	$SEParallel6,
]


func _ready():
	set_process(false)
	se.finished.connect(play_queue)


func _process(_delta):
	pass


func is_playing(audio: AudioStream) -> bool:
	var every_se : Array = se_parallel
	every_se.append(se)
	for node in every_se:
		if node.playing and node.stream == audio:
			return true
	return false


func play(audio: AudioStream, queued: bool = false, parallel_delay: float = 0.0):
	if queued:
		add_to_queue(audio)
	else:
		if parallel_delay != 0.0:
			var parallel_tween := create_tween()
			parallel_tween.tween_interval(parallel_delay)
			parallel_tween.tween_callback(play_parallel.bind(audio))
		else:
			play_parallel(audio)

func stop():
	clear_queue()
	stop_playing()


func stop_specified(audio: AudioStream):
	var every_se : Array = se_parallel
	every_se.append(se)
	for node in every_se:
		if node.playing and node.stream == audio:
			node.playing = false
			node.stream = null

 ## functions to use sounds in sequence.


func play_queue():
	var sound: AudioStream = sounds_queue.pop_front()
	if sound != null:
		se.stream = sound
		se.playing = true
	else:
		se.playing = false
		finished.emit()


func add_to_queue(audio: AudioStream):
	sounds_queue.append(audio)
	if not se.playing:
		se.stream = sounds_queue.pop_front()
		se.playing = true


func clear_queue():
	sounds_queue.clear()


func stop_playing():
	for node in get_children():
		node.playing = false
		node.stream = null


## functions to play sounds in parallel


func play_parallel(audio: AudioStream):
	var sound_effect_node: Node
	for node in se_parallel:
		if not node.playing:
			sound_effect_node = node
			break
	if sound_effect_node == null:
		print("sound_effects.gd, se_parallel full : create new instance")
		sound_effect_node = se.duplicate()
		add_child(sound_effect_node)
		se_parallel.append(sound_effect_node)
	sound_effect_node.stream = audio
	sound_effect_node.playing = true
	sound_effect_node.finished.connect(func(): finished.emit())
