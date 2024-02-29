class_name SoundEffectResource

extends Resource

## the audio_stream file(s) : your can place multiple variation of the same voice
@export var audio: Array


func _init(p_audio = []):
	audio = p_audio


func get_audio() -> AudioStream:
	var size := audio.size()
	if size == 1:
		return audio.front()
	else:
		return audio[randi() % size]
