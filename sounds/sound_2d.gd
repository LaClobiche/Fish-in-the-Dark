class_name Sound2D

extends Node2D

signal finished

var wait: Tween
var current_tweens := []

var max_distance: float = 2000.0:
	set(value):
		value = clampf(value, 0.0, 2000.0)
		max_distance = value
		set_max_distance(value)
var volume_db: float = 0.0:
	set(value):
		value = clampf(value, -80.0, 24.0)
		volume_db = value
		set_volume_db(value)
var playing: bool = false

func _ready():
	connect_players_finished_to_callable(emit_finished)
#	$AudioStreamPlayer2D1.stream = load("res://sounds/effects/luring/catch_sound/chant0.mp3")
#	$AudioStreamPlayer2D1.play(2.0)
#func _process(delta):
#	print($AudioStreamPlayer2D1.get_playback_position())


func clear_tweens():
	if current_tweens != null:
		for tween in current_tweens:
			tween.kill()
		current_tweens.clear()


func fade_out_tween(tween: Tween, node: Node):
	tween.tween_property(node, "volume_db", -80.0, 0.6).from_current()
	tween.tween_callback(func(): node.set_volume_db(0.0))
	tween.tween_callback(func(): node.stop())


func fade_in_tween(tween: Tween, node: Node):
	tween.tween_property(node, "volume_db", 0.0, 0.3).from(-80.0)


func is_playing() -> bool:
	var bool_to_return: bool = false
	for player in get_children():
		if player is AudioStreamPlayer2D:
			if player.is_playing():
				bool_to_return = true
				break
	return bool_to_return


func is_playing_specific(audio) -> bool:
	var bool_to_return: bool = false
	if audio == null:
		return false
	elif audio is SoundEffectResource:
		for stream in audio.audio:
			for player in get_children():
				if player is AudioStreamPlayer2D:
					if player.is_playing() and player.stream == audio:
						bool_to_return = true
						break
	elif audio is AudioStream:
		for player in get_children():
			if player is AudioStreamPlayer2D:
				if player.is_playing() and player.stream == audio:
					bool_to_return = true
					break
	else:
		print("sound.gd, is_se_playing : argument type not supported")
	return bool_to_return


func play(audio, from_position: float = 0.0, fade_in=false, fade_out_from: float = 0.0):
	var audio_stream: AudioStream
	if audio is SoundEffectResource:
		audio_stream = audio.get_audio()
	elif audio is AudioStream:
		audio_stream = audio
	else:
		print("sound2d.gd, play : argument type not supported")
		return
#	if single:
#		stop()
	for player in get_children():
		if player is AudioStreamPlayer2D:
			if not player.playing:
				player.stream = audio_stream
				player.volume_db = volume_db
				player.seek(from_position)
				clear_tweens()
				var tween := create_tween()
				current_tweens.append(tween)
				tween.tween_callback(func(): player.play(from_position))
				if fade_in:
					fade_in_tween(tween, player)
				if fade_out_from != 0.0:
					tween.tween_interval(fade_out_from)
					fade_out_tween(tween, player)
				break


func stop(fade_out:bool = false):
	for player in get_children():
		if player is AudioStreamPlayer2D:
			if fade_out:
				if player.playing:
					clear_tweens()
					var tween := create_tween()
					current_tweens.append(tween)
					fade_out_tween(tween, player)
					tween.tween_callback(func(): player.playing = false)
				else:
					player.stop()
					playing = false
			else:
				player.stop()
				playing = false


func stop_specified(audio: AudioStream):
	for player in get_children():
		if player is AudioStreamPlayer2D and player.stream == audio:
			player.stop()
			playing = false


func pause_specified(audio: AudioStream):
	for player in get_children():
		if player is AudioStreamPlayer2D and player.stream == audio:
			player.stream_paused = not player.stream_paused


func set_panning_strength(panning: float = 1.0):
	for player in get_children():
		if player is AudioStreamPlayer2D:
			player.panning_strength = panning


func set_volume_db(value: float):
	value = clampf(value, -80.0, 24.0)
	for player in get_children():
		if player is AudioStreamPlayer2D:
			player.volume_db = value


func set_max_distance(value: float):
	for player in get_children():
		if player is AudioStreamPlayer2D:
			player.max_distance = value


func connect_players_finished_to_callable(callable: Callable):
	for player in get_children():
		if player is AudioStreamPlayer2D:
			player.finished.connect(callable)


func emit_finished():
	for player in get_children():
		if player is AudioStreamPlayer2D:
			if player.playing:
				break
	playing = false
	finished.emit()
