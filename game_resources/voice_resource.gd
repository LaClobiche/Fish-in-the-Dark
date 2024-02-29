class_name VoiceResource

extends Resource

## the audio_stream file(s) : your can place multiple variation of the same voice
@export var audio: Array
## the audio_stream file(s) played if touchscreen enabled : your can place multiple variation of the same voice
@export var audio_touchscreen: Array
## true if the voice is an helper
@export var help: bool = false


func _init(p_audio = [], p_help = false, p_audio_touchscreen = []):
	audio = p_audio
	help = p_help
	audio_touchscreen = p_audio_touchscreen


func get_audio(touchscreen: bool = false) -> AudioStream:
	var audio_array = audio_touchscreen if touchscreen and not audio_touchscreen.is_empty() else audio
	var size := audio_array.size()
	if size == 1:
		return audio_array.front()
	else:
		return audio_array[randi() % size]
