extends Node

## this AUTOLOAD script contains all the signals used globally.

## UI SIGNALS



## EVENTS SIGNALS

signal scene_requested(scene_name)
signal game_over_requested()
signal current_place_changed()

## SOUNDS SIGNALS

# play a sound effect in sequential(queued = true) or parallel(queued = false)
#signal sound_effects(name, queued)
## stop all sounds and clear the queue
#signal sound_effects_stop
## play a music
#signal music(name)
## stop music
#signal music_stop
## play an ambience
#signal ambience(name)
## stop ambience
#signal ambience_stop
## play an voice
#signal voice(name, value)
## stop ambience
#signal voice_stop
