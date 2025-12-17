extends Node

## this AUTOLOAD script contains all the signals used globally.

## UI SIGNALS
signal menu_requested(menu_array_of_strings, current_index_if_not_0, label_separation_if_not_20)
signal menu_index_changed(new_index)
signal menu_selected
signal menu_opened
signal menu_closed

signal subtitle_requested(text)
signal subtitle_closed

signal set_floating_text(array_of_4_strings)
signal set_floating_text_highlighted_label(string)
signal free_floating_text

# Visuals signal

signal fade_in_black
signal fade_out_black

signal glitch_show
signal glitch_hide

signal vortex_particle_hide
signal vortex_particle_show

signal fish_show(fish_resource)
signal fish_hide

signal downsize_logo
signal update_logo

signal rod_state(state)

signal flash

signal breach_panel_hide
signal breach_panel_show

signal lure_position(global_position)
signal casting_lure()

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
