extends Node

signal voice_stopped
signal all_voices_finished
signal all_se_finished

var musics := {
	
}

var voices := {
	"pause_0_5_s" : load("res://sounds/voice_resources/pause_0_5_s.tres"),
	"pause_1_s" : load("res://sounds/voice_resources/pause_1_s.tres"),
}

var ambiences := {
	"pond_night" : load("res://sounds/ambience/pond_night_loop.wav"),
}

var effects := {
	"paper" : load("res://sounds/effects/paper.wav"),
	"paper_reverse" : load("res://sounds/effects/paper_reverse.wav"),
	"write" : load("res://sounds/effects/catching/write.mp3"),
	"walk_out" : load("res://sounds/effects/walk_out.wav"),
	"body_falling" : load("res://sounds/effects/body_falling.mp3"),
	"glass_breaking" : load("res://sounds/effects/glass_breaking.mp3"),
	"cassette_motor" : load("res://sounds/effects/credits/cassette_motor.mp3"),
	"cassette_in" : load("res://sounds/effects/credits/cassette_in.mp3"),
	"cassette_out" : load("res://sounds/effects/credits/cassette_out.mp3"),
	"casting_loud" : load("res://sounds/effects/casting/cast_the_rod_loud.mp3"),
	"casting_normal" : load("res://sounds/effects/casting/cast_the_rod_normal.mp3"),
	"casting_strengthen" : load("res://sounds/effects/casting/gather_strength.wav"),
	"casting_whoosh" : load("res://sounds/effects/casting/whoosh.wav"),
	"casting_swish" : load("res://sounds/effects/casting/swish.wav"),
	"casting_exhausted" : load("res://sounds/effects/casting/exhausted_voice.wav"),
	"casting_lure_in" : load("res://sounds/effects/casting/lure_in_water.mp3"),
	"fish_catched" : load("res://sounds/effects/catching/out_of_water_grip_swish.wav"),
	"crunch" : load("res://sounds/effects/luring/surf_vortex/crunch.wav"),
	"voice_catching" : load("res://sounds/effects/catching/voice_catching.tres"),
	"luring_catched" : load("res://sounds/effects/luring/catched0.mp3"),
	"reeling_super_slow" : load("res://sounds/effects/reeling_super_slow.wav"),
	"reeling_slow" : load("res://sounds/effects/reeling_slow.wav"),
	"reeling_normal" : load("res://sounds/effects/reeling_normal.wav"),
	"reeling_fast" : load("res://sounds/effects/reeling_fast.wav"),
	"reeling_super_fast" : load("res://sounds/effects/reeling_super_fast.wav"),
	"bubbles" : load("res://sounds/effects/bubbles.mp3"),
	"bubbles_loop" : load("res://sounds/effects/bubbles_loop.mp3"),
	"bubbles_loop_low" : load("res://sounds/effects/bubbles_loop_low.wav"),
	"bubbles_loop_super_low" : load("res://sounds/effects/bubbles_loop_super_low.wav"),
	"splashes_loop" : load("res://sounds/effects/splashes_loop.wav"),
	"splashes_loop_fast" : load("res://sounds/effects/splashes_loop_fast.wav"),
	"rod_damage_crack" : load("res://sounds/effects/rod_damage.tres"),
	"move_left" : load("res://sounds/effects/loading_left.wav"),
	"move_right" : load("res://sounds/effects/loading_right.wav"),
	"pull_left" : load("res://sounds/effects/catching/angling_left_low.tres"),
	"pull_right" : load("res://sounds/effects/catching/angling_right_low.tres"),
	"insects_eating" : load("res://sounds/effects/luring/surf_vortex/insects_eating.wav"),
}

# contains array of array of voices, a voice is an array containing [AudioStream, subtitle: String]
var voice_queue: Array[Array] = []
# contain current array of voices
var voice_array: Array = []

@onready var voice: AudioStreamPlayer2D = load("res://global/sound_scenes/voice.tscn").instantiate()
@onready var music : AudioStreamPlayer2D = load("res://global/sound_scenes/music.tscn").instantiate()
@onready var ambience : Node = load("res://global/sound_scenes/ambience.tscn").instantiate()
@onready var sound_effects: Node = load("res://global/sound_scenes/sound_effects.tscn").instantiate()


func _ready():
	add_child(voice)
	add_child(music)
	add_child(ambience)
	add_child(sound_effects)
	voice.finished.connect(play_next_voice)
	sound_effects.finished.connect(emit_all_se_finished)


