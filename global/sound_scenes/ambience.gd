extends Node

## this script ensure that the next ambience sound is played exactly after the previous,
## it can only play one ambience sound at a time and uses two AudioStreamPlayer2D as slots

@onready var ambience_slots := [$AmbienceSlot1, $AmbienceSlot2]


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func play(audio: AudioStream, do_fade_in: bool = false, from_position: float = 0.0):
	var audio_stream: AudioStream
	if audio is AudioStream:
		audio_stream = audio
	else:
		print("ambience.gd, play : argument type not supported")
		return

	var playing_slots := []
	var stopped_slots := []

	for player in ambience_slots:
		if player.playing:
			playing_slots.append(player)
		else:
			stopped_slots.append(player)

	var slot_to_use: AudioStreamPlayer2D

	if playing_slots.size() == ambience_slots.size():
		stop()
		slot_to_use = ambience_slots[0]
	elif playing_slots.size() == 0:
		slot_to_use = ambience_slots[0]
	elif playing_slots.size() == 1 and stopped_slots.size() == 1:
		slot_to_use = stopped_slots[0]
		playing_slots[0].stop()
	else:
		print("ambience.gd, play : unexpected number of playing_slots")
		return

	# Prépare le slot pour jouer
	slot_to_use.stream = audio_stream
	if do_fade_in:
		slot_to_use.volume_db = -80.0
	else:
		slot_to_use.volume_db = 0.0
	slot_to_use.seek(from_position)
	slot_to_use.play()

	# Applique le fade-in si demandé
	if do_fade_in:
		var tween = create_tween()
		tween.tween_property(slot_to_use, "volume_db", 0.0, 1.0)
		

#doens't work
func fade_in(time: float = 1.0):
	var targeted_db := 0.0 
	for slot in ambience_slots:
		var fade_in_tween := create_tween()
		fade_in_tween.tween_property(slot, "volume_db", targeted_db, time).from(-80.0)


func fade_out(time: float = 1.0):
	var targeted_db := -80.0
	for slot in ambience_slots:
		if slot.playing:
			var fade_out_tween := create_tween()
			fade_out_tween.tween_property(slot, "volume_db", targeted_db, time).from(0.0)


func stop():
	for player in ambience_slots:
		player.stop()
