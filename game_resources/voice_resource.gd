class_name VoiceResource

extends Resource

## the audio_stream file(s) : your can place multiple variation of the same voice
@export var audio: Array
## the audio_stream file(s) played if touchscreen enabled : your can place multiple variation of the same voice
@export var audio_touchscreen: Array
## true if the voice is an helper
@export var help: bool = false
## subtitle
@export var subtitle: String
## subtitle for touchscreen, used if there is an audio_touchscreen
@export var subtitle_touchscreen: String


func _init(p_audio = [], p_help = false, p_audio_touchscreen = [], p_subtitle = "", p_subtitle_touchscreen = ""):
	audio = p_audio
	help = p_help
	audio_touchscreen = p_audio_touchscreen
	subtitle = p_subtitle
	subtitle_touchscreen = p_subtitle_touchscreen


func get_resources(touchscreen: bool = false) -> Array:
	# get the audio resource
	var audio_array = audio_touchscreen if touchscreen and not audio_touchscreen.is_empty() else audio
	var size := audio_array.size()
	var audio_to_return: AudioStream
	if size == 1:
		audio_to_return = audio_array.front()
	else:
		audio_to_return = audio_array[randi() % size]
	# get the subtitle resource
	var sub_to_return = subtitle_touchscreen if touchscreen and not audio_touchscreen.is_empty() and not subtitle_touchscreen.is_empty() else subtitle
	return [audio_to_return, sub_to_return]
