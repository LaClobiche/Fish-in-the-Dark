class_name VoiceArray

extends Resource

## put your voice_resource files in play order
@export var voice_array: Array
## if this resource is a number, get_narrative_block will return number.
@export var is_number: bool = false
## if this resource is a number, get_audio will return this number.
@export var number: int = 0

func _init(p_voice_array = [], p_is_number = false, p_number = 0):
	voice_array = p_voice_array
	is_number = p_is_number
	number = p_number


## if with_helper, gives a narrative_block with additional helpers.
## if play_once, gives a narrative_block with voices that should play once. 
func get_voice_array(with_helper: bool = Saves.data["options"]["helper"], 
		touchscreen: bool = Global.touchscreen) -> Array:
	var array_to_return := []
	if is_number:
		array_to_return.append_array(get_number())
	else:
		for voice_resource in voice_array:
			if voice_resource.help and not with_helper:
				pass
			else:
				var audio: AudioStream = voice_resource.get_audio(touchscreen)
				if audio != null:
					array_to_return.append(audio)
				else:
					print("narrative_block.gd, get_narrative_block: error,
							 tried to append a null voice_resource audio.
							\n Empty voice_resource: " + voice_resource.resource_path)
	return array_to_return


## return an array of audio_stream that says the number
func get_number() -> Array:
	# TODO
	var array_to_return: Array = []
	var path_to_number_files: String = "res://sounds/voice_resources/numbers/"
	var number_str := str(number)
	
	if number_str.length() == 3:
		# pop the first number to have only the tens left.
		var hundred_number = number_str.left(1)
		number_str = number_str.erase(0)
		var hundred_number_voice: AudioStream = load(path_to_number_files + hundred_number + ".mp3")
		array_to_return.append(hundred_number_voice)
		var hundred_voice: AudioStream = load(path_to_number_files + "100.mp3")
		array_to_return.append(hundred_voice)
	
	if number_str.length() == 2:
		match number_str:
			"00":
				number_str = ""
			# pronounce "and" before the unit
			"01","02","03","04","05","06","07","08","09":
				var and_voice: AudioStream = load(path_to_number_files + "0_.mp3")
				array_to_return.append(and_voice)
				var unit_number := number_str.right(1)
				var unit_number_voice: AudioStream = load(path_to_number_files + unit_number + ".mp3")
				array_to_return.append(unit_number_voice)
				number_str = ""
			# select unique voice for uniquely pronouced numbers
			"10","11","12","13","14","15","16","17","18","19","20","30","40","50","60","70","80","90":
				var tens_unique_voice: AudioStream = load(path_to_number_files + number_str + ".mp3")
				array_to_return.append(tens_unique_voice)
				number_str = ""
			# select the tens number and continue with "if number_str.length() == 1"
			_:
				# pop the first number to have the units left.
				var tens_number := number_str.left(1)
				number_str = number_str.erase(0)
				var tens_number_voice: AudioStream = load(path_to_number_files + tens_number + "0.mp3")
				array_to_return.append(tens_number_voice)
	
	if number_str.length() == 1:
		var unit_number := number_str
		var unit_number_voice: AudioStream = load(path_to_number_files + unit_number + ".mp3")
		array_to_return.append(unit_number_voice)
	return array_to_return