func play_music(audio: AudioStream):
	play(audio, music)


func stop_music():
	stop(music)


# if is playing, add audio to voice_queue. If it is not playing, play immediately.
func play_voice(voice_audio, with_helper: bool = Saves.data["options"]["helper"]):
	if voice_audio is VoiceArray:
		voice_queue.append(voice_audio.get_voice_array(with_helper))
	elif voice_audio is VoiceResource:
		if not with_helper and voice_audio.help:
			pass
		else:
			var voice_to_append: Array = voice_audio.get_resources(Global.touchscreen)
			if voice_to_append[0] != null:
				voice_queue.append([voice_to_append])
	elif voice_audio is AudioStream:
		voice_queue.append([[voice_audio, ""]])
	else:
		print("sound.gd, play_voice : argument type not supported")
	if not voice.playing:
			voice.stream = get_next_voice()[0]
			voice.playing = true


func play_next_voice():
	var audio: AudioStream = get_next_voice()[0]
	if audio != null:
		voice.stream = audio
		voice.playing = true
	else:
		voice.playing = false
		all_voices_finished.emit()


func get_next_voice() -> Array:
	var voice_resource = null
	var audio: AudioStream = null
	var subtitle: String = ""
	if not voice_array.is_empty():
		voice_resource = voice_array.pop_front()
	elif not voice_queue.is_empty():
		voice_array = voice_queue.pop_front()
		voice_resource = get_next_voice()
	else:
		pass
	if voice_resource != null:
		audio = voice_resource[0]
		subtitle = voice_resource[1]
	Signals.subtitle_requested.emit(subtitle)
	return [audio, subtitle]


# stop voice & clear voice_array
func stop_voice_array():
	voice_array.clear()
	Signals.subtitle_requested.emit("")
	if voice.playing:
		voice.stop()
#	-> if fade_out wanted, need to create another instance for the next voice_queue, 
#	then delete the current instance.
#	if voice.playing:
#		var fade := create_tween()
#		fade_tween(fade, voice)


func stop_voice_array_and_queue():
	voice_queue.clear()
	stop_voice_array()


func is_voices_playing() -> bool:
	if voice_queue.is_empty() and voice_array.is_empty() and not voice.playing:
		return false
	else:
		return true


func play_ambience(audio: AudioStream, fade_in: bool = false):
	ambience.play(audio, fade_in)

func fade_out_ambience(time: float = 1_0):
	ambience.fade_out(time)


func stop_ambience():
	ambience.stop()


func play_se(audio, queued: bool = false, parallel_delay: float = 0.0):
	if audio is SoundEffectResource:
		sound_effects.play(audio.get_audio(), queued, parallel_delay)
	elif audio is AudioStream:
		sound_effects.play(audio, queued, parallel_delay)
	else:
		print("sound.gd, play_se : argument type not supported")


func is_se_playing(audio) -> bool:
	var bool_to_return: bool = false
	if audio == null:
		return false
	elif audio is SoundEffectResource:
		for stream in audio.audio:
			if sound_effects.is_playing(stream):
				bool_to_return = true
				break
	elif audio is AudioStream:
		bool_to_return = sound_effects.is_playing(audio)
	else:
		print("sound.gd, is_se_playing : argument type not supported")
	return bool_to_return


func stop_se():
	sound_effects.stop()


func stop_se_specified(audio):
	if audio is SoundEffectResource:
		for stream in audio.audio:
			if sound_effects.is_playing(stream):
				sound_effects.stop_specified(stream)
	elif audio is AudioStream:
		sound_effects.stop_specified(audio)
	else:
		print("sound.gd, stop_se_specified : argument type not supported")


func emit_all_se_finished():
	all_se_finished.emit()


func play(audio: AudioStream, node: Node) -> void:
	if not audio:
		return
	if node.playing:
		var fade := create_tween()
		fade_out_tween(fade, node)
		fade.tween_callback(play.bind(audio, node))
	else:
		var fade := create_tween()
		node.stream = audio
		node.play()
		fade_in_tween(fade, node)


func stop(node: Node) -> void:
	if node.playing:
		var fade := create_tween()
		fade_out_tween(fade, node)


func fade_out_tween(tween: Tween, node: Node):
	tween.tween_property(node, "volume_db", -80.0, 0.8).from_current()
	tween.tween_callback(func(): node.set_volume_db(0.0))
	tween.tween_callback(func(): node.stop())


func fade_in_tween(tween: Tween, node: Node):
	tween.tween_property(node, "volume_db", 0.0, 0.8).from(-80.0)

